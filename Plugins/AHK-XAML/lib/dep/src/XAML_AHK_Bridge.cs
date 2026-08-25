// =============================================================================
// Engine entry: shared usings, assembly info, logging
// =============================================================================
using System;
using System.Linq;
using System.Windows;
using System.Windows.Markup;
using System.Windows.Controls;
using System.Windows.Controls.Primitives;
using System.Windows.Interop;
using System.Runtime.InteropServices;
using System.Text;
using System.Xml;
using System.Reflection;
using System.Windows.Documents;
using System.Windows.Media;
#if ENABLE_WEBVIEW
using Microsoft.Web.WebView2.Wpf;
using Microsoft.Web.WebView2.Core;
#endif
#if ENABLE_AVALONEDIT
using ICSharpCode.AvalonEdit;
using ICSharpCode.AvalonEdit.Highlighting;
using ICSharpCode.AvalonEdit.CodeCompletion;
using ICSharpCode.AvalonEdit.Document;
using ICSharpCode.AvalonEdit.Editing;
using ICSharpCode.AvalonEdit.Folding;
using ICSharpCode.AvalonEdit.Rendering;
using ICSharpCode.AvalonEdit.Search;
#endif
#if ENABLE_DOCUMENT
using DocumentFormat.OpenXml;
using DocumentFormat.OpenXml.Packaging;
using DocumentFormat.OpenXml.Wordprocessing;
#endif
using Color = System.Windows.Media.Color;


[assembly: AssemblyTitle("ahk-xaml Engine")]
[assembly: AssemblyDescription("WPF Rendering Engine for AutoHotkey")]
[assembly: AssemblyCompany("owhs")]
[assembly: AssemblyProduct("ahk-xaml Shared Engine")]
[assembly: AssemblyCopyright("Copyright © 2026")]
[assembly: AssemblyVersion("1.0.0.0")]
[assembly: AssemblyFileVersion("1.0.0.0")]

[ComVisible(true)]
[ClassInterface(ClassInterfaceType.AutoDispatch)]
public partial class AhkWpfEngine
{
    public static bool EnableLogging = true;
    private static string _logDir = null;

    private static string GetLogDir()
    {
        if (_logDir == null)
        {
            _logDir = System.Environment.GetEnvironmentVariable("RMT_LOG_DIR");
            if (string.IsNullOrEmpty(_logDir))
            {
                _logDir = System.IO.Path.Combine(System.IO.Path.GetTempPath(), "AhkWpf");
            }
        }
        if (!System.IO.Directory.Exists(_logDir))
            System.IO.Directory.CreateDirectory(_logDir);
        return _logDir;
    }

    private static string GetLogPath(string filename)
    {
        return System.IO.Path.Combine(GetLogDir(), filename);
    }

    private static void LogDebug(string msg)
    {
        try
        {
            System.IO.File.AppendAllText(GetLogPath("AhkWpfDebug.log"),
                System.DateTime.Now.ToString("HH:mm:ss.fff") + " " + msg + "\n");
        }
        catch { }
    }
}
