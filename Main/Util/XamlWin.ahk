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
        ui.Show()
        return XamlWin.WaitHwnd(ui, ownerHwnd, activate)
    }

    static WaitHwnd(ui, ownerHwnd := "", activate := true) {
        if (!IsObject(ui))
            return false
        loop 40 {
            if (ui.HasProp("wpfHwnd") && ui.wpfHwnd) {
                if (ownerHwnd != "")
                    try ui.Update("Window", "NativeOwner", String(ownerHwnd))
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
