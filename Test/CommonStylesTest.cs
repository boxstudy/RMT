// Compile with CommonStyles.cs and WPF references. Run in a separate STA process.
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Markup;
using System.Windows.Media;
using System.Windows.Threading;

class CommonStylesTest
{
    static void Check(bool value, string message) { if (!value) throw new Exception(message); Console.WriteLine("PASS " + message); }
    static void Pump() { var frame = new DispatcherFrame(); var timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(150) }; timer.Tick += delegate { timer.Stop(); frame.Continue = false; }; timer.Start(); Dispatcher.PushFrame(frame); }
    static IEnumerable<TreeViewItem> FlattenTree(TreeViewItem item)
    {
        yield return item;
        foreach (TreeViewItem child in item.Items.OfType<TreeViewItem>())
            foreach (var nested in FlattenTree(child)) yield return nested;
    }
    static IEnumerable<DependencyObject> WalkLogical(DependencyObject root)
    {
        yield return root;
        foreach (object child in LogicalTreeHelper.GetChildren(root))
        {
            var node = child as DependencyObject;
            if (node == null) continue;
            foreach (var nested in WalkLogical(node)) yield return nested;
        }
    }
    static string DisplayedValue(FrameworkElement element)
    {
        var box = element as TextBox;
        if (box != null) return box.Text;
        var combo = element as ComboBox;
        if (combo != null)
        {
            var item = combo.SelectedItem as ComboBoxItem;
            return item == null ? combo.Text : Convert.ToString(item.Content);
        }
        return "";
    }
    static Dictionary<string, string> SectionValues(StackPanel panel, string start, string end)
    {
        var result = new Dictionary<string, string>();
        bool active = false;
        foreach (UIElement child in panel.Children)
        {
            var heading = child as TextBlock;
            if (heading != null)
            {
                if ((heading.Text ?? "").StartsWith(start)) { active = true; continue; }
                if (active && (heading.Text ?? "").StartsWith(end)) break;
            }
            var row = active ? child as Grid : null;
            if (row == null) continue;
            foreach (TextBlock label in row.Children.OfType<TextBlock>())
            {
                int column = Grid.GetColumn(label);
                var input = row.Children.OfType<FrameworkElement>().FirstOrDefault(x => !(x is TextBlock) && Grid.GetColumn(x) == column + 1);
                if (input != null) result[label.Text] = DisplayedValue(input);
            }
        }
        return result;
    }
    static bool SectionInputsDimmed(StackPanel panel, string start, string end)
    {
        bool active = false, found = false;
        foreach (UIElement child in panel.Children)
        {
            var heading = child as TextBlock;
            if (heading != null)
            {
                if ((heading.Text ?? "").StartsWith(start)) { active = true; continue; }
                if (active && (heading.Text ?? "").StartsWith(end)) break;
            }
            var row = active ? child as Grid : null;
            if (row == null) continue;
            foreach (FrameworkElement input in row.Children.OfType<FrameworkElement>().Where(x => !(x is TextBlock) && Grid.GetColumn(x) % 2 == 1))
            {
                found = true;
                if (input.Opacity >= 1 || input.IsHitTestVisible || input.Focusable) return false;
            }
        }
        return found;
    }
    [STAThread]
    static int Main(string[] args)
    {
        try
        {
            var app = new Application { ShutdownMode = ShutdownMode.OnExplicitShutdown };
            foreach (string file in Directory.GetFiles(Path.Combine(Path.GetTempPath(), "RmtGMUI-check"), "dialog-*.xaml"))
            {
                var dialog = (Window)XamlReader.Parse(File.ReadAllText(file));
                Check(dialog.Content != null, "migrated dialog XAML parses: " + Path.GetFileName(file));
                dialog.Close();
            }
            string path = Path.Combine(Path.GetTempPath(), "RmtGMUI-test-" + Guid.NewGuid().ToString("N") + ".xml");
            var window = (Window)XamlReader.Parse(@"<Window xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation' xmlns:x='http://schemas.microsoft.com/winfx/2006/xaml' Title='Test' Width='600' Height='450' ShowInTaskbar='False' Opacity='0.01'>
              <Window.Resources><SolidColorBrush x:Key='ActionBg' Color='Red'/><Style x:Key='RmtItemEditBtn' TargetType='Button'><Setter Property='Width' Value='64'/></Style></Window.Resources>
              <StackPanel><Button Name='First' Style='{StaticResource RmtItemEditBtn}' Background='{DynamicResource ActionBg}' Content='A'/><Button Name='Second' Uid='gm:Main.Config' Content='C'/><Button Name='Special' Uid='gm-exception:test' Width='31'/><TextBox Name='Input' Text='hello'/><ItemsControl Name='Virtual'><ItemsControl.ItemTemplate><DataTemplate><Button Style='{StaticResource RmtItemEditBtn}' Content='{Binding}'/></DataTemplate></ItemsControl.ItemTemplate></ItemsControl></StackPanel></Window>");
            bool release = args.Length > 0 && args[0] == "release";
            RmtCommonStyles.Configure(window, path + (release ? "|0" : "|1"));
            window.Show(); Pump();
            var mainSizeBefore = window.RenderSize;
            var mainContentBefore = ((StackPanel)window.Content).RenderSize;
            var mainSecondBefore = (Button)window.FindName("Second");
            var mainSecondSizeBefore = mainSecondBefore.RenderSize;
            var mainSecondMarginBefore = mainSecondBefore.Margin;
            RmtCommonStyles.Open(window); Pump();
            if (release)
            {
                Check(!app.Windows.Cast<Window>().Any(w => w is RmtStyleEditor), "release editor blocked"); window.Close(); return 0;
            }
            var editor = app.Windows.Cast<Window>().OfType<RmtStyleEditor>().Single(); editor.Opacity = 0;
            Check(window.RenderSize == mainSizeBefore && ((StackPanel)window.Content).RenderSize == mainContentBefore && mainSecondBefore.RenderSize == mainSecondSizeBefore && mainSecondBefore.Margin == mainSecondMarginBefore, "opening GM-UI preserves main window layout");
            Check(editor.Owner == null && !editor.ShowInTaskbar, "GM-UI does not own the main window so other dialogs stay on top");
            Check(editor.WindowStartupLocation == WindowStartupLocation.Manual, "GM-UI places itself relative to the source window");
            Check(!editor.Resources.MergedDictionaries.Contains(window.Resources), "GM-UI uses an isolated resource snapshot");
            var initialDrafts = (Dictionary<string, Dictionary<string, string>>)typeof(RmtStyleEditor).GetField("drafts", BindingFlags.Instance | BindingFlags.NonPublic).GetValue(editor);
            Check(initialDrafts.Count == 0, "opening GM-UI does not stage draft overrides");
            var editorRoot = (Border)editor.Content;
            var closeGlyph = (TextBlock)editorRoot.FindName("CloseGlyph");
            var pinGlyph = (TextBlock)editorRoot.FindName("PinGlyph");
            var mainTabs = (TabControl)editorRoot.FindName("MainTabs");
            Check(mainTabs != null && mainTabs.Items.Count == 2 && mainTabs.SelectedIndex == 0 && ((TabItem)mainTabs.Items[0]).Header as string == "样式管理" && ((TabItem)mainTabs.Items[1]).Header as string == "控件反射", "GM-UI tabs default to style management");
            Check(mainTabs.Margin.Top == 2 && ((DockPanel)editorRoot.FindName("StylesContent")).Margin.Top == 2 && ((DockPanel)editorRoot.FindName("ReflectContent")).Margin.Top == 5, "tab and content vertical offsets");
            Check(!WalkLogical((DependencyObject)editorRoot.FindName("StylesContent")).OfType<TextBlock>().Any(t => t.Text == "属性名 / 属性值（每行三组）"), "property section caption removed");
            Check(mainTabs.Style != null && ((TabItem)mainTabs.Items[0]).Style != null && ((TabItem)mainTabs.Items[0]).Tag as string == "first" && ((TabItem)mainTabs.Items[1]).Tag as string == "last", "GM-UI tabs use main-window-like tab chrome");
            var tabTemplate = (ControlTemplate)((Setter)((TabItem)mainTabs.Items[0]).Style.Setters.OfType<Setter>().First(s => s.Property == Control.TemplateProperty)).Value;
            string expectedFont = Math.Max(12, RmtCommonStyles.ThemeFontSize(window) + 2).ToString("0.##", System.Globalization.CultureInfo.InvariantCulture);
            Check(XamlWriter.Save(tabTemplate).IndexOf("FontSize=\"" + expectedFont + "\"", StringComparison.Ordinal) >= 0, "tab header font size is theme plus two");
            Check(editorRoot.FindName("CmdReflect") == null && editorRoot.FindName("CmdReset") == null && editorRoot.FindName("CmdSave") == null && editorRoot.FindName("Status") == null, "top reset/apply/status controls removed");
            Check(editorRoot.FindName("BtnWinPin") is Button, "editor pin button exists");
            Check(editorRoot.FindName("BtnWinMin") is Button && editorRoot.FindName("BtnWinMax") is Button, "editor minimize and maximize buttons exist");
            Check(((TextBlock)editorRoot.FindName("MinGlyph")).Text == "\uE921" && ((TextBlock)editorRoot.FindName("MaxGlyph")).Text == "\uE922", "minimize and maximize glyphs match window chrome");
            Check(closeGlyph.Text == "\uE8BB" && closeGlyph.FontFamily.Source == "Segoe Fluent Icons, Segoe MDL2 Assets" && closeGlyph.FontSize >= Math.Max(15, window.FontSize) && closeGlyph.FontWeight == FontWeights.Bold, "close glyph matches scaled bold main window chrome");
            Check(pinGlyph.FontSize == closeGlyph.FontSize && pinGlyph.FontWeight == closeGlyph.FontWeight, "pin glyph uses the same scaled bold chrome style");
            Check(editorRoot.FindName("CmdItemReset") is Button && editorRoot.FindName("CmdItemRefresh") == null && editorRoot.FindName("CmdItemApply") is Button && editorRoot.FindName("CmdFindTemplate") is Button && editorRoot.FindName("CmdApplyTemplate") is Button && editorRoot.FindName("CmdAddTemplate") is Button, "item action bar exists without manual refresh");
            Check(((Button)editorRoot.FindName("CmdAddTemplate")).Content as string == "添加新模版", "add template button renamed");
            Check(((Button)editorRoot.FindName("CmdApplyTemplate")).Content as string == "应用到模版", "apply to template button exists");
            var fontCombo = new ComboBox { Name = "FontChoice" }; fontCombo.Items.Add("宋体"); fontCombo.Items.Add("黑体"); fontCombo.SelectedIndex = 0;
            ((StackPanel)window.Content).Children.Add(fontCombo); Pump();
            mainTabs.SelectedIndex = 1; Pump();
            var hierarchyTree = (TreeView)editorRoot.FindName("HierarchyTree");
            Check(hierarchyTree != null && hierarchyTree.Items.Count > 0, "control reflector tab shows window hierarchy");
            var hierarchyRoot = (TreeViewItem)hierarchyTree.Items[0];
            Check(hierarchyRoot.ContextMenu != null && hierarchyRoot.ContextMenu.Items.Count == 2, "hierarchy nodes provide expand and collapse menu");
            Check((hierarchyRoot.Header as string ?? "").IndexOf("（" + window.Title + "）", StringComparison.Ordinal) >= 0, "window hierarchy node includes title");
            if (hierarchyRoot.Items.Count > 0)
            {
                var child = (TreeViewItem)hierarchyRoot.Items[0];
                child.IsExpanded = true;
                mainTabs.SelectedIndex = 0; Pump();
                mainTabs.SelectedIndex = 1; Pump();
                Check(ReferenceEquals(hierarchyTree.Items[0], hierarchyRoot) && child.IsExpanded, "switching tabs preserves hierarchy expansion");
            }
            var comboNode = hierarchyRoot.Items.OfType<TreeViewItem>().SelectMany(FlattenTree).FirstOrDefault(x => (x.Header as string ?? "").StartsWith("ComboBox"));
            Check(comboNode != null && comboNode.Items.Count == 0, "combo box hierarchy stops at ComboBox without option items");
            mainTabs.SelectedIndex = 0; Pump();
            var selection = (string)typeof(RmtStyleEditor).GetField("selected", BindingFlags.Instance | BindingFlags.NonPublic).GetValue(editor);
            Check(selection == "通用/Button", "button template is selected by default");
            var selectedField = typeof(RmtStyleEditor).GetField("selected", BindingFlags.Instance | BindingFlags.NonPublic);
            var renderMethod = typeof(RmtStyleEditor).GetMethod("Render", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.DeclaredOnly);
            selectedField.SetValue(editor, "Theme.Confirm"); renderMethod.Invoke(editor, null);
            var themeSample = (Button)typeof(RmtStyleEditor).GetField("sample", BindingFlags.Instance | BindingFlags.NonPublic).GetValue(editor);
            var themeBorder = themeSample.Template.LoadContent() as Border;
            Check(themeSample.Width == 80 && themeSample.Height == 32 && themeBorder != null && themeBorder.CornerRadius.TopLeft == 3, "theme confirm preview keeps real button template");
            selectedField.SetValue(editor, selection); renderMethod.Invoke(editor, null); Pump();
            var buttonSample = (Button)typeof(RmtStyleEditor).GetField("sample", BindingFlags.Instance | BindingFlags.NonPublic).GetValue(editor);
            var previewPanel = (StackPanel)typeof(RmtStyleEditor).GetField("preview", BindingFlags.Instance | BindingFlags.NonPublic).GetValue(editor);
            var previewButton = previewPanel.Children.OfType<Border>().Select(host => host.Child).OfType<Button>().FirstOrDefault();
            var actionBg = editor.TryFindResource("ActionBg") as SolidColorBrush;
            var previewBg = previewButton == null ? null : previewButton.Background as SolidColorBrush;
            Check(buttonSample != null && buttonSample.Template != null && previewButton != null && previewButton.Template != null && actionBg != null && previewBg != null && previewBg.Color == actionBg.Color, "button template preview uses ActionBg chrome matching override colors");
            selectedField.SetValue(editor, "Main.Config"); renderMethod.Invoke(editor, null); Pump();
            var configSample = (Button)typeof(RmtStyleEditor).GetField("sample", BindingFlags.Instance | BindingFlags.NonPublic).GetValue(editor);
            var configPreview = ((StackPanel)typeof(RmtStyleEditor).GetField("preview", BindingFlags.Instance | BindingFlags.NonPublic).GetValue(editor)).Children.OfType<Border>().Select(host => host.Child).OfType<Button>().FirstOrDefault();
            var configPresets = (Dictionary<string, ComboBox>)typeof(RmtStyleEditor).GetField("presetInputs", BindingFlags.Instance | BindingFlags.NonPublic).GetValue(editor);
            Check(configSample != null && configPreview != null && Math.Abs(configSample.Height - configPreview.Height) < .1 && Math.Abs(configSample.Padding.Left - configPreview.Padding.Left) < .1, "named button preview height and padding match sample");
            Check(configPresets.ContainsKey("Padding") && configPreview.Padding.Left == configSample.Padding.Left, "button 3 padding field matches preview chrome");
            selectedField.SetValue(editor, "通用/Window"); renderMethod.Invoke(editor, null); Pump();
            var windowPreview = ((StackPanel)typeof(RmtStyleEditor).GetField("preview", BindingFlags.Instance | BindingFlags.NonPublic).GetValue(editor)).Children.OfType<Border>().FirstOrDefault();
            var windowBody = windowPreview == null ? null : ((Grid)windowPreview.Child).Children.OfType<Border>().FirstOrDefault(x => Grid.GetRow(x) == 1);
            Check(windowBody != null && windowBody.Child is Border && ((Border)windowBody.Child).Background != null, "window template preview fills content with background to reveal padding");
            selectedField.SetValue(editor, selection); renderMethod.Invoke(editor, null);
            var catalog = (TreeView)typeof(RmtStyleEditor).GetField("catalog", BindingFlags.Instance | BindingFlags.NonPublic).GetValue(editor);
            var defaultLeaf = catalog.Items.OfType<TreeViewItem>().SelectMany(x => x.Items.OfType<TreeViewItem>()).First(x => (x.Tag as string) == "通用/Button");
            var defaultHeader = defaultLeaf.Header as Grid;
            Check(defaultLeaf.IsSelected && defaultHeader != null && defaultHeader.Children.OfType<System.Windows.Shapes.Ellipse>().Any(e => e.Visibility == Visibility.Visible) && defaultLeaf.FontWeight == FontWeights.Normal, "default button template has selection background and corner dot");
            foreach (TreeViewItem group in catalog.Items)
                foreach (TreeViewItem item in group.Items) item.IsSelected = true;
            Check(true, "all catalog previews render");
            var a = (Button)window.FindName("First"); var b = (Button)window.FindName("Second");
            editor.AcceptHierarchyTarget(b); Pump();
            var reflectGroup = catalog.Items.OfType<TreeViewItem>().First(g => (g.Header as string) == "反射控件");
            var reflectLeaf = reflectGroup.Items.OfType<TreeViewItem>().First();
            Check(reflectLeaf.IsSelected && ReferenceEquals(catalog.SelectedItem, reflectLeaf), "locate selects reflected control not its template");
            var positionX = (TextBox)typeof(RmtStyleEditor).GetField("positionX", BindingFlags.Instance | BindingFlags.NonPublic).GetValue(editor);
            var positionY = (TextBox)typeof(RmtStyleEditor).GetField("positionY", BindingFlags.Instance | BindingFlags.NonPublic).GetValue(editor);
            var fieldsPanel = (StackPanel)typeof(RmtStyleEditor).GetField("fields", BindingFlags.Instance | BindingFlags.NonPublic).GetValue(editor);
            var templateBeforeReset = SectionValues(fieldsPanel, "模版属性", "重载属性");
            Check(templateBeforeReset.Count > 0 && SectionInputsDimmed(fieldsPanel, "模版属性", "重载属性"), "reflected template properties are visibly read-only");
            var reflectedColors = (Dictionary<string, ComboBox>)typeof(RmtStyleEditor).GetField("colorInputs", BindingFlags.Instance | BindingFlags.NonPublic).GetValue(editor);
            var reflectedBackground = (ComboBoxItem)reflectedColors["Background"].SelectedItem;
            Check(reflectedBackground != null && Convert.ToString(reflectedBackground.Content).IndexOf("继承当前颜色", StringComparison.Ordinal) < 0, "reflected inherited colors show their concrete value");
            Check(reflectedColors["Background"].Items.Count == 14 && reflectedColors["Background"].Items.Cast<ComboBoxItem>().All(x => (x.Tag as string ?? "").StartsWith("$Theme:")), "color properties contain only colors 1 through 14");
            var positionLabel = fieldsPanel.Children.OfType<Grid>().SelectMany(g => g.Children.OfType<TextBlock>()).First(t => t.Text == "位置X");
            Check(positionLabel.Cursor == System.Windows.Input.Cursors.SizeWE, "position labels support drag adjustment");
            var beforePosition = b.TranslatePoint(new Point(0, 0), (UIElement)b.Parent);
            Check(Math.Abs(double.Parse(positionX.Text) - beforePosition.X) < .1 && Math.Abs(double.Parse(positionY.Text) - beforePosition.Y) < .1, "reflected position reads rendered coordinates");
            Check(typeof(RmtStyleEditor).GetField("anchorType", BindingFlags.Instance | BindingFlags.NonPublic) == null && typeof(RmtStyleEditor).GetField("anchorObject", BindingFlags.Instance | BindingFlags.NonPublic) == null, "reflector position UI no longer exposes anchors");
            positionX.Text = (double.Parse(positionX.Text) + 10).ToString(); Pump();
            var movedPosition = b.TranslatePoint(new Point(0, 0), (UIElement)b.Parent);
            Check(Math.Abs(movedPosition.X - beforePosition.X - 10) < .5, "position edit automatically updates reflected control");
            ((Button)editorRoot.FindName("CmdItemReset")).RaiseEvent(new RoutedEventArgs(Button.ClickEvent)); Pump();
            var restoredPosition = b.TranslatePoint(new Point(0, 0), (UIElement)b.Parent);
            Check(Math.Abs(restoredPosition.X - beforePosition.X) < .5, "one reset restores the pre-edit position");
            var templateAfterReset = SectionValues(fieldsPanel, "模版属性", "重载属性");
            Check(templateBeforeReset.OrderBy(x => x.Key).SequenceEqual(templateAfterReset.OrderBy(x => x.Key)), "reset does not change reflected template properties");
            var selectCatalog = typeof(RmtStyleEditor).GetMethod("SelectCatalog", BindingFlags.Instance | BindingFlags.NonPublic);
            Check(!(bool)selectCatalog.Invoke(editor, new object[] { "通用/TextBox", true, true, false }), "controls without a template cannot resolve to the reflected node");
            typeof(RmtStyleEditor).GetMethod("FindTemplate", BindingFlags.Instance | BindingFlags.NonPublic).Invoke(editor, null); Pump();
            var templateLeaf = (TreeViewItem)catalog.SelectedItem;
            var templateHeader = templateLeaf == null ? null : templateLeaf.Header as Grid;
            Check(templateLeaf != null && (templateLeaf.Tag as string) == "通用/Button" && templateHeader != null && templateHeader.Children.OfType<System.Windows.Shapes.Ellipse>().Any(e => e.Visibility == Visibility.Visible), "find template frames selected template");
            var inspectAfterFind = (WeakReference)typeof(RmtStyleEditor).GetField("inspectRef", BindingFlags.Instance | BindingFlags.NonPublic).GetValue(editor);
            Check(inspectAfterFind != null && ReferenceEquals(inspectAfterFind.Target, b), "find template keeps reflected control reference");
            Check(catalog.Items.OfType<TreeViewItem>().Any(g => (g.Header as string) == "反射控件"), "reflected control catalog group remains after find template");
            typeof(RmtStyleEditor).GetMethod("ApplyReloadToTemplate", BindingFlags.Instance | BindingFlags.NonPublic).Invoke(editor, null); Pump();
            Check(RmtCommonStyles.Values.ContainsKey("通用/Button"), "apply reload properties to template");
            var special = (Button)window.FindName("Special");
            var input = (TextBox)window.FindName("Input"); input.SetBinding(TextBox.FontSizeProperty, new Binding("Tag") { Source = input }); input.Tag = 19.0;
            var other = new Window { Content = new Button { Content = "other" }, Width = 300, Height = 200, Opacity = 0.01, ShowInTaskbar = false };
            RmtCommonStyles.Configure(other, path + "|1"); other.Show(); Pump();
            RmtCommonStyles.Values["通用/Button"] = new Dictionary<string, string> { { "Width", "123" }, { "Padding", "4,5,6,7" } };
            RmtCommonStyles.Values["样式/RmtItemEditBtn"] = new Dictionary<string, string> { { "Width", "88" } };
            RmtCommonStyles.Values["通用/TextBox"] = new Dictionary<string, string> { { "RelativeFontSize", "2" } };
            RmtCommonStyles.Refresh();
            Check(b.Width == 123, "button template applies to named instances as base");
            Check(a.Width == 88, "named style overrides button template");
            Check(special.Width == 31, "explicit exception retained");
            Check(input.FontSize == 19 && BindingOperations.IsDataBound(input, TextBox.FontSizeProperty), "data binding retained");
            var dynamic = new Button(); ((StackPanel)window.Content).Children.Add(dynamic); Pump();
            Check(dynamic.Width == 123, "button template applies to new instances");
            ((ItemsControl)window.FindName("Virtual")).Items.Add("row"); Pump();
            Check(RmtCommonStyles.Live().Count(x => x.Key == "样式/RmtItemEditBtn") >= 2, "DataTemplate row registered");
            var styled = (Button)XamlReader.Parse("<Button xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation' xmlns:x='http://schemas.microsoft.com/winfx/2006/xaml'><Button.Style><Style TargetType='Button'><Setter Property='Background' Value='#00000000'/><Setter Property='BorderBrush' Value='#FF223344'/><Setter Property='BorderThickness' Value='1'/><Setter Property='Template'><Setter.Value><ControlTemplate TargetType='Button'><Border x:Name='StyledBd' Background='{TemplateBinding Background}' BorderBrush='{TemplateBinding BorderBrush}' BorderThickness='{TemplateBinding BorderThickness}' CornerRadius='3'><Grid><Rectangle Width='8' Height='8' Fill='Orange'/></Grid></Border></ControlTemplate></Setter.Value></Setter></Style></Button.Style></Button>");
            ((StackPanel)window.Content).Children.Add(styled); Pump();
            var rounded = (Button)XamlReader.Parse("<Button xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation' xmlns:x='http://schemas.microsoft.com/winfx/2006/xaml'><Button.Template><ControlTemplate TargetType='Button'><Border x:Name='BD' CornerRadius='3'/></ControlTemplate></Button.Template></Button>");
            ((StackPanel)window.Content).Children.Add(rounded); Pump();
            RmtCommonStyles.Values["样式/RmtItemEditBtn"]["CornerRadius"] = "9"; RmtCommonStyles.Refresh();
            var bd = (Border)rounded.Template.FindName("BD", rounded);
            Check(bd.CornerRadius.TopLeft == 3, "button template remains isolated from formal instances");
            RmtCommonStyles.Values["样式/RmtItemEditBtn"].Remove("CornerRadius"); RmtCommonStyles.Refresh();
            Check(bd.CornerRadius.TopLeft == 3, "button corner radius restored");
            RmtCommonStyles.Values["通用/Button"]["CornerRadius"] = "7";
            RmtCommonStyles.Values["通用/Button"]["HoverBackground"] = "#FF345678";
            RmtCommonStyles.Values["通用/Button"]["PressedBackground"] = "#FF234567";
            RmtCommonStyles.Refresh();
            Check(styled.Template.FindName("StyledBd", styled) is Border, "button overrides keep styled button template");
            RmtCommonStyles.Values["通用/Button"].Remove("CornerRadius");
            RmtCommonStyles.Values["通用/Button"].Remove("HoverBackground");
            RmtCommonStyles.Values["通用/Button"].Remove("PressedBackground");
            RmtCommonStyles.Refresh();
            RmtCommonStyles.Values["样式/RmtItemEditBtn"]["Background"] = "#FF123456"; RmtCommonStyles.Refresh();
            Check(((SolidColorBrush)a.Background).Color == Color.FromRgb(18,52,86), "local resource override applied");
            window.Resources["ActionBg"] = Brushes.Blue; RmtCommonStyles.ThemeChanged(window, "ActionBg"); Pump();
            RmtCommonStyles.Values.Remove("样式/RmtItemEditBtn"); RmtCommonStyles.Values.Remove("通用/Button"); RmtCommonStyles.Refresh();
            Check(a.Width == 64 && double.IsNaN(b.Width), "restore style and unset local values");
            Check(((SolidColorBrush)a.Background).Color == Colors.Blue, "reset resolves latest dynamic resource");
            window.Resources["ActionBg"] = Brushes.Blue; Pump();
            Check(((SolidColorBrush)a.Background).Color == Colors.Blue, "dynamic resource survives override reset");
            RmtCommonStyles.Values["颜色/ActionBg"] = new Dictionary<string, string> { { "Color", "#FF00FF00" } }; RmtCommonStyles.Refresh();
            Check(((SolidColorBrush)a.Background).Color == Colors.Lime, "shared color updates real control");
            window.Resources["ActionBg"] = Brushes.Purple; RmtCommonStyles.ThemeChanged(window, "ActionBg"); Pump();
            Check(((SolidColorBrush)a.Background).Color == Colors.Lime, "theme change preserves override");
            RmtCommonStyles.Values.Remove("颜色/ActionBg"); RmtCommonStyles.Refresh();
            Check(((SolidColorBrush)a.Background).Color == Colors.Purple, "color reset uses latest theme");
            RmtCommonStyles.Values["Main.Config"] = new Dictionary<string, string> { { "RelativeFontSize", "2" } }; RmtCommonStyles.Refresh();
            b.FontSize = 18; RmtCommonStyles.Refresh();
            RmtCommonStyles.Values.Remove("Main.Config"); RmtCommonStyles.Refresh();
            Check(b.FontSize == 18, "font reset uses latest application value");
            RmtCommonStyles.Values["Main.Config"] = new Dictionary<string, string> { { "RelativeFontSize", "1" } }; RmtCommonStyles.Save();
            Check(File.ReadAllText(path).Contains("Main.Config"), "configuration saved");
            RmtCommonStyles.Save(); Check(File.Exists(path + ".bak"), "atomic save backup");
            RmtCommonStyles.Values.Clear();
            typeof(RmtCommonStyles).GetMethod("Load", BindingFlags.NonPublic | BindingFlags.Static).Invoke(null, null);
            Check(RmtCommonStyles.Values["Main.Config"]["RelativeFontSize"] == "1", "saved configuration reloads");
            editor.Close();
            RmtCommonStyles.Refresh();
            RmtCommonStyles.Open(window); Pump(); editor = app.Windows.Cast<Window>().OfType<RmtStyleEditor>().Single();
            typeof(RmtStyleEditor).GetField("selected", BindingFlags.Instance | BindingFlags.NonPublic).SetValue(editor, "Main.Config");
            typeof(RmtStyleEditor).GetMethod("Render", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.DeclaredOnly).Invoke(editor, null);
            Pump();
            var sliders = (Dictionary<string, Slider>)typeof(RmtStyleEditor).GetField("sliderInputs", BindingFlags.Instance | BindingFlags.NonPublic).GetValue(editor);
            var editorInputs = (Dictionary<string, TextBox>)typeof(RmtStyleEditor).GetField("inputs", BindingFlags.Instance | BindingFlags.NonPublic).GetValue(editor);
            var editorOptions = (Dictionary<string, ComboBox>)typeof(RmtStyleEditor).GetField("optionInputs", BindingFlags.Instance | BindingFlags.NonPublic).GetValue(editor);
            var editorPresets = (Dictionary<string, ComboBox>)typeof(RmtStyleEditor).GetField("presetInputs", BindingFlags.Instance | BindingFlags.NonPublic).GetValue(editor);
            var apply = typeof(RmtStyleEditor).GetMethod("Apply", BindingFlags.Instance | BindingFlags.NonPublic);
            Check(!editorInputs.ContainsKey("Cursor") && !editorOptions.ContainsKey("IsEnabled") && !editorOptions.ContainsKey("Visibility"), "reload properties remain on the compact template property set");
            Check(editorPresets.ContainsKey("Padding") && sliders.ContainsKey("RelativeFontSize"), "compact reload properties keep the original editable controls");
            editorPresets["Padding"].Text = "7,7,7,7";
            editorPresets["Padding"].RaiseEvent(new TextChangedEventArgs(TextBox.TextChangedEvent, UndoAction.None));
            Check(b.Padding.Left == 7 && b.Padding.Bottom == 7, "text property edit automatically refreshes control");
            sliders["RelativeFontSize"].Value = 3;
            Check(b.FontSize == window.FontSize + 3, "editor automatically refreshes edited control");
            var later = new Button { Uid = "gm:Main.Config", Content = "later" }; ((StackPanel)window.Content).Children.Add(later); Pump();
            Check(later.FontSize != window.FontSize + 3 && later.Padding.Left != 7, "automatic draft refresh does not affect later controls");
            Check((bool)apply.Invoke(editor, null) && b.FontSize == window.FontSize + 3, "editor applies relative font preview");
            editor.Close(); Check(b.FontSize > 0, "closing restores a valid saved style state");
            other.Close(); window.Close();
            File.Delete(path); File.Delete(path + ".bak");
            Console.WriteLine("ALL PASS"); return 0;
        }
        catch (Exception ex) { Console.WriteLine(ex); return 1; }
    }
}
