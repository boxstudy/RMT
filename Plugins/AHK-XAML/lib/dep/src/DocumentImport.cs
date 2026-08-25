// =============================================================================
// DOCX import & parsing (ENABLE_DOCUMENT)
// =============================================================================
#if ENABLE_DOCUMENT

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

#if ENABLE_DOCUMENT
using DocumentFormat.OpenXml;
using DocumentFormat.OpenXml.Packaging;
using DocumentFormat.OpenXml.Wordprocessing;
#endif
public partial class AhkWpfEngine
{
    private void ApplyDocFormat(RichTextBox rtb, string command) {
        string[] cmdParts = command.Split(new[] { '|' }, 2);
        string cmd = cmdParts[0];
        string val = cmdParts.Length > 1 ? cmdParts[1] : "";

        var selection = rtb.Selection;

        switch (cmd) {
            case "Bold":
                EditingCommands.ToggleBold.Execute(null, rtb);
                break;
            case "Italic":
                EditingCommands.ToggleItalic.Execute(null, rtb);
                break;
            case "Underline":
                EditingCommands.ToggleUnderline.Execute(null, rtb);
                break;
            case "Strikethrough":
                selection.ApplyPropertyValue(Inline.TextDecorationsProperty, TextDecorations.Strikethrough);
                break;
            case "FontFamily":
                if (!string.IsNullOrEmpty(val))
                    selection.ApplyPropertyValue(TextElement.FontFamilyProperty, ResolveFontFamily(val));
                break;
            case "FontSize":
                double fs; if (double.TryParse(val, out fs))
                    selection.ApplyPropertyValue(TextElement.FontSizeProperty, fs);
                break;
            case "FontColor":
                if (!string.IsNullOrEmpty(val)) {
                    try {
                        var brush = new System.Windows.Media.BrushConverter().ConvertFromString(val) as System.Windows.Media.Brush;
                        if (brush != null) selection.ApplyPropertyValue(TextElement.ForegroundProperty, brush);
                    } catch { }
                }
                break;
            case "Highlight":
                if (!string.IsNullOrEmpty(val)) {
                    try {
                        var brush = new System.Windows.Media.BrushConverter().ConvertFromString(val) as System.Windows.Media.Brush;
                        if (brush != null) selection.ApplyPropertyValue(TextElement.BackgroundProperty, brush);
                    } catch { }
                }
                break;
            case "AlignLeft":
                EditingCommands.AlignLeft.Execute(null, rtb);
                break;
            case "AlignCenter":
                EditingCommands.AlignCenter.Execute(null, rtb);
                break;
            case "AlignRight":
                EditingCommands.AlignRight.Execute(null, rtb);
                break;
            case "AlignJustify":
                EditingCommands.AlignJustify.Execute(null, rtb);
                break;
            case "BulletList":
                EditingCommands.ToggleBullets.Execute(null, rtb);
                break;
            case "NumberList":
                EditingCommands.ToggleNumbering.Execute(null, rtb);
                break;
            case "IncreaseIndent":
                EditingCommands.IncreaseIndentation.Execute(null, rtb);
                break;
            case "DecreaseIndent":
                EditingCommands.DecreaseIndentation.Execute(null, rtb);
                break;
            case "Superscript":
                selection.ApplyPropertyValue(Inline.BaselineAlignmentProperty, BaselineAlignment.Superscript);
                double curSize = 14;
                var szObj = selection.GetPropertyValue(TextElement.FontSizeProperty);
                if (szObj is double) curSize = (double)szObj;
                selection.ApplyPropertyValue(TextElement.FontSizeProperty, curSize * 0.7);
                break;
            case "Subscript":
                selection.ApplyPropertyValue(Inline.BaselineAlignmentProperty, BaselineAlignment.Subscript);
                double curSize2 = 14;
                var szObj2 = selection.GetPropertyValue(TextElement.FontSizeProperty);
                if (szObj2 is double) curSize2 = (double)szObj2;
                selection.ApplyPropertyValue(TextElement.FontSizeProperty, curSize2 * 0.7);
                break;
            case "ClearFormatting":
                selection.ClearAllProperties();
                break;
            case "Heading": {
                double headingSize = 24;
                if (!string.IsNullOrEmpty(val)) {
                    switch (val) {
                        case "1": headingSize = 28; break;
                        case "2": headingSize = 24; break;
                        case "3": headingSize = 20; break;
                        case "4": headingSize = 18; break;
                        case "5": headingSize = 16; break;
                        case "6": headingSize = 14; break;
                    }
                }
                selection.ApplyPropertyValue(TextElement.FontSizeProperty, headingSize);
                selection.ApplyPropertyValue(TextElement.FontWeightProperty, FontWeights.Bold);
                break;
            }
            case "TableCellBackground": {
                if (!string.IsNullOrEmpty(val)) {
                    try {
                        var brush = new System.Windows.Media.BrushConverter().ConvertFromString(val) as System.Windows.Media.Brush;
                        if (brush != null) {
                            var cell = GetCurrentCell(rtb);
                            if (cell != null) cell.Background = brush;
                        }
                    } catch { }
                }
                break;
            }
            case "TableMergeRight": {
                var cell = GetCurrentCell(rtb);
                if (cell != null) {
                    cell.ColumnSpan = cell.ColumnSpan + 1;
                }
                break;
            }
            case "TableAddRowBelow": {
                var cell = GetCurrentCell(rtb);
                if (cell != null) {
                    var row = cell.Parent as System.Windows.Documents.TableRow;
                    var rg = row != null ? row.Parent as System.Windows.Documents.TableRowGroup : null;
                    if (row != null && rg != null) {
                        var newRow = new System.Windows.Documents.TableRow();
                        int colCount = 0;
                        foreach (var c in row.Cells) colCount += c.ColumnSpan;
                        for (int i = 0; i < colCount; i++) {
                            var newCell = new System.Windows.Documents.TableCell(new System.Windows.Documents.Paragraph());
                            newCell.BorderBrush = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(180, 180, 180));
                            newCell.BorderThickness = new Thickness(0.5);
                            newCell.Padding = new Thickness(10, 8, 10, 8);
                            newRow.Cells.Add(newCell);
                        }
                        int rowIdx = rg.Rows.IndexOf(row);
                        if (rowIdx < rg.Rows.Count - 1)
                            rg.Rows.Insert(rowIdx + 1, newRow);
                        else
                            rg.Rows.Add(newRow);
                    }
                }
                break;
            }
            case "TableAddRowAbove": {
                var cell = GetCurrentCell(rtb);
                if (cell != null) {
                    var row = cell.Parent as System.Windows.Documents.TableRow;
                    var rg = row != null ? row.Parent as System.Windows.Documents.TableRowGroup : null;
                    if (row != null && rg != null) {
                        var newRow = new System.Windows.Documents.TableRow();
                        int colCount = 0;
                        foreach (var c in row.Cells) colCount += c.ColumnSpan;
                        for (int i = 0; i < colCount; i++) {
                            var newCell = new System.Windows.Documents.TableCell(new System.Windows.Documents.Paragraph());
                            newCell.BorderBrush = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(180, 180, 180));
                            newCell.BorderThickness = new Thickness(0.5);
                            newCell.Padding = new Thickness(10, 8, 10, 8);
                            newRow.Cells.Add(newCell);
                        }
                        int rowIdx = rg.Rows.IndexOf(row);
                        rg.Rows.Insert(rowIdx, newRow);
                    }
                }
                break;
            }
            case "TableAddColumnRight": {
                var cell = GetCurrentCell(rtb);
                if (cell != null) {
                    var row = cell.Parent as System.Windows.Documents.TableRow;
                    var rg = row != null ? row.Parent as System.Windows.Documents.TableRowGroup : null;
                    var table = rg != null ? rg.Parent as System.Windows.Documents.Table : null;
                    if (table != null && rg != null) {
                        int cellIdx = row.Cells.IndexOf(cell);
                        table.Columns.Add(new System.Windows.Documents.TableColumn { Width = new GridLength(1, GridUnitType.Star) });
                        foreach (var r in rg.Rows) {
                            int insertAt = Math.Min(cellIdx + 1, r.Cells.Count);
                            var newCell = new System.Windows.Documents.TableCell(new System.Windows.Documents.Paragraph());
                            newCell.BorderBrush = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(180, 180, 180));
                            newCell.BorderThickness = new Thickness(0.5);
                            newCell.Padding = new Thickness(10, 8, 10, 8);
                            r.Cells.Insert(insertAt, newCell);
                        }
                    }
                }
                break;
            }
            case "TableDeleteRow": {
                var cell = GetCurrentCell(rtb);
                if (cell != null) {
                    var row = cell.Parent as System.Windows.Documents.TableRow;
                    var rg = row != null ? row.Parent as System.Windows.Documents.TableRowGroup : null;
                    if (rg != null && rg.Rows.Count > 1) {
                        rg.Rows.Remove(row);
                    }
                }
                break;
            }
            case "TableDeleteColumn": {
                var cell = GetCurrentCell(rtb);
                if (cell != null) {
                    var row = cell.Parent as System.Windows.Documents.TableRow;
                    var rg = row != null ? row.Parent as System.Windows.Documents.TableRowGroup : null;
                    var table = rg != null ? rg.Parent as System.Windows.Documents.Table : null;
                    if (table != null && rg != null) {
                        int cellIdx = row.Cells.IndexOf(cell);
                        foreach (var r in rg.Rows.ToList()) {
                            if (cellIdx >= 0 && cellIdx < r.Cells.Count && r.Cells.Count > 1)
                                r.Cells.RemoveAt(cellIdx);
                        }
                        if (table.Columns.Count > 1)
                            table.Columns.RemoveAt(table.Columns.Count - 1);
                    }
                }
                break;
            }
        }
    }

    private System.Windows.Documents.TableCell GetCurrentCell(RichTextBox rtb) {
        DependencyObject pointer = rtb.CaretPosition.Parent;
        while (pointer != null && !(pointer is System.Windows.Documents.TableCell)) {
            pointer = System.Windows.Media.VisualTreeHelper.GetParent(pointer);
        }
        if (pointer == null) {
            pointer = rtb.CaretPosition.Parent;
            while (pointer != null && !(pointer is System.Windows.Documents.TableCell)) {
                pointer = LogicalTreeHelper.GetParent(pointer);
            }
        }
        return pointer as System.Windows.Documents.TableCell;
    }

    public class DocLayoutSettings {
        public double PageWidth { get; set; }
        public double PageHeight { get; set; }
        public Thickness PagePadding { get; set; }
        public double LinePitch { get; set; } // From <w:docGrid w:linePitch="312"/> in twips; 0 = not set
        public double LineSpacingOverride { get; set; } // User-set multiplier (0 = use document default)
    }

    private void _ApplyLineSpacingToBlocks(BlockCollection blocks, double multiplier, double gridLH) {
        foreach (var block in blocks) {
            if (block is System.Windows.Documents.Paragraph) {
                var para = (System.Windows.Documents.Paragraph)block;
                double effFontSize = para.FontSize;
                double baseHeight;
                if (gridLH > 0) {
                    baseHeight = Math.Max(gridLH, effFontSize * 1.2);
                } else {
                    baseHeight = effFontSize * 1.2;
                }
                para.LineHeight = baseHeight * multiplier;
                para.LineStackingStrategy = LineStackingStrategy.MaxHeight;
            } else if (block is System.Windows.Documents.Section) {
                _ApplyLineSpacingToBlocks(((System.Windows.Documents.Section)block).Blocks, multiplier, gridLH);
            } else if (block is System.Windows.Documents.List) {
                foreach (var li in ((System.Windows.Documents.List)block).ListItems) {
                    _ApplyLineSpacingToBlocks(li.Blocks, multiplier, gridLH);
                }
            }
        }
    }

    private string _themeMajorLatin = "Calibri Light";
    private string _themeMinorLatin = "Calibri";
    private string _themeMajorEastAsia = "Microsoft YaHei";
    private string _themeMinorEastAsia = "SimSun";

    private static RunProperties GetStyleRunProperties(string styleId, Styles styles) {
        if (styles == null || string.IsNullOrEmpty(styleId)) return null;
        var style = styles.Elements<DocumentFormat.OpenXml.Wordprocessing.Style>().FirstOrDefault(s => s.StyleId == styleId);
        if (style == null) return null;
        var rPr = style.Elements<RunProperties>().FirstOrDefault();
        if (rPr != null) return rPr;
        var basedOn = style.Elements<BasedOn>().FirstOrDefault();
        if (basedOn != null && basedOn.Val != null) {
            return GetStyleRunProperties(basedOn.Val.Value, styles);
        }
        return null;
    }

    private static ParagraphProperties GetStyleParagraphProperties(string styleId, Styles styles) {
        if (styles == null || string.IsNullOrEmpty(styleId)) return null;
        var style = styles.Elements<DocumentFormat.OpenXml.Wordprocessing.Style>().FirstOrDefault(s => s.StyleId == styleId);
        if (style == null) return null;
        var pPr = style.Elements<ParagraphProperties>().FirstOrDefault();
        if (pPr != null) return pPr;
        var basedOn = style.Elements<BasedOn>().FirstOrDefault();
        if (basedOn != null && basedOn.Val != null) {
            return GetStyleParagraphProperties(basedOn.Val.Value, styles);
        }
        return null;
    }

    private static T GetPropertyFromStyleHierarchy<T>(string styleId, Styles styles) where T : OpenXmlElement {
        if (styles == null || string.IsNullOrEmpty(styleId)) return null;
        var style = styles.Elements<DocumentFormat.OpenXml.Wordprocessing.Style>().FirstOrDefault(s => s.StyleId == styleId);
        if (style == null) return null;
        // Style definitions use StyleRunProperties (not RunProperties) for <w:rPr> children
        var srPr = style.Elements<DocumentFormat.OpenXml.Wordprocessing.StyleRunProperties>().FirstOrDefault();
        if (srPr != null) {
            var prop = srPr.Elements<T>().FirstOrDefault();
            if (prop != null) return prop;
        }
        // Also check RunProperties in case some documents use it (shouldn't per spec, but be safe)
        var rPr = style.Elements<RunProperties>().FirstOrDefault();
        if (rPr != null) {
            var prop = rPr.Elements<T>().FirstOrDefault();
            if (prop != null) return prop;
        }
        var basedOn = style.Elements<BasedOn>().FirstOrDefault();
        if (basedOn != null && basedOn.Val != null) {
            return GetPropertyFromStyleHierarchy<T>(basedOn.Val.Value, styles);
        }
        return null;
    }

    private static T GetParagraphPropertyFromStyleHierarchy<T>(string styleId, Styles styles) where T : OpenXmlElement {
        if (styles == null || string.IsNullOrEmpty(styleId)) return null;
        var style = styles.Elements<DocumentFormat.OpenXml.Wordprocessing.Style>().FirstOrDefault(s => s.StyleId == styleId);
        if (style == null) return null;
        // Style definitions use StyleParagraphProperties (not ParagraphProperties)
        var spPr = style.Elements<DocumentFormat.OpenXml.Wordprocessing.StyleParagraphProperties>().FirstOrDefault();
        if (spPr != null) {
            var prop = spPr.Elements<T>().FirstOrDefault();
            if (prop != null) return prop;
        }
        // Also check ParagraphProperties for compatibility
        var pPr = style.Elements<ParagraphProperties>().FirstOrDefault();
        if (pPr != null) {
            var prop = pPr.Elements<T>().FirstOrDefault();
            if (prop != null) return prop;
        }
        var basedOn = style.Elements<BasedOn>().FirstOrDefault();
        if (basedOn != null && basedOn.Val != null) {
            return GetParagraphPropertyFromStyleHierarchy<T>(basedOn.Val.Value, styles);
        }
        return null;
    }

    private T GetParagraphProperty<T>(ParagraphProperties pPr, string paragraphStyleId, Styles styles, ParagraphProperties defaultPPr) where T : OpenXmlElement {
        if (pPr != null) {
            var prop = pPr.Elements<T>().FirstOrDefault();
            if (prop != null) return prop;
        }
        if (!string.IsNullOrEmpty(paragraphStyleId)) {
            var prop = GetParagraphPropertyFromStyleHierarchy<T>(paragraphStyleId, styles);
            if (prop != null) return prop;
        }
        if (defaultPPr != null) {
            var prop = defaultPPr.Elements<T>().FirstOrDefault();
            if (prop != null) return prop;
        }
        return null;
    }

    private static string ResolveRunFontName(RunFonts runFonts, string themeMajorLatin, string themeMinorLatin, string themeMajorEastAsia, string themeMinorEastAsia, bool hasNonAscii) {
        if (runFonts == null) return null;
        string fontName = null;
        if (hasNonAscii) {
            if (runFonts.EastAsia != null) fontName = runFonts.EastAsia.Value;
            else if (runFonts.EastAsiaTheme != null && runFonts.EastAsiaTheme.Value != null) {
                var themeVal = runFonts.EastAsiaTheme.Value.ToString();
                if (themeVal.Contains("major") || themeVal.Contains("Major")) fontName = themeMajorEastAsia;
                else if (themeVal.Contains("minor") || themeVal.Contains("Minor")) fontName = themeMinorEastAsia;
            }
            if (!string.IsNullOrEmpty(fontName)) return fontName;
        }
        if (runFonts.Ascii != null) fontName = runFonts.Ascii.Value;
        else if (runFonts.AsciiTheme != null && runFonts.AsciiTheme.Value != null) {
            var themeVal = runFonts.AsciiTheme.Value.ToString();
            if (themeVal.Contains("major") || themeVal.Contains("Major")) fontName = themeMajorLatin;
            else if (themeVal.Contains("minor") || themeVal.Contains("Minor")) fontName = themeMinorLatin;
        }
        if (!string.IsNullOrEmpty(fontName)) return fontName;
        if (runFonts.HighAnsi != null) fontName = runFonts.HighAnsi.Value;
        else if (runFonts.HighAnsiTheme != null && runFonts.HighAnsiTheme.Value != null) {
            var themeVal = runFonts.HighAnsiTheme.Value.ToString();
            if (themeVal.Contains("major") || themeVal.Contains("Major")) fontName = themeMajorLatin;
            else if (themeVal.Contains("minor") || themeVal.Contains("Minor")) fontName = themeMinorLatin;
        }
        return fontName;
    }

    private FlowDocument DocxToFlowDocument(string filePath) {
        var doc = new FlowDocument();
        doc.FontFamily = new System.Windows.Media.FontFamily("Segoe UI, Segoe UI Emoji, Segoe UI Symbol");
        doc.FontSize = 14;
        doc.PagePadding = new Thickness(96, 72, 96, 72); // Standard page margins (1" left/right, 0.75" top/bottom)
        // Set high-quality text rendering on the document itself
        TextOptions.SetTextFormattingMode(doc, TextFormattingMode.Ideal);
        TextOptions.SetTextRenderingMode(doc, TextRenderingMode.ClearType);
        TextOptions.SetTextHintingMode(doc, TextHintingMode.Fixed);

        using (var wordDoc = WordprocessingDocument.Open(filePath, false)) {
            var mainPart = wordDoc.MainDocumentPart;
            var body = mainPart.Document.Body;
            
            // Try to parse theme fonts
            _themeMajorLatin = "Calibri Light";
            _themeMinorLatin = "Calibri";
            _themeMajorEastAsia = "Microsoft YaHei";
            _themeMinorEastAsia = "SimSun";
            try {
                var themePart = mainPart.ThemePart;
                if (themePart != null && themePart.Theme != null) {
                    var themeElements = themePart.Theme.Elements<DocumentFormat.OpenXml.Drawing.ThemeElements>().FirstOrDefault();
                    var fontScheme = themeElements != null ? themeElements.Elements<DocumentFormat.OpenXml.Drawing.FontScheme>().FirstOrDefault() : null;
                    if (fontScheme != null) {
                        var majorFont = fontScheme.Elements<DocumentFormat.OpenXml.Drawing.MajorFont>().FirstOrDefault();
                        if (majorFont != null) {
                            var latin = majorFont.Elements<DocumentFormat.OpenXml.Drawing.LatinFont>().FirstOrDefault();
                            if (latin != null && latin.Typeface != null) _themeMajorLatin = latin.Typeface.Value;
                            var ea = majorFont.Elements<DocumentFormat.OpenXml.Drawing.EastAsianFont>().FirstOrDefault();
                            if (ea != null && ea.Typeface != null) _themeMajorEastAsia = ea.Typeface.Value;
                        }
                        var minorFont = fontScheme.Elements<DocumentFormat.OpenXml.Drawing.MinorFont>().FirstOrDefault();
                        if (minorFont != null) {
                            var latin = minorFont.Elements<DocumentFormat.OpenXml.Drawing.LatinFont>().FirstOrDefault();
                            if (latin != null && latin.Typeface != null) _themeMinorLatin = latin.Typeface.Value;
                            var ea = minorFont.Elements<DocumentFormat.OpenXml.Drawing.EastAsianFont>().FirstOrDefault();
                            if (ea != null && ea.Typeface != null) _themeMinorEastAsia = ea.Typeface.Value;
                        }
                    }
                }
            } catch { }

            // Try to parse document default font and size
            string defaultFont = "Segoe UI";
            double defaultPtSize = 11.0;
            try {
                var stylesPart = mainPart.StyleDefinitionsPart;
                if (stylesPart != null && stylesPart.Styles != null) {
                    var docDefaults = stylesPart.Styles.DocDefaults;
                    if (docDefaults != null && docDefaults.RunPropertiesDefault != null && docDefaults.RunPropertiesDefault.Elements<RunProperties>().FirstOrDefault() != null) {
                        var defaultRPr = docDefaults.RunPropertiesDefault.Elements<RunProperties>().FirstOrDefault();
                        if (defaultRPr.RunFonts != null) {
                            string asciiFont = ResolveRunFontName(defaultRPr.RunFonts, _themeMajorLatin, _themeMinorLatin, _themeMajorEastAsia, _themeMinorEastAsia, false);
                            string eastAsiaFont = ResolveRunFontName(defaultRPr.RunFonts, _themeMajorLatin, _themeMinorLatin, _themeMajorEastAsia, _themeMinorEastAsia, true);
                            
                            string defaultFontChain = "";
                            if (!string.IsNullOrEmpty(asciiFont)) defaultFontChain += asciiFont;
                            if (!string.IsNullOrEmpty(eastAsiaFont) && eastAsiaFont != asciiFont) {
                                if (defaultFontChain != "") defaultFontChain += ", ";
                                defaultFontChain += eastAsiaFont;
                            }
                            if (!string.IsNullOrEmpty(defaultFontChain)) defaultFont = defaultFontChain;
                        }
                        if (defaultRPr.FontSize != null && defaultRPr.FontSize.Val != null) {
                            double sz;
                            if (double.TryParse(defaultRPr.FontSize.Val.Value, out sz)) {
                                defaultPtSize = sz / 2.0;
                            }
                        }
                    }
                }
            } catch { }

            doc.FontFamily = ResolveFontFamily(defaultFont);
            doc.FontSize = defaultPtSize * (96.0 / 72.0);

            // Try to parse page size and margins from SectionProperties
            try {
                var sectPr = body.Elements<SectionProperties>().LastOrDefault() ?? body.Descendants<SectionProperties>().LastOrDefault();
                if (sectPr != null) {
                    var pgSz = sectPr.Elements<PageSize>().FirstOrDefault();
                    if (pgSz != null) {
                        if (pgSz.Width != null && pgSz.Width.Value > 0)
                            doc.PageWidth = (pgSz.Width.Value / 20.0) * (96.0 / 72.0);
                        if (pgSz.Height != null && pgSz.Height.Value > 0)
                            doc.PageHeight = (pgSz.Height.Value / 20.0) * (96.0 / 72.0);
                    }
                    var pgMar = sectPr.Elements<PageMargin>().FirstOrDefault();
                    if (pgMar != null) {
                        double left = 96, top = 72, right = 96, bottom = 72;
                        if (pgMar.Left != null) left = (pgMar.Left.Value / 20.0) * (96.0 / 72.0);
                        if (pgMar.Top != null) top = (pgMar.Top.Value / 20.0) * (96.0 / 72.0);
                        if (pgMar.Right != null) right = (pgMar.Right.Value / 20.0) * (96.0 / 72.0);
                        if (pgMar.Bottom != null) bottom = (pgMar.Bottom.Value / 20.0) * (96.0 / 72.0);
                        doc.PagePadding = new Thickness(left, top, right, bottom);
                    }
                }
            } catch { }

            // Parse document grid (controls line spacing in Chinese docs)
            double docGridLinePitch = 0;
            try {
                var sectPr = body.Elements<SectionProperties>().LastOrDefault() ?? body.Descendants<SectionProperties>().LastOrDefault();
                if (sectPr != null) {
                    var docGrid = sectPr.Elements<DocumentFormat.OpenXml.Wordprocessing.DocGrid>().FirstOrDefault();
                    if (docGrid != null && docGrid.LinePitch != null && docGrid.LinePitch.Value > 0) {
                        docGridLinePitch = docGrid.LinePitch.Value; // Value is in twips (1/20th of a point)
                    }
                }
            } catch { }

            doc.Tag = new DocLayoutSettings {
                PageWidth = doc.PageWidth,
                PageHeight = doc.PageHeight,
                PagePadding = doc.PagePadding,
                LinePitch = docGridLinePitch
            };
            
            // Pre-build numbering lookup
            var numberingFormats = new System.Collections.Generic.Dictionary<string, string>(); // numId_level -> format
            var numberingCounters = new System.Collections.Generic.Dictionary<string, int>();
            var numPart = mainPart.NumberingDefinitionsPart;
            if (numPart != null && numPart.Numbering != null) {
                // Build abstractNumId -> NumberingInstance mapping
                var absNumFormats = new System.Collections.Generic.Dictionary<int, System.Collections.Generic.Dictionary<int, string>>();
                foreach (var absNum in numPart.Numbering.Elements<AbstractNum>()) {
                    if (absNum.AbstractNumberId == null) continue;
                    var levelFormats = new System.Collections.Generic.Dictionary<int, string>();
                    foreach (var lvl in absNum.Elements<Level>()) {
                        if (lvl.LevelIndex == null) continue;
                        string fmt = "bullet";
                        if (lvl.NumberingFormat != null && lvl.NumberingFormat.Val != null) {
                            fmt = lvl.NumberingFormat.Val.Value.ToString().ToLower();
                        }
                        levelFormats[lvl.LevelIndex.Value] = fmt;
                    }
                    absNumFormats[absNum.AbstractNumberId.Value] = levelFormats;
                }
                foreach (var numInst in numPart.Numbering.Elements<NumberingInstance>()) {
                    if (numInst.NumberID == null || numInst.AbstractNumId == null || numInst.AbstractNumId.Val == null) continue;
                    int absId = numInst.AbstractNumId.Val.Value;
                    if (absNumFormats.ContainsKey(absId)) {
                        foreach (var kv in absNumFormats[absId]) {
                            numberingFormats[numInst.NumberID.Value + "_" + kv.Key] = kv.Value;
                        }
                    }
                }
            }

            // Track current list state for grouping consecutive list items
            System.Windows.Documents.List currentList = null;
            string currentListKey = "";

            ParseBodyElements(body, doc, ref currentList, ref currentListKey, mainPart, numberingFormats);
        }
        return doc;
    }

    private void ParseBodyElements(OpenXmlElement parent, FlowDocument doc, ref System.Windows.Documents.List currentList, ref string currentListKey, MainDocumentPart mainPart, System.Collections.Generic.Dictionary<string, string> numberingFormats) {
        foreach (var element in parent.ChildElements) {
            if (element is DocumentFormat.OpenXml.Wordprocessing.Paragraph) {
                var para = (DocumentFormat.OpenXml.Wordprocessing.Paragraph)element;
                var pPr = para.ParagraphProperties;

                // Check if this is a list paragraph
                bool isList = false;
                int listLevel = 0;
                string listFormat = "bullet";
                string listKey = "";
                if (pPr != null && pPr.NumberingProperties != null) {
                    var numProps = pPr.NumberingProperties;
                    string numId = "0";
                    if (numProps.NumberingId != null && numProps.NumberingId.Val != null) {
                        numId = numProps.NumberingId.Val.Value.ToString();
                    }
                    if (numProps.NumberingLevelReference != null && numProps.NumberingLevelReference.Val != null) {
                        listLevel = numProps.NumberingLevelReference.Val.Value;
                    }
                    if (numId != "0") {
                        isList = true;
                        listKey = numId + "_" + listLevel;
                        if (numberingFormats.ContainsKey(listKey)) {
                            listFormat = numberingFormats[listKey];
                        }
                    }
                }

                if (isList) {
                    // Create or continue a List block
                    if (currentList == null || currentListKey != listKey) {
                        currentList = new System.Windows.Documents.List();
                        currentList.Margin = new Thickness(listLevel * 20 + 20, 2, 0, 2);
                        if (listFormat == "bullet" || listFormat == "none") {
                            currentList.MarkerStyle = TextMarkerStyle.Disc;
                        } else if (listFormat == "decimal" || listFormat == "arabic") {
                            currentList.MarkerStyle = TextMarkerStyle.Decimal;
                        } else if (listFormat == "lowerroman") {
                            currentList.MarkerStyle = TextMarkerStyle.LowerRoman;
                        } else if (listFormat == "upperroman") {
                            currentList.MarkerStyle = TextMarkerStyle.UpperRoman;
                        } else if (listFormat == "lowerletter") {
                            currentList.MarkerStyle = TextMarkerStyle.LowerLatin;
                        } else if (listFormat == "upperletter") {
                            currentList.MarkerStyle = TextMarkerStyle.UpperLatin;
                        } else {
                            currentList.MarkerStyle = TextMarkerStyle.Disc;
                        }
                        currentListKey = listKey;
                        doc.Blocks.Add(currentList);
                    }
                    var listItem = new System.Windows.Documents.ListItem();
                    var listPara = BuildFlowParagraph(para, pPr, mainPart, doc);
                    listItem.Blocks.Add(listPara);
                    currentList.ListItems.Add(listItem);
                } else {
                    // End any active list
                    currentList = null;
                    currentListKey = "";

                    var flowPara = BuildFlowParagraph(para, pPr, mainPart, doc);
                    doc.Blocks.Add(flowPara);
                }
            } else if (element is DocumentFormat.OpenXml.Wordprocessing.Table) {
                currentList = null;
                currentListKey = "";
                var flowTable = BuildFlowTable((DocumentFormat.OpenXml.Wordprocessing.Table)element, mainPart, doc);
                doc.Blocks.Add(flowTable);
            } else if (element is SdtBlock || element is SdtContentBlock || element is CustomXmlBlock) {
                ParseBodyElements(element, doc, ref currentList, ref currentListKey, mainPart, numberingFormats);
            }
        }
    }

    // Build a FlowDocument Paragraph from an OpenXML Paragraph
    private System.Windows.Documents.Paragraph BuildFlowParagraph(
        DocumentFormat.OpenXml.Wordprocessing.Paragraph para,
        ParagraphProperties pPr,
        MainDocumentPart mainPart,
        FlowDocument doc) {
        
        var flowPara = new System.Windows.Documents.Paragraph();
        double effFontSize = doc.FontSize;

        ParagraphProperties defaultPPr = null;
        RunProperties defaultRPr = null;
        Styles docStyles = null;
        try {
            var stylesPart = mainPart.StyleDefinitionsPart;
            if (stylesPart != null && stylesPart.Styles != null) {
                docStyles = stylesPart.Styles;
                var docDefaults = docStyles.DocDefaults;
                if (docDefaults != null) {
                    if (docDefaults.ParagraphPropertiesDefault != null) {
                        defaultPPr = docDefaults.ParagraphPropertiesDefault.Elements<ParagraphProperties>().FirstOrDefault();
                    }
                    if (docDefaults.RunPropertiesDefault != null) {
                        defaultRPr = docDefaults.RunPropertiesDefault.Elements<RunProperties>().FirstOrDefault();
                    }
                }
            }
        } catch { }

        string styleId = "";
        if (pPr != null && pPr.ParagraphStyleId != null && pPr.ParagraphStyleId.Val != null) {
            styleId = pPr.ParagraphStyleId.Val.Value;
        } else {
            styleId = "Normal";
        }

        flowPara.Tag = styleId;
        if (styleId.StartsWith("Heading") || styleId.StartsWith("heading")) {
            int level = 1;
            if (styleId.Length > 7) int.TryParse(styleId.Substring(7), out level);
            flowPara.FontWeight = FontWeights.Bold;
            flowPara.FontSize = Math.Max(11, 24 - (level * 2)) * (96.0 / 72.0); // Convert points to pixels
            flowPara.Margin = new Thickness(0, 12.0 * (96.0 / 72.0), 0, 4.0 * (96.0 / 72.0));
            effFontSize = flowPara.FontSize;
        } else if (styleId.Contains("Quote") || styleId.Contains("quote")) {
            flowPara.FontStyle = FontStyles.Italic;
            flowPara.Foreground = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(100, 100, 100));
            flowPara.BorderBrush = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(200, 200, 200));
            flowPara.BorderThickness = new Thickness(3.0 * (96.0 / 72.0), 0, 0, 0);
            flowPara.Padding = new Thickness(12.0 * (96.0 / 72.0), 4.0 * (96.0 / 72.0), 4.0 * (96.0 / 72.0), 4.0 * (96.0 / 72.0));
        } else if (!string.IsNullOrEmpty(styleId) && docStyles != null) {
            var fontSizeProp = GetPropertyFromStyleHierarchy<DocumentFormat.OpenXml.Wordprocessing.FontSize>(styleId, docStyles);
            if (fontSizeProp != null && fontSizeProp.Val != null) {
                double sz;
                if (double.TryParse(fontSizeProp.Val.Value, out sz)) {
                    effFontSize = (sz / 2.0) * (96.0 / 72.0);
                }
            } else if (defaultRPr != null) {
                var defaultFontSize = defaultRPr.Elements<DocumentFormat.OpenXml.Wordprocessing.FontSize>().FirstOrDefault();
                if (defaultFontSize != null && defaultFontSize.Val != null) {
                    double sz;
                    if (double.TryParse(defaultFontSize.Val.Value, out sz)) {
                        effFontSize = (sz / 2.0) * (96.0 / 72.0);
                    }
                }
            }
            // Apply bold from paragraph style hierarchy
            var styleBold = GetPropertyFromStyleHierarchy<DocumentFormat.OpenXml.Wordprocessing.Bold>(styleId, docStyles);
            if (styleBold != null && IsBoldTrue(styleBold)) {
                flowPara.FontWeight = FontWeights.Bold;
            } else {
                var styleBoldCs = GetPropertyFromStyleHierarchy<DocumentFormat.OpenXml.Wordprocessing.BoldComplexScript>(styleId, docStyles);
                if (styleBoldCs != null && (styleBoldCs.Val == null || styleBoldCs.Val.Value)) {
                    flowPara.FontWeight = FontWeights.Bold;
                }
            }
            // Apply italic from paragraph style hierarchy
            var styleItalic = GetPropertyFromStyleHierarchy<DocumentFormat.OpenXml.Wordprocessing.Italic>(styleId, docStyles);
            if (styleItalic != null && IsItalicTrue(styleItalic)) {
                flowPara.FontStyle = FontStyles.Italic;
            } else {
                var styleItalicCs = GetPropertyFromStyleHierarchy<DocumentFormat.OpenXml.Wordprocessing.ItalicComplexScript>(styleId, docStyles);
                if (styleItalicCs != null && (styleItalicCs.Val == null || styleItalicCs.Val.Value)) {
                    flowPara.FontStyle = FontStyles.Italic;
                }
            }
        }

        // Scan all runs inside the paragraph to resolve the actual maximum font size.
        // This ensures line heights scale proportionally to inline run sizes.
        double maxRunFontSize = effFontSize;
        foreach (var run in para.Descendants<DocumentFormat.OpenXml.Wordprocessing.Run>()) {
            string runStyleId = (run.RunProperties != null && run.RunProperties.RunStyle != null && run.RunProperties.RunStyle.Val != null)
                ? run.RunProperties.RunStyle.Val.Value
                : null;
            var rFontSize = GetRunProperty<DocumentFormat.OpenXml.Wordprocessing.FontSize>(run.RunProperties, runStyleId, styleId, docStyles, defaultRPr);
            if (rFontSize != null && rFontSize.Val != null) {
                double sz;
                if (double.TryParse(rFontSize.Val.Value, out sz)) {
                    double runSize = (sz / 2.0) * (96.0 / 72.0);
                    if (runSize > maxRunFontSize) {
                        maxRunFontSize = runSize;
                    }
                }
            }
        }
        effFontSize = maxRunFontSize;

        // Justification
        var jc = GetParagraphProperty<Justification>(pPr, styleId, docStyles, defaultPPr);
        if (jc != null) {
            var jcVal = jc.Val != null ? jc.Val.Value : JustificationValues.Left;
            switch (jcVal) {
                case JustificationValues.Center: flowPara.TextAlignment = System.Windows.TextAlignment.Center; break;
                case JustificationValues.Right: flowPara.TextAlignment = System.Windows.TextAlignment.Right; break;
                case JustificationValues.Both: flowPara.TextAlignment = System.Windows.TextAlignment.Justify; break;
                default: flowPara.TextAlignment = System.Windows.TextAlignment.Left; break;
            }
        }

        // Shading/Background
        var shading = GetParagraphProperty<Shading>(pPr, styleId, docStyles, defaultPPr);
        if (shading != null && shading.Fill != null) {
            string fillHex = shading.Fill.Value;
            if (!string.IsNullOrEmpty(fillHex) && fillHex != "auto" && fillHex != "Auto") {
                try {
                    flowPara.Background = new System.Windows.Media.SolidColorBrush(
                        (System.Windows.Media.Color)System.Windows.Media.ColorConverter.ConvertFromString("#" + fillHex));
                    flowPara.Padding = new Thickness(10, 6, 10, 6);
                } catch { }
            }
        }

        // Default paragraph margin (Word style: 0 before, scaled after)
        flowPara.Margin = new Thickness(0, 0, 0, effFontSize * 0.6);

        // Indentation
        var indent = GetParagraphProperty<DocumentFormat.OpenXml.Wordprocessing.Indentation>(pPr, styleId, docStyles, defaultPPr);
        if (indent != null) {
            double leftIndent = 0, rightIndent = 0, firstLine = 0;
            if (indent.Left != null) {
                double val;
                if (double.TryParse(indent.Left.Value, out val))
                    leftIndent = (val / 20.0) * (96.0 / 72.0);
            }
            if (indent.Right != null) {
                double val;
                if (double.TryParse(indent.Right.Value, out val))
                    rightIndent = (val / 20.0) * (96.0 / 72.0);
            }
            if (indent.FirstLine != null) {
                double val;
                if (double.TryParse(indent.FirstLine.Value, out val))
                    firstLine = (val / 20.0) * (96.0 / 72.0);
            }
            if (leftIndent > 0 || rightIndent > 0) {
                double top = flowPara.Margin.Top;
                double bottom = flowPara.Margin.Bottom;
                flowPara.Margin = new Thickness(leftIndent, top, rightIndent, bottom);
            }
            if (firstLine > 0)
                flowPara.TextIndent = firstLine;
        }

        // Spacing (before/after) and Line spacing (within paragraph)
        var spacing = GetParagraphProperty<DocumentFormat.OpenXml.Wordprocessing.SpacingBetweenLines>(pPr, styleId, docStyles, defaultPPr);
        double before = 0;
        double after = 0; // Default no after-spacing; Chinese docs typically have 0pt after-paragraph spacing
        if (spacing != null) {
            if (spacing.BeforeLines != null) {
                double val = spacing.BeforeLines.Value;
                var ls = doc.Tag as DocLayoutSettings;
                double lineUnit = (ls != null && ls.LinePitch > 0) ? ((ls.LinePitch / 20.0) * (96.0 / 72.0)) : (effFontSize * 1.3);
                before = lineUnit * (val / 100.0);
            } else if (spacing.Before != null) {
                double val;
                if (double.TryParse(spacing.Before.Value, out val))
                    before = (val / 20.0) * (96.0 / 72.0);
            }

            if (spacing.AfterLines != null) {
                double val = spacing.AfterLines.Value;
                var ls = doc.Tag as DocLayoutSettings;
                double lineUnit = (ls != null && ls.LinePitch > 0) ? ((ls.LinePitch / 20.0) * (96.0 / 72.0)) : (effFontSize * 1.3);
                after = lineUnit * (val / 100.0);
            } else if (spacing.After != null) {
                double val;
                if (double.TryParse(spacing.After.Value, out val))
                    after = (val / 20.0) * (96.0 / 72.0);
            }
        }
        double leftMargin = flowPara.Margin.Left;
        double rightMargin = flowPara.Margin.Right;
        flowPara.Margin = new Thickness(leftMargin, before, rightMargin, after);

        // Resolve document grid line height (used as base unit for line spacing)
        var _layoutSettings = doc.Tag as DocLayoutSettings;
        double gridLineHeight = 0;
        if (_layoutSettings != null && _layoutSettings.LinePitch > 0) {
            gridLineHeight = (_layoutSettings.LinePitch / 20.0) * (96.0 / 72.0); // twips → WPF pixels
        }

        if (spacing != null && spacing.Line != null) {
            string lineStr = spacing.Line.Value;
            double lineVal;
            if (double.TryParse(lineStr, out lineVal)) {
                var lineRule = spacing.LineRule != null ? spacing.LineRule.Value : LineSpacingRuleValues.Auto;
                if (lineRule == LineSpacingRuleValues.Auto) {
                    double multiple = lineVal / 240.0;
                    if (gridLineHeight > 0) {
                        // Word uses grid pitch as the base unit for Auto multipliers
                        // 240 = 1 grid unit, 360 = 1.5 grid units, 480 = 2 grid units
                        double baseHeight = Math.Max(gridLineHeight, effFontSize * 1.2);
                        flowPara.LineHeight = baseHeight * multiple;
                    } else {
                        // No grid — use font-proportional with leading
                        flowPara.LineHeight = effFontSize * multiple * 1.2;
                    }
                    flowPara.LineStackingStrategy = LineStackingStrategy.MaxHeight;
                } else if (lineRule == LineSpacingRuleValues.Exact) {
                    flowPara.LineHeight = (lineVal / 20.0) * (96.0 / 72.0);
                    flowPara.LineStackingStrategy = LineStackingStrategy.BlockLineHeight;
                } else if (lineRule == LineSpacingRuleValues.AtLeast) {
                    flowPara.LineHeight = (lineVal / 20.0) * (96.0 / 72.0);
                    flowPara.LineStackingStrategy = LineStackingStrategy.MaxHeight;
                }
            }
        } else {
            // No explicit spacing — use document grid for line height
            if (gridLineHeight > 0) {
                // Snap text to grid: each line occupies ceil(fontHeight / gridPitch) grid units
                double fontNaturalHeight = effFontSize * 1.2; // approximate font line metrics
                double gridUnits = Math.Ceiling(fontNaturalHeight / gridLineHeight);
                flowPara.LineHeight = gridUnits * gridLineHeight;
            } else {
                // No grid — use font-proportional spacing (~130% of font em-size)
                flowPara.LineHeight = effFontSize * 1.3;
            }
            flowPara.LineStackingStrategy = LineStackingStrategy.MaxHeight;
        }

        // Process paragraph children (Runs, Hyperlinks, Bookmarks, etc.)
        foreach (var child in para.ChildElements) {
            if (child is DocumentFormat.OpenXml.Wordprocessing.Run) {
                var run = (DocumentFormat.OpenXml.Wordprocessing.Run)child;
                
                // Check for inline images (Drawing elements)
                var drawings = run.Descendants<DocumentFormat.OpenXml.Wordprocessing.Drawing>();
                bool hasDrawing = false;
                foreach (var drawing in drawings) {
                    hasDrawing = true;
                    try {
                        var img = ExtractImageFromDrawing(drawing, mainPart);
                        if (img != null) {
                            flowPara.Inlines.Add(new InlineUIContainer(img));
                        }
                    } catch {
                        flowPara.Inlines.Add(new System.Windows.Documents.Run("[Image]") {
                            Foreground = System.Windows.Media.Brushes.Gray,
                            FontStyle = FontStyles.Italic
                        });
                    }
                }
                string runStyleId = (run.RunProperties != null && run.RunProperties.RunStyle != null && run.RunProperties.RunStyle.Val != null) 
                    ? run.RunProperties.RunStyle.Val.Value 
                    : null;
                string text = run.InnerText;
                var flowRun = new System.Windows.Documents.Run(text);
                ApplyRunProperties(flowRun, run.RunProperties, runStyleId, styleId, docStyles, defaultRPr);
                flowPara.Inlines.Add(flowRun);

            } else if (child is DocumentFormat.OpenXml.Wordprocessing.Hyperlink) {
                var hyperlink = (DocumentFormat.OpenXml.Wordprocessing.Hyperlink)child;
                string url = "";
                
                // Resolve the URL from relationship
                if (hyperlink.Id != null) {
                    try {
                        var rel = mainPart.HyperlinkRelationships
                            .FirstOrDefault(r => r.Id == hyperlink.Id.Value);
                        if (rel != null) url = rel.Uri.ToString();
                    } catch { }
                }
                if (string.IsNullOrEmpty(url) && hyperlink.Anchor != null) {
                    url = "#" + hyperlink.Anchor.Value;
                }

                // Get link display text and formatting
                string linkText = "";
                var linkSpan = new System.Windows.Documents.Hyperlink();
                foreach (var hRun in hyperlink.Elements<DocumentFormat.OpenXml.Wordprocessing.Run>()) {
                    linkText += hRun.InnerText;
                    string linkRunStyleId = (hRun.RunProperties != null && hRun.RunProperties.RunStyle != null && hRun.RunProperties.RunStyle.Val != null) 
                        ? hRun.RunProperties.RunStyle.Val.Value 
                        : null;
                    var linkFlowRun = new System.Windows.Documents.Run(hRun.InnerText);
                    ApplyRunProperties(linkFlowRun, hRun.RunProperties, linkRunStyleId, styleId, docStyles, defaultRPr);
                    linkSpan.Inlines.Add(linkFlowRun);
                }

                if (!string.IsNullOrEmpty(url)) {
                    try { linkSpan.NavigateUri = new Uri(url, UriKind.RelativeOrAbsolute); } catch { }
                    linkSpan.ToolTip = url;
                    linkSpan.Cursor = System.Windows.Input.Cursors.Hand;
                    linkSpan.RequestNavigate += (sender, e) => {
                        try { System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo(e.Uri.AbsoluteUri) { UseShellExecute = true }); } catch { }
                        e.Handled = true;
                    };
                }
                linkSpan.Foreground = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(17, 85, 204));
                flowPara.Inlines.Add(linkSpan);

            } else if (child is DocumentFormat.OpenXml.Wordprocessing.BookmarkStart ||
                       child is DocumentFormat.OpenXml.Wordprocessing.BookmarkEnd ||
                       child is DocumentFormat.OpenXml.Wordprocessing.ProofError) {
                // Skip bookmark markers and proofing info
                continue;
            }
        }

        return flowPara;
    }

    // Check if a Bold element actually means "bold" (bare <w:b/> = true, <w:b w:val="0"/> = false)
    private static bool IsBoldTrue(DocumentFormat.OpenXml.Wordprocessing.Bold bold) {
        if (bold == null) return false;
        if (bold.Val == null) return true; // bare <w:b/> means true
        return bold.Val.Value; // OnOffValue resolves "0"/"false" to false, "1"/"true" to true
    }

    // Check if an Italic element actually means "italic"
    private static bool IsItalicTrue(DocumentFormat.OpenXml.Wordprocessing.Italic italic) {
        if (italic == null) return false;
        if (italic.Val == null) return true;
        return italic.Val.Value;
    }

    private T GetRunProperty<T>(RunProperties rPr, string runStyleId, string paragraphStyleId, Styles styles, RunProperties defaultRPr) where T : OpenXmlElement {
        if (rPr != null) {
            var prop = rPr.Elements<T>().FirstOrDefault();
            if (prop != null) return prop;
        }
        if (!string.IsNullOrEmpty(runStyleId)) {
            var prop = GetPropertyFromStyleHierarchy<T>(runStyleId, styles);
            if (prop != null) return prop;
        }
        if (!string.IsNullOrEmpty(paragraphStyleId)) {
            var prop = GetPropertyFromStyleHierarchy<T>(paragraphStyleId, styles);
            if (prop != null) return prop;
        }
        if (defaultRPr != null) {
            var prop = defaultRPr.Elements<T>().FirstOrDefault();
            if (prop != null) return prop;
        }
        return null;
    }

    // Apply run properties to a WPF Run
    private void ApplyRunProperties(System.Windows.Documents.Run flowRun, RunProperties rPr, string runStyleId, string paragraphStyleId, Styles styles, RunProperties defaultRPr) {
        if (rPr == null && string.IsNullOrEmpty(runStyleId) && string.IsNullOrEmpty(paragraphStyleId) && defaultRPr == null) return;
        
        var bold = GetRunProperty<DocumentFormat.OpenXml.Wordprocessing.Bold>(rPr, runStyleId, paragraphStyleId, styles, defaultRPr);
        if (bold != null && IsBoldTrue(bold)) {
            flowRun.FontWeight = FontWeights.Bold;
        } else {
            // Check BoldComplexScript for CJK text
            var boldCs = GetRunProperty<DocumentFormat.OpenXml.Wordprocessing.BoldComplexScript>(rPr, runStyleId, paragraphStyleId, styles, defaultRPr);
            if (boldCs != null && (boldCs.Val == null || boldCs.Val.Value)) {
                flowRun.FontWeight = FontWeights.Bold;
            }
        }
        
        var italic = GetRunProperty<DocumentFormat.OpenXml.Wordprocessing.Italic>(rPr, runStyleId, paragraphStyleId, styles, defaultRPr);
        if (italic != null && IsItalicTrue(italic)) {
            flowRun.FontStyle = FontStyles.Italic;
        } else {
            var italicCs = GetRunProperty<DocumentFormat.OpenXml.Wordprocessing.ItalicComplexScript>(rPr, runStyleId, paragraphStyleId, styles, defaultRPr);
            if (italicCs != null && (italicCs.Val == null || italicCs.Val.Value)) {
                flowRun.FontStyle = FontStyles.Italic;
            }
        }
        
        var decs = new TextDecorationCollection();
        var underline = GetRunProperty<DocumentFormat.OpenXml.Wordprocessing.Underline>(rPr, runStyleId, paragraphStyleId, styles, defaultRPr);
        if (underline != null && underline.Val != null && underline.Val.Value != UnderlineValues.None) {
            foreach (var d in TextDecorations.Underline) decs.Add(d);
        }
        var strike = GetRunProperty<DocumentFormat.OpenXml.Wordprocessing.Strike>(rPr, runStyleId, paragraphStyleId, styles, defaultRPr);
        if (strike != null) {
            foreach (var d in TextDecorations.Strikethrough) decs.Add(d);
        }
        if (decs.Count > 0) {
            flowRun.TextDecorations = decs;
        }

        var fontSize = GetRunProperty<DocumentFormat.OpenXml.Wordprocessing.FontSize>(rPr, runStyleId, paragraphStyleId, styles, defaultRPr);
        if (fontSize != null) {
            double sz;
            if (fontSize.Val != null && double.TryParse(fontSize.Val.Value, out sz))
                flowRun.FontSize = (sz / 2.0) * (96.0 / 72.0); // Convert points to WPF pixels
        }
        var color = GetRunProperty<DocumentFormat.OpenXml.Wordprocessing.Color>(rPr, runStyleId, paragraphStyleId, styles, defaultRPr);
        if (color != null && color.Val != null) {
            try {
                string cVal = color.Val.Value;
                if (cVal != "auto" && cVal != "Auto")
                    flowRun.Foreground = new System.Windows.Media.SolidColorBrush(
                        (System.Windows.Media.Color)System.Windows.Media.ColorConverter.ConvertFromString("#" + cVal));
            } catch { }
        }
        
        string asciiFont = null;
        string eastAsiaFont = null;
        var runFonts = GetRunProperty<DocumentFormat.OpenXml.Wordprocessing.RunFonts>(rPr, runStyleId, paragraphStyleId, styles, defaultRPr);
        if (runFonts != null) {
            asciiFont = ResolveRunFontName(runFonts, _themeMajorLatin, _themeMinorLatin, _themeMajorEastAsia, _themeMinorEastAsia, false);
            eastAsiaFont = ResolveRunFontName(runFonts, _themeMajorLatin, _themeMinorLatin, _themeMajorEastAsia, _themeMinorEastAsia, true);
        }

        bool hasNonAscii = false;
        if (flowRun.Text != null) {
            foreach (char ch in flowRun.Text) {
                if (ch > 127) { hasNonAscii = true; break; }
            }
        }

        if (hasNonAscii && string.IsNullOrEmpty(eastAsiaFont)) {
            eastAsiaFont = _themeMinorEastAsia; // Fallback to document default East Asian font
        }
        if (string.IsNullOrEmpty(asciiFont)) {
            asciiFont = _themeMinorLatin; // Fallback to document default Latin font
        }

        string fontChain = "";
        if (hasNonAscii) {
            if (!string.IsNullOrEmpty(eastAsiaFont)) fontChain += eastAsiaFont;
            if (!string.IsNullOrEmpty(asciiFont) && asciiFont != eastAsiaFont) {
                if (fontChain != "") fontChain += ", ";
                fontChain += asciiFont;
            }
        } else {
            if (!string.IsNullOrEmpty(asciiFont)) fontChain += asciiFont;
            if (!string.IsNullOrEmpty(eastAsiaFont) && eastAsiaFont != asciiFont) {
                if (fontChain != "") fontChain += ", ";
                fontChain += eastAsiaFont;
            }
        }
        if (!string.IsNullOrEmpty(fontChain)) {
            flowRun.FontFamily = ResolveFontFamily(fontChain);
        }
        // Highlight
        if (rPr != null && rPr.Highlight != null && rPr.Highlight.Val != null) {
            flowRun.Background = HighlightColorToBrush(rPr.Highlight.Val.Value);
        }
        // Shading on run
        if (rPr != null && rPr.Shading != null && rPr.Shading.Fill != null) {
            string fillHex = rPr.Shading.Fill.Value;
            if (!string.IsNullOrEmpty(fillHex) && fillHex != "auto" && fillHex != "Auto") {
                try {
                    flowRun.Background = new System.Windows.Media.SolidColorBrush(
                        (System.Windows.Media.Color)System.Windows.Media.ColorConverter.ConvertFromString("#" + fillHex));
                } catch { }
            }
        }
        // Superscript / Subscript
        if (rPr != null && rPr.VerticalTextAlignment != null && rPr.VerticalTextAlignment.Val != null) {
            if (rPr.VerticalTextAlignment.Val.Value == VerticalPositionValues.Superscript) {
                flowRun.Typography.Variants = System.Windows.FontVariants.Superscript;
                flowRun.FontSize = (flowRun.FontSize > 0 ? flowRun.FontSize : 14) * 0.7;
                flowRun.BaselineAlignment = BaselineAlignment.Superscript;
            } else if (rPr.VerticalTextAlignment.Val.Value == VerticalPositionValues.Subscript) {
                flowRun.Typography.Variants = System.Windows.FontVariants.Subscript;
                flowRun.FontSize = (flowRun.FontSize > 0 ? flowRun.FontSize : 14) * 0.7;
                flowRun.BaselineAlignment = BaselineAlignment.Subscript;
            }
        }
    }

    // Convert OOXML highlight color name to WPF Brush
    private System.Windows.Media.Brush HighlightColorToBrush(HighlightColorValues color) {
        switch (color) {
            case HighlightColorValues.Yellow: return new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(255, 255, 0));
            case HighlightColorValues.Green: return new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(0, 255, 0));
            case HighlightColorValues.Cyan: return new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(0, 255, 255));
            case HighlightColorValues.Magenta: return new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(255, 0, 255));
            case HighlightColorValues.Blue: return new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(0, 0, 255));
            case HighlightColorValues.Red: return new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(255, 0, 0));
            case HighlightColorValues.DarkBlue: return new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(0, 0, 139));
            case HighlightColorValues.DarkCyan: return new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(0, 139, 139));
            case HighlightColorValues.DarkGreen: return new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(0, 100, 0));
            case HighlightColorValues.DarkMagenta: return new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(139, 0, 139));
            case HighlightColorValues.DarkRed: return new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(139, 0, 0));
            case HighlightColorValues.DarkYellow: return new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(128, 128, 0));
            case HighlightColorValues.DarkGray: return new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(169, 169, 169));
            case HighlightColorValues.LightGray: return new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(211, 211, 211));
            case HighlightColorValues.Black: return new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(0, 0, 0));
            case HighlightColorValues.White: return new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(255, 255, 255));
            default: return System.Windows.Media.Brushes.Yellow;
        }
    }

    // Extract an image from an OpenXML Drawing element
    private System.Windows.Controls.Image ExtractImageFromDrawing(
        DocumentFormat.OpenXml.Wordprocessing.Drawing drawing, MainDocumentPart mainPart) {
        
        // Try inline images first, then anchored
        var blipFill = drawing.Descendants<DocumentFormat.OpenXml.Drawing.Blip>().FirstOrDefault();
        if (blipFill == null || blipFill.Embed == null) return null;
        
        string relId = blipFill.Embed.Value;
        var imagePart = mainPart.GetPartById(relId);
        if (imagePart == null) return null;
        
        var bi = new System.Windows.Media.Imaging.BitmapImage();
        using (var stream = imagePart.GetStream()) {
            bi.BeginInit();
            bi.CacheOption = System.Windows.Media.Imaging.BitmapCacheOption.OnLoad;
            bi.StreamSource = stream;
            bi.EndInit();
        }
        bi.Freeze();
        
        var img = new System.Windows.Controls.Image();
        img.Source = bi;
        img.Stretch = System.Windows.Media.Stretch.Uniform;
        
        // Try to get dimensions from extent (EMU → pixels, 1 EMU = 1/914400 inch, 96 DPI)
        double maxWidth = 600;
        var extents = drawing.Descendants<DocumentFormat.OpenXml.Drawing.Wordprocessing.Extent>().FirstOrDefault();
        if (extents != null) {
            if (extents.Cx != null && extents.Cx.Value > 0) {
                double widthPx = extents.Cx.Value / 914400.0 * 96.0;
                maxWidth = Math.Min(widthPx, 660);
            }
            if (extents.Cy != null && extents.Cy.Value > 0) {
                double heightPx = extents.Cy.Value / 914400.0 * 96.0;
                img.MaxHeight = heightPx;
            }
        }
        img.MaxWidth = maxWidth;
        img.Margin = new Thickness(0, 4, 0, 4);
        return img;
    }

    // Build a FlowDocument Table from an OpenXML Table
    private System.Windows.Documents.Table BuildFlowTable(
        DocumentFormat.OpenXml.Wordprocessing.Table oxTable, MainDocumentPart mainPart, FlowDocument doc) {
        
        var flowTable = new System.Windows.Documents.Table();
        flowTable.BorderBrush = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(110, 110, 110));
        flowTable.BorderThickness = new Thickness(1);
        flowTable.CellSpacing = 0;
        flowTable.Margin = new Thickness(0, 8, 0, 8);

        // Parse TableGrid for high-fidelity column widths
        var tblGrid = oxTable.Elements<TableGrid>().FirstOrDefault();
        if (tblGrid != null) {
            var gridCols = tblGrid.Elements<GridColumn>().ToList();
            if (gridCols.Count > 0) {
                foreach (var gc in gridCols) {
                    double wVal = 100;
                    if (gc.Width != null) {
                        double twips;
                        if (double.TryParse(gc.Width.Value, out twips)) {
                            wVal = twips / 15.0; // convert twips to WPF pixels
                        }
                    }
                    flowTable.Columns.Add(new System.Windows.Documents.TableColumn { Width = new GridLength(wVal) });
                }
            }
        }

        var rg = new System.Windows.Documents.TableRowGroup();
        foreach (var oxRow in oxTable.Elements<DocumentFormat.OpenXml.Wordprocessing.TableRow>()) {
            var flowRow = new System.Windows.Documents.TableRow();
            foreach (var oxCell in oxRow.Elements<DocumentFormat.OpenXml.Wordprocessing.TableCell>()) {
                var cell = new System.Windows.Documents.TableCell();
                cell.BorderBrush = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(110, 110, 110));
                cell.BorderThickness = new Thickness(0.5);
                cell.Padding = new Thickness(8, 6, 8, 6);

                // Cell content — multiple paragraphs
                foreach (var cellPara in oxCell.Elements<DocumentFormat.OpenXml.Wordprocessing.Paragraph>()) {
                    var flowCellPara = BuildFlowParagraph(cellPara, cellPara.ParagraphProperties, mainPart, doc);
                    flowCellPara.Margin = new Thickness(0, 0, 0, 2);
                    cell.Blocks.Add(flowCellPara);
                }
                // If no blocks were added, add empty paragraph
                if (cell.Blocks.Count == 0) {
                    cell.Blocks.Add(new System.Windows.Documents.Paragraph());
                }

                // Cell properties
                var tcPr = oxCell.TableCellProperties;
                if (tcPr != null) {
                    var shading = tcPr.Shading;
                    if (shading != null && shading.Fill != null) {
                        string fillHex = shading.Fill.Value;
                        if (!string.IsNullOrEmpty(fillHex) && fillHex != "auto" && fillHex != "Auto") {
                            try {
                                cell.Background = new System.Windows.Media.SolidColorBrush(
                                    (System.Windows.Media.Color)System.Windows.Media.ColorConverter.ConvertFromString("#" + fillHex));
                            } catch { }
                        }
                    }
                    var gridSpan = tcPr.GridSpan;
                    if (gridSpan != null && gridSpan.Val != null) {
                        int spanVal;
                        if (int.TryParse(gridSpan.Val.ToString(), out spanVal) && spanVal > 1) {
                            cell.ColumnSpan = spanVal;
                        }
                    }
                }
                flowRow.Cells.Add(cell);
            }
            rg.Rows.Add(flowRow);
        }
        flowTable.RowGroups.Add(rg);
        if (flowTable.Columns.Count == 0) {
            int maxCols = 1;
            foreach (var r in rg.Rows) {
                int rowColCount = 0;
                foreach (var c in r.Cells) rowColCount += c.ColumnSpan;
                if (rowColCount > maxCols) maxCols = rowColCount;
            }
            for (int i = 0; i < maxCols; i++)
                flowTable.Columns.Add(new System.Windows.Documents.TableColumn { Width = new GridLength(1, GridUnitType.Star) });
        }

        // Fix table cropping: scale absolute column widths to fit within available content area
        try {
            double pageWidth = double.IsNaN(doc.PageWidth) ? 816.0 : doc.PageWidth;
            double availableWidth = pageWidth - doc.PagePadding.Left - doc.PagePadding.Right;
            if (availableWidth > 0 && flowTable.Columns.Count > 0) {
                double totalColWidth = 0;
                bool allAbsolute = true;
                foreach (var col in flowTable.Columns) {
                    if (col.Width.IsStar) { allAbsolute = false; break; }
                    totalColWidth += col.Width.Value;
                }
                // Only scale if columns use absolute widths and exceed available space
                if (allAbsolute && totalColWidth > availableWidth && totalColWidth > 0) {
                    double scale = availableWidth / totalColWidth;
                    foreach (var col in flowTable.Columns) {
                        col.Width = new GridLength(col.Width.Value * scale);
                    }
                }
            }
        } catch { }

        return flowTable;
    }

}
#endif
