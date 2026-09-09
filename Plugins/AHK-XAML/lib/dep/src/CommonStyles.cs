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
using System.Windows.Markup;
using System.Windows.Input;
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
        "Background", "HoverBackground", "PressedBackground", "Foreground", "BorderBrush", "BorderThickness", "CornerRadius",
        "Margin", "Padding", "Width", "Height", "MaxWidth", "MaxHeight",
        "FontSize", "FontWeight", "Opacity", "HorizontalContentAlignment", "VerticalContentAlignment", "SizeMode"
    };
    // Mirrors AppThemeUtil.ColorDefs order. These are the only colours GM-UI may assign.
    internal static readonly string[] ThemePaletteResources = {
        "ActionBg", "ActionHoverBg", "EditHoverBg", "TitleBarColor", "TitleBarForeground", "BgColor", "InputBg",
        "InputStroke", "GroupStroke", "TextMain", "InputText", "GraphLine", "GraphConn", "ActionText"
    };
    private static readonly ConditionalWeakTable<FrameworkElement, Entry> entries = new ConditionalWeakTable<FrameworkElement, Entry>();
    private static readonly List<WeakReference> elements = new List<WeakReference>();
    internal static readonly Dictionary<string, Dictionary<string, string>> Values = new Dictionary<string, Dictionary<string, string>>();
    internal static readonly Dictionary<string, string> CloneBases = new Dictionary<string, string>();
    internal static readonly Dictionary<string, string> DisplayNames = new Dictionary<string, string>();
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
    // Background has no common hover DP.  Keep it as an attached property so it can be
    // configured just like the other GM-UI properties without changing every template.
    private sealed class HoverState { internal Brush Base; internal bool Hooked, Hovering; }
    private static readonly ConditionalWeakTable<Control, HoverState> hovers = new ConditionalWeakTable<Control, HoverState>();
    private static readonly DependencyProperty ControlHoverBackground = DependencyProperty.RegisterAttached(
        "CommonHoverBackground", typeof(Brush), typeof(RmtCommonStyles), new PropertyMetadata(null,
            (obj, args) => ApplyHoverBackground(obj as Control)));
    private sealed class PressState { internal Brush Base; internal bool Hooked, Pressed; }
    private static readonly ConditionalWeakTable<Control, PressState> presses = new ConditionalWeakTable<Control, PressState>();
    private static readonly DependencyProperty ControlPressedBackground = DependencyProperty.RegisterAttached(
        "CommonPressedBackground", typeof(Brush), typeof(RmtCommonStyles), new PropertyMetadata(null,
            (obj, args) => ApplyPressedBackground(obj as Control)));
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
        // A copied GM-UI style is attached declaratively with Uid="gm:Button1" (or TextBox1, ComboBox1...).
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
        if (name == "HoverBackground" && fe is Control) return ControlHoverBackground;
        if (name == "PressedBackground" && fe is Control) return ControlPressedBackground;
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

    internal static bool IsThemeColor(string value)
    {
        return !string.IsNullOrEmpty(value) && value.StartsWith("$Theme:", StringComparison.Ordinal);
    }
    internal static string ThemeColorKey(string value)
    {
        return IsThemeColor(value) ? value.Substring("$Theme:".Length) : "";
    }
    internal static bool IsColorProperty(string name)
    {
        return name == "Color" || name == "Background" || name == "HoverBackground" || name == "PressedBackground" || name == "Foreground" || name == "BorderBrush";
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
                if (IsColorProperty(pair.Key) && IsThemeColor(pair.Value))
                    fe.SetResourceReference(dp, ThemeColorKey(pair.Value));
                else
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
            try
            {
                string value = item.Value["Color"];
                window.Resources[name] = IsThemeColor(value) ? window.TryFindResource(ThemeColorKey(value)) : ConvertValue(typeof(Brush), value);
            }
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

    private static void ApplyHoverBackground(Control control)
    {
        if (control == null) return;
        var state = hovers.GetValue(control, c => new HoverState());
        if (!state.Hooked)
        {
            state.Hooked = true;
            control.MouseEnter += delegate
            {
                state.Hovering = true;
                var hover = control.GetValue(ControlHoverBackground) as Brush;
                if (hover == null) return;
                state.Base = control.Background;
                control.SetCurrentValue(Control.BackgroundProperty, hover);
            };
            control.MouseLeave += delegate
            {
                state.Hovering = false;
                if (state.Base != null) control.SetCurrentValue(Control.BackgroundProperty, state.Base);
            };
        }
        if (!state.Hovering) state.Base = control.Background;
    }

    private static void ApplyPressedBackground(Control control)
    {
        if (control == null) return;
        var state = presses.GetValue(control, c => new PressState());
        if (!state.Hooked)
        {
            state.Hooked = true;
            control.PreviewMouseLeftButtonDown += delegate
            {
                var pressed = control.GetValue(ControlPressedBackground) as Brush;
                if (pressed == null) return;
                state.Pressed = true; state.Base = control.Background;
                control.SetCurrentValue(Control.BackgroundProperty, pressed);
            };
            MouseButtonEventHandler restore = delegate
            {
                if (!state.Pressed) return;
                state.Pressed = false;
                if (state.Base != null) control.SetCurrentValue(Control.BackgroundProperty, state.Base);
            };
            control.PreviewMouseLeftButtonUp += restore;
            control.MouseLeave += delegate
            {
                if (!state.Pressed) return;
                state.Pressed = false;
                if (state.Base != null) control.SetCurrentValue(Control.BackgroundProperty, state.Base);
            };
        }
        if (!state.Pressed) state.Base = control.Background;
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
                            if (name == "SizeMode") { properties[name] = value; continue; }
                            if (IsColorProperty(name) && IsThemeColor(value)) { properties[name] = value; continue; }
                            var dp = name == "Color" ? null : Property(new Button(), name);
                            object converted = ConvertValue(dp == null ? typeof(Brush) : dp.PropertyType, value);
                            if (dp != null && !dp.IsValidValue(converted)) throw new ArgumentException(name + " 值无效");
                            properties[name] = value;
                        }
                        catch (Exception ex) { LoadError = "已忽略无效配置 " + name + ": " + ex.Message; }
                    }
                string styleKey = style.GetAttribute("key");
                Values[styleKey] = properties;
                if (style.HasAttribute("base")) CloneBases[styleKey] = style.GetAttribute("base");
                if (style.HasAttribute("display")) DisplayNames[styleKey] = style.GetAttribute("display");
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
                string cloneBase;
                if (CloneBases.TryGetValue(style.Key, out cloneBase)) writer.WriteAttributeString("base", cloneBase);
                string displayName;
                if (DisplayNames.TryGetValue(style.Key, out displayName)) writer.WriteAttributeString("display", displayName);
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
    private readonly TreeView catalog = new TreeView();
    private readonly StackPanel fields = new StackPanel();
    private readonly StackPanel preview = new StackPanel();
    private readonly TextBlock status = new TextBlock { TextWrapping = TextWrapping.Wrap };
    private readonly TextBox search = new TextBox();
    private readonly Dictionary<string, TextBox> inputs = new Dictionary<string, TextBox>();
    private readonly Dictionary<string, ComboBox> colorInputs = new Dictionary<string, ComboBox>();
    private readonly Dictionary<string, ComboBox> optionInputs = new Dictionary<string, ComboBox>();
    private readonly HashSet<string> colorTouched = new HashSet<string>();
    private Grid propertyRow;
    private int propertyPair;
    private bool rendering, applying;
    private readonly Dictionary<string, string> labels = new Dictionary<string, string> {
        {"样式/RmtItemEditBtn", "按钮 1 · 宏配置—操作按钮"}, {"样式/RmtItemPrimaryBtn", "按钮 2 · 宏配置—设置按钮"},
        {"Main.Config", "按钮 3 · 主界面—配置管理"}, {"Main.Save", "按钮 4 · 主界面—应用保存"},
        {"Theme.Confirm", "按钮 5 · 设置—主题选项确定"}
    };
    private static readonly Dictionary<string, string> notices = new Dictionary<string, string> {
        {"特殊说明/系统菜单与系统弹窗", "系统 Menu、MsgBox、InputBox 由 Windows 绘制，不属于 WPF 控件树。此项仅登记来源，不能通过通用 WPF 属性编辑。应用内使用 XAMLHost 的对话框仍自动接入。"},
        {"特殊说明/屏幕搜索范围标记", "Gui/SearchProGui.ahk：四个原生无标题置顶窗口用于描绘屏幕范围，带鼠标穿透。属于自绘标记，未接入通用控件尺寸与边距覆盖。"},
        {"特殊说明/旧输入按钮条", "Gui/InputBtnGui.ahk：旧原生透明按钮条，透明键色 EEAA99，字体 s11 w550，按钮宽 80。新版 Gui/InputBtnXamlGui.ahk 已经通过 XAMLHost 自动接入。"},
        {"特殊说明/运行浮层与轮盘业务颜色", "Main/Util/ThemeUtil.ahk 的 AppThemeUtil.ColorDefs 维护 Wheel_*、Panel_*、CMD_* 业务配色；在设置→主题选项中配置。它们属于独立业务绘制，不等同于通用窗口按钮颜色。"}
    };
    private static readonly Dictionary<string, string> propertyLabels = new Dictionary<string, string> {
        {"Background", "背景颜色"}, {"HoverBackground", "悬停背景"}, {"PressedBackground", "按住背景"}, {"Foreground", "文字颜色"}, {"BorderBrush", "边框颜色"}, {"BorderThickness", "边框粗细"}, {"CornerRadius", "圆角"},
        {"Margin", "外边距"}, {"Padding", "内边距"}, {"Width", "宽度"}, {"Height", "高度"},
        {"MaxWidth", "最大宽度"}, {"MaxHeight", "最大高度"}, {"FontSize", "字号"}, {"FontWeight", "字体粗细"},
        {"Opacity", "不透明度"}, {"HorizontalContentAlignment", "水平对齐"}, {"VerticalContentAlignment", "垂直对齐"}, {"SizeMode", "宽高类型"}, {"Color", "颜色"}
    };
    private string selected;
    private FrameworkElement sample;
    private bool dirty;
    private Dictionary<string, Dictionary<string, string>> snapshot;
    private Dictionary<string, string> cloneSnapshot;
    private Dictionary<string, string> displaySnapshot;

    internal RmtStyleEditor(Window owner)
    {
        source = owner; Owner = owner; Title = "GM-UI · 通用样式管理";
        Width = 1240; Height = 850; MinWidth = 980; MinHeight = 640;
        FontFamily = owner.FontFamily; FontSize = owner.FontSize;
        snapshot = CopyValues();
        cloneSnapshot = new Dictionary<string, string>(RmtCommonStyles.CloneBases);
        displaySnapshot = new Dictionary<string, string>(RmtCommonStyles.DisplayNames);
        const string editorXaml = @"<Border xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation' xmlns:x='http://schemas.microsoft.com/winfx/2006/xaml' Margin='10' Background='{DynamicResource BgColor}' BorderBrush='{DynamicResource ControlBorder}' BorderThickness='1' CornerRadius='{DynamicResource WindowRadius}' TextElement.Foreground='{DynamicResource TextMain}'>
  <Border.Effect><DropShadowEffect BlurRadius='15' ShadowDepth='2' Opacity='.30'/></Border.Effect>
  <Grid><Grid.RowDefinitions><RowDefinition Height='36'/><RowDefinition Height='*'/></Grid.RowDefinitions>
    <Grid x:Name='DragArea' Background='{DynamicResource TitleBarColor}'><TextBlock Text='GM-UI · 控件样式管理' Foreground='{DynamicResource TitleBarForeground}' FontWeight='Bold' FontSize='17' VerticalAlignment='Center' Margin='15,0,0,0'/><Button x:Name='CmdClose' Content='×' HorizontalAlignment='Right' Width='46' Height='36' Padding='0' Background='Transparent' Foreground='{DynamicResource TitleBarForeground}' BorderThickness='0'/></Grid>
    <DockPanel Grid.Row='1' Margin='18'>
      <TextBlock DockPanel.Dock='Top' Text='按钮样式统一在此管理。颜色只能引用主题颜色 1～14；属性值修改后仅更新下方目标预览。' TextWrapping='Wrap' Margin='0,0,0,12'/>
      <StackPanel DockPanel.Dock='Bottom' Margin='0,12,0,0'><StackPanel Orientation='Horizontal'><Button x:Name='CmdReset' Content='重置' Padding='12,7' Margin='0,0,8,8'/><Button x:Name='CmdSave' Content='应用并重启' Padding='12,7' Margin='0,0,8,8'/></StackPanel><TextBlock x:Name='Status' TextWrapping='Wrap'/></StackPanel>
      <Grid><Grid.ColumnDefinitions><ColumnDefinition Width='300'/><ColumnDefinition Width='16'/><ColumnDefinition Width='*'/></Grid.ColumnDefinitions>
        <Border Grid.Column='0' BorderBrush='{DynamicResource Win_GroupStroke}' BorderThickness='1' CornerRadius='5' Padding='10'><DockPanel><TextBox x:Name='Search' DockPanel.Dock='Top' MinHeight='30' Margin='0,0,0,8' ToolTip='搜索按钮样式'/><TreeView x:Name='Catalog'/></DockPanel></Border>
        <DockPanel Grid.Column='2'><GroupBox DockPanel.Dock='Top' Header='目标样式预览' Margin='0,0,0,10' Padding='12' MaxHeight='175'><StackPanel x:Name='Preview'/></GroupBox><TextBlock DockPanel.Dock='Top' Text='属性名 / 属性值（每行三组）' FontWeight='SemiBold' Margin='0,0,0,6'/><ScrollViewer VerticalScrollBarVisibility='Auto'><StackPanel x:Name='Fields'/></ScrollViewer></DockPanel>
      </Grid>
    </DockPanel>
  </Grid>
</Border>";
        var root = (Border)XamlReader.Parse(editorXaml); Content = root;
        WindowStyle = WindowStyle.None; AllowsTransparency = true; Background = Brushes.Transparent; ShowInTaskbar = false; WindowStartupLocation = WindowStartupLocation.CenterOwner;
        var chrome = new System.Windows.Shell.WindowChrome { CaptionHeight = 36, ResizeBorderThickness = new Thickness(6), GlassFrameThickness = new Thickness(0), CornerRadius = new CornerRadius(0) };
        System.Windows.Shell.WindowChrome.SetWindowChrome(this, chrome);
        Resources.MergedDictionaries.Add(source.Resources);
        search = (TextBox)root.FindName("Search");
        catalog = (TreeView)root.FindName("Catalog");
        fields = (StackPanel)root.FindName("Fields");
        preview = (StackPanel)root.FindName("Preview");
        status = (TextBlock)root.FindName("Status");
        var drag = (Grid)root.FindName("DragArea"); drag.MouseLeftButtonDown += delegate { try { DragMove(); } catch { } };
        var close = (Button)root.FindName("CmdClose"); close.Style = source.TryFindResource("TitleBarCloseButton") as Style; System.Windows.Shell.WindowChrome.SetIsHitTestVisibleInChrome(close, true); close.Click += delegate { Close(); };
        ((Button)root.FindName("CmdSave")).Click += delegate { if (Commit(true)) { try { RmtCommonStyles.Save(); snapshot = CopyValues(); cloneSnapshot = new Dictionary<string, string>(RmtCommonStyles.CloneBases); displaySnapshot = new Dictionary<string, string>(RmtCommonStyles.DisplayNames); dirty = false; status.Text = "已保存并应用到所有已打开实例；软件重启后也会保持此样式。"; } catch (Exception ex) { status.Text = ex.Message; } } };
        ((Button)root.FindName("CmdReset")).Click += delegate { Restore(); selected = null; Populate(); Render(); };
        catalog.SelectedItemChanged += delegate { var item = catalog.SelectedItem as TreeViewItem; if (item != null && item.Tag is string) { selected = (string)item.Tag; Render(); } };
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
        RmtCommonStyles.CloneBases.Clear(); foreach (var item in cloneSnapshot) RmtCommonStyles.CloneBases[item.Key] = item.Value;
        RmtCommonStyles.DisplayNames.Clear(); foreach (var item in displaySnapshot) RmtCommonStyles.DisplayNames[item.Key] = item.Value;
        RmtCommonStyles.Refresh(); dirty = false; status.Text = "已撤销未保存预览。";
    }
    private static void AddButton(Panel parent, string title, Func<bool> callback)
    {
        var button = new Button { Content = title, Padding = new Thickness(12, 7, 12, 7), Margin = new Thickness(0, 0, 8, 8) };
        button.Click += delegate { callback(); }; parent.Children.Add(button);
    }
    private void Populate()
    {
        string old = selected, query = search.Text ?? "";
        catalog.Items.Clear();
        var all = new HashSet<string>(labels.Keys);
        all.UnionWith(new[] { "通用/Button" });
        all.UnionWith(RmtCommonStyles.Live().Select(x => x.Key));
        all.UnionWith(RmtCommonStyles.Values.Keys);
        all.UnionWith(RmtCommonStyles.CloneBases.Keys);
        TreeViewItem firstLeaf = null;
        var buttonGroup = new TreeViewItem { Header = "按钮", IsExpanded = true, FontWeight = FontWeights.SemiBold };
        int buttonNo = 0;
        foreach (string key in all.Where(IsButtonKey).OrderBy(ButtonOrder))
        {
            string text = key == "通用/Button" ? "通用按钮" : "按钮" + (++buttonNo) + " - " + ButtonTitle(key);
            if ((text + key).IndexOf(query, StringComparison.OrdinalIgnoreCase) < 0) continue;
            var leaf = MakeLeaf(text, key);
            buttonGroup.Items.Add(leaf);
            if (firstLeaf == null) firstLeaf = leaf;
            if (key == old) leaf.IsSelected = true;
        }
        if (buttonGroup.Items.Count > 0) catalog.Items.Add(buttonGroup);
        if (catalog.SelectedItem == null && firstLeaf != null) firstLeaf.IsSelected = true;
    }

    private TreeViewItem MakeLeaf(string text, string key)
    {
        var leaf = new TreeViewItem { Header = text, Tag = key, ToolTip = key, Padding = new Thickness(4) };
        var menu = new ContextMenu();
        if (key != "通用/Button")
        {
            var rename = new MenuItem { Header = "重命名" };
            rename.Click += delegate { BeginRename(leaf, key); };
            menu.Items.Add(rename);
        }
        var copy = new MenuItem { Header = "复制新增样式" };
        copy.Click += delegate { CopyStyle(key); };
        menu.Items.Add(copy);
        leaf.ContextMenu = menu;
        return leaf;
    }

    private void BeginRename(TreeViewItem leaf, string key)
    {
        var edit = new TextBox { Text = ButtonTitle(key), MinWidth = 170, Padding = new Thickness(3) };
        string original = (string)leaf.Header;
        bool done = false;
        Action<bool> finish = accept =>
        {
            if (done) return; done = true;
            string name = edit.Text.Trim();
            if (accept && !string.IsNullOrEmpty(name)) { RmtCommonStyles.DisplayNames[key] = name; dirty = true; }
            leaf.Header = original; Populate();
        };
        edit.KeyDown += delegate(object sender, System.Windows.Input.KeyEventArgs args)
        {
            if (args.Key == System.Windows.Input.Key.Enter) { finish(true); args.Handled = true; }
            else if (args.Key == System.Windows.Input.Key.Escape) { finish(false); args.Handled = true; }
        };
        edit.LostKeyboardFocus += delegate { finish(true); };
        leaf.Header = edit;
        Dispatcher.BeginInvoke(new Action(delegate { edit.Focus(); edit.SelectAll(); }));
    }

    private static bool IsButtonKey(string key) { return ControlType(key) == "按钮"; }
    private static int ButtonOrder(string key)
    {
        if (key == "通用/Button") return 0;
        if (key == "样式/RmtItemEditBtn") return 1;
        if (key == "样式/RmtItemPrimaryBtn") return 2;
        if (key == "Main.Config") return 3;
        if (key == "Main.Save") return 4;
        if (key == "Theme.Confirm") return 5;
        return 1000;
    }
    private string ButtonTitle(string key)
    {
        string value;
        if (RmtCommonStyles.DisplayNames.TryGetValue(key, out value) && !string.IsNullOrWhiteSpace(value)) return value;
        if (labels.TryGetValue(key, out value))
        {
            int mark = value.IndexOf('·');
            return mark >= 0 ? value.Substring(mark + 1).Trim() : value;
        }
        return "未命名样式";
    }

    private static string ControlType(string key)
    {
        string raw = key.StartsWith("通用/") ? key.Substring(3) : key;
        if (raw.IndexOf("Button", StringComparison.OrdinalIgnoreCase) >= 0 || raw.StartsWith("Main.") || raw.StartsWith("Theme.")) return "按钮";
        return "其它控件";
    }
    private string DisplayName(string key)
    {
        string value;
        if (labels.TryGetValue(key, out value)) return value;
        if (key == "通用/Button") return "通用按钮";
        if (key.StartsWith("样式/Button")) return key.Substring(3).Replace("Button", "按钮 ");
        return key.StartsWith("通用/") ? "通用 " + key.Substring(3) : key;
    }

    private void CopyStyle(string sourceName)
    {
        if (string.IsNullOrEmpty(sourceName) || !IsButtonKey(sourceName))
        {
            status.Text = "请选择一个控件样式后再复制。"; return;
        }
        string family = "Button";
        int number = 1; string next;
        do { next = family + number++; } while (RmtCommonStyles.Values.ContainsKey(next) || RmtCommonStyles.CloneBases.ContainsKey(next));
        Dictionary<string, string> original;
        RmtCommonStyles.Values.TryGetValue(sourceName, out original);
        RmtCommonStyles.Values[next] = original == null ? new Dictionary<string, string>() : new Dictionary<string, string>(original);
        RmtCommonStyles.CloneBases[next] = sourceName;
        if (IsButtonKey(next)) RmtCommonStyles.DisplayNames[next] = ButtonTitle(sourceName) + "（副本）";
        dirty = true; selected = next; Populate(); Render();
        status.Text = DisplayName(next) + " 已由「" + DisplayName(sourceName) + "」复制；可在右侧继续调整。";
    }

    private void Render()
    {
        rendering = true;
        fields.Children.Clear(); preview.Children.Clear(); inputs.Clear(); colorInputs.Clear(); optionInputs.Clear(); colorTouched.Clear(); propertyRow = null; propertyPair = 0; sample = null;
        if (selected == null) { rendering = false; return; }
        Dictionary<string, string> values; RmtCommonStyles.Values.TryGetValue(selected, out values);
        string previewBase;
        RmtCommonStyles.CloneBases.TryGetValue(selected, out previewBase);
        string targetKey = previewBase ?? selected;
        var matches = RmtCommonStyles.Live().Where(x => x.Key == targetKey || (targetKey.StartsWith("通用/") && ((FrameworkElement)x.Element.Target).GetType().Name == targetKey.Substring(3))).ToList();
        var entry = matches.FirstOrDefault();
        // Named styles must be previewed from a real registered target. A generic replacement is misleading for icon buttons and fixed layouts.
        if (entry == null && !targetKey.StartsWith("通用/"))
        {
            preview.Children.Add(new TextBlock { Text = "对应目标控件尚未打开；打开它并点击“刷新实例”后，预览会直接复制目标样式、内容和尺寸。", TextWrapping = TextWrapping.Wrap });
            fields.Children.Add(new TextBlock { Text = selected + " · 已加载实例 0", FontWeight = FontWeights.Bold, Margin = new Thickness(0, 0, 0, 8) });
            fields.Children.Add(new TextBlock { Text = "为避免错误预览，此命名样式在没有真实实例时不显示替代控件。", TextWrapping = TextWrapping.Wrap });
            rendering = false;
            return;
        }
        sample = entry == null ? CreateSample(targetKey) : entry.Element.Target as FrameworkElement;
        if (entry == null && sample != null && targetKey.StartsWith("样式/"))
            sample.Style = source.TryFindResource(targetKey.Substring(3)) as Style;
        fields.Children.Add(new TextBlock { Text = selected + " · 已加载实例 " + matches.Count, FontWeight = FontWeights.Bold, Margin = new Thickness(0, 0, 0, 8) });
        if (sample == null) { fields.Children.Add(new TextBlock { Text = "请先打开使用此样式的界面，再刷新目录。" }); rendering = false; return; }
        if (entry == null && !selected.StartsWith("通用/") && sample.Style == null)
            fields.Children.Add(new TextBlock { Text = "此界面尚未加载，当前为类型示例；打开对应界面并刷新后可查看实际样式。", TextWrapping = TextWrapping.Wrap });
        ShowPreview(sample);
        foreach (string property in RmtCommonStyles.Properties)
        {
            if (property == "Width" || property == "Height" || property == "MaxWidth" || property == "MaxHeight") continue;
            var dp = RmtCommonStyles.Property(sample, property); if (dp == null) continue;
            bool bound = BindingOperations.IsDataBound(sample, dp);
            Field(property, values != null && values.ContainsKey(property) ? values[property] : "", RmtCommonStyles.Text(RmtCommonStyles.DisplayValue(sample, property, dp)), bound);
        }
        string sizeMode = SizeMode(values, sample);
        Field("SizeMode", sizeMode, sizeMode, false);
        if (sizeMode == "固定宽高" || sizeMode == "自适应高度")
            AddSizeField("Width", values);
        if (sizeMode == "固定宽高" || sizeMode == "自适应宽度")
            AddSizeField("Height", values);
        if (sizeMode == "自适应宽度") AddSizeField("MaxWidth", values);
        if (sizeMode == "自适应高度") AddSizeField("MaxHeight", values);
        if (!selected.StartsWith("通用/"))
        {
            var used = matches.Take(3).Select(x => x.Location).ToArray();
            string descriptions = used.Length == 0 ? "暂无已打开实例。" : string.Join("\n\n", used.Select((item, index) => "示例 " + (index + 1) + "：\n" + item));
            fields.Children.Add(new GroupBox { Header = "使用此样式的示例（1～3 个）", Margin = new Thickness(0, 12, 0, 0), Content = new TextBlock { Text = descriptions, TextWrapping = TextWrapping.Wrap, Margin = new Thickness(8) } });
        }
        if (sample.Style != null)
        {
            try { fields.Children.Add(new Expander { Header = "样式模板 / 交互状态（只读来源）", Content = new TextBox { Text = System.Windows.Markup.XamlWriter.Save(sample.Style), IsReadOnly = true, TextWrapping = TextWrapping.Wrap, MaxHeight = 240, VerticalScrollBarVisibility = ScrollBarVisibility.Auto } }); }
            catch { }
        }
        rendering = false;
    }

    private static string SizeMode(Dictionary<string, string> values, FrameworkElement element)
    {
        string value;
        if (values != null && values.TryGetValue("SizeMode", out value) && (value == "固定宽高" || value == "自适应宽度" || value == "自适应高度")) return value;
        if (values != null && values.TryGetValue("Width", out value) && value.Equals("Auto", StringComparison.OrdinalIgnoreCase)) return "自适应宽度";
        if (values != null && values.TryGetValue("Height", out value) && value.Equals("Auto", StringComparison.OrdinalIgnoreCase)) return "自适应高度";
        if (element != null && double.IsNaN(element.Width)) return "自适应宽度";
        if (element != null && double.IsNaN(element.Height)) return "自适应高度";
        return "固定宽高";
    }

    private void AddSizeField(string name, Dictionary<string, string> values)
    {
        var dp = RmtCommonStyles.Property(sample, name);
        if (dp == null) return;
        string current = RmtCommonStyles.Text(RmtCommonStyles.DisplayValue(sample, name, dp));
        if ((name == "Width" || name == "Height") && current == "NaN") current = "";
        Field(name, values != null && values.ContainsKey(name) ? values[name] : "", current, BindingOperations.IsDataBound(sample, dp));
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
                if (dp != null)
                {
                    if (RmtCommonStyles.IsColorProperty(pair.Key) && RmtCommonStyles.IsThemeColor(pair.Value))
                        element.SetResourceReference(dp, RmtCommonStyles.ThemeColorKey(pair.Value));
                    else
                        element.SetCurrentValue(dp, RmtCommonStyles.ConvertValue(dp.PropertyType, pair.Value));
                }
            }
        var content = element as ContentControl;
        if (content != null)
        {
            var originalContent = original as ContentControl;
            string actual = originalContent == null ? null : originalContent.Content as string;
            content.Content = !string.IsNullOrEmpty(actual) ? actual : PreviewTextFor(element);
        }
        var text = element as TextBox; if (text != null) text.Text = "输入内容";
        var block = element as TextBlock; if (block != null) block.Text = "文本内容";
        var combo = element as ComboBox; if (combo != null) { combo.Items.Add("选项一"); combo.Items.Add("选项二"); combo.SelectedIndex = 0; }
        var list = element as ListBox; if (list != null) { list.Items.Add("内容一"); list.Items.Add("内容二"); }
        var border = element as Border; if (border != null) border.Child = new TextBlock { Text = "内容框" };
        // A preview has no business layout parent. Keep fixed dimensions, and give adaptive controls a bounded natural width.
        if (double.IsNaN(element.Width) && element.HorizontalAlignment == HorizontalAlignment.Stretch)
            element.HorizontalAlignment = HorizontalAlignment.Left;
        var host = new Border { Child = element, HorizontalAlignment = HorizontalAlignment.Left, MaxWidth = 440, Padding = new Thickness(2) };
        preview.Children.Add(host);
    }

    private static string PreviewTextFor(FrameworkElement element)
    {
        if (element is CheckBox) return "启用选项";
        if (element is RadioButton) return "单选项";
        if (element is Button) return "按钮";
        if (element is GroupBox) return "分组标题";
        return "控件内容";
    }
    private void Field(string name, string value, string current, bool bound)
    {
        if (propertyRow == null || propertyPair == 3)
        {
            propertyRow = new Grid { Margin = new Thickness(0, 3, 0, 3) };
            for (int i = 0; i < 3; i++)
            {
                propertyRow.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(80) });
                propertyRow.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            }
            fields.Children.Add(propertyRow); propertyPair = 0;
        }
        int column = propertyPair++ * 2;
        var label = new TextBlock { Text = propertyLabels.ContainsKey(name) ? propertyLabels[name] : name, ToolTip = name, VerticalAlignment = VerticalAlignment.Center, Margin = new Thickness(0, 0, 5, 0) };
        Grid.SetColumn(label, column); propertyRow.Children.Add(label);
        if (RmtCommonStyles.IsColorProperty(name))
        {
            var combo = ThemeColorPicker(value, current, bound); combo.Margin = new Thickness(0, 0, 14, 0);
            combo.SelectionChanged += delegate { colorTouched.Add(name); Commit(false); };
            Grid.SetColumn(combo, column + 1); propertyRow.Children.Add(combo); colorInputs[name] = combo;
        }
        else if (IsOptionProperty(name))
        {
            var combo = OptionPicker(name, value, current, bound); combo.Margin = new Thickness(0, 0, 14, 0);
            combo.SelectionChanged += delegate { Commit(false); };
            Grid.SetColumn(combo, column + 1); propertyRow.Children.Add(combo); optionInputs[name] = combo;
        }
        else
        {
            bool inherited = string.IsNullOrEmpty(value);
            var box = new TextBox { Text = inherited ? current : value, IsReadOnly = bound, Padding = new Thickness(5), MinHeight = 28, Margin = new Thickness(0, 0, 14, 0), ToolTip = inherited ? "显示当前继承值；修改后立即覆盖并应用。" : "当前覆盖值", Tag = inherited ? "inherit" : "override" };
            if (inherited) box.Foreground = Brushes.SlateGray;
            box.TextChanged += delegate { if (!box.IsReadOnly) { box.Tag = "override"; box.Foreground = Brushes.Black; Commit(false); } };
            Grid.SetColumn(box, column + 1); propertyRow.Children.Add(box); inputs[name] = box;
        }
    }

    private static bool IsOptionProperty(string name)
    {
        return name == "FontWeight" || name == "HorizontalContentAlignment" || name == "VerticalContentAlignment" || name == "SizeMode";
    }

    private ComboBox OptionPicker(string name, string value, string current, bool bound)
    {
        var combo = new ComboBox { IsEnabled = !bound, MinHeight = 28, Padding = new Thickness(4), ToolTip = "选择后会立即应用。" };
        var options = name == "FontWeight" ? new[] { "Thin", "ExtraLight", "Light", "Normal", "Medium", "SemiBold", "Bold", "ExtraBold", "Black" } :
            name == "VerticalAlignment" || name == "VerticalContentAlignment" ? new[] { "Top", "Center", "Bottom", "Stretch" } :
            name == "SizeMode" ? new[] { "固定宽高", "自适应宽度", "自适应高度" } : new[] { "Left", "Center", "Right", "Stretch" };
        bool inherited = string.IsNullOrEmpty(value) && name != "SizeMode";
        if (inherited) combo.Items.Add(new ComboBoxItem { Content = "继承当前值（" + current + "）", Tag = "" });
        foreach (string option in options)
        {
            var item = new ComboBoxItem { Content = option, Tag = option };
            combo.Items.Add(item);
            if ((inherited && option == current) || (!inherited && option == value)) combo.SelectedItem = item;
        }
        if (combo.SelectedIndex < 0) combo.SelectedIndex = 0;
        return combo;
    }

    private ComboBox ThemeColorPicker(string value, string current, bool bound)
    {
        var combo = new ComboBox { IsEnabled = !bound, MinHeight = 28, Padding = new Thickness(4), ToolTip = "只能选择主题颜色序列；切换主题时会自动同步。" };
        string wanted = RmtCommonStyles.IsThemeColor(value) ? RmtCommonStyles.ThemeColorKey(value) : "";
        for (int i = 0; i < RmtCommonStyles.ThemePaletteResources.Length; i++)
        {
            string key = RmtCommonStyles.ThemePaletteResources[i];
            var brush = source.TryFindResource(key) as Brush;
            if (brush == null) continue;
            string hex = RmtCommonStyles.Text(brush);
            var row = new StackPanel { Orientation = Orientation.Horizontal };
            row.Children.Add(new Border { Width = 18, Height = 18, Background = brush, BorderBrush = Brushes.Gray, BorderThickness = new Thickness(1), Margin = new Thickness(0, 0, 7, 0) });
            row.Children.Add(new TextBlock { Text = "颜色" + (i + 1) + "   " + hex, VerticalAlignment = VerticalAlignment.Center });
            var item = new ComboBoxItem { Content = row, Tag = "$Theme:" + key };
            combo.Items.Add(item);
            // Existing literal values are migrated to their matching theme resource on the next save.
            if (key == wanted || (string.IsNullOrEmpty(wanted) && (hex == value || hex == current))) combo.SelectedItem = item;
        }
        if (combo.SelectedIndex < 0) combo.SelectedIndex = 0;
        return combo;
    }

    // Retained for the test hook and explicit final application path.
    private bool Apply() { return Commit(true); }

    private bool Commit(bool rerender)
    {
        if (rendering || applying || selected == null || sample == null) return false;
        if (notices.ContainsKey(selected)) { status.Text = "此项为特殊界面的来源登记，未接入通用 WPF 属性编辑。"; return false; }
        applying = true;
        Dictionary<string, string> saved;
        RmtCommonStyles.Values.TryGetValue(selected, out saved);
        var next = saved == null ? new Dictionary<string, string>() : new Dictionary<string, string>(saved);
        try
        {
            foreach (var input in inputs)
            {
                if (input.Value.IsReadOnly) continue;
                if ((input.Value.Tag as string) == "inherit" || string.IsNullOrWhiteSpace(input.Value.Text)) { next.Remove(input.Key); continue; }
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
            foreach (var input in optionInputs)
            {
                var item = input.Value.SelectedItem as ComboBoxItem;
                string value = item == null ? "" : (item.Tag as string ?? "");
                if (input.Key == "SizeMode") continue;
                if (string.IsNullOrEmpty(value)) next.Remove(input.Key); else next[input.Key] = value;
            }
            foreach (var input in colorInputs)
            {
                if (!input.Value.IsEnabled) continue;
                if (!colorTouched.Contains(input.Key)) continue;
                var item = input.Value.SelectedItem as ComboBoxItem;
                string value = item == null ? "" : (item.Tag as string ?? "");
                if (string.IsNullOrEmpty(value)) next.Remove(input.Key); else next[input.Key] = value;
            }
            string mode = "固定宽高";
            ComboBox modeInput;
            if (optionInputs.TryGetValue("SizeMode", out modeInput) && modeInput.SelectedItem is ComboBoxItem)
                mode = ((ComboBoxItem)modeInput.SelectedItem).Tag as string ?? mode;
            next["SizeMode"] = mode;
            if (mode == "自适应宽度")
            {
                next["Width"] = "Auto"; next.Remove("MaxHeight");
            }
            else if (mode == "自适应高度")
            {
                next["Height"] = "Auto"; next.Remove("MaxWidth");
            }
            else { next.Remove("MaxWidth"); next.Remove("MaxHeight"); }
            RmtCommonStyles.Values[selected] = next;
            dirty = true;
            // Edits are staged in the configuration dictionary.  Only this window's cloned
            // target preview is redrawn; live application controls stay untouched until save.
            preview.Children.Clear(); ShowPreview(sample);
            if (rerender) RmtCommonStyles.Refresh();
            status.Text = rerender ? "已保存并应用到正式界面。" : "预览已更新；点击“应用并重启”后才会影响正式界面。"; return true;
        }
        catch (Exception ex) { status.Text = "未应用：" + ex.Message; return false; }
        finally { applying = false; }
    }
}
