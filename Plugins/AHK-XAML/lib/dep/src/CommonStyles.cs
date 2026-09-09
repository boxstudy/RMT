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
using System.Windows.Shapes;
using System.Windows.Documents;
using System.Windows.Threading;
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
        "Background", "HoverBackground", "PressedBackground", "Foreground", "BorderBrush", "CornerRadius", "BorderThickness",
        "Margin", "Padding", "Width", "Height", "MinWidth", "MinHeight", "MaxWidth", "MaxHeight",
        "FontWeight", "RelativeFontSize", "Opacity", "HorizontalContentAlignment", "VerticalContentAlignment", "SizeMode"
    };
    internal static readonly string[] WindowExtraProperties = { "ShowMinimize", "ShowMaximize", "ShowPin", "ShowClose" };
    // Mirrors AppThemeUtil.ColorDefs order. These are the only colours GM-UI may assign.
    internal static readonly string[] ThemePaletteResources = {
        "ActionBg", "ActionHoverBg", "EditHoverBg", "TitleBarColor", "TitleBarForeground", "BgColor", "InputBg",
        "InputStroke", "GroupStroke", "TextMain", "InputText", "GraphLine", "GraphConn", "ActionText"
    };
    private static readonly ConditionalWeakTable<FrameworkElement, Entry> entries = new ConditionalWeakTable<FrameworkElement, Entry>();
    private static readonly List<WeakReference> elements = new List<WeakReference>();
    internal static readonly Dictionary<string, Dictionary<string, string>> Values = new Dictionary<string, Dictionary<string, string>>();
    internal static readonly Dictionary<string, Dictionary<string, string>> Layouts = new Dictionary<string, Dictionary<string, string>>();
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
        if (fe.TemplatedParent is Control && !(fe.TemplatedParent is ContentPresenter)) return false;
        if (Window.GetWindow(fe) is RmtStyleEditor || fe is RmtStyleEditor) return false;
        if (fe is Window)
            return Application.Current == null || !ReferenceEquals(fe, Application.Current.MainWindow);
        return fe is Control || fe is Border || fe is TextBlock;
    }

    private static string StyleKey(FrameworkElement fe)
    {
        // A copied GM-UI style is attached declaratively with Uid="gm:Button1" (or TextBox1, ComboBox1...).
        if (!string.IsNullOrEmpty(fe.Uid) && fe.Uid.StartsWith("gm:")) return fe.Uid.Substring(3);
        if (!string.IsNullOrEmpty(fe.Uid) && fe.Uid.StartsWith("gm-exception:")) return "特殊/" + fe.Uid.Substring(13);
        if (fe.Name == "BtnMinimize" || fe.Name == "BtnMaximize" || fe.Name == "BtnPin" || fe.Name == "BtnWinClose" || fe.Name == "BtnClosePanel")
            return "特殊/窗口标题栏/" + fe.Name;
        var style = fe.Style;
        for (FrameworkElement parent = fe; parent != null; parent = (LogicalTreeHelper.GetParent(parent) ?? VisualParent(parent)) as FrameworkElement)
        {
            string key = FindKey(parent.Resources, style);
            if (key != null) return "样式/" + key;
        }
        return "通用/" + fe.GetType().Name;
    }

    internal static string StyleKeyPublic(FrameworkElement fe)
    {
        return StyleKey(fe);
    }

    internal static bool IsPickable(FrameworkElement fe)
    {
        if (fe == null || fe is Window || fe is RmtStyleEditor) return false;
        if (Window.GetWindow(fe) is RmtStyleEditor) return false;
        if (fe.TemplatedParent is Control && !(fe.TemplatedParent is ContentPresenter)) return false;
        if (fe is ContentPresenter) return false;
        return fe is Control;
    }

    internal static void EnsureRegistered(FrameworkElement fe)
    {
        Register(fe);
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
        ApplyLayout(fe);
    }

    internal static string LayoutId(FrameworkElement fe)
    {
        if (fe == null) return "";
        if (!string.IsNullOrEmpty(fe.Uid) && (fe.Uid.StartsWith("gm:") || fe.Uid.StartsWith("ahk:"))) return fe.Uid;
        var window = fe as Window ?? Window.GetWindow(fe);
        string title = window == null ? "" : (window.Title ?? "");
        if (!string.IsNullOrEmpty(fe.Name)) return title + "/" + fe.Name;
        if (fe is Window && !string.IsNullOrEmpty(title)) return "Window:" + title;
        return "";
    }

    internal static void ApplyLayout(FrameworkElement fe)
    {
        string id = LayoutId(fe);
        Dictionary<string, string> layout;
        if (id == "" || !Layouts.TryGetValue(id, out layout)) return;
        string value;
        if (layout.TryGetValue("Margin", out value))
        {
            try { fe.Margin = (Thickness)ConvertValue(typeof(Thickness), value); } catch { }
        }
        if (layout.TryGetValue("CanvasLeft", out value))
        {
            try { Canvas.SetLeft(fe, (double)ConvertValue(typeof(double), value)); } catch { }
        }
        if (layout.TryGetValue("CanvasTop", out value))
        {
            try { Canvas.SetTop(fe, (double)ConvertValue(typeof(double), value)); } catch { }
        }
        var window = fe as Window;
        if (window != null)
        {
            if (layout.TryGetValue("Left", out value))
            {
                try { window.Left = (double)ConvertValue(typeof(double), value); } catch { }
            }
            if (layout.TryGetValue("Top", out value))
            {
                try { window.Top = (double)ConvertValue(typeof(double), value); } catch { }
            }
        }
    }

    internal static DependencyProperty Property(FrameworkElement fe, string name)
    {
        if (name == "CornerRadius" && fe is Control) return ControlCornerRadius;
        if (name == "HoverBackground" && fe is Control) return ControlHoverBackground;
        if (name == "PressedBackground" && fe is Control) return ControlPressedBackground;
        if (name == "RelativeFontSize") return System.Windows.Documents.TextElement.FontSizeProperty;
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
        string commonKey = "通用/" + fe.GetType().Name;
        if (!entry.Key.StartsWith("特殊/") && Values.TryGetValue(commonKey, out common))
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
            if (fe is Window && (pair.Key == "Padding" || IsWindowExtra(pair.Key))) continue;
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
                else if (pair.Key == "RelativeFontSize")
                    fe.SetCurrentValue(dp, ThemeFontSize(fe) + (double)ConvertValue(typeof(double), pair.Value));
                else
                    fe.SetCurrentValue(dp, ConvertValue(dp.PropertyType, pair.Value));
                entry.Applied.Add(pair.Key);
                entry.LastApplied[pair.Key] = Text(fe.GetValue(dp));
                if (pair.Key == "CornerRadius") ApplyCorners(fe as Control);
            }
            catch (Exception ex) { LoadError = entry.Key + "/" + pair.Key + ": " + ex.Message; }
        }
        ApplyButtonChrome(fe as Button, entry, desired);
        if (fe is Control) ApplyCorners((Control)fe);
        if (fe is Window) ApplyWindowChrome((Window)fe, entry, desired);
    }

    internal static bool IsWindowExtra(string name)
    {
        return Array.IndexOf(WindowExtraProperties, name) >= 0;
    }

    internal static bool IsWindowKey(string key)
    {
        if (string.IsNullOrEmpty(key)) return false;
        if (key == "通用/Window" || key.StartsWith("Window.")) return true;
        if (key.StartsWith("Window") && key.Length > 6)
        {
            int n;
            return int.TryParse(key.Substring(6), out n);
        }
        string cloneBase;
        return CloneBases.TryGetValue(key, out cloneBase) && (cloneBase == "通用/Window" || cloneBase.StartsWith("Window."));
    }

    internal static FrameworkElement WindowBody(Window window)
    {
        if (window == null) return null;
        var named = window.FindName("WindowBody") as FrameworkElement;
        if (named != null) return named;
        FrameworkElement root = window.Content as FrameworkElement;
        var box = root as Viewbox;
        if (box != null) root = box.Child as FrameworkElement;
        var grid = root as Grid;
        if (grid == null) return root;
        foreach (UIElement child in grid.Children)
        {
            var fe = child as FrameworkElement;
            if (fe != null && Grid.GetRow(fe) > 0) return fe;
        }
        return null;
    }

    private static readonly string[][] ChromeButtons = {
        new[] { "ShowMinimize", "BtnMinimize" },
        new[] { "ShowMaximize", "BtnMaximize" },
        new[] { "ShowPin", "BtnPin" },
        new[] { "ShowClose", "BtnClosePanel" },
        new[] { "ShowClose", "BtnWinClose" },
        new[] { "ShowClose", "BtnClose" }
    };

    private static void ApplyWindowChrome(Window window, Entry entry, Dictionary<string, string> desired)
    {
        foreach (string prop in WindowExtraProperties)
        {
            string value;
            bool has = desired.TryGetValue(prop, out value);
            foreach (var map in ChromeButtons)
            {
                if (map[0] != prop) continue;
                var btn = window.FindName(map[1]) as UIElement;
                if (btn == null) continue;
                if (!entry.Original.ContainsKey(prop + "." + map[1]))
                    entry.Original[prop + "." + map[1]] = btn.Visibility;
                if (has)
                    btn.Visibility = value.Equals("True", StringComparison.OrdinalIgnoreCase) ? Visibility.Visible : Visibility.Collapsed;
                else if (entry.Applied.Contains(prop))
                {
                    object original;
                    if (entry.Original.TryGetValue(prop + "." + map[1], out original) && original is Visibility)
                        btn.Visibility = (Visibility)original;
                }
            }
            if (has) entry.Applied.Add(prop);
            else entry.Applied.Remove(prop);
        }
        var body = WindowBody(window);
        if (body != null)
        {
            if (!entry.Original.ContainsKey("Padding"))
                entry.Original["Padding"] = body.Margin;
            string pad;
            if (desired.TryGetValue("Padding", out pad))
            {
                try
                {
                    body.Margin = (Thickness)ConvertValue(typeof(Thickness), pad);
                    entry.Applied.Add("Padding");
                    entry.LastApplied["Padding"] = pad;
                }
                catch (Exception ex) { LoadError = entry.Key + "/Padding: " + ex.Message; }
            }
            else if (entry.Applied.Contains("Padding"))
            {
                object original;
                if (entry.Original.TryGetValue("Padding", out original) && original is Thickness)
                    body.Margin = (Thickness)original;
                entry.Applied.Remove("Padding");
            }
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
        foreach (var entry in Live())
        {
            Apply(entry);
            var fe = entry.Element.Target as FrameworkElement;
            if (fe != null) ApplyLayout(fe);
        }
        foreach (Window window in Application.Current.Windows.Cast<Window>().ToArray()) ApplyResources(window);
    }

    internal static void ApplyCorners(Control control)
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
            border.SetValue(Border.CornerRadiusProperty, control.GetValue(ControlCornerRadius));
        }
    }

    private static ControlTemplate chromeButtonTemplate;
    internal static ControlTemplate ChromeButtonTemplate()
    {
        if (chromeButtonTemplate != null) return chromeButtonTemplate;
        var border = new FrameworkElementFactory(typeof(Border), "Border");
        border.SetValue(Border.SnapsToDevicePixelsProperty, true);
        border.SetValue(Border.BackgroundProperty, new TemplateBindingExtension(Control.BackgroundProperty));
        border.SetValue(Border.BorderBrushProperty, new TemplateBindingExtension(Control.BorderBrushProperty));
        border.SetValue(Border.BorderThicknessProperty, new TemplateBindingExtension(Control.BorderThicknessProperty));
        border.SetValue(Border.PaddingProperty, new TemplateBindingExtension(Control.PaddingProperty));
        border.SetBinding(Border.CornerRadiusProperty, new Binding
        {
            Path = new PropertyPath(ControlCornerRadius),
            RelativeSource = new RelativeSource(RelativeSourceMode.TemplatedParent)
        });
        var presenter = new FrameworkElementFactory(typeof(ContentPresenter));
        presenter.SetValue(ContentPresenter.HorizontalAlignmentProperty, new TemplateBindingExtension(Control.HorizontalContentAlignmentProperty));
        presenter.SetValue(ContentPresenter.VerticalAlignmentProperty, new TemplateBindingExtension(Control.VerticalContentAlignmentProperty));
        border.AppendChild(presenter);
        chromeButtonTemplate = new ControlTemplate(typeof(Button)) { VisualTree = border };
        return chromeButtonTemplate;
    }

    private static void ApplyButtonChrome(Button button, Entry entry, Dictionary<string, string> desired)
    {
        if (button == null || entry == null) return;
        bool need = desired != null && (desired.ContainsKey("CornerRadius") || desired.ContainsKey("HoverBackground") || desired.ContainsKey("PressedBackground"));
        if (need)
        {
            if (!entry.Original.ContainsKey("Template")) entry.Original["Template"] = button.Template;
            button.Template = ChromeButtonTemplate();
        }
        else if (entry.Original.ContainsKey("Template"))
        {
            var old = entry.Original["Template"] as ControlTemplate;
            if (old != null) button.Template = old;
            else button.ClearValue(Control.TemplateProperty);
            entry.Original.Remove("Template");
        }
    }

    internal static double ThemeFontSize(FrameworkElement element)
    {
        var window = Window.GetWindow(element);
        if (window != null && window.FontSize > 0) return window.FontSize;
        return Application.Current != null && Application.Current.MainWindow != null ? Application.Current.MainWindow.FontSize : 15;
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
                control.SetValue(Control.BackgroundProperty, hover);
            };
            control.MouseLeave += delegate
            {
                state.Hovering = false;
                if (state.Base != null) control.SetValue(Control.BackgroundProperty, state.Base);
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
                control.SetValue(Control.BackgroundProperty, pressed);
            };
            MouseButtonEventHandler restore = delegate
            {
                if (!state.Pressed) return;
                state.Pressed = false;
                if (state.Base != null) control.SetValue(Control.BackgroundProperty, state.Base);
            };
            control.PreviewMouseLeftButtonUp += restore;
            control.MouseLeave += delegate
            {
                if (!state.Pressed) return;
                state.Pressed = false;
                if (state.Base != null) control.SetValue(Control.BackgroundProperty, state.Base);
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
                    if (Properties.Contains(prop.GetAttribute("name")) || IsWindowExtra(prop.GetAttribute("name")) || prop.GetAttribute("name") == "Color")
                    {
                        string name = prop.GetAttribute("name"), value = prop.GetAttribute("value");
                        try
                        {
                            if (name == "SizeMode" || IsWindowExtra(name)) { properties[name] = value; continue; }
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
            foreach (XmlElement layout in doc.SelectNodes("/CommonStyles/Layout"))
            {
                var properties = new Dictionary<string, string>();
                foreach (XmlElement prop in layout.SelectNodes("Property"))
                    properties[prop.GetAttribute("name")] = prop.GetAttribute("value");
                string layoutKey = layout.GetAttribute("key");
                if (!string.IsNullOrEmpty(layoutKey)) Layouts[layoutKey] = properties;
            }
        }
        catch (Exception ex) { LoadError = "样式配置读取失败：" + ex.Message; }
    }

    internal static void Save()
    {
        Directory.CreateDirectory(System.IO.Path.GetDirectoryName(path));
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
            foreach (var layout in Layouts.OrderBy(x => x.Key))
            {
                writer.WriteStartElement("Layout"); writer.WriteAttributeString("key", layout.Key);
                foreach (var prop in layout.Value.OrderBy(x => x.Key))
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
    private readonly Dictionary<string, Slider> sliderInputs = new Dictionary<string, Slider>();
    private readonly Dictionary<string, ComboBox> dimensionInputs = new Dictionary<string, ComboBox>();
    private readonly Dictionary<string, ComboBox> presetInputs = new Dictionary<string, ComboBox>();
    private readonly Dictionary<string, CheckBox> chromeChecks = new Dictionary<string, CheckBox>();
    private TextBox previewContent;
    private readonly HashSet<string> colorTouched = new HashSet<string>();
    private Grid propertyRow;
    private int propertyPair;
    private bool rendering, applying;
    private readonly Dictionary<string, string> labels = new Dictionary<string, string> {
        {"样式/RmtItemEditBtn", "按钮 1 · 宏配置—操作按钮"}, {"样式/RmtItemPrimaryBtn", "按钮 2 · 宏配置—设置按钮"},
        {"Main.Config", "按钮 3 · 主界面—配置管理"}, {"Main.Save", "按钮 4 · 主界面—应用保存"},
        {"Theme.Confirm", "按钮 5 · 设置—主题选项确定"},
        {"Window.TriggerKey", "窗口 1 · 触发键编辑窗口"}, {"Window.Theme", "窗口 2 · 设置—主题"}
    };
    private static readonly Dictionary<string, string> notices = new Dictionary<string, string> {
        {"特殊说明/系统菜单与系统弹窗", "系统 Menu、MsgBox、InputBox 由 Windows 绘制，不属于 WPF 控件树。此项仅登记来源，不能通过通用 WPF 属性编辑。应用内使用 XAMLHost 的对话框仍自动接入。"},
        {"特殊说明/屏幕搜索范围标记", "Gui/SearchProGui.ahk：四个原生无标题置顶窗口用于描绘屏幕范围，带鼠标穿透。属于自绘标记，未接入通用控件尺寸与边距覆盖。"},
        {"特殊说明/旧输入按钮条", "Gui/InputBtnGui.ahk：旧原生透明按钮条，透明键色 EEAA99，字体 s11 w550，按钮宽 80。新版 Gui/InputBtnXamlGui.ahk 已经通过 XAMLHost 自动接入。"},
        {"特殊说明/运行浮层与轮盘业务颜色", "Main/Util/ThemeUtil.ahk 的 AppThemeUtil.ColorDefs 维护 Wheel_*、Panel_*、CMD_* 业务配色；在设置→主题选项中配置。它们属于独立业务绘制，不等同于通用窗口按钮颜色。"}
    };
    private static readonly Dictionary<string, string> propertyLabels = new Dictionary<string, string> {
        {"Background", "背景颜色"}, {"HoverBackground", "悬停背景"}, {"PressedBackground", "按住背景"}, {"Foreground", "文字颜色"}, {"BorderBrush", "边框颜色"}, {"BorderThickness", "边框宽度"}, {"CornerRadius", "圆角"},
        {"Margin", "外边距"}, {"Padding", "内边距"}, {"Width", "宽度"}, {"Height", "高度"}, {"MinWidth", "最小宽度"}, {"MinHeight", "最小高度"},
        {"MaxWidth", "最大宽度"}, {"MaxHeight", "最大高度"}, {"RelativeFontSize", "相对字号"}, {"FontWeight", "字体粗细"},
        {"Opacity", "不透明度"}, {"HorizontalContentAlignment", "水平对齐"}, {"VerticalContentAlignment", "垂直对齐"}, {"SizeMode", "宽高类型"}, {"Color", "颜色"}
    };
    private string selected;
    private FrameworkElement sample;
    private WeakReference inspectRef;
    private bool reflecting;
    private bool dirty;
    private Button cmdReflect;
    private Ellipse reflectorDot;
    private DispatcherTimer reflectorTimer;
    private readonly HashSet<Window> reflectorWindows = new HashSet<Window>();
    private FrameworkElement highlightTarget;
    private Dictionary<string, Dictionary<string, string>> snapshot;
    private Dictionary<string, Dictionary<string, string>> layoutSnapshot;
    private Dictionary<string, string> cloneSnapshot;
    private Dictionary<string, string> displaySnapshot;

    internal RmtStyleEditor(Window owner)
    {
        source = owner; Title = "GM-UI · 通用样式管理";
        Width = 1240; Height = 850; MinWidth = 980; MinHeight = 640;
        FontFamily = owner.FontFamily; FontSize = owner.FontSize;
        snapshot = CopyValues();
        layoutSnapshot = CopyLayouts();
        cloneSnapshot = new Dictionary<string, string>(RmtCommonStyles.CloneBases);
        displaySnapshot = new Dictionary<string, string>(RmtCommonStyles.DisplayNames);
        const string editorXaml = @"<Border xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation' xmlns:x='http://schemas.microsoft.com/winfx/2006/xaml' Margin='10' Background='{DynamicResource BgColor}' BorderBrush='{DynamicResource ControlBorder}' BorderThickness='1' CornerRadius='{DynamicResource WindowRadius}' TextElement.Foreground='{DynamicResource TextMain}'>
  <Border.Effect><DropShadowEffect BlurRadius='15' ShadowDepth='2' Opacity='.30'/></Border.Effect>
  <Grid><Grid.RowDefinitions><RowDefinition Height='30'/><RowDefinition Height='*'/></Grid.RowDefinitions>
    <Grid Background='{DynamicResource TitleBarColor}'>
      <Grid.ColumnDefinitions><ColumnDefinition Width='*'/><ColumnDefinition Width='Auto'/></Grid.ColumnDefinitions>
      <Border x:Name='DragArea' Grid.Column='0' Background='{DynamicResource TitleBarColor}'>
        <TextBlock Text='GM-UI · 控件样式管理' Foreground='{DynamicResource TitleBarForeground}' FontWeight='Bold' FontSize='17' VerticalAlignment='Center' Margin='15,0,0,0'/>
      </Border>
      <StackPanel Grid.Column='1' Orientation='Horizontal' VerticalAlignment='Stretch'>
        <Button x:Name='BtnWinClose' Width='46' Height='30' MinWidth='46' MinHeight='30' Padding='0' Margin='0' VerticalAlignment='Stretch' Background='Transparent' Foreground='{DynamicResource TitleBarForeground}' BorderThickness='0'>
          <TextBlock Text='&#xE8BB;' FontFamily='Segoe Fluent Icons, Segoe MDL2 Assets' FontSize='10' VerticalAlignment='Center' HorizontalAlignment='Center' Margin='0' Foreground='{DynamicResource TitleBarForeground}'/>
        </Button>
      </StackPanel>
    </Grid>
    <DockPanel Grid.Row='1' Margin='18'>
      <DockPanel DockPanel.Dock='Top' Margin='0,0,0,12'>
        <StackPanel Orientation='Horizontal' DockPanel.Dock='Left'>
          <Grid x:Name='ReflectorHost' Margin='0,0,8,0'>
            <Button x:Name='CmdReflect' Content='控件反射器' Padding='12,7'/>
            <Ellipse x:Name='ReflectorDot' Width='8' Height='8' Fill='#E53935' HorizontalAlignment='Right' VerticalAlignment='Top' Margin='0,-3,-3,0' Visibility='Collapsed' IsHitTestVisible='False'/>
          </Grid>
          <Button x:Name='CmdReset' Content='重置' Padding='12,7' Margin='0,0,8,0'/>
          <Button x:Name='CmdSave' Content='应用并重启' Padding='12,7'/>
        </StackPanel>
        <TextBlock x:Name='Status' TextWrapping='Wrap' VerticalAlignment='Center' Margin='16,0,0,0'/>
      </DockPanel>
      <Grid><Grid.ColumnDefinitions><ColumnDefinition Width='300'/><ColumnDefinition Width='16'/><ColumnDefinition Width='*'/></Grid.ColumnDefinitions>
        <Border Grid.Column='0' BorderBrush='{DynamicResource Win_GroupStroke}' BorderThickness='1' CornerRadius='5' Padding='10'><DockPanel><TextBox x:Name='Search' DockPanel.Dock='Top' MinHeight='30' Margin='0,0,0,8' ToolTip='搜索按钮或窗口样式'/><TreeView x:Name='Catalog'/></DockPanel></Border>
        <DockPanel Grid.Column='2'><GroupBox DockPanel.Dock='Top' Header='目标样式预览' Margin='0,0,0,10' Padding='12' MaxHeight='175'><StackPanel x:Name='Preview'/></GroupBox><TextBlock DockPanel.Dock='Top' Text='属性名 / 属性值（每行三组）' FontWeight='SemiBold' Margin='0,0,0,6'/><ScrollViewer VerticalScrollBarVisibility='Auto'><StackPanel x:Name='Fields'/></ScrollViewer></DockPanel>
      </Grid>
    </DockPanel>
  </Grid>
</Border>";
        var root = (Border)XamlReader.Parse(editorXaml); Content = root;
        WindowStyle = WindowStyle.None; AllowsTransparency = true; Background = Brushes.Transparent; ShowInTaskbar = true; WindowStartupLocation = WindowStartupLocation.CenterScreen;
        var chrome = new System.Windows.Shell.WindowChrome { CaptionHeight = 30, ResizeBorderThickness = new Thickness(6), GlassFrameThickness = new Thickness(0), CornerRadius = new CornerRadius(0) };
        System.Windows.Shell.WindowChrome.SetWindowChrome(this, chrome);
        Resources.MergedDictionaries.Add(source.Resources);
        search = (TextBox)root.FindName("Search");
        catalog = (TreeView)root.FindName("Catalog");
        fields = (StackPanel)root.FindName("Fields");
        preview = (StackPanel)root.FindName("Preview");
        status = (TextBlock)root.FindName("Status");
        var drag = (Border)root.FindName("DragArea"); drag.MouseLeftButtonDown += delegate { try { DragMove(); } catch { } };
        var close = (Button)root.FindName("BtnWinClose");
        close.Style = source.TryFindResource("TitleBarCloseButton") as Style ?? Application.Current.TryFindResource("TitleBarCloseButton") as Style;
        close.Width = 46; close.Height = 30; close.MinWidth = 46; close.MinHeight = 30;
        close.Padding = new Thickness(0); close.Margin = new Thickness(0);
        close.VerticalAlignment = VerticalAlignment.Stretch;
        close.Background = Brushes.Transparent; close.BorderThickness = new Thickness(0);
        var glyph = close.Content as TextBlock;
        if (glyph == null)
        {
            glyph = new TextBlock();
            close.Content = glyph;
        }
        glyph.Text = "\uE8BB";
        glyph.FontFamily = new FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets");
        glyph.FontSize = 10;
        glyph.Margin = new Thickness(0);
        glyph.HorizontalAlignment = HorizontalAlignment.Center;
        glyph.VerticalAlignment = VerticalAlignment.Center;
        glyph.Foreground = close.Foreground;
        System.Windows.Shell.WindowChrome.SetIsHitTestVisibleInChrome(close, true); close.Click += delegate { Close(); };
        cmdReflect = (Button)root.FindName("CmdReflect");
        reflectorDot = (Ellipse)root.FindName("ReflectorDot");
        cmdReflect.Click += delegate { ToggleReflector(); };
        ((Button)root.FindName("CmdSave")).Click += delegate { if (Commit(true)) { try { RmtCommonStyles.Save(); snapshot = CopyValues(); layoutSnapshot = CopyLayouts(); cloneSnapshot = new Dictionary<string, string>(RmtCommonStyles.CloneBases); displaySnapshot = new Dictionary<string, string>(RmtCommonStyles.DisplayNames); dirty = false; status.Text = "已保存并应用到所有已打开实例；软件重启后也会保持此样式。"; } catch (Exception ex) { status.Text = ex.Message; } } };
        ((Button)root.FindName("CmdReset")).Click += delegate { Restore(); selected = null; inspectRef = null; Populate(); Render(); };
        catalog.SelectedItemChanged += delegate { var item = catalog.SelectedItem as TreeViewItem; if (item != null && item.Tag is string) { selected = (string)item.Tag; Render(); } };
        search.TextChanged += delegate { Populate(); };
        PreviewKeyDown += EditorKeyDown;
        Closing += delegate(object sender, CancelEventArgs args) { StopReflector(); if (dirty) Restore(); };
        Populate();
        status.Text = RmtCommonStyles.LoadError;
    }

    private static Dictionary<string, Dictionary<string, string>> CopyValues()
    {
        return RmtCommonStyles.Values.ToDictionary(x => x.Key, x => new Dictionary<string, string>(x.Value));
    }
    private static Dictionary<string, Dictionary<string, string>> CopyLayouts()
    {
        return RmtCommonStyles.Layouts.ToDictionary(x => x.Key, x => new Dictionary<string, string>(x.Value));
    }
    private void Restore()
    {
        RmtCommonStyles.Values.Clear(); foreach (var item in snapshot) RmtCommonStyles.Values[item.Key] = new Dictionary<string, string>(item.Value);
        RmtCommonStyles.Layouts.Clear(); foreach (var item in layoutSnapshot) RmtCommonStyles.Layouts[item.Key] = new Dictionary<string, string>(item.Value);
        RmtCommonStyles.CloneBases.Clear(); foreach (var item in cloneSnapshot) RmtCommonStyles.CloneBases[item.Key] = item.Value;
        RmtCommonStyles.DisplayNames.Clear(); foreach (var item in displaySnapshot) RmtCommonStyles.DisplayNames[item.Key] = item.Value;
        RmtCommonStyles.Refresh(); dirty = false; status.Text = "已撤销未保存预览。";
    }

    private FrameworkElement Inspected()
    {
        return inspectRef == null ? null : inspectRef.Target as FrameworkElement;
    }

    private bool LiveInspecting()
    {
        var target = Inspected();
        return target != null && selected == RmtCommonStyles.StyleKeyPublic(target);
    }

    private void ToggleReflector()
    {
        if (reflecting) StopReflector();
        else StartReflector();
    }

    private void StartReflector()
    {
        reflecting = true;
        UpdateReflectorVisual();
        HookNewWindows();
        if (reflectorTimer == null)
        {
            reflectorTimer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(400) };
            reflectorTimer.Tick += delegate { if (reflecting) HookNewWindows(); else reflectorTimer.Stop(); };
        }
        reflectorTimer.Start();
        status.Text = "控件反射器已开启：在其它窗口上点击要调整的控件，Esc 或再点一次按钮退出。";
    }

    private void StopReflector()
    {
        if (!reflecting) return;
        reflecting = false;
        if (reflectorTimer != null) reflectorTimer.Stop();
        ClearHighlight();
        foreach (Window window in reflectorWindows.ToArray())
            UnhookReflector(window);
        reflectorWindows.Clear();
        UpdateReflectorVisual();
        status.Text = Inspected() == null ? "已退出控件反射器。" : "已退出控件反射器，可继续调整上次选中的控件。";
    }

    private void HookNewWindows()
    {
        if (Application.Current == null) return;
        foreach (Window window in Application.Current.Windows.Cast<Window>().ToArray())
        {
            if (window == null || window is RmtStyleEditor || reflectorWindows.Contains(window)) continue;
            window.PreviewMouseMove += InspectMove;
            window.PreviewMouseLeftButtonDown += InspectDown;
            window.PreviewKeyDown += InspectKey;
            window.Cursor = Cursors.Cross;
            window.Closed += ReflectorWindowClosed;
            reflectorWindows.Add(window);
        }
    }

    private void UnhookReflector(Window window)
    {
        if (window == null) return;
        window.PreviewMouseMove -= InspectMove;
        window.PreviewMouseLeftButtonDown -= InspectDown;
        window.PreviewKeyDown -= InspectKey;
        window.Closed -= ReflectorWindowClosed;
        window.Cursor = Cursors.Arrow;
        reflectorWindows.Remove(window);
    }

    private void ReflectorWindowClosed(object sender, EventArgs args)
    {
        UnhookReflector(sender as Window);
    }

    private void UpdateReflectorVisual()
    {
        if (cmdReflect == null) return;
        if (reflecting)
            cmdReflect.Background = source.TryFindResource("ActionHoverBg") as Brush
                ?? source.TryFindResource("ControlBorder") as Brush
                ?? Brushes.Orange;
        else
            cmdReflect.ClearValue(Control.BackgroundProperty);
        if (reflectorDot != null) reflectorDot.Visibility = reflecting ? Visibility.Visible : Visibility.Collapsed;
    }

    private void EditorKeyDown(object sender, KeyEventArgs args)
    {
        if (args.Key == Key.Escape && reflecting) { StopReflector(); args.Handled = true; }
    }

    private void InspectKey(object sender, KeyEventArgs args)
    {
        if (args.Key == Key.Escape && reflecting) { StopReflector(); args.Handled = true; }
    }

    private RmtHighlightAdorner highlightAdorner;

    private void InspectMove(object sender, MouseEventArgs args)
    {
        if (!reflecting) return;
        var window = sender as Window;
        if (window == null) return;
        var hit = HitControl(window, args.GetPosition(window));
        ShowHighlight(hit);
    }

    private void InspectDown(object sender, MouseButtonEventArgs args)
    {
        if (!reflecting) return;
        var window = sender as Window;
        if (window == null) return;
        var hit = HitControl(window, args.GetPosition(window));
        args.Handled = true;
        if (hit == null) { StopReflector(); return; }
        inspectRef = new WeakReference(hit);
        selected = RmtCommonStyles.StyleKeyPublic(hit);
        RmtCommonStyles.EnsureRegistered(hit);
        StopReflector();
        Populate();
        SelectCatalog(selected);
        Render();
        status.Text = "已选中 " + hit.GetType().Name + (string.IsNullOrEmpty(hit.Name) ? "" : " / " + hit.Name) + "，可继续调整重载属性与位置。";
    }

    private static FrameworkElement HitControl(Window window, Point pos)
    {
        var result = VisualTreeHelper.HitTest(window, pos);
        var current = result == null ? null : result.VisualHit as DependencyObject;
        while (current != null)
        {
            var fe = current as FrameworkElement;
            if (fe != null && RmtCommonStyles.IsPickable(fe)) return fe;
            current = VisualTreeHelper.GetParent(current);
        }
        return null;
    }

    private void ShowHighlight(FrameworkElement element)
    {
        if (highlightTarget == element) return;
        ClearHighlight();
        if (element == null) return;
        var layer = AdornerLayer.GetAdornerLayer(element);
        if (layer == null) return;
        highlightAdorner = new RmtHighlightAdorner(element);
        layer.Add(highlightAdorner);
        highlightTarget = element;
    }

    private void ClearHighlight()
    {
        if (highlightAdorner != null)
        {
            var layer = AdornerLayer.GetAdornerLayer(highlightAdorner.AdornedElement);
            if (layer != null) layer.Remove(highlightAdorner);
            highlightAdorner = null;
        }
        highlightTarget = null;
    }

    private void SelectCatalog(string key)
    {
        foreach (TreeViewItem group in catalog.Items)
            foreach (TreeViewItem leaf in group.Items)
                if ((leaf.Tag as string) == key) { leaf.IsSelected = true; return; }
    }

    private void AddPositionFields(FrameworkElement target)
    {
        fields.Children.Add(new TextBlock { Text = "位置（仅当前控件，点“应用位置”后下次打开生效）", FontWeight = FontWeights.SemiBold, Margin = new Thickness(0, 12, 0, 6) });
        var row = new Grid { Margin = new Thickness(0, 0, 0, 8) };
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(80) });
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(80) });
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(100) });
        double left = target.Margin.Left, top = target.Margin.Top;
        if (target is Window)
        {
            left = ((Window)target).Left;
            top = ((Window)target).Top;
        }
        else if (target.Parent is Canvas)
        {
            if (!double.IsNaN(Canvas.GetLeft(target))) left = Canvas.GetLeft(target);
            if (!double.IsNaN(Canvas.GetTop(target))) top = Canvas.GetTop(target);
        }
        var leftBox = new TextBox { Name = "PosLeft", Text = left.ToString("0.##", CultureInfo.InvariantCulture), Height = 28, MinHeight = 28, Padding = new Thickness(2, 0, 2, 0), VerticalContentAlignment = VerticalAlignment.Center, Margin = new Thickness(0, 0, 14, 0) };
        var topBox = new TextBox { Name = "PosTop", Text = top.ToString("0.##", CultureInfo.InvariantCulture), Height = 28, MinHeight = 28, Padding = new Thickness(2, 0, 2, 0), VerticalContentAlignment = VerticalAlignment.Center, Margin = new Thickness(0, 0, 14, 0) };
        var apply = new Button { Content = "应用位置", Padding = new Thickness(10, 6, 10, 6) };
        apply.Click += delegate { ApplyInspectedPosition(leftBox.Text, topBox.Text); };
        row.Children.Add(new TextBlock { Text = "左边距", VerticalAlignment = VerticalAlignment.Center });
        Grid.SetColumn(leftBox, 1); row.Children.Add(leftBox);
        var topLabel = new TextBlock { Text = "上边距", VerticalAlignment = VerticalAlignment.Center };
        Grid.SetColumn(topLabel, 2); row.Children.Add(topLabel);
        Grid.SetColumn(topBox, 3); row.Children.Add(topBox);
        Grid.SetColumn(apply, 4); row.Children.Add(apply);
        fields.Children.Add(row);
    }

    private void ApplyInspectedPosition(string leftText, string topText)
    {
        var target = Inspected();
        if (target == null) { status.Text = "没有选中的控件。"; return; }
        double left, top;
        if (!double.TryParse(leftText.Trim(), NumberStyles.Float, CultureInfo.InvariantCulture, out left)
            || !double.TryParse(topText.Trim(), NumberStyles.Float, CultureInfo.InvariantCulture, out top))
        { status.Text = "位置请输入数字。"; return; }
        string id = RmtCommonStyles.LayoutId(target);
        if (id == "") { status.Text = "该控件没有稳定名称，位置无法在下次打开时恢复。请先给控件命名。"; return; }
        var layout = new Dictionary<string, string>();
        if (target is Window)
        {
            ((Window)target).Left = left;
            ((Window)target).Top = top;
            layout["Left"] = left.ToString(CultureInfo.InvariantCulture);
            layout["Top"] = top.ToString(CultureInfo.InvariantCulture);
        }
        else if (target.Parent is Canvas)
        {
            Canvas.SetLeft(target, left);
            Canvas.SetTop(target, top);
            layout["CanvasLeft"] = left.ToString(CultureInfo.InvariantCulture);
            layout["CanvasTop"] = top.ToString(CultureInfo.InvariantCulture);
        }
        else
        {
            var m = target.Margin;
            target.Margin = new Thickness(left, top, m.Right, m.Bottom);
            layout["Margin"] = RmtCommonStyles.Text(target.Margin);
        }
        RmtCommonStyles.Layouts[id] = layout;
        layoutSnapshot = CopyLayouts();
        try { RmtCommonStyles.Save(); status.Text = "位置已应用并保存，下次打开该界面会保持此位置。"; }
        catch (Exception ex) { status.Text = ex.Message; }
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
        all.UnionWith(new[] { "通用/Button", "通用/Window", "Window.TriggerKey", "Window.Theme" });
        all.UnionWith(RmtCommonStyles.Live().Select(x => x.Key));
        all.UnionWith(RmtCommonStyles.Values.Keys);
        all.UnionWith(RmtCommonStyles.CloneBases.Keys);
        var inspected = Inspected();
        if (inspected != null) all.Add(RmtCommonStyles.StyleKeyPublic(inspected));
        TreeViewItem firstLeaf = null;
        if (inspected != null)
        {
            string inspectKey = RmtCommonStyles.StyleKeyPublic(inspected);
            string inspectText = inspected.GetType().Name + (string.IsNullOrEmpty(inspected.Name) ? "" : " / " + inspected.Name);
            if ((inspectText + inspectKey).IndexOf(query, StringComparison.OrdinalIgnoreCase) >= 0)
            {
                var inspectGroup = new TreeViewItem { Header = "反射控件", IsExpanded = true, FontWeight = FontWeights.SemiBold };
                var leaf = MakeLeaf(inspectText, inspectKey);
                inspectGroup.Items.Add(leaf);
                if (inspectKey == old) leaf.IsSelected = true;
                catalog.Items.Add(inspectGroup);
                firstLeaf = leaf;
            }
        }
        var buttonGroup = new TreeViewItem { Header = "按钮", IsExpanded = true, FontWeight = FontWeights.SemiBold };
        int buttonNo = 0;
        foreach (string key in all.Where(IsButtonKey).OrderBy(ButtonOrder))
        {
            string text = key == "通用/Button" ? "按钮模版" : "按钮" + (++buttonNo) + " - " + ButtonTitle(key);
            if ((text + key).IndexOf(query, StringComparison.OrdinalIgnoreCase) < 0) continue;
            var leaf = MakeLeaf(text, key);
            buttonGroup.Items.Add(leaf);
            if (firstLeaf == null) firstLeaf = leaf;
            if (key == old) leaf.IsSelected = true;
        }
        if (buttonGroup.Items.Count > 0) catalog.Items.Add(buttonGroup);
        var windowGroup = new TreeViewItem { Header = "窗口", IsExpanded = true, FontWeight = FontWeights.SemiBold };
        int windowNo = 0;
        foreach (string key in all.Where(RmtCommonStyles.IsWindowKey).OrderBy(WindowOrder))
        {
            string text = key == "通用/Window" ? "窗口模版" : "窗口" + (++windowNo) + " - " + ButtonTitle(key);
            if ((text + key).IndexOf(query, StringComparison.OrdinalIgnoreCase) < 0) continue;
            var leaf = MakeLeaf(text, key);
            windowGroup.Items.Add(leaf);
            if (firstLeaf == null) firstLeaf = leaf;
            if (key == old) leaf.IsSelected = true;
        }
        if (windowGroup.Items.Count > 0) catalog.Items.Add(windowGroup);
        if (catalog.SelectedItem == null && firstLeaf != null) firstLeaf.IsSelected = true;
    }

    private TreeViewItem MakeLeaf(string text, string key)
    {
        var leaf = new TreeViewItem { Header = text, Tag = key, ToolTip = key, Padding = new Thickness(4) };
        var menu = new ContextMenu();
        if (key != "通用/Button" && key != "通用/Window")
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
    private static int WindowOrder(string key)
    {
        if (key == "通用/Window") return 0;
        if (key == "Window.TriggerKey") return 1;
        if (key == "Window.Theme") return 2;
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
        if (RmtCommonStyles.IsWindowKey(key) || raw == "Window") return "窗口";
        if (raw.IndexOf("Button", StringComparison.OrdinalIgnoreCase) >= 0 || raw.StartsWith("Main.") || raw.StartsWith("Theme.")) return "按钮";
        return "其它控件";
    }
    private string DisplayName(string key)
    {
        string value;
        if (labels.TryGetValue(key, out value)) return value;
        if (key == "通用/Button") return "按钮模版";
        if (key == "通用/Window") return "窗口模版";
        if (key.StartsWith("样式/Button")) return key.Substring(3).Replace("Button", "按钮 ");
        return key.StartsWith("通用/") ? "通用 " + key.Substring(3) : key;
    }

    private void CopyStyle(string sourceName)
    {
        if (string.IsNullOrEmpty(sourceName) || (!IsButtonKey(sourceName) && !RmtCommonStyles.IsWindowKey(sourceName)))
        {
            status.Text = "请选择一个控件样式后再复制。"; return;
        }
        string family = RmtCommonStyles.IsWindowKey(sourceName) ? "Window" : "Button";
        int number = 1; string next;
        do { next = family + number++; } while (RmtCommonStyles.Values.ContainsKey(next) || RmtCommonStyles.CloneBases.ContainsKey(next));
        Dictionary<string, string> original;
        RmtCommonStyles.Values.TryGetValue(sourceName, out original);
        RmtCommonStyles.Values[next] = original == null ? new Dictionary<string, string>() : new Dictionary<string, string>(original);
        RmtCommonStyles.CloneBases[next] = sourceName;
        if (IsButtonKey(next) || RmtCommonStyles.IsWindowKey(next)) RmtCommonStyles.DisplayNames[next] = ButtonTitle(sourceName) + "（副本）";
        dirty = true; selected = next; Populate(); Render();
        status.Text = DisplayName(next) + " 已由「" + DisplayName(sourceName) + "」复制；可在右侧继续调整。";
    }

    private void Render()
    {
        rendering = true;
        fields.Children.Clear(); preview.Children.Clear(); inputs.Clear(); colorInputs.Clear(); optionInputs.Clear(); sliderInputs.Clear(); dimensionInputs.Clear(); presetInputs.Clear(); chromeChecks.Clear(); colorTouched.Clear(); propertyRow = null; propertyPair = 0; sample = null;
        if (selected == null) { rendering = false; return; }
        var inspected = Inspected();
        bool inspectMode = inspected != null && selected == RmtCommonStyles.StyleKeyPublic(inspected);
        if (RmtCommonStyles.IsWindowKey(selected))
        {
            RenderWindow();
            if (inspectMode)
            {
                AddTemplateSection(inspected);
                AddPositionFields(inspected);
            }
            rendering = false;
            return;
        }
        Dictionary<string, string> values; RmtCommonStyles.Values.TryGetValue(selected, out values);
        string previewBase;
        RmtCommonStyles.CloneBases.TryGetValue(selected, out previewBase);
        string targetKey = previewBase ?? selected;
        bool fromTemplateClone = previewBase == "通用/Button" && selected != "通用/Button";
        bool isTemplate = selected == "通用/Button" || fromTemplateClone;
        var matches = fromTemplateClone ? new List<RmtCommonStyles.Entry>() : RmtCommonStyles.Live().Where(x => x.Key == targetKey || (targetKey.StartsWith("通用/") && ((FrameworkElement)x.Element.Target).GetType().Name == targetKey.Substring(3))).ToList();
        var entry = matches.FirstOrDefault();
        bool namedPreview = IsNamedButtonKey(targetKey);
        // Named styles must be previewed from a real registered target. A generic replacement is misleading for icon buttons and fixed layouts.
        if (!inspectMode && entry == null && !targetKey.StartsWith("通用/") && !namedPreview)
        {
            preview.Children.Add(new TextBlock { Text = "对应目标控件尚未打开；打开它并点击“刷新实例”后，预览会直接复制目标样式、内容和尺寸。", TextWrapping = TextWrapping.Wrap });
            fields.Children.Add(new TextBlock { Text = selected + " · 已加载实例 0", FontWeight = FontWeights.Bold, Margin = new Thickness(0, 0, 0, 8) });
            fields.Children.Add(new TextBlock { Text = "为避免错误预览，此命名样式在没有真实实例时不显示替代控件。", TextWrapping = TextWrapping.Wrap });
            rendering = false;
            return;
        }
        sample = inspectMode ? inspected : (isTemplate ? CreateSample("通用/Button") : entry == null ? CreateSample(targetKey) : entry.Element.Target as FrameworkElement);
        if (isTemplate && !inspectMode) ConfigureButtonTemplate(sample as Button);
        if (!inspectMode && entry == null && namedPreview) ConfigureNamedButtonSample(sample as Button, targetKey);
        if (!inspectMode && entry == null && sample != null && targetKey.StartsWith("样式/"))
            sample.Style = source.TryFindResource(targetKey.Substring(3)) as Style;
        string header = inspectMode
            ? ("反射 · " + inspected.GetType().Name + (string.IsNullOrEmpty(inspected.Name) ? "" : " / " + inspected.Name) + " · " + selected)
            : (selected == "通用/Button" ? "按钮模版 · 应用到未单独指定样式的按钮，具名样式可覆盖" : (fromTemplateClone ? selected + " · 基于按钮模版的独立预览" : (entry == null ? selected + " · 按样式属性预览" : selected + " · 已加载实例 " + matches.Count)));
        fields.Children.Add(new TextBlock { Text = header, FontWeight = FontWeights.Bold, Margin = new Thickness(0, 0, 0, 8) });
        if (sample == null) { fields.Children.Add(new TextBlock { Text = "请先打开使用此样式的界面，再刷新目录。" }); rendering = false; return; }
        if (!inspectMode && entry == null && !selected.StartsWith("通用/") && !namedPreview && sample.Style == null)
            fields.Children.Add(new TextBlock { Text = "此界面尚未加载，当前为类型示例；打开对应界面并刷新后可查看实际样式。", TextWrapping = TextWrapping.Wrap });
        AddPreviewOptions();
        ShowPreview(sample);
        if (inspectMode) AddTemplateSection(inspected);
        fields.Children.Add(new TextBlock { Text = inspectMode ? "重载属性（修改后立即作用到选中控件）" : "重载属性", FontWeight = FontWeights.SemiBold, Margin = new Thickness(0, 10, 0, 6) });
        propertyRow = null; propertyPair = 0;
        foreach (string property in RmtCommonStyles.Properties)
        {
            if (property == "Width" || property == "Height" || property == "MinWidth" || property == "MinHeight" || property == "MaxWidth" || property == "MaxHeight") continue;
            var dp = RmtCommonStyles.Property(sample, property); if (dp == null) continue;
            bool bound = BindingOperations.IsDataBound(sample, dp);
            string current = property == "RelativeFontSize" ? "0" : RmtCommonStyles.Text(RmtCommonStyles.DisplayValue(sample, property, dp));
            Field(property, values != null && values.ContainsKey(property) ? values[property] : "", current, bound);
        }
        string sizeMode = SizeMode(values, sample);
        Field("SizeMode", sizeMode, sizeMode, false);
        if (sizeMode == "固定宽高" || sizeMode == "自适应高度")
            AddSizeField("Width", values);
        if (sizeMode == "固定宽高" || sizeMode == "自适应宽度")
            AddSizeField("Height", values);
        if (sizeMode == "自适应宽度") { AddSizeField("MinWidth", values); AddSizeField("MaxWidth", values); }
        if (sizeMode == "自适应高度") { AddSizeField("MinHeight", values); AddSizeField("MaxHeight", values); }
        if (sizeMode == "自适应宽高")
        {
            AddSizeField("MinWidth", values); AddSizeField("MinHeight", values);
            AddSizeField("MaxWidth", values); AddSizeField("MaxHeight", values);
        }
        if (sample.Style != null)
        {
            try { fields.Children.Add(new Expander { Header = "样式模板 / 交互状态（只读来源）", Content = new TextBox { Text = System.Windows.Markup.XamlWriter.Save(sample.Style), IsReadOnly = true, TextWrapping = TextWrapping.Wrap, MaxHeight = 240, VerticalScrollBarVisibility = ScrollBarVisibility.Auto } }); }
            catch { }
        }
        if (inspectMode) AddPositionFields(inspected);
        rendering = false;
    }

    private void AddTemplateSection(FrameworkElement target)
    {
        string templateKey = "通用/" + target.GetType().Name;
        string cloneBase;
        if (RmtCommonStyles.CloneBases.TryGetValue(selected, out cloneBase) && !string.IsNullOrEmpty(cloneBase))
            templateKey = cloneBase;
        Dictionary<string, string> template;
        RmtCommonStyles.Values.TryGetValue(templateKey, out template);
        fields.Children.Add(new TextBlock { Text = "模版属性（" + templateKey + "，只读）", FontWeight = FontWeights.SemiBold, Margin = new Thickness(0, 8, 0, 6) });
        if (template == null || template.Count == 0)
        {
            fields.Children.Add(new TextBlock { Text = "该模版尚未配置覆盖项，当前显示控件自身样式。", TextWrapping = TextWrapping.Wrap, Margin = new Thickness(0, 0, 0, 8) });
            return;
        }
        var box = new StackPanel { Margin = new Thickness(0, 0, 0, 8) };
        foreach (var pair in template.OrderBy(x => x.Key))
        {
            string title = propertyLabels.ContainsKey(pair.Key) ? propertyLabels[pair.Key] : pair.Key;
            box.Children.Add(new TextBlock { Text = title + "  " + pair.Value, Margin = new Thickness(0, 2, 0, 2) });
        }
        fields.Children.Add(box);
    }

    private void RenderWindow()
    {
        Dictionary<string, string> values;
        RmtCommonStyles.Values.TryGetValue(selected, out values);
        string previewBase;
        RmtCommonStyles.CloneBases.TryGetValue(selected, out previewBase);
        string targetKey = previewBase ?? selected;
        var matches = RmtCommonStyles.Live().Where(x => x.Element.Target is Window && (x.Key == targetKey || (targetKey == "通用/Window" && x.Key == "通用/Window"))).ToList();
        var inspectedWindow = Inspected();
        sample = (inspectedWindow is Window && selected == RmtCommonStyles.StyleKeyPublic(inspectedWindow))
            ? inspectedWindow
            : (matches.Count > 0 ? matches[0].Element.Target as FrameworkElement : new Window());
        fields.Children.Add(new TextBlock
        {
            Text = selected == "通用/Window" ? "窗口模版 · 应用到未单独指定的窗口；具名窗口可覆盖" : (matches.Count > 0 ? selected + " · 已加载实例 " + matches.Count : selected + " · 按样式属性预览"),
            FontWeight = FontWeights.Bold,
            Margin = new Thickness(0, 0, 0, 8)
        });
        fields.Children.Add(new TextBlock { Text = "右上角交互按钮", FontWeight = FontWeights.SemiBold, Margin = new Thickness(0, 4, 0, 6) });
        var chromeRow = new StackPanel { Orientation = Orientation.Horizontal, Margin = new Thickness(0, 0, 0, 10) };
        AddChromeCheck(chromeRow, "ShowMinimize", "最小化", values, DefaultChrome(targetKey, "ShowMinimize"));
        AddChromeCheck(chromeRow, "ShowMaximize", "最大化", values, DefaultChrome(targetKey, "ShowMaximize"));
        AddChromeCheck(chromeRow, "ShowPin", "置顶", values, DefaultChrome(targetKey, "ShowPin"));
        AddChromeCheck(chromeRow, "ShowClose", "关闭", values, DefaultChrome(targetKey, "ShowClose"));
        fields.Children.Add(chromeRow);
        propertyRow = null; propertyPair = 0;
        string pad = values != null && values.ContainsKey("Padding") ? values["Padding"] : CurrentWindowPadding();
        Field("Padding", values != null && values.ContainsKey("Padding") ? values["Padding"] : "", pad, false);
        ShowWindowPreview();
    }

    private static bool DefaultChrome(string key, string prop)
    {
        if (prop == "ShowClose") return true;
        return false;
    }

    private string CurrentWindowPadding()
    {
        var window = sample as Window;
        var body = window == null ? null : RmtCommonStyles.WindowBody(window);
        if (body != null) return RmtCommonStyles.Text(body.Margin);
        return "0";
    }

    private void AddChromeCheck(Panel parent, string name, string title, Dictionary<string, string> values, bool fallback)
    {
        bool on = fallback;
        string stored;
        if (values != null && values.TryGetValue(name, out stored))
            on = stored.Equals("True", StringComparison.OrdinalIgnoreCase);
        else
        {
            var window = sample as Window;
            string btnName = name == "ShowMinimize" ? "BtnMinimize" : name == "ShowMaximize" ? "BtnMaximize" : name == "ShowPin" ? "BtnPin" : "BtnClosePanel";
            var btn = window == null ? null : window.FindName(btnName) as UIElement;
            if (btn == null && name == "ShowClose" && window != null)
                btn = (window.FindName("BtnWinClose") as UIElement) ?? (window.FindName("BtnClose") as UIElement);
            if (btn != null) on = btn.Visibility == Visibility.Visible;
        }
        var box = new CheckBox { Content = title, IsChecked = on, Margin = new Thickness(0, 0, 18, 0), VerticalAlignment = VerticalAlignment.Center };
        box.Click += delegate { Commit(false); };
        parent.Children.Add(box);
        chromeChecks[name] = box;
    }

    private void ShowWindowPreview()
    {
        preview.Children.Clear();
        bool min = ChromeOn("ShowMinimize"), max = ChromeOn("ShowMaximize"), pin = ChromeOn("ShowPin"), close = ChromeOn("ShowClose");
        string pad = "0";
        TextBox padBox;
        if (inputs.TryGetValue("Padding", out padBox) && !string.IsNullOrWhiteSpace(padBox.Text)) pad = padBox.Text.Trim();
        var frame = new Border
        {
            BorderBrush = source.TryFindResource("ControlBorder") as Brush ?? Brushes.Gray,
            BorderThickness = new Thickness(1),
            CornerRadius = new CornerRadius(6),
            Width = 360,
            Height = 150,
            SnapsToDevicePixels = true
        };
        var grid = new Grid();
        grid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(36) });
        grid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });
        var bar = new Grid { Background = source.TryFindResource("TitleBarColor") as Brush ?? Brushes.LightGray };
        bar.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        bar.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        bar.Children.Add(new TextBlock
        {
            Text = selected == "通用/Window" ? "窗口模版" : ButtonTitle(selected),
            Foreground = source.TryFindResource("TitleBarForeground") as Brush ?? Brushes.Black,
            FontWeight = FontWeights.Bold,
            VerticalAlignment = VerticalAlignment.Center,
            Margin = new Thickness(12, 0, 0, 0)
        });
        var btns = new StackPanel { Orientation = Orientation.Horizontal, HorizontalAlignment = HorizontalAlignment.Right };
        Grid.SetColumn(btns, 1);
        if (min) btns.Children.Add(PreviewChromeGlyph("\uE921"));
        if (max) btns.Children.Add(PreviewChromeGlyph("\uE922"));
        if (pin) btns.Children.Add(PreviewChromeGlyph("\uE840"));
        if (close) btns.Children.Add(PreviewChromeGlyph("\uE8BB"));
        bar.Children.Add(btns);
        var body = new Border
        {
            Background = source.TryFindResource("BgColor") as Brush ?? Brushes.White,
            Margin = SafeThickness(pad),
            Child = new TextBlock { Text = "窗口内边距 " + pad, VerticalAlignment = VerticalAlignment.Center, HorizontalAlignment = HorizontalAlignment.Center, Opacity = 0.7 }
        };
        Grid.SetRow(body, 1);
        grid.Children.Add(bar);
        grid.Children.Add(body);
        frame.Child = grid;
        preview.Children.Add(frame);
    }

    private static Border PreviewChromeGlyph(string glyph)
    {
        return new Border
        {
            Width = 36,
            Height = 36,
            Child = new TextBlock
            {
                Text = glyph,
                FontFamily = new FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets"),
                FontSize = 10,
                HorizontalAlignment = HorizontalAlignment.Center,
                VerticalAlignment = VerticalAlignment.Center
            }
        };
    }

    private bool ChromeOn(string name)
    {
        CheckBox box;
        if (chromeChecks.TryGetValue(name, out box) && box.IsChecked == true) return true;
        return false;
    }

    private static Thickness SafeThickness(string value)
    {
        try { return (Thickness)RmtCommonStyles.ConvertValue(typeof(Thickness), value); }
        catch { return new Thickness(0); }
    }

    private static string SizeMode(Dictionary<string, string> values, FrameworkElement element)
    {
        string value;
        if (values != null && values.TryGetValue("SizeMode", out value) && (value == "固定宽高" || value == "自适应宽度" || value == "自适应高度" || value == "自适应宽高")) return value;
        bool autoW = (values != null && values.TryGetValue("Width", out value) && value.Equals("Auto", StringComparison.OrdinalIgnoreCase)) || (element != null && double.IsNaN(element.Width));
        bool autoH = (values != null && values.TryGetValue("Height", out value) && value.Equals("Auto", StringComparison.OrdinalIgnoreCase)) || (element != null && double.IsNaN(element.Height));
        if (autoW && autoH) return "自适应宽高";
        if (autoW) return "自适应宽度";
        if (autoH) return "自适应高度";
        return "固定宽高";
    }

    private void AddSizeField(string name, Dictionary<string, string> values)
    {
        var dp = RmtCommonStyles.Property(sample, name);
        if (dp == null) return;
        string current = RmtCommonStyles.Text(RmtCommonStyles.DisplayValue(sample, name, dp));
        if ((name == "Width" || name == "Height") && (current == "NaN" || string.IsNullOrEmpty(current))) current = "Auto";
        if ((name == "MaxWidth" || name == "MaxHeight") && (current == "Infinity" || current == "∞")) current = "无限";
        Field(name, values != null && values.ContainsKey(name) ? values[name] : "", current, BindingOperations.IsDataBound(sample, dp));
    }

    private static FrameworkElement CreateSample(string key)
    {
        if (key == "Theme.Confirm" || key == "Main.Config" || key == "Main.Save" || key.Contains("Btn")) return new Button();
        if (!key.StartsWith("通用/")) return null;
        Type type = typeof(Button).Assembly.GetType("System.Windows.Controls." + key.Substring(3));
        return type == null ? null : Activator.CreateInstance(type) as FrameworkElement;
    }

    private void ConfigureButtonTemplate(Button button)
    {
        if (button == null) return;
        // The template is a representative action button, not WPF's bare default Button.
        // Its inherited values therefore match the properties shown at right.
        button.SetResourceReference(Control.BackgroundProperty, "ActionBg");
        button.SetResourceReference(Control.ForegroundProperty, "ActionText");
        button.SetResourceReference(Control.BorderBrushProperty, "ActionBg");
        button.SetResourceReference(RmtCommonStyles.Property(button, "HoverBackground"), "ActionHoverBg");
        if (source.TryFindResource("ActionPressBg") != null)
            button.SetResourceReference(RmtCommonStyles.Property(button, "PressedBackground"), "ActionPressBg");
        button.BorderThickness = new Thickness(1);
        button.Padding = new Thickness(10, 4, 10, 4);
        button.Height = 32;
        button.MinHeight = 32;
        button.SetValue(RmtCommonStyles.Property(button, "CornerRadius"), new CornerRadius(3));
        button.HorizontalContentAlignment = HorizontalAlignment.Center;
        button.VerticalContentAlignment = VerticalAlignment.Center;
        button.Template = RmtCommonStyles.ChromeButtonTemplate();
    }

    private static bool IsNamedButtonKey(string key)
    {
        return key == "Theme.Confirm" || key == "Main.Config" || key == "Main.Save";
    }

    private void ConfigureNamedButtonSample(Button button, string key)
    {
        if (button == null) return;
        if (key == "Theme.Confirm")
        {
            button.SetResourceReference(Control.BackgroundProperty, "ActionBg");
            button.SetResourceReference(Control.ForegroundProperty, "ActionText");
            button.SetResourceReference(Control.BorderBrushProperty, "ActionStroke");
            button.BorderThickness = new Thickness(1);
            button.FontWeight = FontWeights.Bold;
            button.Width = 80;
            button.Height = 32;
            button.Content = "确定";
            button.Cursor = Cursors.Hand;
            button.HorizontalContentAlignment = HorizontalAlignment.Center;
            button.VerticalContentAlignment = VerticalAlignment.Center;
            return;
        }
        if (key == "Main.Config")
        {
            Style style = source.TryFindResource("RmtSidebarBtn") as Style;
            if (style != null) button.Style = style;
            button.Height = 33;
            button.MinHeight = 33;
            button.Content = "配置管理";
            return;
        }
        if (key == "Main.Save")
        {
            button.FontWeight = FontWeights.Bold;
            button.Height = 36;
            button.MinHeight = 36;
            button.Content = "应用并保存";
        }
    }

    private string DefaultPreviewText()
    {
        var content = sample as ContentControl;
        string actual = content == null ? null : content.Content as string;
        if (!string.IsNullOrEmpty(actual)) return actual;
        if (selected == "Theme.Confirm") return "确定";
        if (selected == "Main.Config") return "配置管理";
        if (selected == "Main.Save") return "应用并保存";
        return "按钮";
    }

    private void AddPreviewOptions()
    {
        if (!(sample is Button)) return;
        var row = new Grid { Margin = new Thickness(0, 0, 0, 9) };
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(80) });
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        row.Children.Add(new TextBlock { Text = "示例内容", VerticalAlignment = VerticalAlignment.Center, ToolTip = "仅影响右侧预览；可输入普通文本或符号。" });
        previewContent = new TextBox { Text = DefaultPreviewText(), Height = 42, Padding = new Thickness(5), ToolTip = "例如：保存、✓、⚙" };
        previewContent.TextChanged += delegate { if (!rendering && sample != null) { preview.Children.Clear(); ShowPreview(sample); } };
        Grid.SetColumn(previewContent, 1); row.Children.Add(previewContent); fields.Children.Add(row);
    }
    private void ShowPreview(FrameworkElement original)
    {
        FrameworkElement element;
        try { element = Activator.CreateInstance(original.GetType()) as FrameworkElement; } catch { return; }
        if (element == null) return;
        // Resource lookup uses the actual source window, including interaction-state colors.
        element.Resources.MergedDictionaries.Add(source.Resources);
        element.Style = original.Style;
        if (element is Button) ((Button)element).Template = RmtCommonStyles.ChromeButtonTemplate();
        foreach (string name in RmtCommonStyles.Properties)
            CopyPreviewProperty(element, original, name);
        Dictionary<string, string> configured;
        if (RmtCommonStyles.Values.TryGetValue(selected, out configured))
            foreach (var pair in configured)
                ApplyPreviewValue(element, pair.Key, pair.Value);
        foreach (var input in colorInputs)
        {
            var item = input.Value.SelectedItem as ComboBoxItem;
            string value = item == null ? "" : (item.Tag as string ?? "");
            if (!string.IsNullOrEmpty(value)) ApplyPreviewValue(element, input.Key, value);
        }
        foreach (var input in presetInputs)
        {
            string value = ComboText(input.Value);
            if (!string.IsNullOrEmpty(value)) ApplyPreviewValue(element, input.Key, value);
        }
        var content = element as ContentControl;
        if (content != null)
        {
            var originalContent = original as ContentControl;
            string actual = originalContent == null ? null : originalContent.Content as string;
            content.Content = previewContent != null && !string.IsNullOrEmpty(previewContent.Text) ? previewContent.Text : (!string.IsNullOrEmpty(actual) ? actual : PreviewTextFor(element));
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
        element.ApplyTemplate();
        RmtCommonStyles.ApplyCorners(element as Control);
    }

    private void ApplyPreviewValue(FrameworkElement element, string name, string value)
    {
        var dp = RmtCommonStyles.Property(element, name);
        if (dp == null || string.IsNullOrEmpty(value)) return;
        if (RmtCommonStyles.IsColorProperty(name) && RmtCommonStyles.IsThemeColor(value))
            element.SetResourceReference(dp, RmtCommonStyles.ThemeColorKey(value));
        else if (name == "RelativeFontSize")
            element.SetValue(dp, RmtCommonStyles.ThemeFontSize(source) + (double)RmtCommonStyles.ConvertValue(typeof(double), value));
        else if (value.Equals("Auto", StringComparison.OrdinalIgnoreCase) && (name == "Width" || name == "Height"))
            element.SetValue(dp, double.NaN);
        else if ((name == "MaxWidth" || name == "MaxHeight") && value == "无限")
            element.SetValue(dp, double.PositiveInfinity);
        else
            element.SetValue(dp, RmtCommonStyles.ConvertValue(dp.PropertyType, value));
    }

    private static void CopyPreviewProperty(FrameworkElement dest, FrameworkElement src, string name)
    {
        var dp = RmtCommonStyles.Property(dest, name);
        if (dp == null) return;
        if (name == "CornerRadius" && src is Control && src.ReadLocalValue(dp) == DependencyProperty.UnsetValue)
            return;
        object local = src.ReadLocalValue(dp);
        if (local != null && local.GetType().Name == "ResourceReferenceExpression")
        {
            var key = local.GetType().GetProperty("ResourceKey", System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.NonPublic);
            if (key != null)
            {
                dest.SetResourceReference(dp, key.GetValue(local, null));
                return;
            }
        }
        dest.SetValue(dp, src.GetValue(dp));
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
            combo.SelectionChanged += delegate { Commit(false); if (name == "SizeMode") Render(); };
            Grid.SetColumn(combo, column + 1); propertyRow.Children.Add(combo); optionInputs[name] = combo;
        }
        else if (name == "Opacity" || name == "RelativeFontSize")
        {
            double number;
            if (!double.TryParse(string.IsNullOrEmpty(value) ? current : value, NumberStyles.Float, CultureInfo.InvariantCulture, out number)) number = name == "Opacity" ? 1 : 0;
            var panel = new Grid { MinHeight = 28, Margin = new Thickness(0, 0, 14, 0) };
            panel.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            panel.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(42) });
            var slider = new Slider { Minimum = name == "Opacity" ? 0 : -8, Maximum = name == "Opacity" ? 1 : 8, Value = number, IsEnabled = !bound, VerticalAlignment = VerticalAlignment.Center, Tag = name };
            var display = new TextBlock { Text = name == "Opacity" ? number.ToString("0.00", CultureInfo.InvariantCulture) : (number >= 0 ? "+" : "") + number.ToString("0", CultureInfo.InvariantCulture), VerticalAlignment = VerticalAlignment.Center, HorizontalAlignment = HorizontalAlignment.Right };
            slider.ValueChanged += delegate { display.Text = name == "Opacity" ? slider.Value.ToString("0.00", CultureInfo.InvariantCulture) : (slider.Value >= 0 ? "+" : "") + slider.Value.ToString("0", CultureInfo.InvariantCulture); Commit(false); };
            panel.Children.Add(slider); Grid.SetColumn(display, 1); panel.Children.Add(display);
            Grid.SetColumn(panel, column + 1); propertyRow.Children.Add(panel); sliderInputs[name] = slider;
        }
        else if (IsPresetProperty(name) && !RmtCommonStyles.IsWindowKey(selected))
        {
            var combo = PresetPicker(name, string.IsNullOrEmpty(value) ? current : value, bound);
            combo.Margin = new Thickness(0, 0, 14, 0);
            combo.SelectionChanged += delegate { if (!combo.IsDropDownOpen) Commit(false); };
            combo.DropDownClosed += delegate { Commit(false); };
            combo.LostKeyboardFocus += delegate { if (!combo.IsDropDownOpen) Commit(false); };
            Grid.SetColumn(combo, column + 1); propertyRow.Children.Add(combo); presetInputs[name] = combo;
        }
        else if (name == "MaxWidth" || name == "MaxHeight")
        {
            string shown = string.IsNullOrEmpty(value) ? current : value;
            if (shown == "Infinity" || shown == "∞") shown = "无限";
            var combo = new ComboBox { IsEditable = true, IsReadOnly = bound, MinHeight = 28, Margin = new Thickness(0, 0, 14, 0), Text = shown, ToolTip = "可直接输入数值；最大宽高可选择“无限”。" };
            combo.Items.Add("无限");
            combo.SelectionChanged += delegate { if ((combo.SelectedItem as string) == "无限") combo.Text = "无限"; Commit(false); };
            combo.AddHandler(TextBox.TextChangedEvent, new TextChangedEventHandler(delegate { Commit(false); }));
            combo.LostKeyboardFocus += delegate { Commit(false); };
            Grid.SetColumn(combo, column + 1); propertyRow.Children.Add(combo); dimensionInputs[name] = combo;
        }
        else
        {
            bool inherited = string.IsNullOrEmpty(value);
            bool compactPad = name == "CornerRadius" || name == "BorderThickness" || name == "Margin" || name == "Padding"
                || name == "Width" || name == "Height" || name == "MinWidth" || name == "MinHeight";
            var box = new TextBox { Text = inherited ? current : value, IsReadOnly = bound, Padding = compactPad ? new Thickness(2, 0, 2, 0) : new Thickness(5), Height = 28, MinHeight = 28, VerticalContentAlignment = VerticalAlignment.Center, Margin = new Thickness(0, 0, 14, 0), ToolTip = inherited ? "显示当前继承值；修改后立即覆盖并应用。" : "当前覆盖值", Tag = inherited ? "inherit" : "override" };
            if (inherited) box.Foreground = Brushes.SlateGray;
            box.TextChanged += delegate { if (!box.IsReadOnly) { box.Tag = "override"; box.Foreground = Brushes.Black; Commit(false); } };
            Grid.SetColumn(box, column + 1); propertyRow.Children.Add(box); inputs[name] = box;
        }
    }

    private static bool IsPresetProperty(string name)
    {
        return name == "CornerRadius" || name == "BorderThickness" || name == "Margin" || name == "Padding";
    }

    private ComboBox PresetPicker(string name, string current, bool bound)
    {
        var options = name == "Padding"
            ? new[] { "0,0,0,0", "1,0,1,0", "2,0,2,0", "3,0,3,0", "4,0,4,0" }
            : name == "BorderThickness"
            ? new[] { "0,0,0,0", "1,1,1,1", "1.5,1.5,1.5,1.5", "2,2,2,2", "2.5,2.5,2.5,2.5", "3,3,3,3", "4,4,4,4" }
            : new[] { "0,0,0,0", "1,1,1,1", "2,2,2,2", "3,3,3,3", "4,4,4,4" };
        string shown = string.IsNullOrEmpty(current) ? options[0] : NormalizeThickness(current);
        var combo = new ComboBox { IsEditable = true, IsEnabled = !bound, MinHeight = 28, MaxDropDownHeight = 240, ToolTip = "选择常用值，也可直接输入。" };
        foreach (string option in options) combo.Items.Add(option);
        if (combo.Items.Contains(shown)) combo.SelectedItem = shown;
        return combo;
    }

    private static string NormalizeThickness(string value)
    {
        if (string.IsNullOrEmpty(value)) return "0,0,0,0";
        try
        {
            var t = (Thickness)RmtCommonStyles.ConvertValue(typeof(Thickness), value);
            return t.Left.ToString(CultureInfo.InvariantCulture) + "," + t.Top.ToString(CultureInfo.InvariantCulture) + "," + t.Right.ToString(CultureInfo.InvariantCulture) + "," + t.Bottom.ToString(CultureInfo.InvariantCulture);
        }
        catch { return value.Replace(" ", ""); }
    }

    private static string ComboText(ComboBox combo)
    {
        if (combo == null) return "";
        if (combo.SelectedItem is string) return (string)combo.SelectedItem;
        var item = combo.SelectedItem as ComboBoxItem;
        if (item != null && item.Tag is string) return (string)item.Tag;
        return (combo.Text ?? "").Trim();
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
            name == "SizeMode" ? new[] { "固定宽高", "自适应宽度", "自适应高度", "自适应宽高" } : new[] { "Left", "Center", "Right", "Stretch" };
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

    private bool CommitWindow(bool rerender)
    {
        if (applying) return false;
        applying = true;
        Dictionary<string, string> saved;
        RmtCommonStyles.Values.TryGetValue(selected, out saved);
        var next = saved == null ? new Dictionary<string, string>() : new Dictionary<string, string>(saved);
        try
        {
            foreach (var check in chromeChecks)
                next[check.Key] = check.Value.IsChecked == true ? "True" : "False";
            TextBox padBox;
            if (inputs.TryGetValue("Padding", out padBox))
            {
                string value = padBox.Text.Trim();
                if (string.IsNullOrEmpty(value) || (padBox.Tag as string) == "inherit") next.Remove("Padding");
                else
                {
                    RmtCommonStyles.ConvertValue(typeof(Thickness), value);
                    next["Padding"] = value;
                }
            }
            RmtCommonStyles.Values[selected] = next;
            dirty = true;
            ShowWindowPreview();
            if (rerender || LiveInspecting()) RmtCommonStyles.Refresh();
            status.Text = rerender ? "已保存并应用到正式界面。" : (LiveInspecting() ? "已实时应用到选中控件。" : "预览已更新；点击“应用并重启”后才会影响正式界面。");
            return true;
        }
        catch (Exception ex) { status.Text = "未应用：" + ex.Message; return false; }
        finally { applying = false; }
    }

    // Retained for the test hook and explicit final application path.
    private bool Apply() { return Commit(true); }

    private bool Commit(bool rerender)
    {
        if (rendering || applying || selected == null || sample == null) return false;
        if (notices.ContainsKey(selected)) { status.Text = "此项为特殊界面的来源登记，未接入通用 WPF 属性编辑。"; return false; }
        if (RmtCommonStyles.IsWindowKey(selected)) return CommitWindow(rerender);
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
            foreach (var input in sliderInputs)
                next[input.Key] = input.Key == "Opacity" ? input.Value.Value.ToString("0.00", CultureInfo.InvariantCulture) : input.Value.Value.ToString("0", CultureInfo.InvariantCulture);
            foreach (var input in dimensionInputs)
            {
                string value = input.Value.Text.Trim();
                if (string.IsNullOrEmpty(value)) { next.Remove(input.Key); continue; }
                if (value == "无限") value = "Infinity";
                double number;
                if (!double.TryParse(value, NumberStyles.Float, CultureInfo.InvariantCulture, out number) || number < 0)
                    throw new ArgumentException(input.Key + " 请输入非负数或选择无限。");
                next[input.Key] = value;
            }
            foreach (var input in optionInputs)
            {
                var item = input.Value.SelectedItem as ComboBoxItem;
                string value = item == null ? "" : (item.Tag as string ?? "");
                if (input.Key == "SizeMode") continue;
                if (string.IsNullOrEmpty(value)) next.Remove(input.Key); else next[input.Key] = value;
            }
            foreach (var input in presetInputs)
            {
                if (!input.Value.IsEnabled) continue;
                string value = ComboText(input.Value);
                if (string.IsNullOrWhiteSpace(value)) { next.Remove(input.Key); continue; }
                var dp = RmtCommonStyles.Property(sample, input.Key);
                if (dp != null) RmtCommonStyles.ConvertValue(dp.PropertyType, value);
                next[input.Key] = value;
            }
            foreach (var input in colorInputs)
            {
                if (!input.Value.IsEnabled) continue;
                var item = input.Value.SelectedItem as ComboBoxItem;
                string value = item == null ? "" : (item.Tag as string ?? "");
                if (string.IsNullOrEmpty(value)) next.Remove(input.Key); else next[input.Key] = value;
            }
            string mode = "固定宽高";
            ComboBox modeInput;
            if (optionInputs.TryGetValue("SizeMode", out modeInput) && modeInput.SelectedItem is ComboBoxItem)
                mode = ((ComboBoxItem)modeInput.SelectedItem).Tag as string ?? mode;
            next["SizeMode"] = mode;
            if (mode == "自适应宽高")
            {
                next["Width"] = "Auto"; next["Height"] = "Auto";
            }
            else if (mode == "自适应宽度")
            {
                next["Width"] = "Auto"; next.Remove("MinHeight"); next.Remove("MaxHeight");
            }
            else if (mode == "自适应高度")
            {
                next["Height"] = "Auto"; next.Remove("MinWidth"); next.Remove("MaxWidth");
            }
            else
            {
                string size;
                if (next.TryGetValue("Width", out size) && size == "Auto") next.Remove("Width");
                if (next.TryGetValue("Height", out size) && size == "Auto") next.Remove("Height");
                next.Remove("MinWidth"); next.Remove("MinHeight"); next.Remove("MaxWidth"); next.Remove("MaxHeight");
            }
            RmtCommonStyles.Values[selected] = next;
            dirty = true;
            // Edits are staged in the configuration dictionary.  Only this window's cloned
            // target preview is redrawn; live application controls stay untouched until save.
            preview.Children.Clear(); ShowPreview(sample);
            if (rerender || LiveInspecting()) RmtCommonStyles.Refresh();
            status.Text = rerender ? "已保存并应用到正式界面。" : (LiveInspecting() ? "已实时应用到选中控件。" : "预览已更新；点击“应用并重启”后才会影响正式界面。"); return true;
        }
        catch (Exception ex) { status.Text = "未应用：" + ex.Message; return false; }
        finally { applying = false; }
    }
}

internal sealed class RmtHighlightAdorner : Adorner
{
    private readonly Pen borderPen;
    private readonly Brush fillBrush;

    public RmtHighlightAdorner(UIElement adornedElement) : base(adornedElement)
    {
        IsHitTestVisible = false;
        fillBrush = new SolidColorBrush(Color.FromArgb(40, 255, 140, 0));
        fillBrush.Freeze();
        borderPen = new Pen(new SolidColorBrush(Color.FromRgb(255, 140, 0)), 2);
        borderPen.Freeze();
    }

    protected override void OnRender(DrawingContext drawingContext)
    {
        drawingContext.DrawRectangle(fillBrush, borderPen, new Rect(AdornedElement.RenderSize));
    }
}
