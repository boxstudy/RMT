// =============================================================================
// Document editing: dark mode, export, search/replace (ENABLE_DOCUMENT)
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
    // === Non-Destructive Dark Mode ===
    // Use Dictionary keyed by DependencyObject (reference equality by default)
    private System.Collections.Generic.Dictionary<DependencyObject, System.Windows.Media.Brush[]>
        _darkModeStore = new System.Collections.Generic.Dictionary<DependencyObject, System.Windows.Media.Brush[]>();
    private bool _isDarkMode = false;
    private string _preDarkModeRtf = null;

    private void ApplyDarkModeToDocument(FlowDocument doc) {
        if (_isDarkMode) return;
        _darkModeStore = new System.Collections.Generic.Dictionary<DependencyObject, System.Windows.Media.Brush[]>();
        _isDarkMode = true;
        ApplyDarkModeToElement(doc);
    }

    private void RestoreDocumentColors(FlowDocument doc) {
        if (!_isDarkMode) return;
        
        RestoreElementColors(doc);
        
        _darkModeStore = new System.Collections.Generic.Dictionary<DependencyObject, System.Windows.Media.Brush[]>();
        _isDarkMode = false;
    }

    private void StoreOriginal(DependencyObject element, System.Windows.Media.Brush fg, System.Windows.Media.Brush bg) {
        _darkModeStore[element] = new System.Windows.Media.Brush[] { fg, bg };
    }

    private bool TryGetOriginal(DependencyObject element, out System.Windows.Media.Brush fg, out System.Windows.Media.Brush bg) {
        System.Windows.Media.Brush[] stored;
        if (_darkModeStore.TryGetValue(element, out stored)) {
            fg = stored[0];
            bg = stored[1];
            return true;
        }
        fg = null; bg = null;
        return false;
    }

    private void ApplyDarkModeToElement(DependencyObject obj) {
        if (obj == null) return;
        
        if (obj is System.Windows.Documents.TextElement) {
            var te = (System.Windows.Documents.TextElement)obj;
            var localFg = te.ReadLocalValue(System.Windows.Documents.TextElement.ForegroundProperty) as System.Windows.Media.Brush;
            var localBg = te.ReadLocalValue(System.Windows.Documents.TextElement.BackgroundProperty) as System.Windows.Media.Brush;
            StoreOriginal(te, localFg, localBg);
            
            if (te is System.Windows.Documents.Run) {
                var run = (System.Windows.Documents.Run)te;
                if (run.Foreground is System.Windows.Media.SolidColorBrush) {
                    var origFg = ((System.Windows.Media.SolidColorBrush)run.Foreground).Color;
                    if (origFg.R == 0 && origFg.G == 0 && origFg.B == 0) {
                        run.Foreground = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(224, 224, 224));
                    } else {
                        byte grey = (byte)(0.299 * origFg.R + 0.587 * origFg.G + 0.114 * origFg.B);
                        byte invGrey = (byte)Math.Min(255, 255 - grey + 60);
                        run.Foreground = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(invGrey, invGrey, invGrey));
                    }
                } else {
                    run.Foreground = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(224, 224, 224));
                }
                
                if (run.Background != null && run.Background is System.Windows.Media.SolidColorBrush) {
                    var origBg = ((System.Windows.Media.SolidColorBrush)run.Background).Color;
                    run.Background = new System.Windows.Media.SolidColorBrush(ToDarkGreyscale(origBg));
                }
            } else if (te is System.Windows.Documents.Hyperlink) {
                te.Foreground = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(108, 180, 238));
            } else if (te is System.Windows.Documents.Paragraph || te is System.Windows.Documents.TableCell || te is System.Windows.Documents.List) {
                te.Foreground = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(224, 224, 224));
                if (te.Background != null && te.Background is System.Windows.Media.SolidColorBrush) {
                    var origBg = ((System.Windows.Media.SolidColorBrush)te.Background).Color;
                    te.Background = new System.Windows.Media.SolidColorBrush(ToDarkGreyscale(origBg));
                }
            } else if (te is System.Windows.Documents.Table) {
                var table = (System.Windows.Documents.Table)te;
                var localBorder = table.ReadLocalValue(System.Windows.Documents.Block.BorderBrushProperty) as System.Windows.Media.Brush;
                StoreOriginal(table, localBorder, null);
                table.BorderBrush = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(60, 60, 60));
            }
        }
        
        foreach (var child in LogicalTreeHelper.GetChildren(obj)) {
            if (child is DependencyObject) {
                ApplyDarkModeToElement((DependencyObject)child);
            }
        }
    }

    private void RestoreElementColors(DependencyObject obj) {
        if (obj == null) return;
        
        if (obj is System.Windows.Documents.TextElement) {
            var te = (System.Windows.Documents.TextElement)obj;
            System.Windows.Media.Brush fg, bg;
            if (TryGetOriginal(te, out fg, out bg)) {
                if (te is System.Windows.Documents.Table) {
                    if (fg == null) ((System.Windows.Documents.Table)te).ClearValue(System.Windows.Documents.Block.BorderBrushProperty);
                    else ((System.Windows.Documents.Table)te).BorderBrush = fg;
                } else {
                    if (fg == null) te.ClearValue(System.Windows.Documents.TextElement.ForegroundProperty);
                    else te.Foreground = fg;
                    
                    if (bg == null) te.ClearValue(System.Windows.Documents.TextElement.BackgroundProperty);
                    else te.Background = bg;
                }
            }
        }
        
        foreach (var child in LogicalTreeHelper.GetChildren(obj)) {
            if (child is DependencyObject) {
                RestoreElementColors((DependencyObject)child);
            }
        }
    }

    private System.Windows.Media.Color ToDarkGreyscale(System.Windows.Media.Color c) {
        byte grey = (byte)(0.299 * c.R + 0.587 * c.G + 0.114 * c.B);
        byte dark = (byte)(20 + (grey * 30 / 255));
        return System.Windows.Media.Color.FromRgb(dark, dark, dark);
    }

    private void FlowDocumentToDocx(FlowDocument flowDoc, string filePath) {
        using (var wordDoc = WordprocessingDocument.Create(filePath, WordprocessingDocumentType.Document)) {
            var mainPart = wordDoc.AddMainDocumentPart();
            mainPart.Document = new DocumentFormat.OpenXml.Wordprocessing.Document();
            var body = new DocumentFormat.OpenXml.Wordprocessing.Body();

            ConvertWpfBlocksToOpenXml(flowDoc.Blocks, body, mainPart);

            mainPart.Document.Append(body);
            mainPart.Document.Save();
        }
    }

    private void ConvertWpfBlocksToOpenXml(System.Windows.Documents.BlockCollection blocks, DocumentFormat.OpenXml.Wordprocessing.Body body, MainDocumentPart mainPart) {
        foreach (var block in blocks) {
            if (block is System.Windows.Documents.Paragraph) {
                var flowPara = (System.Windows.Documents.Paragraph)block;
                var oxPara = ConvertWpfParagraphToOpenXml(flowPara, mainPart);
                body.AppendChild(oxPara);
            } else if (block is System.Windows.Documents.Table) {
                var flowTable = (System.Windows.Documents.Table)block;
                var oxTable = ConvertWpfTableToOpenXml(flowTable, mainPart);
                body.AppendChild(oxTable);
            } else if (block is System.Windows.Documents.List) {
                var flowList = (System.Windows.Documents.List)block;
                foreach (var li in flowList.ListItems) {
                    ConvertWpfBlocksToOpenXml(li.Blocks, body, mainPart);
                }
            } else if (block is System.Windows.Documents.Section) {
                var flowSection = (System.Windows.Documents.Section)block;
                ConvertWpfBlocksToOpenXml(flowSection.Blocks, body, mainPart);
            }
        }
    }

    private DocumentFormat.OpenXml.Wordprocessing.Paragraph ConvertWpfParagraphToOpenXml(System.Windows.Documents.Paragraph flowPara, MainDocumentPart mainPart) {
        var oxPara = new DocumentFormat.OpenXml.Wordprocessing.Paragraph();

        var pPr = new DocumentFormat.OpenXml.Wordprocessing.ParagraphProperties();
        
        string styleId = flowPara.Tag as string ?? "";
        if (!string.IsNullOrEmpty(styleId)) {
            pPr.Append(new DocumentFormat.OpenXml.Wordprocessing.ParagraphStyleId { Val = styleId });
        }

        JustificationValues jv = JustificationValues.Left;
        switch (flowPara.TextAlignment) {
            case System.Windows.TextAlignment.Center: jv = JustificationValues.Center; break;
            case System.Windows.TextAlignment.Right: jv = JustificationValues.Right; break;
            case System.Windows.TextAlignment.Justify: jv = JustificationValues.Both; break;
        }
        pPr.Append(new DocumentFormat.OpenXml.Wordprocessing.Justification { Val = jv });
        oxPara.Append(pPr);

        foreach (var inline in flowPara.Inlines) {
            AppendWpfInlineToOpenXmlParagraph(inline, oxPara, mainPart);
        }
        return oxPara;
    }

    private void AppendWpfInlineToOpenXmlParagraph(System.Windows.Documents.Inline inline, DocumentFormat.OpenXml.Wordprocessing.Paragraph oxPara, MainDocumentPart mainPart) {
        if (inline is System.Windows.Documents.Run) {
            var flowRun = (System.Windows.Documents.Run)inline;
            var oxRun = new DocumentFormat.OpenXml.Wordprocessing.Run();
            var rPr = new DocumentFormat.OpenXml.Wordprocessing.RunProperties();

            if (flowRun.FontWeight == FontWeights.Bold)
                rPr.Append(new DocumentFormat.OpenXml.Wordprocessing.Bold());
            if (flowRun.FontStyle == FontStyles.Italic)
                rPr.Append(new DocumentFormat.OpenXml.Wordprocessing.Italic());
            if (flowRun.TextDecorations != null && flowRun.TextDecorations == TextDecorations.Underline)
                rPr.Append(new DocumentFormat.OpenXml.Wordprocessing.Underline { Val = UnderlineValues.Single });
            if (flowRun.FontSize != 14) {
                int halfPoints = (int)(flowRun.FontSize * 2);
                rPr.Append(new DocumentFormat.OpenXml.Wordprocessing.FontSize { Val = halfPoints.ToString() });
            }
            if (flowRun.Foreground is System.Windows.Media.SolidColorBrush) {
                var color = ((System.Windows.Media.SolidColorBrush)flowRun.Foreground).Color;
                rPr.Append(new DocumentFormat.OpenXml.Wordprocessing.Color { Val = color.R.ToString("X2") + color.G.ToString("X2") + color.B.ToString("X2") });
            }
            if (flowRun.Background is System.Windows.Media.SolidColorBrush) {
                rPr.Append(new DocumentFormat.OpenXml.Wordprocessing.Highlight { Val = HighlightColorValues.Yellow });
            }

            oxRun.Append(rPr);
            oxRun.Append(new DocumentFormat.OpenXml.Wordprocessing.Text(flowRun.Text) { Space = SpaceProcessingModeValues.Preserve });
            oxPara.Append(oxRun);
        }
        else if (inline is System.Windows.Documents.Hyperlink) {
            var flowLink = (System.Windows.Documents.Hyperlink)inline;
            string linkUrl = flowLink.NavigateUri != null ? flowLink.NavigateUri.ToString() : "";
            
            string linkText = "";
            foreach (var linkInline in flowLink.Inlines) {
                if (linkInline is System.Windows.Documents.Run) {
                    linkText += ((System.Windows.Documents.Run)linkInline).Text;
                }
            }
            if (string.IsNullOrEmpty(linkText)) linkText = linkUrl;

            if (!string.IsNullOrEmpty(linkUrl)) {
                string relId = "rIdH" + Guid.NewGuid().ToString().Substring(0, 8);
                try {
                    mainPart.AddHyperlinkRelationship(new Uri(linkUrl, UriKind.RelativeOrAbsolute), true, relId);
                    var oxHl = new DocumentFormat.OpenXml.Wordprocessing.Hyperlink { Id = relId };
                    
                    var oxRun = new DocumentFormat.OpenXml.Wordprocessing.Run();
                    var rPr = new DocumentFormat.OpenXml.Wordprocessing.RunProperties(
                        new DocumentFormat.OpenXml.Wordprocessing.Underline { Val = UnderlineValues.Single },
                        new DocumentFormat.OpenXml.Wordprocessing.Color { Val = "1155CC" }
                    );
                    oxRun.Append(rPr);
                    oxRun.Append(new DocumentFormat.OpenXml.Wordprocessing.Text(linkText) { Space = SpaceProcessingModeValues.Preserve });
                    oxHl.Append(oxRun);
                    oxPara.Append(oxHl);
                } catch {
                    var oxRun = new DocumentFormat.OpenXml.Wordprocessing.Run();
                    oxRun.Append(new DocumentFormat.OpenXml.Wordprocessing.Text(linkText));
                    oxPara.Append(oxRun);
                }
            }
        }
        else if (inline is System.Windows.Documents.Span) {
            var flowSpan = (System.Windows.Documents.Span)inline;
            foreach (var childInline in flowSpan.Inlines) {
                AppendWpfInlineToOpenXmlParagraph(childInline, oxPara, mainPart);
            }
        }
        else if (inline is InlineUIContainer) {
            var container = (InlineUIContainer)inline;
            if (container.Child is System.Windows.Controls.Image) {
                var img = (System.Windows.Controls.Image)container.Child;
                var bSrc = img.Source as System.Windows.Media.Imaging.BitmapSource;
                if (bSrc != null) {
                    try {
                        var imgPart = mainPart.AddImagePart(ImagePartType.Png);
                        using (var stream = imgPart.GetStream()) {
                            var encoder = new System.Windows.Media.Imaging.PngBitmapEncoder();
                            encoder.Frames.Add(System.Windows.Media.Imaging.BitmapFrame.Create(bSrc));
                            encoder.Save(stream);
                        }
                        string relId = mainPart.GetIdOfPart(imgPart);
                        
                        double width = img.Width;
                        double height = img.Height;
                        if (double.IsNaN(width) || width <= 0) width = img.ActualWidth;
                        if (double.IsNaN(width) || width <= 0) width = bSrc.PixelWidth;
                        
                        if (double.IsNaN(height) || height <= 0) height = img.ActualHeight;
                        if (double.IsNaN(height) || height <= 0) height = bSrc.PixelHeight;

                        if (width > 650) {
                            height = height * 650 / width;
                            width = 650;
                        }

                        var drawing = CreateDrawingElement(relId, (int)width, (int)height);
                        var oxRun = new DocumentFormat.OpenXml.Wordprocessing.Run();
                        oxRun.Append(drawing);
                        oxPara.Append(oxRun);
                    } catch {}
                }
            }
        }
    }

    private DocumentFormat.OpenXml.Wordprocessing.Table ConvertWpfTableToOpenXml(System.Windows.Documents.Table flowTable, MainDocumentPart mainPart) {
        var oxTable = new DocumentFormat.OpenXml.Wordprocessing.Table();
        var tblPr = new DocumentFormat.OpenXml.Wordprocessing.TableProperties(
            new DocumentFormat.OpenXml.Wordprocessing.TableWidth { Type = TableWidthUnitValues.Pct, Width = "5000" },
            new DocumentFormat.OpenXml.Wordprocessing.TableBorders(
                new TopBorder { Val = BorderValues.Single, Size = 4, Space = 0, Color = "CCCCCC" },
                new BottomBorder { Val = BorderValues.Single, Size = 12, Space = 0, Color = "2F5597" },
                new LeftBorder { Val = BorderValues.None },
                new RightBorder { Val = BorderValues.None },
                new InsideHorizontalBorder { Val = BorderValues.Single, Size = 4, Space = 0, Color = "E0E0E0" },
                new InsideVerticalBorder { Val = BorderValues.None }
            )
        );
        oxTable.AppendChild(tblPr);

        var tblGrid = new DocumentFormat.OpenXml.Wordprocessing.TableGrid();
        if (flowTable.Columns.Count > 0) {
            for (int i = 0; i < flowTable.Columns.Count; i++) {
                tblGrid.AppendChild(new DocumentFormat.OpenXml.Wordprocessing.GridColumn());
            }
        } else {
            tblGrid.AppendChild(new DocumentFormat.OpenXml.Wordprocessing.GridColumn());
        }
        oxTable.AppendChild(tblGrid);

        foreach (var rg in flowTable.RowGroups) {
            foreach (var row in rg.Rows) {
                var oxRow = new DocumentFormat.OpenXml.Wordprocessing.TableRow();
                foreach (var cell in row.Cells) {
                    var oxCell = new DocumentFormat.OpenXml.Wordprocessing.TableCell();
                    
                    var tcPr = new DocumentFormat.OpenXml.Wordprocessing.TableCellProperties();
                    if (cell.Background is System.Windows.Media.SolidColorBrush) {
                        var col = ((System.Windows.Media.SolidColorBrush)cell.Background).Color;
                        string hex = col.R.ToString("X2") + col.G.ToString("X2") + col.B.ToString("X2");
                        tcPr.Append(new DocumentFormat.OpenXml.Wordprocessing.Shading { Val = ShadingPatternValues.Clear, Color = "auto", Fill = hex });
                    }
                    if (cell.ColumnSpan > 1) {
                        tcPr.Append(new DocumentFormat.OpenXml.Wordprocessing.GridSpan { Val = cell.ColumnSpan });
                    }
                    oxCell.Append(tcPr);

                    foreach (var b in cell.Blocks) {
                        if (b is System.Windows.Documents.Paragraph) {
                            var flowPara = (System.Windows.Documents.Paragraph)b;
                            oxCell.Append(ConvertWpfParagraphToOpenXml(flowPara, mainPart));
                        }
                    }
                    if (oxCell.ChildElements.Count == 0) {
                        oxCell.Append(new DocumentFormat.OpenXml.Wordprocessing.Paragraph());
                    }
                    oxRow.Append(oxCell);
                }
                oxTable.Append(oxRow);
            }
        }
        return oxTable;
    }

    private DocumentFormat.OpenXml.Wordprocessing.Drawing CreateDrawingElement(string relationshipId, int widthPx, int heightPx) {
        if (widthPx <= 0) widthPx = 300;
        if (heightPx <= 0) heightPx = 200;
        long cx = (long)(widthPx / 96.0 * 914400.0);
        long cy = (long)(heightPx / 96.0 * 914400.0);

        var drawing = new DocumentFormat.OpenXml.Wordprocessing.Drawing(
            new DocumentFormat.OpenXml.Drawing.Wordprocessing.Inline(
                new DocumentFormat.OpenXml.Drawing.Wordprocessing.Extent() { Cx = cx, Cy = cy },
                new DocumentFormat.OpenXml.Drawing.Wordprocessing.EffectExtent() { LeftEdge = 0L, TopEdge = 0L, RightEdge = 0L, BottomEdge = 0L },
                new DocumentFormat.OpenXml.Drawing.Wordprocessing.DocProperties() { Id = 1U, Name = "Image" },
                new DocumentFormat.OpenXml.Drawing.Wordprocessing.NonVisualGraphicFrameDrawingProperties(
                    new DocumentFormat.OpenXml.Drawing.GraphicFrameLocks() { NoChangeAspect = true }),
                new DocumentFormat.OpenXml.Drawing.Graphic(
                    new DocumentFormat.OpenXml.Drawing.GraphicData(
                        new DocumentFormat.OpenXml.Drawing.Pictures.Picture(
                            new DocumentFormat.OpenXml.Drawing.Pictures.NonVisualPictureProperties(
                                new DocumentFormat.OpenXml.Drawing.Pictures.NonVisualDrawingProperties() { Id = 2U, Name = "Image.png" },
                                new DocumentFormat.OpenXml.Drawing.Pictures.NonVisualPictureDrawingProperties()),
                            new DocumentFormat.OpenXml.Drawing.Pictures.BlipFill(
                                new DocumentFormat.OpenXml.Drawing.Blip() { Embed = relationshipId, CompressionState = DocumentFormat.OpenXml.Drawing.BlipCompressionValues.Print },
                                new DocumentFormat.OpenXml.Drawing.Stretch(
                                    new DocumentFormat.OpenXml.Drawing.FillRectangle())),
                            new DocumentFormat.OpenXml.Drawing.Pictures.ShapeProperties(
                                new DocumentFormat.OpenXml.Drawing.Transform2D(
                                    new DocumentFormat.OpenXml.Drawing.Offset() { X = 0L, Y = 0L },
                                    new DocumentFormat.OpenXml.Drawing.Extents() { Cx = cx, Cy = cy }),
                                new DocumentFormat.OpenXml.Drawing.PresetGeometry() { Preset = DocumentFormat.OpenXml.Drawing.ShapeTypeValues.Rectangle }))
                    ) { Uri = "http://schemas.openxmlformats.org/drawingml/2006/picture" }
                )
            ) { DistanceFromTop = 0U, DistanceFromBottom = 0U, DistanceFromLeft = 0U, DistanceFromRight = 0U }
        );
        return drawing;
    }

    private void TraverseBlocks(System.Windows.Documents.BlockCollection blocks, Action<System.Windows.Documents.Block> action) {
        foreach (var block in blocks) {
            action(block);
            if (block is System.Windows.Documents.Section) {
                TraverseBlocks(((System.Windows.Documents.Section)block).Blocks, action);
            } else if (block is System.Windows.Documents.List) {
                foreach (var li in ((System.Windows.Documents.List)block).ListItems) {
                    TraverseBlocks(li.Blocks, action);
                }
            } else if (block is System.Windows.Documents.Table) {
                foreach (var rg in ((System.Windows.Documents.Table)block).RowGroups) {
                    foreach (var row in rg.Rows) {
                        foreach (var cell in row.Cells) {
                            TraverseBlocks(cell.Blocks, action);
                        }
                    }
                }
            }
        }
    }

    private void TraverseInlines(System.Windows.Documents.InlineCollection inlines, Action<System.Windows.Documents.Inline> action) {
        foreach (var inline in inlines) {
            action(inline);
            if (inline is System.Windows.Documents.Span) {
                TraverseInlines(((System.Windows.Documents.Span)inline).Inlines, action);
            }
        }
    }

    private FlowDocument DocToFlowDocument(string filePath) {
        // .doc format requires COM interop or NPOI — try basic text extraction as fallback
        var doc = new FlowDocument();
        doc.FontFamily = new System.Windows.Media.FontFamily("Segoe UI");
        doc.FontSize = 14;
        doc.PagePadding = new Thickness(40);
        try {
            // Attempt RTF conversion via RichTextBox (works for some .doc files)
            byte[] bytes = System.IO.File.ReadAllBytes(filePath);
            // Check for RTF magic bytes
            string header = Encoding.ASCII.GetString(bytes, 0, Math.Min(5, bytes.Length));
            if (header.StartsWith("{\\rtf")) {
                var range = new TextRange(doc.ContentStart, doc.ContentEnd);
                using (var ms = new System.IO.MemoryStream(bytes)) {
                    range.Load(ms, DataFormats.Rtf);
                }
            } else {
                // Binary .doc — extract plain text as fallback
                var sb = new StringBuilder();
                for (int i = 0; i < bytes.Length; i++) {
                    if (bytes[i] >= 32 && bytes[i] < 127) sb.Append((char)bytes[i]);
                    else if (bytes[i] == 13 || bytes[i] == 10) sb.Append('\n');
                }
                doc.Blocks.Add(new System.Windows.Documents.Paragraph(
                    new System.Windows.Documents.Run(sb.ToString())));
            }
        } catch {
            doc.Blocks.Add(new System.Windows.Documents.Paragraph(
                new System.Windows.Documents.Run("Error: Could not open .doc file. For full .doc support, NPOI library is required.")));
        }
        doc.Tag = new DocLayoutSettings {
            PageWidth = 816,
            PageHeight = 1056,
            PagePadding = doc.PagePadding
        };
        return doc;
    }

    private struct CharPosition {
        public TextPointer Start;
        public TextPointer End;
        public char Character;
    }

    private System.Collections.Generic.List<CharPosition> BuildCharPositionMap(FlowDocument doc) {
        var map = new System.Collections.Generic.List<CharPosition>();
        TextPointer current = doc.ContentStart;
        while (current != null && current.CompareTo(doc.ContentEnd) < 0) {
            TextPointerContext context = current.GetPointerContext(LogicalDirection.Forward);
            if (context == TextPointerContext.Text) {
                string runText = current.GetTextInRun(LogicalDirection.Forward);
                for (int i = 0; i < runText.Length; i++) {
                    map.Add(new CharPosition {
                        Start = current.GetPositionAtOffset(i),
                        End = current.GetPositionAtOffset(i + 1),
                        Character = runText[i]
                    });
                }
            } else if (context == TextPointerContext.ElementEnd) {
                DependencyObject element = current.Parent;
                if (element is System.Windows.Documents.Paragraph || element is System.Windows.Documents.LineBreak) {
                    map.Add(new CharPosition {
                        Start = current,
                        End = current,
                        Character = '\r'
                    });
                    map.Add(new CharPosition {
                        Start = current,
                        End = current,
                        Character = '\n'
                    });
                }
            }
            current = current.GetNextContextPosition(LogicalDirection.Forward);
        }
        return map;
    }

    private void ClearSearchHighlights(RichTextBox rtb) {
        // Walk ALL inlines in the document and remove our highlight brush by color.
        // We cannot rely on stored TextRange objects because WPF splits Runs when
        // ApplyPropertyValue is called, making the original ranges stale.
        try {
            var highlightColor = _highlightBrush.Color;
            var activeColor = _activeMatchBrush.Color;
            TextPointer pos = rtb.Document.ContentStart;
            System.Windows.Documents.Inline lastProcessed = null;
            while (pos != null && pos.CompareTo(rtb.Document.ContentEnd) < 0) {
                var il = pos.Parent as System.Windows.Documents.Inline;
                if (il != null && il != lastProcessed) {
                    lastProcessed = il;
                    var scb = il.Background as System.Windows.Media.SolidColorBrush;
                    if (scb != null && (scb.Color == highlightColor || scb.Color == activeColor)) {
                        il.ClearValue(System.Windows.Documents.Inline.BackgroundProperty);
                    }
                }
                pos = pos.GetNextContextPosition(LogicalDirection.Forward);
            }
        } catch { }
        _highlightedRanges.Clear();
        _highlightedOriginalBackgrounds.Clear();
        _activeMatchRange = null;
    }

    private void ReplaceAllBackward(RichTextBox rtb, string find, string replace, bool matchCase) {
        if (string.IsNullOrEmpty(find)) return;
        var map = BuildCharPositionMap(rtb.Document);
        var sb = new StringBuilder();
        foreach (var cp in map) sb.Append(cp.Character);
        string plain = sb.ToString();

        StringComparison cmp = matchCase ? StringComparison.Ordinal : StringComparison.OrdinalIgnoreCase;
        int searchPos = 0;
        var matches = new System.Collections.Generic.List<int>();
        while (searchPos < plain.Length) {
            int idx = plain.IndexOf(find, searchPos, cmp);
            if (idx < 0) break;
            matches.Add(idx);
            searchPos = idx + find.Length;
        }

        for (int i = matches.Count - 1; i >= 0; i--) {
            int idx = matches[i];
            int endIdx = idx + find.Length - 1;
            if (endIdx < map.Count) {
                TextPointer start = map[idx].Start;
                TextPointer end = map[endIdx].End;
                if (start != null && end != null) {
                    var range = new TextRange(start, end);
                    range.Text = replace;
                }
            }
        }
    }

    private void HighlightAllMatches(RichTextBox rtb, string query, bool matchCase = false) {
        if (string.IsNullOrEmpty(query) || query.Length < 2) return;

        // Use the same precise character-level mapping as FindNext/FindPrevious
        var map = BuildCharPositionMap(rtb.Document);
        var sb = new StringBuilder();
        foreach (var cp in map) sb.Append(cp.Character);
        string plain = sb.ToString();

        StringComparison cmp = matchCase ? StringComparison.Ordinal : StringComparison.OrdinalIgnoreCase;
        int searchPos = 0;
        int matchCount = 0;
        while (searchPos < plain.Length) {
            int idx = plain.IndexOf(query, searchPos, cmp);
            if (idx < 0) break;

            int endIdx = idx + query.Length - 1;
            if (endIdx < map.Count) {
                TextPointer start = map[idx].Start;
                TextPointer end = map[endIdx].End;
                if (start != null && end != null) {
                    var range = new TextRange(start, end);
                    object origBg = range.GetPropertyValue(TextElement.BackgroundProperty);
                    _highlightedRanges.Add(range);
                    _highlightedOriginalBackgrounds.Add(origBg);
                    range.ApplyPropertyValue(TextElement.BackgroundProperty, _highlightBrush);
                    matchCount++;
                }
            }
            searchPos = idx + query.Length;
        }

        var win = System.Windows.Window.GetWindow(rtb);
        if (win != null) {
            var tb = win.FindName(rtb.Name + "_MatchCount") as System.Windows.Controls.TextBlock;
            if (tb != null) {
                tb.Text = matchCount == 1 ? "1 match" : matchCount + " matches";
            }
        }
    }

    private string GetDocumentRtf(FlowDocument doc) {
        var range = new TextRange(doc.ContentStart, doc.ContentEnd);
        using (var ms = new System.IO.MemoryStream()) {
            range.Save(ms, DataFormats.Rtf);
            return Encoding.UTF8.GetString(ms.ToArray());
        }
    }

    private void SetDocumentRtf(FlowDocument doc, string rtf) {
        var range = new TextRange(doc.ContentStart, doc.ContentEnd);
        using (var ms = new System.IO.MemoryStream(Encoding.UTF8.GetBytes(rtf))) {
            range.Load(ms, DataFormats.Rtf);
        }
    }

    private void ReplaceInFlowDocument(FlowDocument doc, string find, string replace, bool matchCase = false) {
        foreach (var block in doc.Blocks) {
            ReplaceInBlock(block, find, replace, matchCase);
        }
    }

    private void ReplaceInBlock(System.Windows.Documents.Block block, string find, string replace, bool matchCase = false) {
        if (block is System.Windows.Documents.Paragraph) {
            var para = (System.Windows.Documents.Paragraph)block;
            foreach (var inline in para.Inlines) {
                ReplaceInInline(inline, find, replace, matchCase);
            }
        } else if (block is System.Windows.Documents.Table) {
            var table = (System.Windows.Documents.Table)block;
            foreach (var rg in table.RowGroups) {
                foreach (var row in rg.Rows) {
                    foreach (var cell in row.Cells) {
                        foreach (var b in cell.Blocks) {
                            ReplaceInBlock(b, find, replace, matchCase);
                        }
                    }
                }
            }
        } else if (block is System.Windows.Documents.List) {
            var list = (System.Windows.Documents.List)block;
            foreach (var li in list.ListItems) {
                foreach (var b in li.Blocks) {
                    ReplaceInBlock(b, find, replace, matchCase);
                }
            }
        } else if (block is System.Windows.Documents.Section) {
            var section = (System.Windows.Documents.Section)block;
            foreach (var b in section.Blocks) {
                ReplaceInBlock(b, find, replace, matchCase);
            }
        }
    }

    private void ReplaceInInline(System.Windows.Documents.Inline inline, string find, string replace, bool matchCase = false) {
        StringComparison cmp = matchCase ? StringComparison.Ordinal : StringComparison.OrdinalIgnoreCase;
        if (inline is System.Windows.Documents.Run) {
            var run = (System.Windows.Documents.Run)inline;
            if (run.Text != null && run.Text.IndexOf(find, cmp) >= 0) {
                run.Text = ReplaceWithComparison(run.Text, find, replace, cmp);
            }
        } else if (inline is System.Windows.Documents.Span) {
            var span = (System.Windows.Documents.Span)inline;
            foreach (var subInline in span.Inlines) {
                ReplaceInInline(subInline, find, replace, matchCase);
            }
        }
    }

    private string ReplaceWithComparison(string text, string find, string replace, StringComparison cmp) {
        if (string.IsNullOrEmpty(text) || string.IsNullOrEmpty(find)) return text;
        int idx = 0;
        var sb = new StringBuilder();
        while (true) {
            int foundIdx = text.IndexOf(find, idx, cmp);
            if (foundIdx < 0) {
                sb.Append(text.Substring(idx));
                break;
            }
            sb.Append(text.Substring(idx, foundIdx - idx));
            sb.Append(replace);
            idx = foundIdx + find.Length;
        }
        return sb.ToString();
    }
}
#endif
