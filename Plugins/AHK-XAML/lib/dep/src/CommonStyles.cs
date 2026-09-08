// Shared WPF control styles. Configuration is data only; never loads executable XAML.
using System;
using System.Collections;
using System.Collections.Generic;
using System.ComponentModel;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Controls.Primitives;
using System.Windows.Data;
using System.Windows.Media;
using System.Xml;

internal static class RmtCommonStyles
{
    internal sealed class Entry
    {
        public WeakReference Element;
        public string Key, Location;
        public Dictionary<string, object> Original = new Dictionary<string, object>();
        public HashSet<string> Unset = new HashSet<string>();
        public HashSet<string> Applied = new HashSet<string>();
        public Dictionary<string, object> ResourceKeys = new Dictionary<string, object>();
        public Dictionary<string, string> LastApplied = new Dictionary<string, string>();
    }
    internal static readonly string[] Properties = {
        "Background", "Foreground", "BorderBrush", "BorderThickness", "CornerRadius",
        "Margin", "Padding", "Width", "Height", "MinWidth", "MinHeight", "MaxWidth", "MaxHeight",
        "FontFamily", "FontSize", "FontWeight", "FontStyle", "Opacity",
        "HorizontalAlignment", "VerticalAlignment", "HorizontalContentAlignment", "VerticalContentAlignment"
    };
    private static readonly ConditionalWeakTable<FrameworkElement, Entry> entries = new ConditionalWeakTable<FrameworkElement, Entry>();
    private static readonly List<WeakReference> elements = new List<WeakReference>();
    internal static readonly Dictionary<string, Dictionary<string, string>> Values = new Dictionary<string, Dictionary<string, string>>();
    private static string path;
    private static bool initialized, development;
    private static RmtStyleEditor editor;
    private static readonly HashSet<Window> watched = new HashSet<Window>();
    private static bool refreshPending;
    private sealed class Corners { public CornerRadius Value; }
    private static readonly ConditionalWeakTable<Border, Corners> corners = new ConditionalWeakTable<Border, Corners>();
    private static readonly DependencyProperty ControlCornerRadius = DependencyProperty.RegisterAttached(
        "CommonCornerRadius", typeof(CornerRadius), typeof(RmtCommonStyles), new PropertyMetadata(new CornerRadius(0),
            (obj, args) => ApplyCorners(obj as Control)));
    internal static string LoadError = "";

    internal static void Configure(Window window, string options)
    {
        var parts = options.Split(new[] { '|' }, 2);
        if (!initialized)
        {
            path = parts[0];
            development = parts.Length == 2 && parts[1] == "1";
            Load();
            EventManager.RegisterClassHandler(typeof(FrameworkElement), FrameworkElement.LoadedEvent,
                new RoutedEventHandler(OnLoaded), true);
            initialized = true;
        }
        Walk(window, new HashSet<DependencyObject>());
        ApplyResources(window);
        if (watched.Add(window))
        {
            bool pending = false, closed = false;
            // WPF does not broadcast Loaded to nodes without an instance/style Loaded handler.
            // Coalesce layout discovery so virtualized and dynamically inserted nodes are included.
            EventHandler layout = delegate
            {
                if (pending || closed) return;
                pending = true;
                window.Dispatcher.BeginInvoke(System.Windows.Threading.DispatcherPriority.Background, new Action(delegate
                {
                    pending = false;
                    if (!closed) Walk(window, new HashSet<DependencyObject>());
                }));
            };
            window.LayoutUpdated += layout;
            window.Closed += delegate { closed = true; window.LayoutUpdated -= layout; watched.Remove(window); };
        }
    }

    private static void OnLoaded(object sender, RoutedEventArgs args)
    {
        var fe = sender as FrameworkElement;
        if (fe != null) Register(fe);
    }

    private static void Walk(DependencyObject root, HashSet<DependencyObject> visited)
    {
        if (root == null || !visited.Add(root)) return;
        var fe = root as FrameworkElement;
        if (fe != null) Register(fe);
        foreach (var child in LogicalTreeHelper.GetChildren(root).OfType<DependencyObject>().ToArray()) Walk(child, visited);
        if (root is Visual)
            for (int i = 0; i < VisualTreeHelper.GetChildrenCount(root); i++) Walk(VisualTreeHelper.GetChild(root, i), visited);
    }

    private static bool Eligible(FrameworkElement fe)
    {
        // DataTemplate controls (including virtual rows) are application controls too.
        if (fe is Window || (fe.TemplatedParent is Control && !(fe.TemplatedParent is ContentPresenter)) || Window.GetWindow(fe) is RmtStyleEditor) return false;
        return fe is Control || fe is Border || fe is TextBlock;
    }

    private static string StyleKey(FrameworkElement fe)
    {
        if (!string.IsNullOrEmpty(fe.Uid) && fe.Uid.StartsWith("gm:")) return fe.Uid.Substring(3);
        if (!string.IsNullOrEmpty(fe.Uid) && fe.Uid.StartsWith("gm-exception:")) return "特殊/" + fe.Uid.Substring(13);
        if (fe.Name == "BtnMinimize" || fe.Name == "BtnMaximize" || fe.Name == "BtnWinClose" || fe.Name == "BtnClosePanel")
            return "特殊/窗口标题栏/" + fe.Name;
        var style = fe.Style;
        for (FrameworkElement parent = fe; parent != null; parent = (LogicalTreeHelper.GetParent(parent) ?? VisualParent(parent)) as FrameworkElement)
        {
            string key = FindKey(parent.Resources, style);
            if (key != null) return "样式/" + key;
        }
        return "通用/" + fe.GetType().Name;
    }

    private static DependencyObject VisualParent(DependencyObject value)
    {
        return value is Visual ? VisualTreeHelper.GetParent(value) : null;
    }

    private static string FindKey(ResourceDictionary resources, Style style)
    {
        if (style == null) return null;
        foreach (object key in resources.Keys)
            if (key is string && ReferenceEquals(resources[key], style)) return (string)key;
        foreach (ResourceDictionary child in resources.MergedDictionaries)
        {
            string key = FindKey(child, style);
            if (key != null) return key;
        }
        return null;
    }

    private static void Register(FrameworkElement fe)
    {
        if (!Eligible(fe)) return;
        Entry existing;
        if (entries.TryGetValue(fe, out existing)) return;
        var window = Window.GetWindow(fe);
        var entry = new Entry { Element = new WeakReference(fe), Key = StyleKey(fe),
            Location = (window == null ? "" : window.Title) + " / " + fe.GetType().Name + " / " + fe.Name + " / " + fe.Uid };
        entries.Add(fe, entry);
        elements.Add(new WeakReference(fe));
        if (elements.Count % 512 == 0) elements.RemoveAll(x => !x.IsAlive);
        foreach (string property in Properties)
        {
            var dp = Property(fe, property);
            if (dp == null) continue;
            entry.Original[property] = fe.GetValue(dp);
            if (fe.ReadLocalValue(dp) == DependencyProperty.UnsetValue) entry.Unset.Add(property);
        }
        Apply(entry);
    }

    internal static DependencyProperty Property(FrameworkElement fe, string name)
    {
        if (name == "CornerRadius" && fe is Control) return ControlCornerRadius;
        var descriptor = DependencyPropertyDescriptor.FromName(name, fe.GetType(), fe.GetType());
        return descriptor == null || descriptor.IsReadOnly ? null : descriptor.DependencyProperty;
    }

    internal static List<Entry> Live()
    {
        elements.RemoveAll(x => !x.IsAlive);
        var result = new List<Entry>();
        foreach (var weak in elements)
        {
            var fe = weak.Target as FrameworkElement;
            Entry entry;
            if (fe != null && entries.TryGetValue(fe, out entry) && Window.GetWindow(fe) != null) result.Add(entry);
        }
        return result;
    }

    internal static string Text(object value)
    {
        if (value == null) return "";
        var converter = TypeDescriptor.GetConverter(value.GetType());
        return converter.CanConvertTo(typeof(string)) ? converter.ConvertToInvariantString(value) : value.ToString();
    }

    internal static object ConvertValue(Type type, string value)
    {
        if (type == typeof(double) && value.Equals("Auto", StringComparison.OrdinalIgnoreCase)) return double.NaN;
        object result = TypeDescriptor.GetConverter(type).ConvertFromInvariantString(value);
        var brush = result as Freezable;
        if (brush != null && brush.CanFreeze) brush.Freeze();
        return result;
    }

    private static void Apply(Entry entry)
    {
        var fe = entry.Element.Target as FrameworkElement;
        if (fe == null) return;
        // A theme/font change may replace a local value while an override is active.
        // Keep that new base value for reset instead of restoring a stale startup value.
        foreach (string name in entry.Applied)
        {
            var dp = Property(fe, name);
            if (entry.LastApplied.ContainsKey(name) && Text(fe.GetValue(dp)) != entry.LastApplied[name])
            {
                entry.Original[name] = fe.GetValue(dp);
                if (fe.ReadLocalValue(dp) == DependencyProperty.UnsetValue) entry.Unset.Add(name);
                else entry.Unset.Remove(name);
            }
        }
        var desired = new Dictionary<string, string>();
        Dictionary<string, string> common, specific;
        // Explicit exceptions opt out of shared overrides but remain editable in the catalog.
        if (!entry.Key.StartsWith("特殊/") && Values.TryGetValue("通用/" + fe.GetType().Name, out common))
            foreach (var pair in common) desired[pair.Key] = pair.Value;
        if (Values.TryGetValue(entry.Key, out specific))
            foreach (var pair in specific) desired[pair.Key] = pair.Value;
        foreach (string name in entry.Applied.ToArray())
        {
            if (desired.ContainsKey(name)) continue;
            var dp = Property(fe, name);
            if (entry.ResourceKeys.ContainsKey(name)) fe.SetResourceReference(dp, entry.ResourceKeys[name]);
            else if (entry.Unset.Contains(name)) fe.ClearValue(dp);
            else fe.SetCurrentValue(dp, entry.Original[name]);
            entry.Applied.Remove(name);
        }
        foreach (var pair in desired)
        {
            var dp = Property(fe, pair.Key);
            if (dp == null || BindingOperations.IsDataBound(fe, dp)) continue;
            try
            {
                if (!entry.Applied.Contains(pair.Key))
                {
                    // Capture at first edit, after startup theme/font updates have completed.
                    entry.Original[pair.Key] = fe.GetValue(dp);
                    var local = fe.ReadLocalValue(dp);
                    if (local != null && local.GetType().Name == "ResourceReferenceExpression")
                    {
                        var key = local.GetType().GetProperty("ResourceKey", System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.NonPublic);
                        if (key != null) entry.ResourceKeys[pair.Key] = key.GetValue(local, null);
                    }
                    if (fe.ReadLocalValue(dp) == DependencyProperty.UnsetValue) entry.Unset.Add(pair.Key);
                    else entry.Unset.Remove(pair.Key);
                }
                // SetCurrentValue retains existing resource and binding expressions.
                fe.SetCurrentValue(dp, ConvertValue(dp.PropertyType, pair.Value));
                entry.Applied.Add(pair.Key);
                entry.LastApplied[pair.Key] = Text(fe.GetValue(dp));
                if (pair.Key == "CornerRadius") ApplyCorners(fe as Control);
            }
            catch (Exception ex) { LoadError = entry.Key + "/" + pair.Key + ": " + ex.Message; }
        }
    }

    private static readonly Dictionary<Window, Dictionary<string, object>> resourceOriginals = new Dictionary<Window, Dictionary<string, object>>();
    internal static void ApplyResources(Window window)
    {
        if (window is RmtStyleEditor) return;
        Dictionary<string, object> originals;
        if (!resourceOriginals.TryGetValue(window, out originals))
        {
            originals = new Dictionary<string, object>();
            resourceOriginals[window] = originals;
            window.Closed += delegate { resourceOriginals.Remove(window); };
        }
        foreach (var item in originals.ToArray())
            if (!Values.ContainsKey("颜色/" + item.Key)) { window.Resources[item.Key] = item.Value; originals.Remove(item.Key); }
        foreach (var item in Values.Where(x => x.Key.StartsWith("颜色/")))
        {
            string name = item.Key.Substring(3);
            var old = window.TryFindResource(name) as SolidColorBrush;
            if (old == null || !item.Value.ContainsKey("Color")) continue;
            if (!originals.ContainsKey(name)) originals[name] = old;
            try { window.Resources[name] = ConvertValue(typeof(Brush), item.Value["Color"]); }
            catch (Exception ex) { LoadError = name + ": " + ex.Message; }
        }
    }

    internal static Dictionary<string, string> Colors(Window window)
    {
        var result = new Dictionary<string, string>();
        if (Application.Current != null) CollectColors(Application.Current.Resources, result);
        CollectColors(window.Resources, result);
        return result;
    }
    private static void CollectColors(ResourceDictionary dictionary, Dictionary<string, string> result)
    {
        foreach (var child in dictionary.MergedDictionaries) CollectColors(child, result);
        foreach (object key in dictionary.Keys)
            if (key is string && dictionary[key] is SolidColorBrush) result[(string)key] = Text(dictionary[key]);
    }

    internal static void Refresh()
    {
        foreach (var entry in Live()) Apply(entry);
        foreach (Window window in Application.Current.Windows.Cast<Window>().ToArray()) ApplyResources(window);
    }

    private static void ApplyCorners(Control control)
    {
        if (control == null) return;
        var border = FindControlBorder(control);
        if (border == null) return;
        if (control.ReadLocalValue(ControlCornerRadius) == DependencyProperty.UnsetValue)
        {
            Corners old;
            if (corners.TryGetValue(border, out old)) { border.SetCurrentValue(Border.CornerRadiusProperty, old.Value); corners.Remove(border); }
        }
        else
        {
            corners.GetValue(border, b => new Corners { Value = b.CornerRadius });
            border.SetCurrentValue(Border.CornerRadiusProperty, control.GetValue(ControlCornerRadius));
        }
    }

    internal static object DisplayValue(FrameworkElement element, string name, DependencyProperty dp)
    {
        if (name == "CornerRadius" && element is Control && element.ReadLocalValue(dp) == DependencyProperty.UnsetValue)
        {
            var border = FindControlBorder((Control)element);
            if (border != null) return border.CornerRadius;
        }
        return element.GetValue(dp);
    }

    private static Border FindControlBorder(Control control)
    {
        control.ApplyTemplate();
        var queue = new Queue<DependencyObject>(); queue.Enqueue(control);
        while (queue.Count > 0)
        {
            var node = queue.Dequeue();
            var border = node as Border;
            if (border != null && ReferenceEquals(border.TemplatedParent, control))
            {
                return border;
            }
            for (int i = 0; i < VisualTreeHelper.GetChildrenCount(node); i++) queue.Enqueue(VisualTreeHelper.GetChild(node, i));
        }
        return null;
    }

    internal static void ThemeChanged(Window window, string name)
    {
        if (!initialized) return;
        Dictionary<string, object> originals;
        if (resourceOriginals.TryGetValue(window, out originals) && originals.ContainsKey(name)) originals[name] = window.TryFindResource(name);
        if (refreshPending) return;
        refreshPending = true;
        window.Dispatcher.BeginInvoke(new Action(delegate { refreshPending = false; Refresh(); }));
    }

    internal static void Open(Window owner)
    {
        if (!development) return;
        if (editor != null) { editor.Activate(); return; }
        editor = new RmtStyleEditor(owner);
        editor.Closed += delegate { editor = null; };
        editor.Show();
    }

    private static void Load()
    {
        if (!File.Exists(path)) return;
        try
        {
            var doc = new XmlDocument { XmlResolver = null };
            using (var reader = XmlReader.Create(path, new XmlReaderSettings { DtdProcessing = DtdProcessing.Prohibit, XmlResolver = null })) doc.Load(reader);
            foreach (XmlElement style in doc.SelectNodes("/CommonStyles/Style"))
            {
                var properties = new Dictionary<string, string>();
                foreach (XmlElement prop in style.SelectNodes("Property"))
                    if (Properties.Contains(prop.GetAttribute("name")) || prop.GetAttribute("name") == "Color")
                    {
                        string name = prop.GetAttribute("name"), value = prop.GetAttribute("value");
                        try
                        {
                            var dp = name == "Color" ? null : Property(new Button(), name);
                            object converted = ConvertValue(dp == null ? typeof(Brush) : dp.PropertyType, value);
                            if (dp != null && !dp.IsValidValue(converted)) throw new ArgumentException(name + " 值无效");
                            properties[name] = value;
                        }
                        catch (Exception ex) { LoadError = "已忽略无效配置 " + name + ": " + ex.Message; }
                    }
                Values[style.GetAttribute("key")] = properties;
            }
        }
        catch (Exception ex) { LoadError = "样式配置读取失败：" + ex.Message; }
    }

    internal static void Save()
    {
        Directory.CreateDirectory(Path.GetDirectoryName(path));
        var settings = new XmlWriterSettings { Indent = true, Encoding = new System.Text.UTF8Encoding(false) };
        string temp = path + ".tmp";
        using (var writer = XmlWriter.Create(temp, settings))
        {
            writer.WriteStartElement("CommonStyles"); writer.WriteAttributeString("version", "1");
            foreach (var style in Values.OrderBy(x => x.Key))
            {
                writer.WriteStartElement("Style"); writer.WriteAttributeString("key", style.Key);
                foreach (var prop in style.Value.OrderBy(x => x.Key))
                {
                    writer.WriteStartElement("Property"); writer.WriteAttributeString("name", prop.Key);
                    writer.WriteAttributeString("value", prop.Value); writer.WriteEndElement();
                }
                writer.WriteEndElement();
            }
            writer.WriteEndElement();
        }
        if (File.Exists(path)) File.Replace(temp, path, path + ".bak"); else File.Move(temp, path);
    }
}

internal sealed class RmtStyleEditor : Window
{
    private readonly Window source;
    private readonly ListBox catalog = new ListBox();
    private readonly StackPanel fields = new StackPanel();
    private readonly StackPanel preview = new StackPanel();
    private readonly TextBlock status = new TextBlock { TextWrapping = TextWrapping.Wrap };
    private readonly TextBox search = new TextBox();
    private readonly Dictionary<string, TextBox> inputs = new Dictionary<string, TextBox>();
    private readonly Dictionary<string, string> labels = new Dictionary<string, string> {
        {"样式/RmtItemEditBtn", "按钮 A · 宏配置—操作按钮"}, {"样式/RmtItemPrimaryBtn", "按钮 B · 宏配置—设置按钮"},
        {"Main.Config", "按钮 C · 主界面—配置管理"}, {"Main.Save", "按钮 D · 主界面—应用保存"},
        {"Theme.Confirm", "按钮 F · 设置—主题选项确定"}
    };
    private static readonly Dictionary<string, string> notices = new Dictionary<string, string> {
        {"特殊说明/系统菜单与系统弹窗", "系统 Menu、MsgBox、InputBox 由 Windows 绘制，不属于 WPF 控件树。此项仅登记来源，不能通过通用 WPF 属性编辑。应用内使用 XAMLHost 的对话框仍自动接入。"},
        {"特殊说明/屏幕搜索范围标记", "Gui/SearchProGui.ahk：四个原生无标题置顶窗口用于描绘屏幕范围，带鼠标穿透。属于自绘标记，未接入通用控件尺寸与边距覆盖。"},
        {"特殊说明/旧输入按钮条", "Gui/InputBtnGui.ahk：旧原生透明按钮条，透明键色 EEAA99，字体 s11 w550，按钮宽 80。新版 Gui/InputBtnXamlGui.ahk 已经通过 XAMLHost 自动接入。"},
        {"特殊说明/运行浮层与轮盘业务颜色", "Main/Util/ThemeUtil.ahk 的 AppThemeUtil.ColorDefs 维护 Wheel_*、Panel_*、CMD_* 业务配色；在设置→主题选项中配置。它们属于独立业务绘制，不等同于通用窗口按钮颜色。"}
    };
    private static readonly Dictionary<string, string> propertyLabels = new Dictionary<string, string> {
        {"Background", "背景颜色"}, {"Foreground", "文字颜色"}, {"BorderBrush", "边框颜色"}, {"BorderThickness", "边框粗细"}, {"CornerRadius", "圆角"},
        {"Margin", "外边距"}, {"Padding", "内边距"}, {"Width", "宽度"}, {"Height", "高度"}, {"MinWidth", "最小宽度"}, {"MinHeight", "最小高度"},
        {"MaxWidth", "最大宽度"}, {"MaxHeight", "最大高度"}, {"FontFamily", "字体"}, {"FontSize", "字号"}, {"FontWeight", "字体粗细"}, {"FontStyle", "字体样式"},
        {"Opacity", "不透明度"}, {"HorizontalAlignment", "水平对齐"}, {"VerticalAlignment", "垂直对齐"}, {"HorizontalContentAlignment", "内容水平对齐"}, {"VerticalContentAlignment", "内容垂直对齐"}, {"Color", "颜色"}
    };
    private string selected;
    private FrameworkElement sample;
    private bool dirty;
    private Dictionary<string, Dictionary<string, string>> snapshot;

    internal RmtStyleEditor(Window owner)
    {
        source = owner; Owner = owner; Title = "GM-UI · 通用样式管理";
        Width = 1120; Height = 820; MinWidth = 900; MinHeight = 600;
        Background = new SolidColorBrush(Color.FromRgb(245, 247, 250));
        FontFamily = new FontFamily("Microsoft YaHei UI"); FontSize = 14;
        snapshot = CopyValues();
        var root = new DockPanel { Margin = new Thickness(18) }; Content = root;
        var heading = new TextBlock { Text = "GM-UI  /  通用样式与特殊配置", FontSize = 23, FontWeight = FontWeights.Bold, Margin = new Thickness(0, 0, 0, 8) };
        DockPanel.SetDock(heading, Dock.Top); root.Children.Add(heading);
        var help = new TextBlock { Text = "选择样式 → 修改右侧属性 → 应用预览 → 保存。空白表示继承；颜色支持 #RRGGBB / #AARRGGBB；边距支持 左,上,右,下。\n通用类型影响所有同类控件，命名样式覆盖通用类型；gm-exception 标记保留特殊配置。绑定属性只读。", TextWrapping = TextWrapping.Wrap, Margin = new Thickness(0, 0, 0, 12) };
        DockPanel.SetDock(help, Dock.Top); root.Children.Add(help);
        var footer = new StackPanel { Margin = new Thickness(0, 12, 0, 0) };
        DockPanel.SetDock(footer, Dock.Bottom); root.Children.Add(footer);
        var buttons = new StackPanel { Orientation = Orientation.Horizontal };
        footer.Children.Add(buttons); footer.Children.Add(status);
        AddButton(buttons, "应用预览", Apply);
        AddButton(buttons, "保存配置", delegate { if (Apply()) { try { RmtCommonStyles.Save(); snapshot = CopyValues(); dirty = false; status.Text = "已保存；当前及后续打开的 WPF 界面使用此配置。"; } catch (Exception ex) { status.Text = ex.Message; } } return true; });
        AddButton(buttons, "恢复所选默认", delegate { if (selected != null) { RmtCommonStyles.Values.Remove(selected); RmtCommonStyles.Refresh(); dirty = true; Render(); } return true; });
        AddButton(buttons, "撤销未保存预览", delegate { Restore(); Render(); return true; });
        AddButton(buttons, "刷新控件目录", delegate { Populate(); return true; });
        var columns = new Grid(); columns.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(310) }); columns.ColumnDefinitions.Add(new ColumnDefinition()); root.Children.Add(columns);
        var left = new DockPanel { Margin = new Thickness(0, 0, 16, 0) }; columns.Children.Add(left);
        search.ToolTip = "搜索名称、类型或样式键"; search.Margin = new Thickness(0, 0, 0, 8); search.MinHeight = 30;
        DockPanel.SetDock(search, Dock.Top); left.Children.Add(search); left.Children.Add(catalog);
        var right = new DockPanel(); Grid.SetColumn(right, 1); columns.Children.Add(right);
        var previewBox = new GroupBox { Header = "真实样式预览（不会执行业务操作）", Content = preview, Padding = new Thickness(16), Margin = new Thickness(0, 0, 0, 12), MaxHeight = 160 };
        DockPanel.SetDock(previewBox, Dock.Top); right.Children.Add(previewBox);
        right.Children.Add(new ScrollViewer { Content = fields, VerticalScrollBarVisibility = ScrollBarVisibility.Auto });
        catalog.SelectionChanged += delegate { var item = catalog.SelectedItem as ListBoxItem; if (item != null) { selected = (string)item.Tag; Render(); } };
        search.TextChanged += delegate { Populate(); };
        Closing += delegate(object sender, CancelEventArgs args) { if (dirty) Restore(); };
        Populate();
        status.Text = RmtCommonStyles.LoadError;
    }

    private static Dictionary<string, Dictionary<string, string>> CopyValues()
    {
        return RmtCommonStyles.Values.ToDictionary(x => x.Key, x => new Dictionary<string, string>(x.Value));
    }
    private void Restore()
    {
        RmtCommonStyles.Values.Clear(); foreach (var item in snapshot) RmtCommonStyles.Values[item.Key] = new Dictionary<string, string>(item.Value);
        RmtCommonStyles.Refresh(); dirty = false; status.Text = "已撤销未保存预览。";
    }
    private static void AddButton(Panel parent, string title, Func<bool> callback)
    {
        var button = new Button { Content = title, Padding = new Thickness(12, 7, 12, 7), Margin = new Thickness(0, 0, 8, 8) };
        button.Click += delegate { callback(); }; parent.Children.Add(button);
    }
    private void Populate()
    {
        var keys = new List<string>(labels.Keys);
        keys.AddRange(new[] { "通用/Button", "通用/TextBox", "通用/ComboBox", "通用/CheckBox", "通用/RadioButton", "通用/ListBox", "通用/GroupBox", "通用/Border", "通用/TextBlock", "通用/Slider", "通用/ProgressBar", "通用/TabControl", "通用/RichTextBox", "通用/PasswordBox" });
        keys.AddRange(RmtCommonStyles.Live().Select(x => x.Key).OrderBy(x => x));
        keys.AddRange(RmtCommonStyles.Colors(source).Keys.OrderBy(x => x).Select(x => "颜色/" + x));
        keys.AddRange(RmtCommonStyles.Values.Keys);
        keys.AddRange(notices.Keys);
        string old = selected; catalog.Items.Clear();
        foreach (string key in keys.Distinct())
        {
            string label = labels.ContainsKey(key) ? labels[key] : key;
            if ((label + key).IndexOf(search.Text, StringComparison.OrdinalIgnoreCase) < 0) continue;
            var item = new ListBoxItem { Content = label, Tag = key, Padding = new Thickness(8), ToolTip = key };
            catalog.Items.Add(item); if (key == old) catalog.SelectedItem = item;
        }
        if (catalog.SelectedIndex < 0 && catalog.Items.Count > 0) catalog.SelectedIndex = 0;
    }

    private void Render()
    {
        fields.Children.Clear(); preview.Children.Clear(); inputs.Clear(); sample = null;
        if (selected == null) return;
        if (notices.ContainsKey(selected))
        {
            fields.Children.Add(new TextBlock { Text = selected, FontWeight = FontWeights.Bold, Margin = new Thickness(0, 0, 0, 12) });
            fields.Children.Add(new TextBlock { Text = notices[selected], TextWrapping = TextWrapping.Wrap });
            return;
        }
        Dictionary<string, string> values; RmtCommonStyles.Values.TryGetValue(selected, out values);
        if (selected.StartsWith("颜色/"))
        {
            string name = selected.Substring(3);
            var brush = source.TryFindResource(name) as Brush;
            preview.Children.Add(new Border { Background = brush, Height = 48 });
            Field("Color", values != null && values.ContainsKey("Color") ? values["Color"] : "", RmtCommonStyles.Text(brush), false);
            return;
        }
        var matches = RmtCommonStyles.Live().Where(x => x.Key == selected || (selected.StartsWith("通用/") && ((FrameworkElement)x.Element.Target).GetType().Name == selected.Substring(3))).ToList();
        var entry = matches.FirstOrDefault();
        sample = entry == null ? CreateSample(selected) : entry.Element.Target as FrameworkElement;
        if (entry == null && sample != null && selected.StartsWith("样式/"))
            sample.Style = source.TryFindResource(selected.Substring(3)) as Style;
        fields.Children.Add(new TextBlock { Text = selected + " · 已加载实例 " + matches.Count, FontWeight = FontWeights.Bold, Margin = new Thickness(0, 0, 0, 8) });
        if (sample == null) { fields.Children.Add(new TextBlock { Text = "请先打开使用此样式的界面，再刷新目录。" }); return; }
        if (entry == null && !selected.StartsWith("通用/") && sample.Style == null)
            fields.Children.Add(new TextBlock { Text = "此界面尚未加载，当前为类型示例；打开对应界面并刷新后可查看实际样式。", TextWrapping = TextWrapping.Wrap });
        ShowPreview(sample);
        foreach (string property in RmtCommonStyles.Properties)
        {
            var dp = RmtCommonStyles.Property(sample, property); if (dp == null) continue;
            bool bound = BindingOperations.IsDataBound(sample, dp);
            Field(property, values != null && values.ContainsKey(property) ? values[property] : "", RmtCommonStyles.Text(RmtCommonStyles.DisplayValue(sample, property, dp)), bound);
        }
        var audit = new System.Text.StringBuilder();
        foreach (var item in matches)
        {
            var fe = item.Element.Target as FrameworkElement; if (fe == null) continue;
            audit.AppendLine(item.Location);
            foreach (string name in RmtCommonStyles.Properties)
            {
                var dp = RmtCommonStyles.Property(fe, name);
                if (dp != null && !item.Unset.Contains(name))
                    audit.AppendLine("  " + name + " = " + RmtCommonStyles.Text(item.Applied.Contains(name) ? item.Original[name] : fe.GetValue(dp)) + (BindingOperations.IsDataBound(fe, dp) ? " [绑定，保留]" : " [局部配置]"));
            }
        }
        fields.Children.Add(new Expander { Header = "使用位置 / 特殊与局部配置（原始值）", Content = new TextBox { Text = audit.ToString(), IsReadOnly = true, TextWrapping = TextWrapping.Wrap, MaxHeight = 280, VerticalScrollBarVisibility = ScrollBarVisibility.Auto }, Margin = new Thickness(0, 12, 0, 0) });
        if (sample.Style != null)
        {
            try { fields.Children.Add(new Expander { Header = "样式模板 / 交互状态（只读来源）", Content = new TextBox { Text = System.Windows.Markup.XamlWriter.Save(sample.Style), IsReadOnly = true, TextWrapping = TextWrapping.Wrap, MaxHeight = 240, VerticalScrollBarVisibility = ScrollBarVisibility.Auto } }); }
            catch { }
        }
    }

    private static FrameworkElement CreateSample(string key)
    {
        if (key == "Theme.Confirm" || key == "Main.Config" || key == "Main.Save" || key.Contains("Btn")) return new Button();
        if (!key.StartsWith("通用/")) return null;
        Type type = typeof(Button).Assembly.GetType("System.Windows.Controls." + key.Substring(3));
        return type == null ? null : Activator.CreateInstance(type) as FrameworkElement;
    }
    private void ShowPreview(FrameworkElement original)
    {
        FrameworkElement element;
        try { element = Activator.CreateInstance(original.GetType()) as FrameworkElement; } catch { return; }
        if (element == null) return;
        // Resource lookup uses the actual source window, including interaction-state colors.
        element.Resources.MergedDictionaries.Add(source.Resources);
        element.Style = original.Style;
        foreach (string name in RmtCommonStyles.Properties)
        {
            var dp = RmtCommonStyles.Property(element, name);
            if (dp != null && !(name == "CornerRadius" && original is Control && original.ReadLocalValue(dp) == DependencyProperty.UnsetValue))
                element.SetCurrentValue(dp, original.GetValue(dp));
        }
        Dictionary<string, string> configured;
        if (RmtCommonStyles.Values.TryGetValue(selected, out configured))
            foreach (var pair in configured)
            {
                var dp = RmtCommonStyles.Property(element, pair.Key);
                if (dp != null) element.SetCurrentValue(dp, RmtCommonStyles.ConvertValue(dp.PropertyType, pair.Value));
            }
        var content = element as ContentControl; if (content != null) content.Content = "示例控件 Aa 中文";
        var text = element as TextBox; if (text != null) text.Text = "输入内容 123";
        var block = element as TextBlock; if (block != null) block.Text = "文本样式 Aa 中文";
        var combo = element as ComboBox; if (combo != null) { combo.Items.Add("选项一"); combo.Items.Add("选项二"); combo.SelectedIndex = 0; }
        var list = element as ListBox; if (list != null) { list.Items.Add("内容一"); list.Items.Add("内容二"); }
        var border = element as Border; if (border != null) border.Child = new TextBlock { Text = "内容框" };
        preview.Children.Add(element);
    }
    private void Field(string name, string value, string current, bool bound)
    {
        var row = new Grid { Margin = new Thickness(0, 3, 8, 3) };
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(175) }); row.ColumnDefinitions.Add(new ColumnDefinition());
        row.Children.Add(new TextBlock { Text = propertyLabels.ContainsKey(name) ? propertyLabels[name] : name, ToolTip = name, VerticalAlignment = VerticalAlignment.Center });
        var box = new TextBox { Text = value, IsReadOnly = bound, Padding = new Thickness(5), ToolTip = "当前：" + current + (bound ? "（数据绑定保留）" : "；留空继承") };
        Grid.SetColumn(box, 1); row.Children.Add(box); fields.Children.Add(row); inputs[name] = box;
        var note = new TextBlock { Text = "当前：" + current + (bound ? " [绑定]" : ""), Foreground = Brushes.SlateGray, FontSize = 11, Margin = new Thickness(175, 0, 0, 3), TextWrapping = TextWrapping.Wrap };
        fields.Children.Add(note);
    }

    private bool Apply()
    {
        if (selected == null) return false;
        if (notices.ContainsKey(selected)) { status.Text = "此项为特殊界面的来源登记，未接入通用 WPF 属性编辑。"; return false; }
        var next = new Dictionary<string, string>();
        try
        {
            foreach (var input in inputs)
            {
                if (input.Value.IsReadOnly || string.IsNullOrWhiteSpace(input.Value.Text)) continue;
                string value = input.Value.Text.Trim();
                Type type = input.Key == "Color" ? typeof(Brush) : RmtCommonStyles.Property(sample, input.Key).PropertyType;
                var converted = RmtCommonStyles.ConvertValue(type, value);
                if (input.Key == "Color" && !(converted is SolidColorBrush)) throw new ArgumentException("颜色须为纯色。");
                if (sample != null && input.Key != "Color")
                {
                    var dp = RmtCommonStyles.Property(sample, input.Key);
                    if (!dp.IsValidValue(converted)) throw new ArgumentException(input.Key + " 的值超出允许范围。");
                }
                next[input.Key] = value;
            }
            if (next.Count == 0) RmtCommonStyles.Values.Remove(selected); else RmtCommonStyles.Values[selected] = next;
            RmtCommonStyles.Refresh(); dirty = true; Render(); status.Text = "预览已应用；保存后下次启动生效，关闭窗口会撤销未保存的预览。"; return true;
        }
        catch (Exception ex) { status.Text = "未应用：" + ex.Message; return false; }
    }
}
