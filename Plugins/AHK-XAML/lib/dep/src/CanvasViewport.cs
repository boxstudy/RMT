// =============================================================================
// Canvas viewport: zoom, pan, world expansion
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
    private Point GetCanvasPosition(UIElement element, Canvas canvas)
    {
        if (element == null) return new Point(0, 0);
        try
        {
            return element.TransformToAncestor(canvas).Transform(new Point(0, 0));
        }
        catch
        {
            return new Point(0, 0);
        }
    }

    // 视口盖不住画布时按块扩展世界（右/下直接加宽高；左/上加宽高并平移子元素，保持逻辑坐标稳定）
    private void EnsureCanvasCoversViewport(Canvas canvas,
        System.Windows.Media.ScaleTransform scaleTransform,
        System.Windows.Media.TranslateTransform translateTransform,
        FrameworkElement parent,
        out double dTx, out double dTy)
    {
        dTx = 0; dTy = 0;
        if (canvas == null || scaleTransform == null || translateTransform == null || parent == null)
            return;
        double pw = parent.ActualWidth;
        double ph = parent.ActualHeight;
        if (pw <= 1 || ph <= 1) return;

        const double chunk = 4000.0;
        const double edgePad = 80.0;
        double s = scaleTransform.ScaleX;
        if (s < 0.01) s = 0.01;

        double dOx = 0, dOy = 0;
        bool changed = false;
        int guard = 0;
        while (guard++ < 32)
        {
            Thickness m = canvas.Margin;
            double tx = translateTransform.X;
            double ty = translateTransform.Y;
            double left = m.Left + tx;
            double top = m.Top + ty;
            double right = m.Left + canvas.Width * s + tx;
            double bottom = m.Top + canvas.Height * s + ty;
            bool grew = false;

            if (right < pw + edgePad)
            {
                canvas.Width += chunk;
                grew = true;
            }
            if (bottom < ph + edgePad)
            {
                canvas.Height += chunk;
                grew = true;
            }
            if (left > -edgePad)
            {
                ShiftCanvasWorld(canvas, chunk, 0);
                m.Left -= chunk;
                canvas.Margin = m;
                translateTransform.X -= chunk * s;
                dTx -= chunk * s;
                dOx += chunk;
                grew = true;
            }
            if (top > -edgePad)
            {
                ShiftCanvasWorld(canvas, 0, chunk);
                m = canvas.Margin;
                m.Top -= chunk;
                canvas.Margin = m;
                translateTransform.Y -= chunk * s;
                dTy -= chunk * s;
                dOy += chunk;
                grew = true;
            }
            if (!grew) break;
            changed = true;
        }

        if (!changed) return;

        SyncCanvasGridBg(canvas);
        string payload = dOx.ToString(System.Globalization.CultureInfo.InvariantCulture) + ","
            + dOy.ToString(System.Globalization.CultureInfo.InvariantCulture) + ","
            + canvas.Width.ToString(System.Globalization.CultureInfo.InvariantCulture) + ","
            + canvas.Height.ToString(System.Globalization.CultureInfo.InvariantCulture);
        SendToAhk("EVENT|" + winId + "|" + canvas.Name + "|CanvasExpanded|" + BridgeUtil.LengthPrefix(payload) + "\n");
    }

    private void ExpandCanvasAroundPoint(Canvas canvas, double canvasX, double canvasY)
    {
        if (canvas == null) return;
        const double chunk = 4000.0;
        const double pad = 400.0;
        double dOx = 0, dOy = 0;
        bool changed = false;
        if (canvasX < pad)
        {
            double need = pad - canvasX;
            int n = (int)Math.Ceiling(need / chunk);
            if (n < 1) n = 1;
            double add = n * chunk;
            ShiftCanvasWorld(canvas, add, 0);
            Thickness m = canvas.Margin;
            m.Left -= add;
            canvas.Margin = m;
            canvas.Width += add;
            canvasX += add; // 点随世界右移
            dOx += add;
            changed = true;
            // 保持视口稳定
            var tg = canvas.RenderTransform as System.Windows.Media.TransformGroup;
            if (tg != null && tg.Children.Count >= 2)
            {
                var st = tg.Children[0] as System.Windows.Media.ScaleTransform;
                var tt = tg.Children[1] as System.Windows.Media.TranslateTransform;
                if (st != null && tt != null)
                    tt.X -= add * st.ScaleX;
            }
        }
        if (canvasY < pad)
        {
            double need = pad - canvasY;
            int n = (int)Math.Ceiling(need / chunk);
            if (n < 1) n = 1;
            double add = n * chunk;
            ShiftCanvasWorld(canvas, 0, add);
            Thickness m = canvas.Margin;
            m.Top -= add;
            canvas.Margin = m;
            canvas.Height += add;
            canvasY += add;
            dOy += add;
            changed = true;
            var tg = canvas.RenderTransform as System.Windows.Media.TransformGroup;
            if (tg != null && tg.Children.Count >= 2)
            {
                var st = tg.Children[0] as System.Windows.Media.ScaleTransform;
                var tt = tg.Children[1] as System.Windows.Media.TranslateTransform;
                if (st != null && tt != null)
                    tt.Y -= add * st.ScaleY;
            }
        }
        if (canvasX > canvas.Width - pad)
        {
            double need = canvasX - (canvas.Width - pad);
            int n = (int)Math.Ceiling(need / chunk);
            if (n < 1) n = 1;
            canvas.Width += n * chunk;
            changed = true;
        }
        if (canvasY > canvas.Height - pad)
        {
            double need = canvasY - (canvas.Height - pad);
            int n = (int)Math.Ceiling(need / chunk);
            if (n < 1) n = 1;
            canvas.Height += n * chunk;
            changed = true;
        }
        if (!changed) return;
        SyncCanvasGridBg(canvas);
        string payload = dOx.ToString(System.Globalization.CultureInfo.InvariantCulture) + ","
            + dOy.ToString(System.Globalization.CultureInfo.InvariantCulture) + ","
            + canvas.Width.ToString(System.Globalization.CultureInfo.InvariantCulture) + ","
            + canvas.Height.ToString(System.Globalization.CultureInfo.InvariantCulture);
        SendToAhk("EVENT|" + winId + "|" + canvas.Name + "|CanvasExpanded|" + BridgeUtil.LengthPrefix(payload) + "\n");
    }

    private static void SyncCanvasGridBg(Canvas canvas)
    {
        foreach (UIElement child in canvas.Children)
        {
            var fe = child as FrameworkElement;
            if (fe == null || fe.Name == null || !fe.Name.EndsWith("_GridBg")) continue;
            fe.Width = canvas.Width;
            fe.Height = canvas.Height;
            break;
        }
    }

    private static void ShiftCanvasWorld(Canvas canvas, double dx, double dy)
    {
        if (dx == 0 && dy == 0) return;
        foreach (UIElement child in canvas.Children)
        {
            var fe = child as FrameworkElement;
            if (fe == null) continue;
            string name = fe.Name ?? "";
            // 网格铺满画布原点，不随世界左/上扩展平移
            if (name.EndsWith("_GridBg")) continue;

            double cl = Canvas.GetLeft(child);
            double ct = Canvas.GetTop(child);
            if (!double.IsNaN(cl)) Canvas.SetLeft(child, cl + dx);
            if (!double.IsNaN(ct)) Canvas.SetTop(child, ct + dy);

            // 连线 Path 用绝对几何；箭头 Data 是本地三角形，只靠 Canvas 坐标
            var path = fe as System.Windows.Shapes.Path;
            if (path != null && path.Data != null && name.Contains("_Path_"))
            {
                try
                {
                    var clone = path.Data.Clone();
                    var existing = clone.Transform;
                    var tt = existing as System.Windows.Media.TranslateTransform;
                    if (existing == null || existing == System.Windows.Media.Transform.Identity)
                        clone.Transform = new System.Windows.Media.TranslateTransform(dx, dy);
                    else if (tt != null)
                        clone.Transform = new System.Windows.Media.TranslateTransform(tt.X + dx, tt.Y + dy);
                    else
                    {
                        var group = new System.Windows.Media.TransformGroup();
                        group.Children.Add(existing);
                        group.Children.Add(new System.Windows.Media.TranslateTransform(dx, dy));
                        clone.Transform = group;
                    }
                    path.Data = clone;
                }
                catch { }
            }
        }
    }

    private void EnableCanvasZoomPan(Canvas canvas)
    {
        if (canvas.Tag != null && canvas.Tag.ToString() == "ZoomPanEnabled") return;
        canvas.Tag = "ZoomPanEnabled";

        // Make the canvas keyboard-focusable so that after clicking / box-selecting on
        // empty canvas the window still receives key events (Delete / Ctrl+C / Ctrl+V).
        // Without focus inside the window, PreviewKeyDown on the window is never raised.
        canvas.Focusable = true;

        var scaleTransform = new System.Windows.Media.ScaleTransform(1, 1);
        var translateTransform = new System.Windows.Media.TranslateTransform(0, 0);
        var tg = new System.Windows.Media.TransformGroup();
        tg.Children.Add(scaleTransform);
        tg.Children.Add(translateTransform);
        canvas.RenderTransform = tg;
        canvas.RenderTransformOrigin = new Point(0, 0);

        var parent = canvas.Parent as FrameworkElement;

        // 外层 Border 无演示菜单时，露底右键也不应冒泡出系统/残留菜单
        if (parent != null)
        {
            parent.ContextMenu = null;
            parent.PreviewMouseRightButtonDown += (s, e) =>
            {
                // 命中在画布上时由画布自己处理；仅露底区域吞掉默认菜单
                if (e.OriginalSource == parent || e.Source == parent)
                    e.Handled = true;
            };
        }

        // 持续记录光标（含移过子节点时）；Ctrl+V 粘贴锚点依赖此缓存
        if (!string.IsNullOrEmpty(canvas.Name))
        {
            try { canvasMouseCache[canvas.Name] = System.Windows.Input.Mouse.GetPosition(canvas); }
            catch { canvasMouseCache[canvas.Name] = new Point(canvas.Width * 0.5, canvas.Height * 0.5); }
        }
        canvas.PreviewMouseMove += (s, e) =>
        {
            if (string.IsNullOrEmpty(canvas.Name)) return;
            canvasMouseCache[canvas.Name] = e.GetPosition(canvas);
        };

        canvas.PreviewMouseWheel += (s, e) =>
        {
            //System.IO.File.AppendAllText("ahk_pan_debug.log", "PreviewMouseWheel fired! Delta: " + e.Delta + "\n");
            double zoom = e.Delta > 0 ? 1.1 : 0.9;
            double scaleX = scaleTransform.ScaleX;
            double newScale = scaleX * zoom;
            if (newScale < 0.2) newScale = 0.2;
            if (newScale > 5.0) newScale = 5.0;

            var canvasPos = e.GetPosition(canvas);
            translateTransform.X = translateTransform.X + canvasPos.X * (scaleX - newScale);
            translateTransform.Y = translateTransform.Y + canvasPos.Y * (scaleX - newScale);

            scaleTransform.ScaleX = newScale;
            scaleTransform.ScaleY = newScale;
            double ignoreTx, ignoreTy;
            EnsureCanvasCoversViewport(canvas, scaleTransform, translateTransform, parent, out ignoreTx, out ignoreTy);
            e.Handled = true;
        };

        bool isPanning = false;
        bool panMoved = false;
        bool panIsRight = false;
        Point panStart = new Point();
        double panStartTX = 0, panStartTY = 0;

        bool isKnifing = false;
        System.Windows.Shapes.Path tempKnife = null;
        Point knifeStart = new Point();
        Point lastKnifePos = new Point();
        string lastSelectionSet = "";
        string lastConnSelectionSet = "";
        bool pathClickPending = false;

        // Label 拖拽改变数值：对【所有节点】的"标签 + 数值输入框"行生效。
        // 采用事件委托（从命中元素向上找 TextBlock），自动适配动态新增的节点，无需逐个挂接。
        // 仅当同行输入框的当前内容是数值时才允许拖拽，避免破坏变量/文本字段。
        bool isLabelDragging = false;
        System.Windows.Controls.Control dragTargetCtrl = null;   // TextBox 或可编辑 ComboBox
        double dragStartX = 0;
        double dragStartValue = 0;

        System.Func<System.Windows.Controls.Control, string> getCtrlText = (c) =>
        {
            var t = c as System.Windows.Controls.TextBox; if (t != null) return t.Text;
            var cb = c as System.Windows.Controls.ComboBox; if (cb != null) return cb.Text;
            return null;
        };
        System.Action<System.Windows.Controls.Control, string> setCtrlText = (c, v) =>
        {
            var t = c as System.Windows.Controls.TextBox; if (t != null) { t.Text = v; return; }
            var cb = c as System.Windows.Controls.ComboBox;
            if (cb != null)
            {
                // 先清选中项，避免 Text 与 SelectedItem 不一致导致读值仍拿旧 Content
                cb.SelectedIndex = -1;
                cb.Text = v;
                try
                {
                    var editBox = cb.Template != null
                        ? cb.Template.FindName("PART_EditableTextBox", cb) as System.Windows.Controls.TextBox
                        : null;
                    if (editBox != null)
                        editBox.Text = v;
                }
                catch { }
                return;
            }
        };

        // 同一 StackPanel 内存在数值内容的 TextBox / 可编辑 ComboBox 则返回它，否则 null
        System.Func<System.Windows.Controls.TextBlock, System.Windows.Controls.Control> findNumericPeerBox = (tb) =>
        {
            if (tb == null) return null;
            var sp = tb.Parent as System.Windows.Controls.StackPanel;
            if (sp == null) return null;
            System.Windows.Controls.Control box = null;
            foreach (var spChild in sp.Children)
            {
                var t = spChild as System.Windows.Controls.TextBox;
                if (t != null) { box = t; break; }
                var cb = spChild as System.Windows.Controls.ComboBox;
                if (cb != null && cb.IsEditable) { box = cb; break; }
            }
            if (box == null) return null;
            if (!box.IsEnabled) return null;
            double tmp;
            if (!double.TryParse(getCtrlText(box), System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, out tmp))
                return null;
            return box;
        };

        // 点击文字时 OriginalSource 可能是内部 Run/文本节点，向上找最近的 TextBlock
        System.Func<object, System.Windows.Controls.TextBlock> asLabel = (src) =>
        {
            var d = src as DependencyObject;
            while (d != null)
            {
                var tb = d as System.Windows.Controls.TextBlock;
                if (tb != null) return tb;
                d = System.Windows.Media.VisualTreeHelper.GetParent(d);
            }
            return null;
        };

        canvas.PreviewMouseDown += (s, e) =>
        {
            if (e.ChangedButton == System.Windows.Input.MouseButton.Middle)
            {
                //System.IO.File.AppendAllText("ahk_pan_debug.log", "Middle PreviewMouseDown fired! Starting pan.\n");
                isPanning = true;
                panMoved = false;
                panIsRight = false;
                panStart = e.GetPosition(parent != null ? parent : canvas);
                panStartTX = translateTransform.X;
                panStartTY = translateTransform.Y;
                canvas.CaptureMouse();
                canvas.Cursor = System.Windows.Input.Cursors.Hand;
                e.Handled = true;
            }
        };

        // Right button: start a potential pan. If released without moving, open the
        // context menu; if the mouse moved, treat it as a canvas drag (no menu).
        canvas.PreviewMouseRightButtonDown += (s, e) =>
        {
            isPanning = true;
            panMoved = false;
            panIsRight = true;
            panStart = e.GetPosition(parent != null ? parent : canvas);
            panStartTX = translateTransform.X;
            panStartTY = translateTransform.Y;
            canvas.CaptureMouse();
            canvas.Focus();
            canvas.Cursor = System.Windows.Input.Cursors.Hand;
            // Suppress WPF's automatic context menu; we open it manually on button-up if not dragged.
            e.Handled = true;
        };

        canvas.PreviewMouseRightButtonUp += (s, e) =>
        {
            if (isPanning && panIsRight)
            {
                isPanning = false;
                panIsRight = false;
                canvas.ReleaseMouseCapture();
                canvas.Cursor = System.Windows.Input.Cursors.Arrow;
                if (!panMoved)
                {
                    var pos = e.GetPosition(canvas);
                    string coords = pos.X.ToString(System.Globalization.CultureInfo.InvariantCulture) + "," + pos.Y.ToString(System.Globalization.CultureInfo.InvariantCulture);
                    // 右键命中连线时附带 PathId，供 AHK 选中连线并弹出仅含「删除」的菜单
                    string hitPath = FindConnectionPathAt(canvas, pos, 10);
                    if (!string.IsNullOrEmpty(hitPath))
                        coords = coords + "," + hitPath;
                    // 诊断：记录右键点的屏幕设备坐标，菜单打开后与其左上角对比，量出真实偏移。
                    try
                    {
                        var devPt = canvas.PointToScreen(pos);
                        _ctxMenuClickDevX = devPt.X;
                        _ctxMenuClickDevY = devPt.Y;
                        var src = PresentationSource.FromVisual(canvas);
                        double dpi = (src != null && src.CompositionTarget != null) ? src.CompositionTarget.TransformToDevice.M11 : 1.0;
                        LogDebug("[CtxMenu] rightClick canvasLocal=(" + pos.X.ToString("F1") + "," + pos.Y.ToString("F1")
                            + ")  screenDevice=(" + devPt.X.ToString("F1") + "," + devPt.Y.ToString("F1") + ")  dpiScale=" + dpi.ToString("F3")
                            + " hitPath=" + (hitPath ?? ""));
                    }
                    catch (Exception ex) { LogDebug("[CtxMenu] rightclick-log err: " + ex.Message); }
                    SendToAhk("EVENT|" + winId + "|" + canvas.Name + "|ContextMenuOpened|" + BridgeUtil.LengthPrefix(coords) + "\n");
                }
                e.Handled = true;
            }
        };

        // 捕获丢失：平移复位；拖线中则按最后坐标完成（避免 MouseUp 落在其他控件导致幽灵线）
        canvas.LostMouseCapture += (s, e) =>
        {
            if (isPanning)
            {
                isPanning = false;
                panIsRight = false;
                canvas.Cursor = System.Windows.Input.Cursors.Arrow;
            }
            if (connectionDragCompleting)
                return;
            if (connectionDragPhase == ConnDragDragging && connectionSourcePort != null)
            {
                Point pos = connectionLastPos;
                try { pos = System.Windows.Input.Mouse.GetPosition(canvas); } catch { }
                CompleteConnectionDrag(canvas, pos);
            }
        };

        canvas.PreviewMouseLeftButtonDown += (s, e) =>
        {
            // 优先处理标签拖拽改值，Handled 后抑制节点拖动/框选
            var labelBox = findNumericPeerBox(asLabel(e.OriginalSource));
            if (labelBox != null)
            {
                double val;
                if (!double.TryParse(getCtrlText(labelBox), System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, out val))
                    val = 0;
                isLabelDragging = true;
                dragTargetCtrl = labelBox;
                dragStartX = e.GetPosition(canvas).X;
                dragStartValue = val;
                canvas.CaptureMouse();
                e.Handled = true;
                return;
            }

            var portEl = FindPortElement(e.OriginalSource as DependencyObject);
            if (portEl != null)
            {
                BeginConnectionDrag(canvas, portEl, e.GetPosition(canvas));
                e.Handled = true;
                return;
            }

            // Clicking directly on a connection path selects it. Handled centrally here
            // (tunneling) so it works for both build-time and runtime-added connections,
            // regardless of whether a per-path WPF handler was attached.
            var el = e.OriginalSource as FrameworkElement;
            if (el is System.Windows.Shapes.Path && el.Name != null && el.Name.Contains("_Path_") && el.Visibility == Visibility.Visible)
            {
                canvas.Focus();
                pathClickPending = true;
                SendToAhk("EVENT|" + winId + "|" + canvas.Name + "|PathClicked|" + BridgeUtil.LengthPrefix(el.Name) + "\n");
                e.Handled = true;
            }
        };

        // Mode logic: Left click on empty space (Canvas) triggers Pan or Select
        canvas.MouseLeftButtonDown += (s, e) =>
        {
            if (FindPortElement(e.OriginalSource as DependencyObject) != null)
                return;

            // If the user clicked on a node or anything else, let it handle its own drag
            if (e.OriginalSource != canvas) return;

            // Give the canvas keyboard focus so Delete / Ctrl+C / Ctrl+V work after a
            // click / box-select on empty space (the window's PreviewKeyDown needs focus
            // to be inside the window). Focus() alone only sets logical focus within the
            // focus scope in some trees; Keyboard.Focus() forces real keyboard focus so
            // the window-level PreviewKeyDown fires for Delete after a box-select.
            canvas.Focus();
            System.Windows.Input.Keyboard.Focus(canvas);

            string mode = "Pan";
            if (canvasModes.ContainsKey(canvas.Name)) mode = canvasModes[canvas.Name];
            //System.IO.File.AppendAllText("ahk_pan_debug.log", "MouseLeftButtonDown fired! Mode: " + mode + "\n");

            if (mode == "Pan")
            {
                isPanning = true;
                panMoved = false;
                panStart = e.GetPosition(parent != null ? parent : canvas);
                panStartTX = translateTransform.X;
                panStartTY = translateTransform.Y;
                canvas.CaptureMouse();
                canvas.Cursor = System.Windows.Input.Cursors.Hand;
                e.Handled = true;
            }
            else if (mode == "Select")
            {
                selectionStart = e.GetPosition(canvas);
                if (selectionBox == null)
                {
                    selectionBox = new System.Windows.Shapes.Rectangle
                    {
                        Stroke = System.Windows.Media.Brushes.DodgerBlue,
                        StrokeThickness = 1,
                        Fill = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromArgb(50, 30, 144, 255)),
                        IsHitTestVisible = false
                    };
                    System.Windows.Controls.Panel.SetZIndex(selectionBox, 9999);
                    canvas.Children.Add(selectionBox);
                }
                Canvas.SetLeft(selectionBox, selectionStart.X);
                Canvas.SetTop(selectionBox, selectionStart.Y);
                selectionBox.Width = 0;
                selectionBox.Height = 0;
                selectionBox.Visibility = Visibility.Visible;
                lastSelectionSet = "FORCE_UPDATE";
                lastConnSelectionSet = "";
                canvas.CaptureMouse();
                e.Handled = true;
            }
            else if (mode == "Knife")
            {
                isKnifing = true;
                knifeStart = e.GetPosition(canvas);
                lastKnifePos = knifeStart;
                if (tempKnife == null)
                {
                    tempKnife = new System.Windows.Shapes.Path
                    {
                        Stroke = System.Windows.Media.Brushes.Red,
                        StrokeThickness = 2,
                        StrokeDashArray = new System.Windows.Media.DoubleCollection(new double[] { 4, 4 }),
                        IsHitTestVisible = false
                    };
                    System.Windows.Controls.Panel.SetZIndex(tempKnife, 9999);
                    canvas.Children.Add(tempKnife);
                }
                tempKnife.Visibility = Visibility.Visible;
                canvas.CaptureMouse();
                e.Handled = true;
            }
        };
        canvas.MouseMove += (s, e) =>
        {
            if (isPanning)
            {
                var pos = e.GetPosition(parent != null ? parent : canvas);
                if (Math.Abs(pos.X - panStart.X) > 2 || Math.Abs(pos.Y - panStart.Y) > 2) panMoved = true;
                translateTransform.X = panStartTX + (pos.X - panStart.X);
                translateTransform.Y = panStartTY + (pos.Y - panStart.Y);
                double dTx, dTy;
                EnsureCanvasCoversViewport(canvas, scaleTransform, translateTransform, parent, out dTx, out dTy);
                // 左/上扩展会改 translate 以稳住视口，需同步 pan 起点，避免下一帧被覆盖
                if (dTx != 0) panStartTX += dTx;
                if (dTy != 0) panStartTY += dTy;
                //System.IO.File.AppendAllText("ahk_pan_debug.log", "Canvas Moved! New TX: " + translateTransform.X + " TY: " + translateTransform.Y + " parent: " + (parent != null ? parent.Name : "null") + "\n");
                e.Handled = true;
            }
            else if (selectionBox != null && selectionBox.Visibility == Visibility.Visible)
            {
                var pos = e.GetPosition(canvas);
                double x = Math.Min(pos.X, selectionStart.X);
                double y = Math.Min(pos.Y, selectionStart.Y);
                double w = Math.Abs(pos.X - selectionStart.X);
                double h = Math.Abs(pos.Y - selectionStart.Y);
                Canvas.SetLeft(selectionBox, x);
                Canvas.SetTop(selectionBox, y);
                selectionBox.Width = w;
                selectionBox.Height = h;

                var currentSelected = new System.Collections.Generic.List<string>();
                foreach (UIElement child in canvas.Children)
                {
                    var fe = child as FrameworkElement;
                    if (fe != null && fe.Name != null && fe.Name.StartsWith("Node_"))
                    {
                        double nx = Canvas.GetLeft(fe);
                        double ny = Canvas.GetTop(fe);
                        if (double.IsNaN(nx)) nx = 0;
                        if (double.IsNaN(ny)) ny = 0;
                        double nw = fe.ActualWidth;
                        double nh = fe.ActualHeight;
                        if (nx < x + w && nx + nw > x && ny < y + h && ny + nh > y)
                        {
                            currentSelected.Add(fe.Name.Substring(5));
                        }
                    }
                }
                string newSet = string.Join(",", currentSelected);
                if (newSet != lastSelectionSet)
                {
                    lastSelectionSet = newSet;
                    bool isCtrl = System.Windows.Input.Keyboard.Modifiers.HasFlag(System.Windows.Input.ModifierKeys.Control);
                    string evName = isCtrl ? "CtrlSelectionBox" : "SelectionBox";
                    SendToAhk("EVENT|" + winId + "|" + canvas.Name + "|" + evName + "|" +
                        BridgeUtil.LengthPrefix(newSet) + "\n");
                }

                // Connections whose (stroked) geometry intersects the selection rectangle
                // are box-selected too (reported separately so nodes/connections stay independent).
                var selRect = new Rect(x, y, w, h);
                var selRectGeom = new System.Windows.Media.RectangleGeometry(selRect);
                var currentConns = new System.Collections.Generic.List<string>();
                foreach (UIElement child in canvas.Children)
                {
                    var pathFe = child as System.Windows.Shapes.Path;
                    if (pathFe == null || pathFe.Name == null || !pathFe.Name.Contains("_Path_")) continue;
                    if (pathFe.Visibility != Visibility.Visible || pathFe.Data == null) continue;
                    try
                    {
                        double tol = pathFe.StrokeThickness > 0 ? pathFe.StrokeThickness : 6;
                        var widened = pathFe.Data.GetWidenedPathGeometry(new System.Windows.Media.Pen(System.Windows.Media.Brushes.Black, Math.Max(tol, 6)));
                        if (widened.FillContainsWithDetail(selRectGeom) != System.Windows.Media.IntersectionDetail.Empty)
                            currentConns.Add(pathFe.Name);
                    }
                    catch { }
                }
                string newConnSet = string.Join(",", currentConns);
                if (newConnSet != lastConnSelectionSet)
                {
                    lastConnSelectionSet = newConnSet;
                    SendToAhk("EVENT|" + winId + "|" + canvas.Name + "|SelectionBoxConn|" +
                        BridgeUtil.LengthPrefix(newConnSet) + "\n");
                }
                e.Handled = true;
            }
            else if (connectionDragPhase == ConnDragDragging)
            {
                MoveConnectionDrag(canvas, e.GetPosition(canvas));
                e.Handled = true;
            }
            else if (isKnifing && tempKnife != null && tempKnife.Visibility == Visibility.Visible)
            {
                var pos = e.GetPosition(canvas);
                string geom = string.Format(System.Globalization.CultureInfo.InvariantCulture, "M{0},{1} L{2},{3}", knifeStart.X, knifeStart.Y, pos.X, pos.Y);
                try { tempKnife.Data = System.Windows.Media.Geometry.Parse(geom); } catch { }

                System.Windows.Media.VisualTreeHelper.HitTest(canvas, null,
                    new System.Windows.Media.HitTestResultCallback((result) =>
                    {
                        var hitEl = result.VisualHit as FrameworkElement;
                        if (hitEl != null && hitEl.Name != null && hitEl.Name.Contains("_Path_") && hitEl.Visibility == Visibility.Visible)
                        {
                            hitEl.Visibility = Visibility.Collapsed;
                            SendToAhk("EVENT|" + winId + "|" + canvas.Name + "|DeleteConnection|" +
                                BridgeUtil.LengthPrefix(hitEl.Name) + "\n");
                        }
                        return System.Windows.Media.HitTestResultBehavior.Continue;
                    }),
                    new System.Windows.Media.GeometryHitTestParameters(new System.Windows.Media.LineGeometry(lastKnifePos, pos))
                );
                lastKnifePos = pos;
                e.Handled = true;
            }
        };
        canvas.MouseUp += (s, e) =>
        {
            if (e.ChangedButton == System.Windows.Input.MouseButton.Middle && isPanning)
            {
                isPanning = false;
                canvas.ReleaseMouseCapture();
                canvas.Cursor = System.Windows.Input.Cursors.Arrow;
                e.Handled = true;
            }
        };
        canvas.MouseLeftButtonUp += (s, e) =>
        {
            // A connection was just clicked (selected) on button-down: swallow this up
            // so the "clicked empty space" branch below doesn't immediately clear it.
            if (pathClickPending)
            {
                pathClickPending = false;
                e.Handled = true;
                return;
            }
            if (isPanning)
            {
                isPanning = false;
                canvas.ReleaseMouseCapture();
                canvas.Cursor = System.Windows.Input.Cursors.Arrow;
                if (!panMoved)
                {
                    SendToAhk("EVENT|" + winId + "|" + canvas.Name + "|ClearSelection|\n");
                }
                e.Handled = true;
            }
            else if (selectionBox != null && selectionBox.Visibility == Visibility.Visible)
            {
                selectionBox.Visibility = Visibility.Collapsed;
                canvas.ReleaseMouseCapture();
                if (lastSelectionSet == "FORCE_UPDATE")
                {
                    SendToAhk("EVENT|" + winId + "|" + canvas.Name + "|ClearSelection|\n");
                }
                lastSelectionSet = "";
                // Re-assert keyboard focus after the box-select finishes: releasing mouse
                // capture can shift focus, and the window-level PreviewKeyDown needs the
                // canvas focused so a following Delete deletes the box-selected nodes.
                canvas.Focus();
                System.Windows.Input.Keyboard.Focus(canvas);
                e.Handled = true;
            }
            else if (connectionDragPhase == ConnDragDragging)
            {
                CompleteConnectionDrag(canvas, e.GetPosition(canvas));
                e.Handled = true;
            }
            else if (isKnifing && tempKnife != null && tempKnife.Visibility == Visibility.Visible)
            {
                tempKnife.Visibility = Visibility.Collapsed;
                isKnifing = false;
                canvas.ReleaseMouseCapture();
                e.Handled = true;
            }
            else
            {
                // 点空白：清掉 Pending 幽灵线，并通知取消选中
                if (connectionDragPhase != ConnDragIdle)
                    CancelConnectionDrag(canvas, true);
                SendToAhk("EVENT|" + winId + "|" + canvas.Name + "|ClearSelection|\n");
            }
        };

        canvas.PreviewMouseMove += (s, e) =>
        {
            if (!isLabelDragging || dragTargetCtrl == null)
            {
                // 悬停在数值标签上时给出左右拖拽光标提示
                if (!isLabelDragging)
                {
                    var tb = asLabel(e.OriginalSource);
                    if (tb != null && tb.Cursor == null && findNumericPeerBox(tb) != null)
                        tb.Cursor = System.Windows.Input.Cursors.SizeWE;
                }
                return;
            }
            double dx = e.GetPosition(canvas).X - dragStartX;
            double step = Math.Max(1, Math.Abs(dragStartValue) * 0.02);
            // 默认下限 0、无上限；可由目标控件 Tag 中的 "Min:x" / "Max:y" 覆盖
            double minV = 0, maxV = double.MaxValue;
            string dragTag = (dragTargetCtrl.Tag as string) ?? "";
            var mMin = System.Text.RegularExpressions.Regex.Match(dragTag, @"Min:(-?\d+(?:\.\d+)?)");
            if (mMin.Success) double.TryParse(mMin.Groups[1].Value, System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, out minV);
            var mMax = System.Text.RegularExpressions.Regex.Match(dragTag, @"Max:(-?\d+(?:\.\d+)?)");
            if (mMax.Success) double.TryParse(mMax.Groups[1].Value, System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, out maxV);
            double newVal = dragStartValue + dx * step;
            if (newVal < minV) newVal = minV;
            if (newVal > maxV) newVal = maxV;
            if (dragStartValue == Math.Floor(dragStartValue))
                setCtrlText(dragTargetCtrl, ((int)Math.Round(newVal)).ToString());
            else
                setCtrlText(dragTargetCtrl, newVal.ToString("F0", System.Globalization.CultureInfo.InvariantCulture));
            e.Handled = true;
        };

        canvas.PreviewMouseLeftButtonUp += (s, e) =>
        {
            if (!isLabelDragging) return;
            isLabelDragging = false;
            canvas.ReleaseMouseCapture();
            // 仅结束拖拽、保留输入框当前显示值；不写回 AHK。
            // 持久化由图形编辑器在「打开节点编辑器前 / 点击保存」时统一 Flush。
            dragTargetCtrl = null;
            e.Handled = true;
        };
    }

    private void ZoomAllCanvas(Canvas canvas)
    {
        var tg = canvas.RenderTransform as System.Windows.Media.TransformGroup;
        if (tg != null && tg.Children.Count >= 2)
        {
            var scaleTransform = tg.Children[0] as System.Windows.Media.ScaleTransform;
            var translateTransform = tg.Children[1] as System.Windows.Media.TranslateTransform;

            if (scaleTransform != null && translateTransform != null)
            {
                double minX = double.MaxValue, minY = double.MaxValue;
                double maxX = double.MinValue, maxY = double.MinValue;

                foreach (UIElement child in canvas.Children)
                {
                    var fe = child as FrameworkElement;
                    if (fe == null || fe.Name == null || !fe.Name.StartsWith("Node_")) continue;

                    double left = Canvas.GetLeft(child);
                    double top = Canvas.GetTop(child);
                    if (double.IsNaN(left)) left = 0;
                    if (double.IsNaN(top)) top = 0;

                    if (fe.ActualWidth > 0 && fe.ActualHeight > 0)
                    {
                        minX = Math.Min(minX, left);
                        minY = Math.Min(minY, top);
                        maxX = Math.Max(maxX, left + fe.ActualWidth);
                        maxY = Math.Max(maxY, top + fe.ActualHeight);
                    }
                }

                if (minX <= maxX && minY <= maxY)
                {
                    double contentWidth = maxX - minX;
                    double contentHeight = maxY - minY;

                    var parent = canvas.Parent as FrameworkElement;
                    if (parent != null && parent.ActualWidth > 0 && parent.ActualHeight > 0)
                    {
                        double viewportWidth = parent.ActualWidth;
                        double viewportHeight = parent.ActualHeight;

                        // Add 250px total padding (125px per side)
                        double scaleX = viewportWidth / (contentWidth + 250);
                        double scaleY = viewportHeight / (contentHeight + 250);
                        double scale = Math.Min(scaleX, scaleY);
                        if (scale > 2.0) scale = 2.0;
                        if (scale < 0.2) scale = 0.2;

                        scaleTransform.CenterX = 0;
                        scaleTransform.CenterY = 0;
                        scaleTransform.ScaleX = scale;
                        scaleTransform.ScaleY = scale;

                        translateTransform.X = (viewportWidth - contentWidth * scale) / 2 - minX * scale - canvas.Margin.Left;
                        translateTransform.Y = (viewportHeight - contentHeight * scale) / 2 - minY * scale - canvas.Margin.Top;
                    }
                }
            }
        }
    }

    private void ZoomCanvas(Canvas canvas, double zoomFactor)
    {
        var tg = canvas.RenderTransform as System.Windows.Media.TransformGroup;
        if (tg != null && tg.Children.Count >= 2)
        {
            var scaleTransform = tg.Children[0] as System.Windows.Media.ScaleTransform;
            var translateTransform = tg.Children[1] as System.Windows.Media.TranslateTransform;

            if (scaleTransform != null && translateTransform != null)
            {
                var parent = canvas.Parent as FrameworkElement;
                if (parent != null)
                {
                    double centerX = parent.ActualWidth / 2;
                    double centerY = parent.ActualHeight / 2;
                    var parentCenter = new Point(centerX, centerY);
                    var canvasPos = parent.TranslatePoint(parentCenter, canvas);

                    double newScale = scaleTransform.ScaleX * zoomFactor;
                    if (newScale > 5.0) newScale = 5.0;
                    if (newScale < 0.1) newScale = 0.1;

                    double scaleX = scaleTransform.ScaleX;
                    translateTransform.X = translateTransform.X + canvasPos.X * (scaleX - newScale);
                    translateTransform.Y = translateTransform.Y + canvasPos.Y * (scaleX - newScale);

                    scaleTransform.ScaleX = newScale;
                    scaleTransform.ScaleY = newScale;
                }
            }
        }
    }

}
