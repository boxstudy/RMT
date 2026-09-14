#Requires AutoHotkey v2.0

; =============================================================================
; XamlWin — 所有 XAML 子窗统一开窗：先入队主题/内容，再 Show，hwnd 后揭盖
;
; 不闪原因（AI 设置同款）：
;   1. 窗口 XAML 带 Opacity="0"，引擎离屏创建
;   2. Show 前 ApplyXamlTheme + 填表，Update 进 _updateQueue
;   3. LoadedHwnd 一次刷入队列，再 Opacity=1
;   4. OnWindowLoad 不再二次 ApplyXamlTheme（后补描边/滚动条会闪）
;
; 用法：
;   建好 ui、绑事件后：
;     XamlWin.Open(this.ui, () => this.Init(cmd), this.OwnerHwnd)
;   OnWindowLoad 里只写：
;     XamlWin.OnLoadTheme(this.ui)
; =============================================================================

class XamlWin {
    ; Small business dialogs share the same chrome, theme and GM-UI registration.
    static Create(title, content, width, height, fluidContent := false) {
        visualScale := fluidContent ? XAMLHost.GetMainViewboxScale() : 1
        bodyFont := fluidContent ? XAMLHost.VisualFontSizeDeclared() : XAMLHost.FontSize()
        titleHeight := fluidContent ? XAMLHost.FormatFontSize(30 * visualScale) : "30"
        main := XAML_Generator("Grid").Name("RmtDialogRoot").Background("{DynamicResource BgColor}")
            .TextElement_FontFamily(MainSoftData.FontType).TextElement_FontSize(bodyFont)
        main.Rows(titleHeight, "*")
        chrome := XAMLHost.AddTitleBar(main, title, titleHeight, "BtnClosePanel", "DialogTitle")
        if (fluidContent) {
            try chrome.Title.FontSize(XAMLHost.VisualFontSizeDeclared(2))
        }
        body := main.Add("Border").Grid_Row(1)
        body._Children.Push(content)
        content._Parent := body
        tmp := StrReplace(XAML_TEMPLATE, "%CaptionHeight%", "30")
        ui := XAMLHost(StrReplace(tmp, "%app%", main.ToString()))
        safeTitle := StrReplace(StrReplace(StrReplace(title, "&", "&amp;"), '"', "&quot;"), "<", "&lt;")
        ; Emit design DIP sizes. ApplyDialogVisualScale enlarges the window and pins the root
        ; so EngineHost's Viewbox matches the main UI. Pre-multiplying here would double-scale.
        ui.xaml := StrReplace(ui.xaml, 'Width="940" Height="700"', 'Title="' safeTitle '" ShowInTaskbar="False" Width="' Round(width * visualScale) '" Height="' Round(height * visualScale) '" Opacity="0"')
        resources := fluidContent ? '<Boolean xmlns="clr-namespace:System;assembly=mscorlib" x:Key="RmtFluidDialogLayout">True</Boolean>' : ""
        ui.xaml := StrReplace(ui.xaml, "%resources%", resources)
        ui.OnEvent("BtnClosePanel", "Click", (*) => ui.Update("Window", "Close", ""))
        ui.OnEvent("Window", "LoadedHwnd", (*) => XamlWin.OnLoadTheme(ui))
        return ui
    }

    static Owner(obj) {
        if (!IsObject(obj))
            return ""
        if (obj.HasProp("OwnerHwnd") && obj.OwnerHwnd != "")
            return obj.OwnerHwnd
        if (obj.HasProp("ParentHwnd") && obj.ParentHwnd != "")
            return obj.ParentHwnd
        return ""
    }

    static QueueTheme(ui) {
        if (!IsObject(ui))
            return
        ui._xamlThemeQueued := true
        try {
            themeName := "RMT_Light"
            if (IsSet(MainSoftData) && IsObject(MainSoftData) && MainSoftData.HasProp("Theme") && MainSoftData.Theme != "")
                themeName := MainSoftData.Theme
            ApplyXamlTheme(ui, themeName)
        } catch {
        }
    }

    ; OnWindowLoad：开窗已入队则跳过，避免揭盖后再刷主题
    static OnLoadTheme(ui) {
        if (!IsObject(ui))
            return
        if (ui.HasProp("_xamlThemeQueued") && ui._xamlThemeQueued)
            return
        XamlWin.QueueTheme(ui)
    }

    static Reveal(ui) {
        if (!IsObject(ui))
            return
        try ui.Update("Window", "Opacity", "1")
    }

    ; fill：Show 前入队内容的回调（Func / BoundFunc / 有 Call 的对象）
    static Open(ui, fill := "", ownerHwnd := "", activate := true) {
        if (!IsObject(ui))
            return false
        XamlWin.QueueTheme(ui)
        if (fill != "") {
            try {
                if (HasMethod(fill, "Call"))
                    fill.Call()
            } catch {
            }
        }
        ; Set the native owner in CREATE_WINDOW, before the hidden window is shown.
        ; Applying it after reveal changes z-order/activation and produces visible flashes.
        if (ownerHwnd != "")
            ui.ownerHwnd := ownerHwnd
        ui.Show()
        return XamlWin.WaitHwnd(ui, ownerHwnd, activate)
    }

    static WaitHwnd(ui, ownerHwnd := "", activate := true) {
        if (!IsObject(ui))
            return false
        loop 40 {
            if (ui.HasProp("wpfHwnd") && ui.wpfHwnd) {
                ; Compatibility fallback for callers that showed the host themselves.
                if (ownerHwnd != "" && (!ui.HasProp("ownerHwnd") || String(ui.ownerHwnd) != String(ownerHwnd)))
                    try ui.Update("Window", "NativeOwner", String(ownerHwnd))
                ; Opaque XamlWin dialogs are already revealed once, after their complete
                ; update queue and font pass, by the LoadedHwnd handler.
                autoReveal := InStr(ui.xaml, 'Opacity="0"') && !InStr(ui.xaml, 'AllowsTransparency="True"')
                skipReveal := ui.HasOwnProp("_skipAutoReveal") && ui._skipAutoReveal
                if (!autoReveal && !skipReveal)
                    XamlWin.Reveal(ui)
                if (activate)
                    try WinActivate("ahk_id " ui.wpfHwnd)
                return true
            }
            Sleep(50)
        }
        return false
    }
}
