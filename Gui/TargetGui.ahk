#Requires AutoHotkey v2.0

; =====================================================================
; 定位取色器 —— 全屏覆盖版 v4（Quicker 取色器逻辑，2026-08-22）
;
; 架构（本轮重构：预览渲染零 IPC + 单元素渲染）：
;   - 覆盖层窗口创建后发 PickerStart，预览（9×9 放大镜/坐标/RGB/面板跟随）
;     由 **daemon（WPF）进程内 DispatcherTimer（100ms = 10fps，用户确认足够）本地驱动**：
;       采样 = 一次 BitBlt 抓 9×9 区域到内存 DIB（替代 81 次 GetPixel）；
;       渲染 = 9×9 WriteableBitmap 单 Image（NearestNeighbor 放大，单元素失效）
;     全程不经过跨进程 IPC、不逐帧改 81 个元素 —— daemon UI 线程占用 <1%，主界面零卡顿
;   - 唯一回传：**确认时**（左键/回车）AHK 本地 MouseGetPos + GetPixel 读一次
;     坐标+颜色 → 回调 SureAction(x, y, "0xRRGGBB")；Esc/右键取消
;   - 方向键微调真实鼠标（SetCursorPos 1px，daemon 下个 tick 自动刷新预览）
;
; 交互：无遮罩、不冻结屏幕；光标变十字准星（Cursor=Cross，热点=采样点）；
;       9×9 放大镜网格（中心格=采样点白色粗框高亮）+ 坐标 + RGB 实时跟随
; 桥接新增命令（只加不改 + 登记）：PickerStart / PickerStop（XAML_AHK_Bridge.cs）
; 已知限制：DPI 换算用 GetDpiForSystem 单值（与 MainWindowXaml 一致），混合 DPI 多屏会偏差；
;           root 命中层用 #01000000（alpha=1/255）——实测 Background="Transparent" 不可命中
;
; 公开接口保持：ShowGui() / HideGui() / AddGui() / SureAction / Gui(兼容访问器) / Hwnd() / _lbuttonCb
; 外部引用核对：
;   MyTargetGui.SureAction := cb + MyTargetGui.ShowGui()  —— SearchProGui:725-726 / MouseMoveGui:382-383 /
;                                                             MMProGui:532-533 / SearchGui:402-403 / MacroGraphHandlers:1138-1139
;   MyTargetGui._lbuttonCb := ""                          —— Main/UIUtil.ahk:65（保留普通成员）
; =====================================================================

class TargetGui {
    __new() {
        this.Gui := ""          ; 兼容访问器：窗口存活期间为 facade（GetPos/Move/Show/Hide/Hwnd），关闭后为 ""
        this.ui := ""           ; XAMLHost 实例
        this._closed := true

        this.SureAction := ""
        this._lbuttonCb := ""   ; UIUtil.ahk:65 兼容（普通可写成员，本方案不订阅全局鼠标）

        this._hkIds := []       ; WinHotkey 注册 id（方向键/Enter/Esc）

        this._vL := 0, this._vT := 0, this._vW := 0, this._vH := 0
        this._scale := 1.0

        ; 放大镜网格参数（PickerStart 传给 daemon 侧：GridN|CellSize DIP）
        ; 25×25 每格 5 DIP = 125×125 DIP，覆盖 ±12 像素，面板尺寸只比 9×9@12 大 16%
        this.GRID_N := 25
        this.CELL := 5
        this._PanelW := 0
        this._PanelH := 0
    }

    Hwnd() {
        return (IsObject(this.ui) && this.ui.HasProp("wpfHwnd")) ? this.ui.wpfHwnd : 0
    }

    ; ---------- 兼容访问器实现（外部 MyTargetGui.Gui.GetPos/Move/Show/Hide 直操入口）----------
    GetPos(&x, &y, &w, &h) {
        hwnd := this.Hwnd()
        if (hwnd == 0) {
            x := 0, y := 0, w := 0, h := 0
            return 0
        }
        ; 陈旧句柄防护：窗口已关闭/重建时 Hwnd() 可能仍非 0，WinGetPos 会抛 TargetError
        try WinGetPos(&x, &y, &w, &h, hwnd)
        catch
            return 0
        return 1
    }

    Move(x, y, w := "", h := "") {
        hwnd := this.Hwnd()
        if (hwnd == 0)
            return
        try {
            if (w == "" && h == "")
                WinMove(x, y, , , hwnd)
            else
                WinMove(x, y, w, h, hwnd)
        }
    }

    Show() {
        ; 全屏覆盖层不支持隐藏复用：隐藏/未建一律重建
        if (this.Hwnd() != 0 && this._IsVisible())
            return
        this.ShowGui()
    }

    Hide() {
        hwnd := this.Hwnd()
        if (hwnd != 0) {
            try WinHide(hwnd)
        }
    }

    _IsVisible() {
        hwnd := this.Hwnd()
        if (hwnd == 0)
            return false
        ; 陈旧句柄防护：取不到样式一律视为不可见
        try style := WinGetStyle(hwnd)
        catch
            return false
        return (style & 0x10000000) != 0  ; 0x10000000 = WS_VISIBLE
    }

    ; ---------- 生命周期 ----------
    ShowGui() {
        if (this._IsVisible())
            return
        this._BuildAndShow()
    }

    AddGui() {
        this.ShowGui()
    }

    HideGui() {
        this._CloseAll()
    }

    _BuildAndShow() {
        global MainSoftData
        this._closed := false

        ; 虚拟屏幕边界（物理像素）
        this._vL := SysGet(76), this._vT := SysGet(77)
        this._vW := SysGet(78), this._vH := SysGet(79)
        ; DPI 换算：物理 → DIP（GetDpiForSystem 单值，混合 DPI 多屏为已知限制）
        this._scale := DllCall("GetDpiForSystem", "UInt") / 96.0
        wD := Round(this._vW / this._scale), hD := Round(this._vH / this._scale)
        lD := Round(this._vL / this._scale), tD := Round(this._vT / this._scale)

        ; 放大镜网格边长（DIP）+ 信息面板尺寸：网格 + 坐标/RGB 两行文本（"1920,1080" 12px 约 65px < 网格宽，不截断）
        gridPx := this.GRID_N * this.CELL
        this._PanelW := gridPx + 16
        this._PanelH := 6 + gridPx + 4 + 16 + 4 + 16 + 6

        main := XAML_Generator("Grid").Name("Root").Width(wD).Height(hD)
            .Cursor("Cross")    ; 十字准星光标（系统 Cross，热点在中心 = 采样点）
            .Background("#01000000")  ; 近透明命中层（alpha=1/255 视觉不可见，整窗可点击）
        cv := main.Add("Canvas").Name("OverlayCanvas").Width(wD).Height(hD)
        ; 信息面板：9×9 放大镜网格（中心格 = 光标采样点，白色粗框高亮）+ 坐标 + RGB
        panel := cv.Add("Border").Name("InfoPanel").Width(this._PanelW).Height(this._PanelH)
            .Background("#F21E1E1E").CornerRadius("8").BorderBrush("#88FFFFFF").BorderThickness("1")
            .Canvas_Left("0").Canvas_Top("0")
        inner := panel.Add("StackPanel").Margin("8,6,8,6")
        gcv := inner.Add("Canvas").Name("GridCanvas").Width(gridPx).Height(gridPx)
        ; N×N 放大镜网格：单个 Image 承载 daemon 侧 WriteableBitmap（NearestNeighbor 放大，
        ; 单元素渲染避免数百个 Border 逐帧更新）；中心格高亮 = 叠层白色粗框
        gcv.Add("Image").Name("GridImage").Width(gridPx).Height(gridPx).Stretch("Fill")
            .SetProp("RenderOptions.BitmapScalingMode", "NearestNeighbor")
        gcv.Add("Border").Name("CenterBox").Width(this.CELL + 2).Height(this.CELL + 2).Background("Transparent")
            .BorderBrush("#FFFFFFFF").BorderThickness("2").Canvas_Left("0").Canvas_Top("0")
        inner.Add("TextBlock").Name("CoordText").Text("0,0").FontSize("12")
            .Foreground("#FFFFFFFF").Margin("0,4,0,0")
        rgbRow := inner.Add("StackPanel").Orientation("Horizontal").Margin("0,4,0,0")
        rgbRow.Add("TextBlock").Name("RgbText").Text("#000000").FontSize("12")
            .Foreground("#FFFFFFFF").VerticalAlignment("Center")

        tmp := StrReplace(XAML_TEMPLATE, "%CaptionHeight%", "30")
        this.ui := XAMLHost(StrReplace(tmp, "%app%", main.ToString()), "", "")
        this.ui.xaml := StrReplace(this.ui.xaml, 'Width="940" Height="700"'
            , 'Title="RMT-Target" Width="' wD '" Height="' hD '" Topmost="True" ShowInTaskbar="False"')
        this.ui.xaml := StrReplace(this.ui.xaml, 'ResizeMode="CanResize"', 'ResizeMode="NoResize"')
        this.ui.xaml := StrReplace(this.ui.xaml, 'AllowsTransparency="False"', 'AllowsTransparency="True"')
        this.ui.xaml := StrReplace(this.ui.xaml, 'WindowStartupLocation="CenterScreen"'
            , 'WindowStartupLocation="Manual" Left="' lD '" Top="' tD '"')
        ; 透明窗口不能带 WindowChrome（GlassFrame 与每像素 Alpha 冲突），移除整块
        this.ui.xaml := RegExReplace(this.ui.xaml, "s)<WindowChrome\.WindowChrome>.*?</WindowChrome\.WindowChrome>")
        this.ui.xaml := StrReplace(this.ui.xaml, '%resources%', '')
        this.ui.xaml := StrReplace(this.ui.xaml, 'FontFamily="Segoe UI Variable Display, Segoe UI, sans-serif"'
            , 'FontFamily="' MainSoftData.FontType '"')

        ; 事件（回调异步，勿做阻塞操作）
        this.ui.OnEvent("Window", "Closing", ObjBindMethod(this, "OnWindowClosing", this.ui))
        this.ui.OnEvent("Root", "MouseLeftButtonDown", ObjBindMethod(this, "OnConfirmClick"))
        this.ui.OnEvent("Root", "MouseRightButtonDown", ObjBindMethod(this, "OnCancelClick"))

        if (!XamlWin.Open(this.ui, "", "", false)) {
            this._closed := true
            this.Gui := ""
            return
        }
        this.Gui := this._NewGuiFacade()

        ; 启动 daemon 本地预览驱动（零 IPC：预览渲染全部在 daemon 进程内完成；
        ; 传网格参数 GridN|CellSize 供 daemon 侧创建对应尺寸的采样缓冲/位图）
        this.ui.Update("Window", "PickerStart", this.GRID_N "|" this.CELL)

        ; 热键：方向键微调 / Enter 确定 / Esc 取消（全局拦截，覆盖层活动期间生效）
        this._hkIds := WinHotkey.Register(["Left", "Right", "Up", "Down", "Enter", "Esc"]
            , ObjBindMethod(this, "_OnHotkey"))
    }

    _NewGuiFacade() {
        ; 注意：不用 fat-arrow（带 ByRef 参数会挂起解释器），用真实类转发
        return _RmtGuiFacade(this)
    }

    ; ---------- 确认时取色（唯一回传：坐标 + 颜色）----------
    ; GDI 实时读屏幕像素（GetPixel 返回 COLORREF 0x00BBGGRR，须反转），返回 "RRGGBB"
    _GetPixel(mx, my) {
        hdc := DllCall("GetDC", "Ptr", 0, "Ptr")
        if (!hdc)
            return "000000"
        c := DllCall("GetPixel", "Ptr", hdc, "Int", mx, "Int", my, "UInt")
        DllCall("ReleaseDC", "Ptr", 0, "Ptr", hdc)
        r := c & 0xFF
        g := (c >> 8) & 0xFF
        b := (c >> 16) & 0xFF
        return Format("{:02X}{:02X}{:02X}", r, g, b)
    }

    ; ---------- 热键 / 鼠标 ----------
    _OnHotkey(key) {
        if (this._closed)
            return
        if (key == "Left" || key == "Right" || key == "Up" || key == "Down") {
            CoordMode("Mouse", "Screen")
            MouseGetPos &mx, &my
            if (key == "Left")
                mx -= 1
            else if (key == "Right")
                mx += 1
            else if (key == "Up")
                my -= 1
            else
                my += 1
            DllCall("SetCursorPos", "Int", mx, "Int", my)
            ; daemon PickerTick 30ms 内自动刷新预览
            return
        }
        if (key == "Enter") {
            this._Confirm()
            return
        }
        if (key == "Esc")
            this._Cancel()
    }

    OnConfirmClick(state, ctrl, event) {
        this._Confirm()
    }

    OnCancelClick(state, ctrl, event) {
        this._CloseAll()
    }

    _Confirm() {
        if (this._closed)
            return
        CoordMode("Mouse", "Screen")
        MouseGetPos &mx, &my
        hex := this._GetPixel(mx, my)
        action := this.SureAction
        this._CloseAll()
        ; 契约：回调 (PosX, PosY, Color)，Color 形如 "0xRRGGBB"（SearchProGui.OnSureTarget 按此解析）
        if (action != "")
            action(mx, my, "0x" hex)
    }

    _Cancel(*) {
        this._CloseAll()
    }

    ; ---------- 清理（幂等：热键/停 Picker/关窗）----------
    _CloseAll() {
        if (this._hkIds.Length > 0) {
            WinHotkey.UnregisterAll(this._hkIds)
            this._hkIds := []
        }
        if (IsObject(this.ui)) {
            try this.ui.Update("Window", "PickerStop", "")
            try this.ui.Update("Window", "Close", "")
        }
        this.ui := ""
        this._closed := true
        this.Gui := ""
    }

    OnWindowClosing(expectedUi, state, ctrl, event) {
        ; 关旧重建时，旧窗口的延迟 Closing 事件会异步到达：只认当前 ui 的回调
        if (expectedUi != this.ui)
            return
        this._CloseAll()
    }
}

; =====================================================================
; 兼容访问器：外部直操 MyTargetGui.Gui 的 GetPos/Move/Show/Hide
; 转发到所属类的真实方法，窗口关闭后对应 Gui 属性为 ""，不会持有本对象
; =====================================================================
class _RmtGuiFacade {
    __New(owner) {
        this._owner := owner
    }

    GetPos(&x, &y, &w, &h) {
        return this._owner.GetPos(&x, &y, &w, &h)
    }

    Move(x, y, w := "", h := "") {
        return this._owner.Move(x, y, w, h)
    }

    Show(*) {
        return this._owner.Show()
    }

    Hide(*) {
        return this._owner.Hide()
    }

    Hwnd() {
        return this._owner.Hwnd()
    }
}
