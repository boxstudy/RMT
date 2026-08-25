// =============================================================================
// Flow canvas: node connections, ports, dragging
// =============================================================================
using System;
using System.Linq;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Controls.Primitives;
using System.Windows.Interop;
using System.Runtime.InteropServices;
using System.Text;
using System.Xml;
using System.Reflection;
using System.Windows.Documents;
using System.Windows.Media;
using System.Windows.Markup;
using Color = System.Windows.Media.Color;

public partial class AhkWpfEngine
{
    // ---- 端口拖线状态机（Idle → Dragging → PendingMenu → Idle）----
    // 所有入口（开始/移动/松手/丢捕获/点节点/点空白/菜单关/AHK 清理）必须走下面几个方法，避免逻辑分散导致幽灵线。
    const int ConnDragIdle = 0;
    const int ConnDragDragging = 1;
    const int ConnDragPendingMenu = 2;
    int connectionDragPhase = 0;
    System.Windows.Shapes.Path tempConnection = null;
    System.Windows.Shapes.Path tempConnectionArrow = null;
    FrameworkElement connectionSourcePort = null;
    Canvas connectionDragCanvas = null;
    Point connectionDragStart = new Point();
    Point connectionLastPos = new Point();
    bool connectionDragCompleting = false;       // MouseUp 内主动 ReleaseCapture 时抑制 LostMouseCapture 重入
    bool suppressTempClearOnMenuClosed = false;  // AHK 重开指令菜单时勿误清临时线
    bool _restoreTopmostAfterMenu = false;       // Topmost 窗系统菜单期间临时取消置顶，避免菜单被压在下方
    // 兼容旧字段名（部分代码路径仍读 pending）
    bool tempConnectionPendingDrop
    {
        get { return connectionDragPhase == ConnDragPendingMenu; }
        set { if (!value && connectionDragPhase == ConnDragPendingMenu) connectionDragPhase = ConnDragIdle; else if (value) connectionDragPhase = ConnDragPendingMenu; }
    }

    // Canvas drag infrastructure: enables real-time C#-side mouse tracking that sends events to AHK
    private System.Collections.Generic.Dictionary<string, double> nodeGridSizes = new System.Collections.Generic.Dictionary<string, double>();
    private System.Collections.Generic.Dictionary<FrameworkElement, bool> dragEnabled = new System.Collections.Generic.Dictionary<FrameworkElement, bool>();

    // 拖动节点时在 WPF 线程直接刷新连线，避免 AHK 往返导致的滞后感
    private const double NodePortY = 31.0;
    private const double ConnArrowInset = 12.0;
    private const double ConnArrowHalfH = 6.5;

    private static double GetNodeCanvasX(FrameworkElement node)
    {
        double x = Canvas.GetLeft(node);
        return double.IsNaN(x) ? 0 : x;
    }

    private static double GetNodeCanvasY(FrameworkElement node)
    {
        double y = Canvas.GetTop(node);
        return double.IsNaN(y) ? 0 : y;
    }

    private static double GetNodeWidth(FrameworkElement node)
    {
        double w = node.ActualWidth;
        if (w <= 1 && !double.IsNaN(node.Width) && node.Width > 0)
            w = node.Width;
        return w > 1 ? w : 200;
    }

    private static bool TryParseConnEndpoints(string pathName, System.Collections.Generic.HashSet<string> nodeIds,
        out string fromId, out string toId)
    {
        fromId = null;
        toId = null;
        if (string.IsNullOrEmpty(pathName)) return false;
        int marker = pathName.IndexOf("_Path_", StringComparison.Ordinal);
        if (marker < 0) return false;
        string rest = pathName.Substring(marker + 6);
        string bestFrom = null, bestTo = null;
        foreach (string id in nodeIds)
        {
            if (id.Length == 0) continue;
            string prefix = id + "_";
            if (!rest.StartsWith(prefix, StringComparison.Ordinal)) continue;
            string candTo = rest.Substring(prefix.Length);
            if (!nodeIds.Contains(candTo)) continue;
            if (bestFrom == null || id.Length > bestFrom.Length)
            {
                bestFrom = id;
                bestTo = candTo;
            }
        }
        if (bestFrom == null) return false;
        fromId = bestFrom;
        toId = bestTo;
        return true;
    }

    private void RefreshNodeConnectionsLive(Canvas canvas, string nodeId)
    {
        if (canvas == null || string.IsNullOrEmpty(nodeId)) return;

        var nodeMap = new System.Collections.Generic.Dictionary<string, FrameworkElement>();
        var nodeIds = new System.Collections.Generic.HashSet<string>();
        foreach (UIElement child in canvas.Children)
        {
            var fe = child as FrameworkElement;
            if (fe == null || string.IsNullOrEmpty(fe.Name) || !fe.Name.StartsWith("Node_", StringComparison.Ordinal))
                continue;
            string id = fe.Name.Substring(5);
            nodeMap[id] = fe;
            nodeIds.Add(id);
        }
        if (!nodeIds.Contains(nodeId)) return;

        foreach (UIElement child in canvas.Children)
        {
            var path = child as System.Windows.Shapes.Path;
            if (path == null || string.IsNullOrEmpty(path.Name) || path.Visibility != Visibility.Visible)
                continue;
            if (path.Name.IndexOf("_Path_", StringComparison.Ordinal) < 0)
                continue;
            string fromId, toId;
            if (!TryParseConnEndpoints(path.Name, nodeIds, out fromId, out toId))
                continue;
            if (fromId != nodeId && toId != nodeId)
                continue;
            FrameworkElement n1, n2;
            if (!nodeMap.TryGetValue(fromId, out n1) || !nodeMap.TryGetValue(toId, out n2))
                continue;

            double startX = GetNodeCanvasX(n1) + GetNodeWidth(n1);
            double startY = GetNodeCanvasY(n1) + NodePortY;
            // IfPro 分支连线：Tag=ifproStartY:相对Y，起点高度跟情况出点对齐
            string tag = path.Tag as string;
            if (!string.IsNullOrEmpty(tag) && tag.StartsWith("ifproStartY:", StringComparison.Ordinal))
            {
                double relY;
                if (double.TryParse(tag.Substring(12), System.Globalization.NumberStyles.Float,
                    System.Globalization.CultureInfo.InvariantCulture, out relY))
                    startY = GetNodeCanvasY(n1) + relY;
            }
            double endX = GetNodeCanvasX(n2);
            double endY = GetNodeCanvasY(n2) + NodePortY;
            // IfPro 历史几何画到入口中心；普通连线止于箭头根部
            bool ifPro = !string.IsNullOrEmpty(tag) && tag.StartsWith("ifproStartY:", StringComparison.Ordinal);
            double lineEndX = ifPro ? endX : (endX - ConnArrowInset);
            double lineEndY = endY;
            double dx = Math.Abs(lineEndX - startX) * 0.5;
            if (dx < 40) dx = 40;
            string geom;
            if (ifPro && Math.Abs(startY - lineEndY) <= 2)
                geom = string.Format(System.Globalization.CultureInfo.InvariantCulture,
                    "M{0},{1} L{2},{3}", startX, startY, lineEndX, lineEndY);
            else
                geom = string.Format(System.Globalization.CultureInfo.InvariantCulture,
                    "M{0},{1} C{2},{3} {4},{5} {6},{7}",
                    startX, startY, startX + dx, startY, lineEndX - dx, lineEndY, lineEndX, lineEndY);
            try { path.Data = Geometry.Parse(geom); } catch { }

            string arrowName = path.Name.Replace("_Path_", "_Arrow_");
            var arrow = FindControlByPath(arrowName) as System.Windows.Shapes.Path;
            if (arrow == null)
            {
                foreach (UIElement ac in canvas.Children)
                {
                    var afe = ac as FrameworkElement;
                    if (afe != null && afe.Name == arrowName) { arrow = afe as System.Windows.Shapes.Path; break; }
                }
            }
            if (arrow != null)
            {
                Canvas.SetLeft(arrow, endX - ConnArrowInset - 1);
                Canvas.SetTop(arrow, endY - ConnArrowHalfH);
            }
        }
    }

    // 从命中源向上找 Port_*（椭圆内部命中时 OriginalSource 可能无 Name）
    private FrameworkElement FindPortElement(DependencyObject src)
    {
        while (src != null)
        {
            var fe = src as FrameworkElement;
            if (fe != null && fe.Name != null && fe.Name.StartsWith("Port_"))
                return fe;
            src = System.Windows.Media.VisualTreeHelper.GetParent(src);
        }
        return null;
    }

    private void RemoveOrphanTempPaths(Canvas canvas, string baseName)
    {
        if (canvas == null) return;
        string cn = baseName + "_TempConn";
        string an = baseName + "_TempArrow";
        for (int i = canvas.Children.Count - 1; i >= 0; i--)
        {
            var fe = canvas.Children[i] as FrameworkElement;
            if (fe == null || fe.Name == null) continue;
            if (fe.Name != cn && fe.Name != an) continue;
            if (fe == tempConnection || fe == tempConnectionArrow) continue;
            try { canvas.Children.RemoveAt(i); } catch { }
        }
    }

    private void DetachTempPath(System.Windows.Shapes.Path path)
    {
        if (path == null) return;
        try
        {
            var parent = path.Parent as Canvas;
            if (parent != null) parent.Children.Remove(path);
        }
        catch { }
    }

    // 拖线临时连线：保证挂在当前画布上；样式与正式节点连线一致（粗线 + 三角箭头）
    private void EnsureTempConnection(Canvas canvas)
    {
        if (canvas == null) return;
        string baseName = string.IsNullOrEmpty(canvas.Name) ? "Canvas" : canvas.Name;
        RemoveOrphanTempPaths(canvas, baseName);

        // 引用还在但不在当前画布上（重建/换画布）→ 丢弃重建，避免「看不见跟随线」
        if (tempConnection != null && !object.ReferenceEquals(tempConnection.Parent, canvas))
        {
            DetachTempPath(tempConnection);
            try { if (win != null && tempConnection.Name != null) win.UnregisterName(tempConnection.Name); } catch { }
            tempConnection = null;
        }
        if (tempConnectionArrow != null && !object.ReferenceEquals(tempConnectionArrow.Parent, canvas))
        {
            DetachTempPath(tempConnectionArrow);
            try { if (win != null && tempConnectionArrow.Name != null) win.UnregisterName(tempConnectionArrow.Name); } catch { }
            tempConnectionArrow = null;
        }

        if (tempConnection == null)
        {
            tempConnection = new System.Windows.Shapes.Path
            {
                Name = baseName + "_TempConn",
                StrokeThickness = 6,
                Opacity = 0.9,
                IsHitTestVisible = false
            };
            try { tempConnection.SetResourceReference(System.Windows.Shapes.Shape.StrokeProperty, "GraphConn"); }
            catch { tempConnection.Stroke = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(96, 160, 255)); }
            System.Windows.Controls.Panel.SetZIndex(tempConnection, 50);
            canvas.Children.Add(tempConnection);
            try { if (win != null) win.RegisterName(tempConnection.Name, tempConnection); } catch { }
            try { _controlCache[tempConnection.Name] = tempConnection; } catch { }
        }
        else
        {
            tempConnection.StrokeThickness = 6;
            tempConnection.Opacity = 0.9;
        }
        if (tempConnectionArrow == null)
        {
            tempConnectionArrow = new System.Windows.Shapes.Path
            {
                Name = baseName + "_TempArrow",
                Data = System.Windows.Media.Geometry.Parse("M0,0 L11,6.5 L0,13 Z"),
                Opacity = 0.95,
                IsHitTestVisible = false
            };
            try { tempConnectionArrow.SetResourceReference(System.Windows.Shapes.Shape.FillProperty, "GraphConn"); }
            catch { tempConnectionArrow.Fill = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(96, 160, 255)); }
            System.Windows.Controls.Panel.SetZIndex(tempConnectionArrow, 51);
            canvas.Children.Add(tempConnectionArrow);
            try { if (win != null) win.RegisterName(tempConnectionArrow.Name, tempConnectionArrow); } catch { }
            try { _controlCache[tempConnectionArrow.Name] = tempConnectionArrow; } catch { }
        }
    }

    private void UpdateTempConnectionVisual(Canvas canvas, Point endPos)
    {
        if (canvas == null || connectionSourcePort == null)
            return;
        EnsureTempConnection(canvas);
        if (tempConnection == null)
            return;
        connectionLastPos = endPos;
        Point portPos = GetCanvasPosition(connectionSourcePort, canvas);
        double startX = portPos.X + connectionSourcePort.Width / 2;
        double startY = portPos.Y + connectionSourcePort.Height / 2;
        if (double.IsNaN(startX)) startX = 0;
        if (double.IsNaN(startY)) startY = 0;

        double tipX = endPos.X;
        double tipY = endPos.Y;
        bool fromOut = connectionSourcePort.Name != null && connectionSourcePort.Name.StartsWith("Port_Out");
        double lineEndX = fromOut ? (tipX - ConnArrowInset) : (tipX + ConnArrowInset);
        double lineEndY = tipY;

        double dx = Math.Max(40, Math.Abs(lineEndX - startX) * 0.5);
        double c1X = fromOut ? (startX + dx) : (startX - dx);
        double c2X = fromOut ? (lineEndX - dx) : (lineEndX + dx);

        string geom = string.Format(System.Globalization.CultureInfo.InvariantCulture,
            "M{0},{1} C{2},{3} {4},{5} {6},{7}",
            startX, startY, c1X, startY, c2X, lineEndY, lineEndX, lineEndY);
        try { tempConnection.Data = System.Windows.Media.Geometry.Parse(geom); } catch { }
        tempConnection.Visibility = Visibility.Visible;

        if (tempConnectionArrow != null)
        {
            try
            {
                tempConnectionArrow.Data = System.Windows.Media.Geometry.Parse(
                    fromOut ? "M0,0 L11,6.5 L0,13 Z" : "M11,0 L0,6.5 L11,13 Z");
            }
            catch { }
            double ax = fromOut ? (tipX - ConnArrowInset - 1) : tipX;
            double ay = tipY - ConnArrowHalfH;
            Canvas.SetLeft(tempConnectionArrow, ax);
            Canvas.SetTop(tempConnectionArrow, ay);
            tempConnectionArrow.Visibility = Visibility.Visible;
        }
    }

    // 统一收起临时线（不改 phase；由 Cancel/Complete 控制 phase）
    private void CollapseTempConnectionVisual()
    {
        if (tempConnection != null)
            tempConnection.Visibility = Visibility.Collapsed;
        if (tempConnectionArrow != null)
            tempConnectionArrow.Visibility = Visibility.Collapsed;
    }

    // force=true：强制收起。拖线中（Dragging）非 force 不收起，防止误 Collapsed 导致 MouseUp 跳过。
    private void HideTempConnection(bool force = false)
    {
        if (!force && connectionDragPhase == ConnDragDragging)
            return;
        CancelConnectionDrag(null, false);
    }

    // 统一取消/复位：释放捕获、清源、收起线、phase→Idle
    private void ResetConnectionDrag(Canvas canvas)
    {
        CancelConnectionDrag(canvas, true);
    }

    private void CancelConnectionDrag(Canvas canvas, bool releaseCapture)
    {
        Canvas c = canvas ?? connectionDragCanvas;
        if (releaseCapture)
        {
            try
            {
                connectionDragCompleting = true;
                if (c != null && c.IsMouseCaptured) c.ReleaseMouseCapture();
            }
            catch { }
            finally { connectionDragCompleting = false; }
        }
        connectionSourcePort = null;
        connectionDragCanvas = null;
        connectionDragPhase = ConnDragIdle;
        CollapseTempConnectionVisual();
    }

    // 端口所属节点 Id（Port_In_/Port_Out_/Port_In2_/Port_Out2_ 前缀）
    private string PortOwnerNodeId(string portName)
    {
        if (string.IsNullOrEmpty(portName)) return "";
        if (portName.StartsWith("Port_Out2_", StringComparison.Ordinal)) return portName.Substring(10);
        if (portName.StartsWith("Port_In2_", StringComparison.Ordinal)) return portName.Substring(9);
        if (portName.StartsWith("Port_Out_", StringComparison.Ordinal)) return portName.Substring(9);
        if (portName.StartsWith("Port_In_", StringComparison.Ordinal)) return portName.Substring(8);
        return "";
    }

    private bool PortIsOutput(string portName)
    {
        return !string.IsNullOrEmpty(portName) &&
            (portName.StartsWith("Port_Out_", StringComparison.Ordinal) || portName.StartsWith("Port_Out2_", StringComparison.Ordinal));
    }

    private bool PortIsInput(string portName)
    {
        return !string.IsNullOrEmpty(portName) &&
            (portName.StartsWith("Port_In_", StringComparison.Ordinal) || portName.StartsWith("Port_In2_", StringComparison.Ordinal));
    }

    private Point PortCenterOnCanvas(FrameworkElement port, Canvas canvas)
    {
        Point pp = GetCanvasPosition(port, canvas);
        double w = port.ActualWidth > 0 ? port.ActualWidth : (port.Width > 0 ? port.Width : 14);
        double h = port.ActualHeight > 0 ? port.ActualHeight : (port.Height > 0 ? port.Height : 14);
        return new Point(pp.X + w / 2, pp.Y + h / 2);
    }

    // 在吸附半径内找最近的对端端口（出点→入点 / 入点→出点）。不放大端口外观。
    private FrameworkElement FindSnapTargetPort(Canvas canvas, FrameworkElement srcPort, Point pos, double radiusPx)
    {
        if (canvas == null || srcPort == null || string.IsNullOrEmpty(srcPort.Name))
            return null;
        bool fromOut = PortIsOutput(srcPort.Name);
        bool fromIn = PortIsInput(srcPort.Name);
        if (!fromOut && !fromIn)
            return null;
        string srcOwner = PortOwnerNodeId(srcPort.Name);
        double minDistSq = radiusPx * radiusPx;
        FrameworkElement closest = null;
        var allPorts = FindDescendantsByNamePrefix(canvas, "Port_");
        foreach (var fe in allPorts)
        {
            if (fe == null || fe == srcPort || string.IsNullOrEmpty(fe.Name)) continue;
            if (fe.Visibility != Visibility.Visible) continue;
            // 出点只吸附入点，入点只吸附出点
            if (fromOut && !PortIsInput(fe.Name)) continue;
            if (fromIn && !PortIsOutput(fe.Name)) continue;
            string owner = PortOwnerNodeId(fe.Name);
            if (owner != "" && owner == srcOwner) continue;
            Point pc = PortCenterOnCanvas(fe, canvas);
            double dx = pos.X - pc.X, dy = pos.Y - pc.Y;
            double distSq = dx * dx + dy * dy;
            if (distSq < minDistSq)
            {
                minDistSq = distSq;
                closest = fe;
            }
        }
        return closest;
    }

    // 右键命中连线 Path（按描边加宽几何判定，便于点到线）
    private string FindConnectionPathAt(Canvas canvas, Point pos, double tol)
    {
        if (canvas == null) return null;
        string best = null;
        double bestStroke = -1;
        foreach (UIElement child in canvas.Children)
        {
            var pathFe = child as System.Windows.Shapes.Path;
            if (pathFe == null || pathFe.Name == null || !pathFe.Name.Contains("_Path_")) continue;
            if (pathFe.Visibility != Visibility.Visible || pathFe.Data == null) continue;
            try
            {
                double strokeTol = Math.Max(tol, pathFe.StrokeThickness > 0 ? pathFe.StrokeThickness : 6);
                var widened = pathFe.Data.GetWidenedPathGeometry(
                    new System.Windows.Media.Pen(System.Windows.Media.Brushes.Black, strokeTol));
                if (widened.FillContains(pos))
                {
                    // 多条重叠时取描边更粗的（通常是加粗后的主连线）
                    if (pathFe.StrokeThickness >= bestStroke)
                    {
                        bestStroke = pathFe.StrokeThickness;
                        best = pathFe.Name;
                    }
                }
            }
            catch { }
        }
        return best;
    }

    // 开始从端口拖线
    private void BeginConnectionDrag(Canvas canvas, FrameworkElement port, Point startPos)
    {
        if (canvas == null || port == null) return;
        if (connectionDragPhase != ConnDragIdle)
            CancelConnectionDrag(canvas, true);
        connectionDragCanvas = canvas;
        connectionSourcePort = port;
        connectionDragPhase = ConnDragDragging;
        connectionDragStart = startPos;
        connectionLastPos = startPos;
        EnsureTempConnection(canvas);
        try { tempConnection.SetResourceReference(System.Windows.Shapes.Shape.StrokeProperty, "GraphConn"); } catch { }
        try { if (tempConnectionArrow != null) tempConnectionArrow.SetResourceReference(System.Windows.Shapes.Shape.FillProperty, "GraphConn"); } catch { }
        UpdateTempConnectionVisual(canvas, startPos);
        try { canvas.CaptureMouse(); } catch { }
    }

    // 松手时入点吸附半径（拖线过程中不磁吸，仅 CompleteConnectionDrag 使用）
    private const double ConnPortSnapRadius = 25;

    private void MoveConnectionDrag(Canvas canvas, Point pos)
    {
        if (connectionDragPhase != ConnDragDragging || connectionSourcePort == null)
            return;
        UpdateTempConnectionVisual(canvas ?? connectionDragCanvas, pos);
    }

    // 松手：吸附端口则正式连线；空白则 PendingMenu 并通知 AHK 弹指令菜单
    private void CompleteConnectionDrag(Canvas canvas, Point dropPos)
    {
        if (connectionDragPhase != ConnDragDragging || connectionSourcePort == null)
            return;
        Canvas c = canvas ?? connectionDragCanvas;
        FrameworkElement srcPort = connectionSourcePort;
        connectionLastPos = dropPos;

        connectionDragCompleting = true;
        try { if (c != null && c.IsMouseCaptured) c.ReleaseMouseCapture(); } catch { }
        connectionDragCompleting = false;

        double dragDx = dropPos.X - connectionDragStart.X;
        double dragDy = dropPos.Y - connectionDragStart.Y;
        // 几乎未拖动（单击端口）：取消
        if (dragDx * dragDx + dragDy * dragDy < 64)
        {
            CancelConnectionDrag(c, false);
            return;
        }

        // 优先按距离吸附对端端口（入点附近松手即可连上，不要求鼠标落在节点矩形内）
        FrameworkElement closestPort = FindSnapTargetPort(c, srcPort, dropPos, ConnPortSnapRadius);

        if (closestPort != null)
        {
            CancelConnectionDrag(c, false);
            SendToAhk("EVENT|" + winId + "|" + (c != null ? c.Name : "Canvas") + "|ConnectPorts|" +
                BridgeUtil.LengthPrefix(srcPort.Name + "," + closestPort.Name) + "\n");
            return;
        }

        // 空白处：保留临时线，进入待选指令态；延后通知 AHK，避开 MouseUp/Capture 竞争导致菜单秒关
        connectionSourcePort = srcPort;
        connectionDragCanvas = c;
        connectionDragPhase = ConnDragPendingMenu;
        UpdateTempConnectionVisual(c, dropPos);
        connectionSourcePort = null; // Pending 不持有源端口，避免干扰下一次拖线
        string dropInfo = srcPort.Name + "," +
            dropPos.X.ToString(System.Globalization.CultureInfo.InvariantCulture) + "," +
            dropPos.Y.ToString(System.Globalization.CultureInfo.InvariantCulture);
        string canvasName = c != null ? c.Name : "Canvas";
        try
        {
            if (win != null)
            {
                win.Dispatcher.BeginInvoke(new Action(() =>
                {
                    if (connectionDragPhase != ConnDragPendingMenu) return;
                    SendToAhk("EVENT|" + winId + "|" + canvasName + "|ConnectionDropped|" +
                        BridgeUtil.LengthPrefix(dropInfo) + "\n");
                }), System.Windows.Threading.DispatcherPriority.Background);
            }
            else
            {
                SendToAhk("EVENT|" + winId + "|" + canvasName + "|ConnectionDropped|" +
                    BridgeUtil.LengthPrefix(dropInfo) + "\n");
            }
        }
        catch
        {
            SendToAhk("EVENT|" + winId + "|" + canvasName + "|ConnectionDropped|" +
                BridgeUtil.LengthPrefix(dropInfo) + "\n");
        }
    }

    private void EnableCanvasDrag(FrameworkElement ctrl, string ctrlName, string mode)
    {
        if (mode == "crop")
        {
            EnableCropDrag(ctrl, ctrlName);
            return;
        }

        double gridSize = 1;
        if (mode.StartsWith("grid=")) double.TryParse(mode.Substring(5), out gridSize);
        if (gridSize < 1) gridSize = 1;

        nodeGridSizes[ctrlName] = gridSize;
        if (dragEnabled.ContainsKey(ctrl) && dragEnabled[ctrl]) return;
        dragEnabled[ctrl] = true;

        bool isDragging = false;
        Point dragStart = new Point();
        double startLeft = 0, startTop = 0;
        DateTime lastSend = DateTime.MinValue;
        string dragNodeId = ctrlName.StartsWith("Node_", StringComparison.Ordinal) ? ctrlName.Substring(5) : "";

        ctrl.MouseLeftButtonDown += (s, e) =>
        {
            // 端口命中交给画布拖线状态机，节点不抢捕获
            if (FindPortElement(e.OriginalSource as DependencyObject) != null)
                return;
            isDragging = true;
            dragStart = e.GetPosition((UIElement)ctrl.Parent);
            startLeft = Canvas.GetLeft(ctrl);
            startTop = Canvas.GetTop(ctrl);
            if (double.IsNaN(startLeft)) startLeft = 0;
            if (double.IsNaN(startTop)) startTop = 0;
            System.Windows.Controls.Panel.SetZIndex(ctrl, 999);

            // 点选节点：任意非 Idle 拖线态一律复位（含「线已藏但 phase 未清」）
            if (connectionDragPhase != ConnDragIdle)
                CancelConnectionDrag(ctrl.Parent as Canvas, true);

            bool isCtrl = System.Windows.Input.Keyboard.Modifiers.HasFlag(System.Windows.Input.ModifierKeys.Control);
            string evName = isCtrl ? "CtrlSelectNode" : "SelectNode";
            SendToAhk("EVENT|" + winId + "|" + ctrlName + "|" + evName + "|\n");

            ctrl.CaptureMouse();
            e.Handled = true;
        };
        ctrl.MouseMove += (s, e) =>
        {
            if (!isDragging) return;
            var pos = e.GetPosition((UIElement)ctrl.Parent);
            double dx = pos.X - dragStart.X;
            double dy = pos.Y - dragStart.Y;
            double newLeft = startLeft + dx;
            double newTop = startTop + dy;

            double currentGridSize = nodeGridSizes.ContainsKey(ctrlName) ? nodeGridSizes[ctrlName] : 1;
            if (currentGridSize > 1)
            {
                newLeft = Math.Round(newLeft / currentGridSize) * currentGridSize;
                newTop = Math.Round(newTop / currentGridSize) * currentGridSize;
            }

            Canvas.SetLeft(ctrl, newLeft);
            Canvas.SetTop(ctrl, newTop);

            // 连线跟手：在 UI 线程即时刷新，不走 AHK
            var parentCanvas = ctrl.Parent as Canvas;
            if (parentCanvas != null && dragNodeId != "")
            {
                double preL = newLeft, preT = newTop;
                double nw = ctrl.ActualWidth > 1 ? ctrl.ActualWidth : 200;
                double nh = ctrl.ActualHeight > 1 ? ctrl.ActualHeight : 60;
                ExpandCanvasAroundPoint(parentCanvas, newLeft, newTop);
                newLeft = Canvas.GetLeft(ctrl);
                newTop = Canvas.GetTop(ctrl);
                if (double.IsNaN(newLeft)) newLeft = 0;
                if (double.IsNaN(newTop)) newTop = 0;
                ExpandCanvasAroundPoint(parentCanvas, newLeft + nw, newTop + nh);
                newLeft = Canvas.GetLeft(ctrl);
                newTop = Canvas.GetTop(ctrl);
                if (double.IsNaN(newLeft)) newLeft = 0;
                if (double.IsNaN(newTop)) newTop = 0;
                // 左/上扩展后世界整体平移：校正拖拽起点，避免下一帧写回旧坐标系
                if (newLeft != preL) startLeft += (newLeft - preL);
                if (newTop != preT) startTop += (newTop - preT);
                RefreshNodeConnectionsLive(parentCanvas, dragNodeId);
            }

            // 逻辑坐标 / 多选 / 循环回环等仍通知 AHK（约 60fps）
            if ((DateTime.Now - lastSend).TotalMilliseconds > 16)
            {
                lastSend = DateTime.Now;
                SendToAhk("EVENT|" + winId + "|" + ctrlName + "|DragMove|" +
                    BridgeUtil.LengthPrefix(newLeft.ToString("F0") + "," + newTop.ToString("F0")) + "\n");
            }
            e.Handled = true;
        };
        ctrl.MouseLeftButtonUp += (s, e) =>
        {
            if (!isDragging) return;
            isDragging = false;
            System.Windows.Controls.Panel.SetZIndex(ctrl, 0);
            ctrl.ReleaseMouseCapture();
            // Send final position
            double finalLeft = Canvas.GetLeft(ctrl);
            double finalTop = Canvas.GetTop(ctrl);
            var parentCanvas = ctrl.Parent as Canvas;
            if (parentCanvas != null && dragNodeId != "")
            {
                if (!double.IsNaN(finalLeft) && !double.IsNaN(finalTop))
                    ExpandCanvasAroundPoint(parentCanvas, finalLeft, finalTop);
                finalLeft = Canvas.GetLeft(ctrl);
                finalTop = Canvas.GetTop(ctrl);
                RefreshNodeConnectionsLive(parentCanvas, dragNodeId);
            }
            SendToAhk("EVENT|" + winId + "|" + ctrlName + "|DragMove|" +
                BridgeUtil.LengthPrefix(finalLeft.ToString("F0") + "," + finalTop.ToString("F0")) + "\n");
            DumpState(ctrlName, "DragEnd");
            e.Handled = true;
        };
    }

    private void EnableElementDrag(FrameworkElement element, string options)
    {
        if (element.Tag != null && element.Tag.ToString() == "DragEnabled") return;
        element.Tag = "DragEnabled";

        bool snapToGrid = options.Contains("grid");
        bool boxDragging = false;
        Point boxDragStart = new Point();
        double boxStartLeft = 0, boxStartTop = 0;

        element.MouseLeftButtonDown += (s, e) =>
        {
            boxDragging = true;
            boxDragStart = e.GetPosition((UIElement)element.Parent);
            boxStartLeft = Canvas.GetLeft(element);
            boxStartTop = Canvas.GetTop(element);
            if (double.IsNaN(boxStartLeft)) boxStartLeft = 0;
            if (double.IsNaN(boxStartTop)) boxStartTop = 0;
            element.CaptureMouse();
            e.Handled = true;
        };
        element.MouseMove += (s, e) =>
        {
            if (!boxDragging) return;
            var pos = e.GetPosition((UIElement)element.Parent);
            double newX = boxStartLeft + (pos.X - boxDragStart.X);
            double newY = boxStartTop + (pos.Y - boxDragStart.Y);
            if (snapToGrid)
            {
                newX = Math.Round(newX / 10) * 10;
                newY = Math.Round(newY / 10) * 10;
            }
            Canvas.SetLeft(element, newX);
            Canvas.SetTop(element, newY);
            e.Handled = true;
        };
        element.MouseLeftButtonUp += (s, e) =>
        {
            if (!boxDragging) return;
            boxDragging = false;
            element.ReleaseMouseCapture();
            e.Handled = true;
        };
    }

    private void EnableCropDrag(FrameworkElement box, string boxName)
    {
        bool boxDragging = false;
        Point boxDragStart = new Point();
        double boxStartLeft = 0, boxStartTop = 0;

        box.MouseLeftButtonDown += (s, e) =>
        {
            boxDragging = true;
            boxDragStart = e.GetPosition((UIElement)box.Parent);
            boxStartLeft = Canvas.GetLeft(box);
            boxStartTop = Canvas.GetTop(box);
            if (double.IsNaN(boxStartLeft)) boxStartLeft = 0;
            if (double.IsNaN(boxStartTop)) boxStartTop = 0;
            box.CaptureMouse();
            e.Handled = true;
        };
        box.MouseMove += (s, e) =>
        {
            if (!boxDragging) return;
            var pos = e.GetPosition((UIElement)box.Parent);
            Canvas.SetLeft(box, boxStartLeft + (pos.X - boxDragStart.X));
            Canvas.SetTop(box, boxStartTop + (pos.Y - boxDragStart.Y));
            e.Handled = true;
        };
        box.MouseLeftButtonUp += (s, e) =>
        {
            if (!boxDragging) return;
            boxDragging = false;
            box.ReleaseMouseCapture();
            e.Handled = true;
        };

        string baseName = boxName.Replace("_Box", "");
        var hSE = win.FindName(baseName + "_HSE") as FrameworkElement;
        if (hSE != null)
        {
            bool seResizing = false;
            Point seStart = new Point();
            double seStartW = 0, seStartH = 0;

            hSE.MouseLeftButtonDown += (s, e) =>
            {
                seResizing = true;
                seStart = e.GetPosition((UIElement)box.Parent);
                seStartW = box.Width;
                seStartH = box.Height;
                if (double.IsNaN(seStartW)) seStartW = 100;
                if (double.IsNaN(seStartH)) seStartH = 100;
                hSE.CaptureMouse();
                e.Handled = true;
            };
            hSE.MouseMove += (s, e) =>
            {
                if (!seResizing) return;
                var pos = e.GetPosition((UIElement)box.Parent);
                double nw = Math.Max(50, seStartW + (pos.X - seStart.X));
                double nh = Math.Max(50, seStartH + (pos.Y - seStart.Y));
                box.Width = nw;
                box.Height = nh;
                e.Handled = true;
            };
            hSE.MouseLeftButtonUp += (s, e) =>
            {
                if (!seResizing) return;
                seResizing = false;
                hSE.ReleaseMouseCapture();
                e.Handled = true;
            };
        }

        var hNW = win.FindName(baseName + "_HNW") as FrameworkElement;
        if (hNW != null)
        {
            bool nwResizing = false;
            Point nwStart = new Point();
            double nwStartL = 0, nwStartT = 0, nwStartW = 0, nwStartH = 0;

            hNW.MouseLeftButtonDown += (s, e) =>
            {
                nwResizing = true;
                nwStart = e.GetPosition((UIElement)box.Parent);
                nwStartL = Canvas.GetLeft(box);
                nwStartT = Canvas.GetTop(box);
                nwStartW = box.Width;
                nwStartH = box.Height;
                if (double.IsNaN(nwStartL)) nwStartL = 0;
                if (double.IsNaN(nwStartT)) nwStartT = 0;
                if (double.IsNaN(nwStartW)) nwStartW = 100;
                if (double.IsNaN(nwStartH)) nwStartH = 100;
                hNW.CaptureMouse();
                e.Handled = true;
            };
            hNW.MouseMove += (s, e) =>
            {
                if (!nwResizing) return;
                var pos = e.GetPosition((UIElement)box.Parent);
                double dx = pos.X - nwStart.X;
                double dy = pos.Y - nwStart.Y;
                double nw = Math.Max(50, nwStartW - dx);
                double nh = Math.Max(50, nwStartH - dy);
                if (nw > 50) { Canvas.SetLeft(box, nwStartL + dx); box.Width = nw; }
                if (nh > 50) { Canvas.SetTop(box, nwStartT + dy); box.Height = nh; }
                e.Handled = true;
            };
            hNW.MouseLeftButtonUp += (s, e) =>
            {
                if (!nwResizing) return;
                nwResizing = false;
                hNW.ReleaseMouseCapture();
                e.Handled = true;
            };
        }
    }

}
