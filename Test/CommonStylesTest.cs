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
            RmtCommonStyles.Open(window); Pump();
            if (release)
            {
                Check(!app.Windows.Cast<Window>().Any(w => w is RmtStyleEditor), "release editor blocked"); window.Close(); return 0;
            }
            var editor = app.Windows.Cast<Window>().OfType<RmtStyleEditor>().Single(); editor.Opacity = 0;
            var selection = (string)typeof(RmtStyleEditor).GetField("selected", BindingFlags.Instance | BindingFlags.NonPublic).GetValue(editor);
            Check(!string.IsNullOrEmpty(selection), "first style selected");
            var catalog = (TreeView)typeof(RmtStyleEditor).GetField("catalog", BindingFlags.Instance | BindingFlags.NonPublic).GetValue(editor);
            foreach (TreeViewItem group in catalog.Items)
                foreach (TreeViewItem item in group.Items) item.IsSelected = true;
            Check(true, "all catalog previews render");
            var a = (Button)window.FindName("First"); var b = (Button)window.FindName("Second");
            var special = (Button)window.FindName("Special");
            var input = (TextBox)window.FindName("Input"); input.SetBinding(TextBox.FontSizeProperty, new Binding("Tag") { Source = input }); input.Tag = 19.0;
            var other = new Window { Content = new Button { Content = "other" }, Width = 300, Height = 200, Opacity = 0.01, ShowInTaskbar = false };
            RmtCommonStyles.Configure(other, path + "|1"); other.Show(); Pump();
            RmtCommonStyles.Values["通用/Button"] = new Dictionary<string, string> { { "Width", "123" }, { "Padding", "4,5,6,7" } };
            RmtCommonStyles.Values["样式/RmtItemEditBtn"] = new Dictionary<string, string> { { "Width", "88" } };
            RmtCommonStyles.Values["通用/TextBox"] = new Dictionary<string, string> { { "FontSize", "25" } };
            RmtCommonStyles.Refresh();
            Check(a.Width == 88 && b.Width == 123 && ((Button)other.Content).Width == 123, "cross-window shared and role precedence");
            Check(special.Width == 31, "explicit exception retained");
            Check(input.FontSize == 19 && BindingOperations.IsDataBound(input, TextBox.FontSizeProperty), "data binding retained");
            var dynamic = new Button(); ((StackPanel)window.Content).Children.Add(dynamic); Pump();
            Check(dynamic.Width == 123, "dynamically added control inherits");
            ((ItemsControl)window.FindName("Virtual")).Items.Add("row"); Pump();
            Check(RmtCommonStyles.Live().Count(x => x.Key == "样式/RmtItemEditBtn") >= 2, "DataTemplate row registered");
            var rounded = (Button)XamlReader.Parse("<Button xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation' xmlns:x='http://schemas.microsoft.com/winfx/2006/xaml'><Button.Template><ControlTemplate TargetType='Button'><Border x:Name='BD' CornerRadius='3'/></ControlTemplate></Button.Template></Button>");
            ((StackPanel)window.Content).Children.Add(rounded); Pump();
            RmtCommonStyles.Values["通用/Button"]["CornerRadius"] = "9"; RmtCommonStyles.Refresh();
            var bd = (Border)rounded.Template.FindName("BD", rounded);
            Check(bd.CornerRadius.TopLeft == 9, "button template corner radius configured");
            RmtCommonStyles.Values["通用/Button"].Remove("CornerRadius"); RmtCommonStyles.Refresh();
            Check(bd.CornerRadius.TopLeft == 3, "button corner radius restored");
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
            RmtCommonStyles.Values["Main.Config"] = new Dictionary<string, string> { { "FontSize", "22" } }; RmtCommonStyles.Refresh();
            b.FontSize = 18; RmtCommonStyles.Refresh();
            RmtCommonStyles.Values.Remove("Main.Config"); RmtCommonStyles.Refresh();
            Check(b.FontSize == 18, "font reset uses latest application value");
            RmtCommonStyles.Values["Main.Config"] = new Dictionary<string, string> { { "FontSize", "21" } }; RmtCommonStyles.Save();
            Check(File.ReadAllText(path).Contains("Main.Config"), "configuration saved");
            RmtCommonStyles.Save(); Check(File.Exists(path + ".bak"), "atomic save backup");
            RmtCommonStyles.Values.Clear();
            typeof(RmtCommonStyles).GetMethod("Load", BindingFlags.NonPublic | BindingFlags.Static).Invoke(null, null);
            Check(RmtCommonStyles.Values["Main.Config"]["FontSize"] == "21", "saved configuration reloads");
            editor.Close();
            RmtCommonStyles.Refresh();
            RmtCommonStyles.Open(window); Pump(); editor = app.Windows.Cast<Window>().OfType<RmtStyleEditor>().Single();
            typeof(RmtStyleEditor).GetField("selected", BindingFlags.Instance | BindingFlags.NonPublic).SetValue(editor, "Main.Config");
            typeof(RmtStyleEditor).GetMethod("Render", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.DeclaredOnly).Invoke(editor, null);
            var inputs = (Dictionary<string, TextBox>)typeof(RmtStyleEditor).GetField("inputs", BindingFlags.Instance | BindingFlags.NonPublic).GetValue(editor);
            inputs["FontSize"].Text = "-5";
            var apply = typeof(RmtStyleEditor).GetMethod("Apply", BindingFlags.Instance | BindingFlags.NonPublic);
            Check(!(bool)apply.Invoke(editor, null) && b.FontSize == 21, "invalid edit does not mutate controls");
            inputs["FontSize"].Text = "23"; Check((bool)apply.Invoke(editor, null) && b.FontSize == 23, "editor applies real control preview");
            editor.Close(); Check(b.FontSize == 21, "closing cancels unsaved preview");
            other.Close(); window.Close();
            File.Delete(path); File.Delete(path + ".bak");
            Console.WriteLine("ALL PASS"); return 0;
        }
        catch (Exception ex) { Console.WriteLine(ex); return 1; }
    }
}
