// =============================================================================
// WebView2 commands (ENABLE_WEBVIEW)
// =============================================================================
#if ENABLE_WEBVIEW

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

#if ENABLE_WEBVIEW
using Microsoft.Web.WebView2.Wpf;
using Microsoft.Web.WebView2.Core;
#endif
public partial class AhkWpfEngine
{
    private System.Collections.Generic.Dictionary<string, string> _initialWebViewSources = new System.Collections.Generic.Dictionary<string, string>();

    private void PreprocessXamlAndExtractWebViewSources(ref string xaml)
    {
        if (string.IsNullOrEmpty(xaml)) return;
        try
        {
            var logPath = GetLogPath("AhkWebViewDebug.log");
            System.IO.File.AppendAllText(logPath, "PreprocessXamlAndExtractWebViewSources called. XAML Length: " + xaml.Length + "\n");
            
            var regex = new System.Text.RegularExpressions.Regex(@"<wv2:WebView2\b[^>]*>", System.Text.RegularExpressions.RegexOptions.IgnoreCase);
            xaml = regex.Replace(xaml, (System.Text.RegularExpressions.Match match) =>
            {
                string tag = match.Value;
                System.IO.File.AppendAllText(logPath, "Found tag: " + tag + "\n");
                
                var nameMatch = System.Text.RegularExpressions.Regex.Match(tag, @"\b(?:x:)?Name\s*=\s*""([^""]*)""", System.Text.RegularExpressions.RegexOptions.IgnoreCase);
                var sourceMatch = System.Text.RegularExpressions.Regex.Match(tag, @"\bSource\s*=\s*""([^""]*)""", System.Text.RegularExpressions.RegexOptions.IgnoreCase);
                
                if (nameMatch.Success && sourceMatch.Success)
                {
                    string name = nameMatch.Groups[1].Value;
                    string source = sourceMatch.Groups[1].Value;
                    
                    _initialWebViewSources[name] = source;
                    System.IO.File.AppendAllText(logPath, "Successfully extracted Name='" + name + "', Source='" + source + "'\n");
                    
                    tag = System.Text.RegularExpressions.Regex.Replace(tag, @"\bSource\s*=\s*""[^""]*""\s*", "", System.Text.RegularExpressions.RegexOptions.IgnoreCase);
                }
                else
                {
                    System.IO.File.AppendAllText(logPath, "Tag mismatch: NameMatch=" + nameMatch.Success + ", SourceMatch=" + sourceMatch.Success + "\n");
                }
                return tag;
            });
        }
        catch (Exception ex)
        {
            try { System.IO.File.AppendAllText(GetLogPath("AhkWebViewDebug.log"), "Regex Error: " + ex.ToString() + "\n"); } catch {}
        }
    }

    private void ConfigureWebView2CreationProperties(Window win)
    {
        try
        {
            string customDir = Environment.GetEnvironmentVariable("AHK_XAML_WEBVIEW_DIR");
            string wvDataDir = !string.IsNullOrEmpty(customDir) ? customDir : System.IO.Path.Combine(GetLogDir(), "WebView2Data");
            
            WalkLogicalOrVisualTree(win, (DependencyObject d) =>
            {
                if (d is Microsoft.Web.WebView2.Wpf.WebView2)
                {
                    var wv = (Microsoft.Web.WebView2.Wpf.WebView2)d;
                    if (wv.CreationProperties == null)
                    {
                        wv.CreationProperties = new Microsoft.Web.WebView2.Wpf.CoreWebView2CreationProperties
                        {
                            UserDataFolder = wvDataDir
                        };
                    }
                }
            });
        }
        catch { }
    }

    private async void InitializeWebView2IfPresent(Window win)
    {
        try
        {
            var webViews = new System.Collections.Generic.List<WebView2>();
            WalkVisualTree(win, (obj) => {
                if (obj is WebView2) {
                    webViews.Add((WebView2)obj);
                }
            });
            if (webViews.Count == 0) return;

            string customDir = Environment.GetEnvironmentVariable("AHK_XAML_WEBVIEW_DIR");
            string wvDataDir = !string.IsNullOrEmpty(customDir) ? customDir : System.IO.Path.Combine(GetLogDir(), "WebView2Data");
            var logPath = GetLogPath("AhkWebViewDebug.log");
            
            System.IO.File.AppendAllText(logPath, "InitializeWebView2IfPresent called. Found " + webViews.Count + " WebViews. wvDataDir: " + wvDataDir + "\n");
            
            foreach (var wv in webViews) {
                try {
                    System.IO.File.AppendAllText(logPath, "Initializing WebView with Name: '" + wv.Name + "'\n");
                    wv.WebMessageReceived += (ws, we) => {
                        string debugMsg = we.WebMessageAsJson;
                        try { System.IO.File.AppendAllText(GetLogPath("AhkWebViewDebug.log"), "C# WebMessageReceived: " + debugMsg + "\n"); } catch {}
                        SendToAhk("EVENT|" + winId + "|" + wv.Name + "|WebMessageReceived|" + BridgeUtil.LengthPrefix(debugMsg) + "\n");
                    };
                    wv.NavigationCompleted += (ws, we) => {
                        SendToAhk("EVENT|" + winId + "|" + wv.Name + "|NavigationCompleted|" + BridgeUtil.LengthPrefix(wv.Source != null ? wv.Source.ToString() : "") + "\n");
                    };
                    
                    var env = await CoreWebView2Environment.CreateAsync(null, wvDataDir);
                    await wv.EnsureCoreWebView2Async(env);
                    System.IO.File.AppendAllText(logPath, "EnsureCoreWebView2Async completed successfully.\n");

                    if (!string.IsNullOrEmpty(wv.Name) && _initialWebViewSources.ContainsKey(wv.Name))
                    {
                        System.IO.File.AppendAllText(logPath, "Navigating to extracted Source URL: " + _initialWebViewSources[wv.Name] + "\n");
                        wv.Source = new Uri(_initialWebViewSources[wv.Name]);
                    }
                    else
                    {
                        System.IO.File.AppendAllText(logPath, "No extracted source URL found in _initialWebViewSources (Name='" + wv.Name + "', keyExists=" + _initialWebViewSources.ContainsKey(wv.Name ?? "") + ")\n");
                    }
                } catch (Exception ex) {
                    System.IO.File.AppendAllText(logPath, "WebView Init Exception: " + ex.ToString() + "\n");
                    System.Windows.MessageBox.Show("WebView Init Error:\n" + ex.ToString(), "AHK-XAML WebView Error");
                }
            }
        }
        catch (Exception ex)
        {
            try { System.IO.File.AppendAllText(GetLogPath("AhkWebViewDebug.log"), "InitializeWebView2IfPresent outer Exception: " + ex.ToString() + "\n"); } catch {}
        }
    }
}
#endif
