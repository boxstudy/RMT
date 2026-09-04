// =============================================================================
// Generic element/control tools: tree walk, lookup, drag-drop
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
    private System.Collections.Generic.List<FrameworkElement> FindDescendantsByNamePrefix(DependencyObject parent, string prefix)
    {
        var results = new System.Collections.Generic.List<FrameworkElement>();
        int count = System.Windows.Media.VisualTreeHelper.GetChildrenCount(parent);
        for (int i = 0; i < count; i++)
        {
            var child = System.Windows.Media.VisualTreeHelper.GetChild(parent, i);
            var fe = child as FrameworkElement;
            if (fe != null && fe.Name != null && fe.Name.StartsWith(prefix))
                results.Add(fe);
            results.AddRange(FindDescendantsByNamePrefix(child, prefix));
        }
        return results;
    }

    private void WalkLogicalOrVisualTree(DependencyObject parent, Action<DependencyObject> callback)
    {
        if (parent == null) return;
        callback(parent);

        try
        {
            foreach (object child in LogicalTreeHelper.GetChildren(parent))
            {
                if (child is DependencyObject)
                {
                    WalkLogicalOrVisualTree((DependencyObject)child, callback);
                }
            }
        }
        catch { }

        try
        {
            int count = System.Windows.Media.VisualTreeHelper.GetChildrenCount(parent);
            for (int i = 0; i < count; i++)
            {
                var child = System.Windows.Media.VisualTreeHelper.GetChild(parent, i);
                WalkLogicalOrVisualTree(child, callback);
            }
        }
        catch { }
    }

    private void UnregisterNamesRecursive(DependencyObject d)
    {
        var visited = new System.Collections.Generic.HashSet<object>();
        UnregisterNamesRecursiveInternal(d, visited);
    }

    private void UnregisterNamesRecursiveInternal(DependencyObject d, System.Collections.Generic.HashSet<object> visited)
    {
        if (d == null || !visited.Add(d)) return;
        var fe = d as FrameworkElement;
        if (fe != null && !string.IsNullOrEmpty(fe.Name))
        {
            try {
                var ns = NameScope.GetNameScope(win);
                if (ns != null) { ns.UnregisterName(fe.Name); }
                else { win.UnregisterName(fe.Name); }
            } catch { }
            try {
                var keys = _boundEvents.Where(k => k.StartsWith(fe.Name + ":")).ToList();
                foreach (var key in keys) {
                    _boundEvents.Remove(key);
                }
            } catch { }
        }
        var fce = d as FrameworkContentElement;
        if (fce != null && !string.IsNullOrEmpty(fce.Name))
        {
            try {
                var ns = NameScope.GetNameScope(win);
                if (ns != null) { ns.UnregisterName(fce.Name); }
                else { win.UnregisterName(fce.Name); }
            } catch { }
            try {
                var keys = _boundEvents.Where(k => k.StartsWith(fce.Name + ":")).ToList();
                foreach (var key in keys) {
                    _boundEvents.Remove(key);
                }
            } catch { }
        }
        foreach (object child in LogicalTreeHelper.GetChildren(d))
        {
            if (child is DependencyObject)
            {
                UnregisterNamesRecursiveInternal((DependencyObject)child, visited);
            }
        }
        var cc = d as ContentControl;
        if (cc != null && cc.Content is DependencyObject)
        {
            UnregisterNamesRecursiveInternal((DependencyObject)cc.Content, visited);
        }
        var dec = d as Decorator;
        if (dec != null && dec.Child != null)
        {
            UnregisterNamesRecursiveInternal(dec.Child, visited);
        }
        var panel = d as Panel;
        if (panel != null)
        {
            foreach (UIElement child in panel.Children)
            {
                UnregisterNamesRecursiveInternal(child, visited);
            }
        }
        var ic = d as ItemsControl;
        if (ic != null)
        {
            foreach (object item in ic.Items)
            {
                if (item is DependencyObject)
                {
                    UnregisterNamesRecursiveInternal((DependencyObject)item, visited);
                }
            }
        }
    }

    private DependencyObject FindLogicalNodeDeep(DependencyObject parent, string name)
    {
        var visited = new System.Collections.Generic.HashSet<object>();
        return FindControlDeepInternal(parent, name, visited);
    }

    private DependencyObject FindControlDeepInternal(DependencyObject d, string name, System.Collections.Generic.HashSet<object> visited)
    {
        if (d == null || !visited.Add(d)) return null;

        var fe = d as FrameworkElement;
        if (fe != null && fe.Name == name) return d;

        var fce = d as FrameworkContentElement;
        if (fce != null && fce.Name == name) return d;

        if (fe != null && fe.ContextMenu != null)
        {
            var found = FindControlDeepInternal(fe.ContextMenu, name, visited);
            if (found != null) return found;
        }

        // 1. ContentControl Content
        var cc = d as ContentControl;
        if (cc != null && cc.Content is DependencyObject)
        {
            var found = FindControlDeepInternal((DependencyObject)cc.Content, name, visited);
            if (found != null) return found;
        }

        // 2. Decorator Child
        var dec = d as Decorator;
        if (dec != null && dec.Child != null)
        {
            var found = FindControlDeepInternal(dec.Child, name, visited);
            if (found != null) return found;
        }

        // 3. Panel Children
        var panel = d as Panel;
        if (panel != null)
        {
            foreach (UIElement child in panel.Children)
            {
                var found = FindControlDeepInternal(child, name, visited);
                if (found != null) return found;
            }
        }

        // 4. ItemsControl Items
        var ic = d as ItemsControl;
        if (ic != null)
        {
            foreach (object item in ic.Items)
            {
                if (item is DependencyObject)
                {
                    var found = FindControlDeepInternal((DependencyObject)item, name, visited);
                    if (found != null) return found;
                }
            }
        }

        // 5. Logical Tree Helper
        foreach (object child in LogicalTreeHelper.GetChildren(d))
        {
            if (child is DependencyObject)
            {
                var found = FindControlDeepInternal((DependencyObject)child, name, visited);
                if (found != null) return found;
            }
        }

        return null;
    }

    private void WalkVisualTree(System.Windows.DependencyObject parent, Action<System.Windows.DependencyObject> callback)
    {
        int count = System.Windows.Media.VisualTreeHelper.GetChildrenCount(parent);
        for (int i = 0; i < count; i++)
        {
            var child = System.Windows.Media.VisualTreeHelper.GetChild(parent, i);
            callback(child);
            WalkVisualTree(child, callback);
        }
    }

    private void WalkLogicalTree(System.Windows.DependencyObject parent, Action<System.Windows.DependencyObject> callback)
    {
        foreach (object raw in System.Windows.LogicalTreeHelper.GetChildren(parent))
        {
            var child = raw as System.Windows.DependencyObject;
            if (child == null)
                continue;
            callback(child);
            WalkLogicalTree(child, callback);
        }
    }

    private object FindControlByPath(string path)
    {
        if (string.IsNullOrEmpty(path)) return null;
        object cached;
        if (_controlCache.TryGetValue(path, out cached)) return cached;

        string[] parts = path.Split('>');
        object current = null;
        if (win != null)
        {
            if (parts[0] == "Window")
            {
                current = win;
            }
            else
            {
                current = win.FindName(parts[0]);
                if (current == null && win.Content is FrameworkElement)
                {
                    current = ((FrameworkElement)win.Content).FindName(parts[0]);
                }
                if (current == null)
                {
                    var ns = NameScope.GetNameScope(win);
                    if (ns != null)
                    {
                        current = ns.FindName(parts[0]);
                    }
                }
            }
        }
        if (current == null)
        {
            current = FindLogicalNodeDeep(win, parts[0]);
        }
        if (current == null && win != null)
        {
            WalkVisualTree(win, (DependencyObject d) =>
            {
                if (current != null) return;
                FrameworkElement fe = d as FrameworkElement;
                if (fe != null && fe.Name == parts[0])
                {
                    current = d;
                }
            });
        }

        if (current != null)
        {
            for (int i = 1; i < parts.Length; i++)
            {
                string segment = parts[i];
                if (current is ItemsControl)
                {
                    ItemsControl ic = (ItemsControl)current;
                    object found = null;
                    foreach (var item in ic.Items)
                    {
                        if (item is HeaderedItemsControl)
                        {
                            var hic = (HeaderedItemsControl)item;
                            string headerStr = hic.Header != null ? hic.Header.ToString() : "";
                            if (headerStr.Contains("(" + segment + ")") || headerStr == segment || hic.Name == segment || (hic.Tag != null && hic.Tag.ToString() == segment))
                            {
                                found = hic;
                                break;
                            }
                        }
                        else if (item is FrameworkElement)
                        {
                            var fe = (FrameworkElement)item;
                            if (fe.Name == segment || (fe.Tag != null && fe.Tag.ToString() == segment))
                            {
                                found = fe;
                                break;
                            }
                        }
                    }
                    if (found != null)
                    {
                        current = found;
                    }
                    else
                    {
                        current = null;
                    }
                }
                else if (current is DependencyObject)
                {
                    object found = null;
                    WalkVisualTree((DependencyObject)current, (DependencyObject d) =>
                    {
                        if (found != null) return;
                        FrameworkElement fe = d as FrameworkElement;
                        if (fe != null && (fe.Name == segment || (fe.Tag != null && fe.Tag.ToString() == segment)))
                        {
                            found = fe;
                        }
                    });
                    if (found != null)
                    {
                        current = found;
                    }
                    else
                    {
                        current = null;
                    }
                }
                else
                {
                    current = null;
                }
                if (current == null) break;
            }
        }
        _controlCache[path] = current;
        return current;
    }

    // Generic drag-source: enables any element to be dragged with a custom payload
    // Usage from AHK: ui.Update("MyButton", "EnableDragSource", "DesignerComponent")
    // The drag payload will be the element's Tag property (if set), or its x:Name
    private System.Collections.Generic.Dictionary<UIElement, bool> dragSourceEnabled = new System.Collections.Generic.Dictionary<UIElement, bool>();

    private void EnableGenericDragSource(UIElement element, string ctrlName, string dataFormat)
    {
        if (dragSourceEnabled.ContainsKey(element) && dragSourceEnabled[element]) return;
        dragSourceEnabled[element] = true;

        Point dragStartPos = new Point();
        bool mouseDown = false;

        element.PreviewMouseLeftButtonDown += (s, e) =>
        {
            dragStartPos = e.GetPosition(null);
            mouseDown = true;
        };

        element.PreviewMouseLeftButtonUp += (s, e) =>
        {
            mouseDown = false;
        };

        element.PreviewMouseMove += (s, e) =>
        {
            if (!mouseDown || e.LeftButton != System.Windows.Input.MouseButtonState.Pressed)
            {
                mouseDown = false;
                return;
            }

            Point pos = e.GetPosition(null);
            if (Math.Abs(pos.X - dragStartPos.X) > SystemParameters.MinimumHorizontalDragDistance ||
                Math.Abs(pos.Y - dragStartPos.Y) > SystemParameters.MinimumVerticalDragDistance)
            {

                mouseDown = false;

                // Determine payload: use Tag if set, otherwise use control name
                string payload = ctrlName;
                var fe = element as FrameworkElement;
                if (fe != null && fe.Tag != null && fe.Tag.ToString() != "" && fe.Tag.ToString() != "DragEnabled")
                {
                    payload = fe.Tag.ToString();
                }

                DataObject dragData = new DataObject(dataFormat, payload);
                dragData.SetData("DragSourceName", ctrlName);

                try
                {
                    DragDrop.DoDragDrop(element, dragData, DragDropEffects.Copy | DragDropEffects.Move);
                }
                catch { }
            }
        };
    }

    // Generic drop-target: enables any element to accept drops and sends events to AHK
    // Usage from AHK: ui.Update("CanvasArea", "EnableDropTarget", "DesignerComponent")
    // Events sent: DragEnter (with payload), DragLeave, Drop (with payload + source name)
    private System.Collections.Generic.Dictionary<UIElement, bool> dropTargetEnabled = new System.Collections.Generic.Dictionary<UIElement, bool>();

    private void EnableGenericDropTarget(UIElement element, string ctrlName, string dataFormat)
    {
        if (dropTargetEnabled.ContainsKey(element) && dropTargetEnabled[element]) return;
        dropTargetEnabled[element] = true;

        element.AllowDrop = true;

        element.DragEnter += (s, e) =>
        {
            if (e.Data.GetDataPresent(dataFormat))
            {
                e.Effects = DragDropEffects.Copy;
                string payload = e.Data.GetData(dataFormat) as string ?? "";
                SendToAhk("EVENT|" + winId + "|" + ctrlName + "|DragEnter|" +
                    BridgeUtil.LengthPrefix(payload) + "\n");
            }
            else if (e.Data.GetDataPresent(DataFormats.FileDrop))
            {
                e.Effects = DragDropEffects.Copy;
            }
            else
            {
                e.Effects = DragDropEffects.None;
            }
            e.Handled = true;
        };

        element.DragOver += (s, e) =>
        {
            if (e.Data.GetDataPresent(dataFormat) || e.Data.GetDataPresent(DataFormats.FileDrop))
            {
                e.Effects = DragDropEffects.Copy;
            }
            else
            {
                e.Effects = DragDropEffects.None;
            }
            e.Handled = true;
        };

        element.DragLeave += (s, e) =>
        {
            SendToAhk("EVENT|" + winId + "|" + ctrlName + "|DragLeave|\n");
        };

        element.Drop += (s, e) =>
        {
            if (e.Data.GetDataPresent(dataFormat))
            {
                string payload = e.Data.GetData(dataFormat) as string ?? "";
                string sourceName = e.Data.GetData("DragSourceName") as string ?? "";
                var dropPos = e.GetPosition((UIElement)s);
                string dropData = payload + "|" + sourceName + "|" +
                    dropPos.X.ToString("F0", System.Globalization.CultureInfo.InvariantCulture) + "," +
                    dropPos.Y.ToString("F0", System.Globalization.CultureInfo.InvariantCulture);
                SendToAhk("EVENT|" + winId + "|" + ctrlName + "|Drop|" +
                    BridgeUtil.LengthPrefix(dropData) + "\n");
            }
            else if (e.Data.GetDataPresent(DataFormats.FileDrop))
            {
                string[] files = (string[])e.Data.GetData(DataFormats.FileDrop);
                SendToAhk("EVENT|" + winId + "|" + ctrlName + "|FileDrop|" +
                    BridgeUtil.LengthPrefix(string.Join("|", files)) + "\n");
            }
            e.Handled = true;
        };
    }

    private static readonly System.Collections.Generic.HashSet<ListBox> _listBoxDragDropEnabled =
        new System.Collections.Generic.HashSet<ListBox>();

    private void EnableListBoxDragDrop(ListBox listBox, string ctrlName)
    {
        if (!_listBoxDragDropEnabled.Add(listBox))
            return;
        listBox.AllowDrop = true;
        Point dragStart = new Point();
        bool isDragging = false;

        listBox.PreviewMouseLeftButtonDown += (s, e) =>
        {
            if (e.ClickCount >= 2)
            {
                isDragging = false;
                return;
            }
            dragStart = e.GetPosition(null);
            isDragging = true;
        };

        listBox.PreviewMouseMove += (s, e) =>
        {
            if (e.LeftButton == System.Windows.Input.MouseButtonState.Pressed && isDragging)
            {
                Point pos = e.GetPosition(null);
                if (Math.Abs(pos.X - dragStart.X) > SystemParameters.MinimumHorizontalDragDistance ||
                    Math.Abs(pos.Y - dragStart.Y) > SystemParameters.MinimumVerticalDragDistance)
                {

                    var item = GetListBoxItemUnderMouse(listBox, e.GetPosition(listBox));
                    if (item != null)
                    {
                        int srcIdx = listBox.ItemContainerGenerator.IndexFromContainer(item);
                        string content = "";
                        if (item.Content is string)
                        {
                            content = (string)item.Content;
                        }
                        else if (item.Content is System.Windows.Controls.TextBlock)
                        {
                            content = ((System.Windows.Controls.TextBlock)item.Content).Text;
                        }
                        else
                        {
                            content = item.Content != null ? item.Content.ToString() : "";
                        }

                        DataObject dragData = new DataObject("KanbanItem", content);
                        dragData.SetData("SourceBox", ctrlName);
                        dragData.SetData("SourceIndex", srcIdx.ToString());

                        DragDrop.DoDragDrop(listBox, dragData, DragDropEffects.Move);
                    }
                    isDragging = false;
                }
            }
        };

        listBox.Drop += (s, e) =>
        {
            if (!e.Data.GetDataPresent("KanbanItem"))
                return;
            string content = (string)e.Data.GetData("KanbanItem");
            string sourceBox = e.Data.GetData("SourceBox") as string ?? "";
            if (sourceBox != ctrlName)
            {
                SendToAhk("EVENT|" + winId + "|" + ctrlName + "|ItemDropped|" +
                    BridgeUtil.LengthPrefix(sourceBox + "|" + content) + "\n");
                return;
            }
            int srcIdx = -1;
            int.TryParse(e.Data.GetData("SourceIndex") as string, out srcIdx);
            if (srcIdx < 0)
                return;
            var target = GetListBoxItemUnderMouse(listBox, e.GetPosition(listBox));
            int insert;
            if (target == null)
            {
                insert = listBox.Items.Count;
            }
            else
            {
                int tgt = listBox.ItemContainerGenerator.IndexFromContainer(target);
                if (tgt < 0)
                    tgt = listBox.Items.Count - 1;
                Point p = e.GetPosition(target);
                insert = (p.Y >= target.ActualHeight / 2.0) ? tgt + 1 : tgt;
            }
            if (insert == srcIdx || insert == srcIdx + 1)
                return;
            SendToAhk("EVENT|" + winId + "|" + ctrlName + "|ItemReordered|" +
                BridgeUtil.LengthPrefix(srcIdx.ToString() + "|" + insert.ToString()) + "\n");
        };
    }

    private ListBoxItem GetListBoxItemUnderMouse(ListBox lb, Point p)
    {
        System.Windows.Media.HitTestResult hit = System.Windows.Media.VisualTreeHelper.HitTest(lb, p);
        if (hit != null)
        {
            DependencyObject depObj = hit.VisualHit;
            while (depObj != null && !(depObj is ListBoxItem))
            {
                depObj = System.Windows.Media.VisualTreeHelper.GetParent(depObj);
            }
            return depObj as ListBoxItem;
        }
        return null;
    }

    private void EnableListBoxDragSource(ListBox listBox, string ctrlName, string dataFormat)
    {
        Point dragStart = new Point();
        bool isDragging = false;

        listBox.PreviewMouseLeftButtonDown += (s, e) =>
        {
            dragStart = e.GetPosition(null);
            isDragging = true;
        };

        listBox.PreviewMouseMove += (s, e) =>
        {
            if (e.LeftButton == System.Windows.Input.MouseButtonState.Pressed && isDragging)
            {
                Point pos = e.GetPosition(null);
                if (Math.Abs(pos.X - dragStart.X) > SystemParameters.MinimumHorizontalDragDistance ||
                    Math.Abs(pos.Y - dragStart.Y) > SystemParameters.MinimumVerticalDragDistance)
                {
                    var item = GetListBoxItemUnderMouse(listBox, e.GetPosition(listBox));
                    if (item != null)
                    {
                        string content = "";
                        if (item.Content is string)
                        {
                            content = (string)item.Content;
                        }
                        else if (item.Content is System.Windows.Controls.TextBlock)
                        {
                            content = ((System.Windows.Controls.TextBlock)item.Content).Text;
                        }
                        else
                        {
                            content = item.Content != null ? item.Content.ToString() : "";
                        }

                        DataObject dragData = new DataObject(dataFormat, content);
                        dragData.SetData("DragSourceName", ctrlName);
                        try
                        {
                            DragDrop.DoDragDrop(listBox, dragData, DragDropEffects.Copy | DragDropEffects.Move);
                        }
                        catch { }
                    }
                    isDragging = false;
                }
            }
        };
    }

}
