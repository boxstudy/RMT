// =============================================================================
// AvalonEdit editor: commands & top-level classes
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

public class XamlHighlightAdorner : Adorner
{
    private readonly Pen _borderPen;
    private readonly Brush _fillBrush;

    public XamlHighlightAdorner(UIElement adornedElement) : base(adornedElement)
    {
        IsHitTestVisible = false;
        _fillBrush = new SolidColorBrush(System.Windows.Media.Color.FromArgb(51, 0, 128, 255));
        _fillBrush.Freeze();
        _borderPen = new Pen(new SolidColorBrush(System.Windows.Media.Color.FromRgb(0, 120, 215)), 1.5);
        _borderPen.Freeze();
    }

    protected override void OnRender(DrawingContext drawingContext)
    {
        Rect rect = new Rect(AdornedElement.RenderSize);
        drawingContext.DrawRectangle(_fillBrush, _borderPen, rect);
    }
}


#if ENABLE_AVALONEDIT
public partial class AhkWpfEngine
{
    // AvalonEdit theme application
    private void CustomizeFoldingMargin(TextEditor editor, System.Windows.Media.Brush markerBrush, System.Windows.Media.Brush selectedMarkerBrush, System.Windows.Media.Brush markerBgBrush) {
        foreach (var margin in editor.TextArea.LeftMargins) {
            if (margin.GetType().Name == "FoldingMargin" || margin.GetType().FullName.Contains("FoldingMargin")) {
                try {
                    var fMargin = margin;
                    var markerBrushProp = fMargin.GetType().GetProperty("FoldingMarkerBrush");
                    if (markerBrushProp != null) markerBrushProp.SetValue(fMargin, markerBrush, null);
                    
                    var selMarkerBrushProp = fMargin.GetType().GetProperty("SelectedFoldingMarkerBrush");
                    if (selMarkerBrushProp != null) selMarkerBrushProp.SetValue(fMargin, selectedMarkerBrush, null);
                    
                    var bgMarkerBrushProp = fMargin.GetType().GetProperty("FoldingMarkerBackgroundBrush");
                    if (bgMarkerBrushProp != null) bgMarkerBrushProp.SetValue(fMargin, markerBgBrush, null);
                } catch { }
            }
        }
    }

    private void ApplyAvalonEditTheme(TextEditor editor, string theme) {
        editor.Resources["CurrentTheme"] = theme;
        System.Windows.Media.Brush markerBrush = System.Windows.Media.Brushes.Gray;
        System.Windows.Media.Brush selectedMarkerBrush = System.Windows.Media.Brushes.Blue;
        System.Windows.Media.Brush markerBgBrush = System.Windows.Media.Brushes.White;

        switch (theme.ToLower()) {
            case "dark":
                editor.Background = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(30, 30, 30));
                editor.Foreground = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(212, 212, 212));
                editor.TextArea.TextView.CurrentLineBackground = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromArgb(40, 255, 255, 255));
                editor.TextArea.TextView.CurrentLineBorder = new System.Windows.Media.Pen(new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromArgb(30, 255, 255, 255)), 1);
                editor.LineNumbersForeground = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(100, 100, 100));
                editor.TextArea.SelectionBrush = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromArgb(100, 38, 79, 120));
                editor.TextArea.SelectionForeground = null;
                
                markerBrush = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(90, 90, 90));
                selectedMarkerBrush = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(137, 180, 250)); // #89b4fa
                markerBgBrush = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(37, 37, 38));
                break;
            case "light":
                editor.Background = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(255, 255, 255));
                editor.Foreground = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(0, 0, 0));
                editor.TextArea.TextView.CurrentLineBackground = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromArgb(25, 0, 0, 0));
                editor.TextArea.TextView.CurrentLineBorder = new System.Windows.Media.Pen(new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromArgb(20, 0, 0, 0)), 1);
                editor.LineNumbersForeground = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(150, 150, 150));
                editor.TextArea.SelectionBrush = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromArgb(80, 0, 120, 215));
                editor.TextArea.SelectionForeground = null;
                
                markerBrush = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(160, 160, 160));
                selectedMarkerBrush = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(0, 120, 215));
                markerBgBrush = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(240, 240, 240));
                break;
            case "monokai":
                editor.Background = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(39, 40, 34));
                editor.Foreground = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(248, 248, 242));
                editor.TextArea.TextView.CurrentLineBackground = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromArgb(30, 255, 255, 255));
                editor.TextArea.TextView.CurrentLineBorder = new System.Windows.Media.Pen(System.Windows.Media.Brushes.Transparent, 0);
                editor.LineNumbersForeground = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(100, 100, 80));
                editor.TextArea.SelectionBrush = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromArgb(80, 73, 72, 62));
                
                markerBrush = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(117, 113, 94));
                selectedMarkerBrush = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(166, 226, 46));
                markerBgBrush = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(62, 61, 50));
                break;
            case "one-dark": case "onedark":
                editor.Background = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(40, 44, 52));
                editor.Foreground = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(171, 178, 191));
                editor.TextArea.TextView.CurrentLineBackground = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromArgb(25, 255, 255, 255));
                editor.TextArea.TextView.CurrentLineBorder = new System.Windows.Media.Pen(System.Windows.Media.Brushes.Transparent, 0);
                editor.LineNumbersForeground = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(76, 82, 99));
                editor.TextArea.SelectionBrush = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromArgb(80, 62, 68, 81));
                
                markerBrush = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(92, 99, 112));
                selectedMarkerBrush = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(97, 175, 239));
                markerBgBrush = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(49, 53, 63));
                break;
            case "dracula":
                editor.Background = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(40, 42, 54));
                editor.Foreground = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(248, 248, 242));
                editor.TextArea.TextView.CurrentLineBackground = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromArgb(25, 255, 255, 255));
                editor.TextArea.TextView.CurrentLineBorder = new System.Windows.Media.Pen(System.Windows.Media.Brushes.Transparent, 0);
                editor.LineNumbersForeground = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(98, 114, 164));
                editor.TextArea.SelectionBrush = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromArgb(80, 68, 71, 90));
                
                markerBrush = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(98, 114, 164));
                selectedMarkerBrush = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(189, 147, 249));
                markerBgBrush = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(52, 55, 70));
                break;
            case "solarized-dark":
                editor.Background = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(0, 43, 54));
                editor.Foreground = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(131, 148, 150));
                editor.TextArea.TextView.CurrentLineBackground = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromArgb(20, 255, 255, 255));
                editor.TextArea.TextView.CurrentLineBorder = new System.Windows.Media.Pen(System.Windows.Media.Brushes.Transparent, 0);
                editor.LineNumbersForeground = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(88, 110, 117));
                editor.TextArea.SelectionBrush = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromArgb(60, 7, 54, 66));
                
                markerBrush = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(88, 110, 117));
                selectedMarkerBrush = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(38, 139, 210));
                markerBgBrush = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(7, 54, 66));
                break;
            default:
                if (theme.Contains(":")) {
                    foreach (string pair in theme.Split(',')) {
                        string[] kv = pair.Split(':');
                        if (kv.Length != 2) continue;
                        try {
                            var color = (System.Windows.Media.Color)System.Windows.Media.ColorConverter.ConvertFromString(kv[1]);
                            var brush = new System.Windows.Media.SolidColorBrush(color);
                            switch (kv[0].Trim().ToLower()) {
                                case "bg": editor.Background = brush; break;
                                case "fg": editor.Foreground = brush; break;
                                case "ln": editor.LineNumbersForeground = brush; break;
                                case "sel": editor.TextArea.SelectionBrush = brush; break;
                                case "cur": editor.TextArea.TextView.CurrentLineBackground = brush; break;
                            }
                        } catch { }
                    }
                }
                break;
        }

        CustomizeFoldingMargin(editor, markerBrush, selectedMarkerBrush, markerBgBrush);
    }
}

// Autocomplete item for AvalonEdit completion window
public class AhkCompletionData : ICSharpCode.AvalonEdit.CodeCompletion.ICompletionData {
    public AhkCompletionData(string text, string description = "") {
        this.Text = text;
        this.Description = description;
    }
    public System.Windows.Media.ImageSource Image { get { return null; } }
    public string Text { get; private set; }
    public object Content { get { return this.Text; } }
    public object Description { get; private set; }
    public double Priority { get { return 0; } }

    public void Complete(ICSharpCode.AvalonEdit.Editing.TextArea textArea,
        ICSharpCode.AvalonEdit.Document.ISegment completionSegment,
        EventArgs insertionRequestEventArgs) {
        textArea.Document.Replace(completionSegment, this.Text);
    }
}

// Brace-matching folding strategy for AvalonEdit
public class BraceFoldingStrategy {
    public void UpdateFoldings(ICSharpCode.AvalonEdit.Folding.FoldingManager manager,
        ICSharpCode.AvalonEdit.Document.TextDocument document) {
        var foldings = CreateNewFoldings(document);
        manager.UpdateFoldings(foldings, -1);
    }

    private System.Collections.Generic.IEnumerable<ICSharpCode.AvalonEdit.Folding.NewFolding> CreateNewFoldings(
        ICSharpCode.AvalonEdit.Document.TextDocument document) {
        var foldings = new System.Collections.Generic.List<ICSharpCode.AvalonEdit.Folding.NewFolding>();
        var stack = new System.Collections.Generic.Stack<int>();
        string text = document.Text;

        for (int i = 0; i < text.Length; i++) {
            if (text[i] == '{') {
                stack.Push(i);
            } else if (text[i] == '}' && stack.Count > 0) {
                int start = stack.Pop();
                if (i - start > 1) {
                    foldings.Add(new ICSharpCode.AvalonEdit.Folding.NewFolding(start, i + 1) { Name = "..." });
                }
            }
        }
        foldings.Sort((a, b) => a.StartOffset.CompareTo(b.StartOffset));
        return foldings;
    }
}

// Sexy, minimalist, hover-reactive folding margin mimicking VS Code
public class SexyFoldingMargin : ICSharpCode.AvalonEdit.Editing.AbstractMargin
{
    public FoldingManager FoldingManager { get; set; }
    
    public Brush FoldingMarkerBrush { get; set; }
    public Brush SelectedFoldingMarkerBrush { get; set; }
    public Brush FoldingMarkerBackgroundBrush { get; set; }
    
    public SexyFoldingMargin()
    {
        FoldingMarkerBrush = Brushes.Gray;
        SelectedFoldingMarkerBrush = Brushes.DodgerBlue;
        FoldingMarkerBackgroundBrush = Brushes.Transparent;
    }
    
    private int hoveredLine = -1;
    private bool isMarginHovered = false;
    
    protected override void OnTextViewChanged(TextView oldTextView, TextView newTextView)
    {
        if (oldTextView != null) {
            oldTextView.VisualLinesChanged -= OnVisualLinesChanged;
        }
        base.OnTextViewChanged(oldTextView, newTextView);
        if (newTextView != null) {
            newTextView.VisualLinesChanged += OnVisualLinesChanged;
        }
    }
    
    private void OnVisualLinesChanged(object sender, EventArgs e)
    {
        InvalidateVisual();
    }
    
    protected override Size MeasureOverride(Size availableSize)
    {
        return new Size(26, 0);
    }
    
    protected override void OnRender(DrawingContext drawingContext)
    {
        if (TextView == null || !TextView.VisualLinesValid || FoldingManager == null)
            return;
            
        var visualLines = TextView.VisualLines;
        if (visualLines.Count == 0)
            return;
            
        double viewTop = TextView.VerticalOffset;
        double width = RenderSize.Width;
        
        // Draw a completely transparent rectangle covering the entire margin area.
        // This is a CRITICAL WPF detail: elements with null background are transparent to hit-testing.
        // Drawing a transparent rectangle makes the entire 26px gutter fully hit-testable!
        drawingContext.DrawRectangle(Brushes.Transparent, null, new Rect(0, 0, width, RenderSize.Height));
        
        var foldings = FoldingManager.AllFoldings.ToList();
        
        Brush markerBrush = FoldingMarkerBrush ?? Brushes.Gray;
        Brush highlightBrush = SelectedFoldingMarkerBrush ?? Brushes.DodgerBlue;
        
        // Dynamic faint color matching standard theme folding guide
        Brush lineBrush = new SolidColorBrush(System.Windows.Media.Color.FromArgb(40, 128, 128, 128));
        SolidColorBrush scb = markerBrush as SolidColorBrush;
        if (scb != null) {
            lineBrush = new SolidColorBrush(System.Windows.Media.Color.FromArgb(50, scb.Color.R, scb.Color.G, scb.Color.B));
        }
        
        foreach (var line in visualLines) {
            int lineNum = line.FirstDocumentLine.LineNumber;
            double startY = line.VisualTop - viewTop;
            double endY = startY + line.Height;
            double centerY = startY + line.Height / 2;
            double centerX = width / 2;
            
            // Find all active/expanded foldings that cover this line
            var activeFolds = foldings.Where(f => !f.IsFolded && 
                lineNum >= TextView.Document.GetLineByOffset(f.StartOffset).LineNumber && 
                lineNum <= TextView.Document.GetLineByOffset(f.EndOffset).LineNumber).ToList();
                
            foreach (var fold in activeFolds) {
                int foldStartLine = TextView.Document.GetLineByOffset(fold.StartOffset).LineNumber;
                int foldEndLine = TextView.Document.GetLineByOffset(fold.EndOffset).LineNumber;
                
                double segmentStartY = startY;
                double segmentEndY = endY;
                
                if (lineNum == foldStartLine) {
                    segmentStartY = centerY + 6;
                }
                if (lineNum == foldEndLine) {
                    segmentEndY = centerY - 4;
                }
                
                bool isHovered = (hoveredLine >= foldStartLine && hoveredLine <= foldEndLine);
                Brush currentLineBrush = isHovered ? highlightBrush : lineBrush;
                Pen pen = new Pen(currentLineBrush, 1.5);
                
                drawingContext.DrawLine(pen, new Point(centerX, segmentStartY), new Point(centerX, segmentEndY));
                
                if (lineNum == foldEndLine) {
                    drawingContext.DrawLine(pen, new Point(centerX, segmentEndY), new Point(centerX + 4, segmentEndY));
                }
            }
            
            // Draw chevrons starting on this line
            var startFold = foldings.FirstOrDefault(f => 
                TextView.Document.GetLineByOffset(f.StartOffset).LineNumber == lineNum);
                
            if (startFold != null) {
                bool shouldDraw = isMarginHovered || startFold.IsFolded;
                if (shouldDraw) {
                    bool isHovered = (hoveredLine == lineNum);
                    Brush brush = isHovered ? highlightBrush : markerBrush;
                    Pen pen = new Pen(brush, 2.0);
                    
                    if (startFold.IsFolded) {
                        StreamGeometry geometry = new StreamGeometry();
                        using (StreamGeometryContext ctx = geometry.Open()) {
                            ctx.BeginFigure(new Point(centerX - 2, centerY - 4), false, false);
                            ctx.LineTo(new Point(centerX + 2, centerY), true, false);
                            ctx.LineTo(new Point(centerX - 2, centerY + 4), true, false);
                        }
                        geometry.Freeze();
                        drawingContext.DrawGeometry(null, pen, geometry);
                    } else {
                        StreamGeometry geometry = new StreamGeometry();
                        using (StreamGeometryContext ctx = geometry.Open()) {
                            ctx.BeginFigure(new Point(centerX - 4, centerY - 2), false, false);
                            ctx.LineTo(new Point(centerX, centerY + 2), true, false);
                            ctx.LineTo(new Point(centerX + 4, centerY - 2), true, false);
                        }
                        geometry.Freeze();
                        drawingContext.DrawGeometry(null, pen, geometry);
                    }
                }
            }
        }
    }
    
    protected override void OnMouseEnter(System.Windows.Input.MouseEventArgs e)
    {
        base.OnMouseEnter(e);
        isMarginHovered = true;
        InvalidateVisual();
    }
    
    protected override void OnMouseLeave(System.Windows.Input.MouseEventArgs e)
    {
        base.OnMouseLeave(e);
        isMarginHovered = false;
        hoveredLine = -1;
        InvalidateVisual();
    }
    
    protected override void OnMouseMove(System.Windows.Input.MouseEventArgs e)
    {
        base.OnMouseMove(e);
        if (TextView == null || !TextView.VisualLinesValid) return;
        
        Point p = e.GetPosition(this);
        double localY = p.Y;
        
        int newLine = -1;
        foreach (var line in TextView.VisualLines) {
            double startY = line.VisualTop - TextView.VerticalOffset;
            double endY = startY + line.Height;
            if (localY >= startY && localY <= endY) {
                newLine = line.FirstDocumentLine.LineNumber;
                break;
            }
        }
        
        if (newLine != hoveredLine) {
            hoveredLine = newLine;
            InvalidateVisual();
        }
    }
    
    protected override void OnMouseDown(System.Windows.Input.MouseButtonEventArgs e)
    {
        base.OnMouseDown(e);
        if (TextView == null || !TextView.VisualLinesValid || FoldingManager == null) return;
        
        Point p = e.GetPosition(this);
        double localY = p.Y;
        
        foreach (var line in TextView.VisualLines) {
            double startY = line.VisualTop - TextView.VerticalOffset;
            double endY = startY + line.Height;
            if (localY >= startY && localY <= endY) {
                int lineNum = line.FirstDocumentLine.LineNumber;
                int lineStartOffset = line.FirstDocumentLine.Offset;
                int lineEndOffset = line.FirstDocumentLine.EndOffset;
                
                // 1. Check direct chevron click
                var startFoldings = FoldingManager.AllFoldings
                    .Where(f => f.StartOffset >= lineStartOffset && f.StartOffset <= lineEndOffset)
                    .ToList();
                    
                if (startFoldings.Count > 0) {
                    startFoldings[0].IsFolded = !startFoldings[0].IsFolded;
                    e.Handled = true;
                    InvalidateVisual();
                    break;
                }
                
                // 2. Check vertical guide line click (collapse innermost expanded fold covering this line)
                var activeFolds = FoldingManager.AllFoldings
                    .Where(f => !f.IsFolded && 
                        lineNum >= TextView.Document.GetLineByOffset(f.StartOffset).LineNumber && 
                        lineNum <= TextView.Document.GetLineByOffset(f.EndOffset).LineNumber)
                    .OrderByDescending(f => f.StartOffset)
                    .ToList();
                    
                if (activeFolds.Count > 0) {
                    activeFolds[0].IsFolded = true;
                    e.Handled = true;
                    InvalidateVisual();
                    break;
                }
            }
        }
    }
}
#endif
