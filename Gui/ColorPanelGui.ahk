#Requires AutoHotkey v2.0

; =====================================================================
; 颜色面板 —— XAML 迁移版（TargetGui 内嵌）
; 公开接口保持：ShowGui() / AddGui() / SureAction / Gui(兼容访问器) / PickColor() / RowColorNum / ColColorNum /
;               ColorValue / CoordX / CoordY / ColorConMap / ColorCon / CoordCon / OverlayCon
; 外部引用核对：
;   MyColorPanel.SureAction := cb      —— TargetGui:ShowGui（本文件同批迁移）
;   MyColorPanel.ShowGui()             —— TargetGui:ShowGui
;   MyColorPanel.RefreshCoord()        —— TargetGui:GuiDrag/_OnLButton/_OnHotkey/OnArrowKeyDown
;   MyColorPanel.RefreshMapImage()     —— TargetGui:_OnLButton/_OnHotkey/OnArrowKeyDown
;   MyColorPanel.GuiDoubleClick()      —— TargetGui:GuiDoubleClick
;   ColorPanelGui.PickColor()          —— 静态方法自用
; =====================================================================

class ColorPanelGui {
    __new() {
        this.Gui := ""          ; 兼容访问器：窗口存活期间为 facade，关闭后为 ""
        this.ui := ""           ; XAMLHost 实例
        this._closed := true
        this.ColorCon := ""
        this.CoordCon := ""
        this.ColorConMap := Map()   ; 原生按 "col-row" 存控件句柄；XAML 版控件以 Name 寻址，保留空 Map 兼容
        this.OverlayCon := ""

        this.ColorValue := "F0F0F0"
        this.CoordX := 1920
        this.CoordY := 1080

        this.RowColorNum := 11
        this.ColColorNum := 15
        this.GuiWidth := 160
        this.GuiHeight := 150

        this.SureAction := ""
        this._hkIds := []
        this._lastClickTick := 0
    }

    Hwnd() {
        return (IsObject(this.ui) && this.ui.HasProp("wpfHwnd")) ? this.ui.wpfHwnd : 0
    }

    ; ---------- 兼容访问器实现 ----------
    GetPos(&x, &y, &w, &h) {
        hwnd := this.Hwnd()
        if (hwnd == 0) {
            x := 0, y := 0, w := 0, h := 0
            return 0
        }
        ; 陈旧句柄防护：窗口已关闭/重建时 Hwnd() 可能仍非 0，WinGetPos 会抛 TargetError（与 Hide() 的 try 风格一致）
        try WinGetPos(&x, &y, &w, &h, hwnd)
        catch
            return 0
        return 1
    }

    Move(x, y, w := "", h := "") {
        hwnd := this.Hwnd()
        if (hwnd == 0)
            return
        ; 陈旧句柄防护：窗口刚关闭/重建时 Hwnd() 仍可能非 0，WinMove 会抛 "Target window not found"
        try {
            if (w == "" && h == "")
                WinMove(x, y, , , hwnd)
            else
                WinMove(x, y, w, h, hwnd)
        }
    }

    Show() {
        if (this.Hwnd() != 0 && this._IsVisible())
            return
        this.AddGui()
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
        ; 陈旧句柄防护：取不到样式一律视为不可见，避免 WinGetStyle 抛错
        try style := WinGetStyle(hwnd)
        catch
            return false
        return (style & 0x10000000) != 0  ; 0x10000000 = WS_VISIBLE
    }

    ; ---------- 生命周期 ----------
    ShowGui() {
        if (IsObject(this.ui) && !this._closed)
            this._CloseWindow()
        this._BuildAndShow()
        ; 注册 Enter 热键（颜色面板活动期间有效）
        if (this._hkIds.Length == 0)
            this._hkIds := WinHotkey.Register(["Enter"], ObjBindMethod(this, "_OnEnter"))
        this.RefreshCoord()
        this.RefreshMapImage()
    }

    AddGui() {
        if (IsObject(this.ui) && !this._closed)
            this._CloseWindow()
        this._BuildAndShow()
    }

    _BuildAndShow() {
        global MySoftData
        this._closed := false

        main := XAML_Generator("Grid").Background("#EEAA99").Width("160").Height("150")
        cv := main.Add("Canvas").Width("160").Height("150")

        ; 11x15 色块网格（10x10 一格，与原生逐控件布局一致；中心格 8-6 跳过）
        StartPosX := 5
        StartPosY := 5
        loop this.RowColorNum {
            RowValue := A_Index
            loop this.ColColorNum {
                ColValue := A_Index
                if (RowValue == 6 && ColValue == 8)
                    continue
                PosX := StartPosX + (ColValue - 1) * 10
                PosY := StartPosY + (RowValue - 1) * 10
                cv.Add("Border").Name("Cell_" ColValue "_" RowValue).Width("10").Height("10")
                    .Canvas_Left(PosX).Canvas_Top(PosY).Background("#FF0000")
            }
        }
        ; 中心 14x14 白盒（显示当前颜色反色）
        cv.Add("Border").Name("Cell_0_0").Width("14").Height("14").Canvas_Left(73).Canvas_Top(53).Background("#FFFFFF")
        ; 中心 10x10 格（col 8, row 6）
        cv.Add("Border").Name("Cell_8_6").Width("10").Height("10").Canvas_Left(75).Canvas_Top(55).Background("#FFFFFF")

        ; 当前颜色块 + 坐标文本
        cv.Add("Border").Name("ColorCon").Width("25").Height("25").Canvas_Left(5).Canvas_Top(120).Background("#FF0000")
        cv.Add("TextBlock").Name("CoordCon").Canvas_Left(35).Canvas_Top(122).Width("95")
            .TextAlignment("Center").Text("1920,1080").FontSize("13").FontWeight("SemiBold").Foreground("#1A1A1A")

        ; 拖动/双击覆盖层（桥接层对 Name=DragArea 的元素自动挂 Window.DragMove）
        cv.Add("Border").Name("DragArea").Width("160").Height("150").Canvas_Left(0).Canvas_Top(0).Background("Transparent")
        ; 关闭按钮（最上层，覆盖层之上）
        cv.Add("Button").Name("BtnPanelClose").Canvas_Left(130).Canvas_Top(120).Width("25").Height("25").Padding("0")
            .Content("X").FontSize("12").Background("#E0E0E0").BorderBrush("#B0B0B0").BorderThickness("1").Cursor("Hand")

        tmp := StrReplace(XAML_TEMPLATE, "%CaptionHeight%", "30")
        this.ui := XAMLHost(StrReplace(tmp, "%app%", main.ToString()), "", "")
        this.ui.xaml := StrReplace(this.ui.xaml, 'Width="940" Height="700"', 'Title="RMT-Target" Width="160" Height="150" Opacity="0" Topmost="True" ShowInTaskbar="False"')
        this.ui.xaml := StrReplace(this.ui.xaml, 'ResizeMode="CanResize"', 'ResizeMode="NoResize"')
        ; 去掉 WindowChrome：本窗口无标题栏需求，且原生面板是直角矩形
        this.ui.xaml := RegExReplace(this.ui.xaml, "s)<WindowChrome\.WindowChrome>.*?</WindowChrome\.WindowChrome>")
        this.ui.xaml := StrReplace(this.ui.xaml, '%resources%', '')
        this.ui.xaml := StrReplace(this.ui.xaml, 'FontFamily="Segoe UI Variable Display, Segoe UI, sans-serif"', 'FontFamily="' MainSoftData.FontType '"')

        ; 事件（回调异步，勿做阻塞操作）
        this.ui.OnEvent("Window", "Closing", ObjBindMethod(this, "OnWindowClosing", this.ui))
        this.ui.OnEvent("BtnPanelClose", "Click", ObjBindMethod(this, "OnClose"))
        this.ui.OnEvent("DragArea", "MouseLeftButtonDown", ObjBindMethod(this, "OnPanelMouseDown"))

        if (!XamlWin.Open(this.ui, "", "", false))
            this._closed := true
        else {
            PanelPosX := A_ScreenWidth - this.GuiWidth
            try WinMove(PanelPosX, 0, , , this.ui.wpfHwnd)
        }
        this.Gui := this._NewGuiFacade()
    }

    _NewGuiFacade() {
        ; 注意：不用 fat-arrow（带 ByRef 参数会挂起解释器），用真实类转发
        return _RmtGuiFacade(this)
    }

    _CloseWindow() {
        if (IsObject(this.ui)) {
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
        if (this._hkIds.Length > 0) {
            WinHotkey.UnregisterAll(this._hkIds)
            this._hkIds := []
        }
        ; 面板窗口被直接关闭（Alt+F4 / daemon 关窗）时，同步清理目标窗口的订阅并隐藏目标窗口（与 _DoHide 一致；均幂等）
        MyTargetGui.HideGui()
        if (MyTargetGui.Gui != "")
            MyTargetGui.Gui.Hide()
        this.ui := ""
        this._closed := true
        this.Gui := ""
    }

    ; ---------- 拖动 / 双击 ----------
    ; 拖动函数（保留公开方法；实际拖动由 DragArea 自动 DragMove 完成）
    GuiDrag(*) {
        hwnd := this.Hwnd()
        if (hwnd == 0)
            return
        ; 陈旧句柄防护：XAML 事件回调异步到达时窗口可能已关闭/重建，PostMessage 会抛 TargetError
        try PostMessage(0xA1, 2, 0, 0, "ahk_id " hwnd)
    }

    OnPanelMouseDown(state, ctrl, event) {
        now := A_TickCount
        if (this._lastClickTick != 0 && now - this._lastClickTick <= 400) {
            ; 双击：确定关闭
            this._lastClickTick := 0
            this.GuiDoubleClick()
            return
        }
        this._lastClickTick := now
        ; 单击：DragArea 自动 DragMove 负责拖动，无需额外处理
    }

    ;双击确定关闭
    GuiDoubleClick(*) {
        if (!this._IsVisible())
            return
        this._DoHide()
        if (this.SureAction == "")
            return
        action := this.SureAction
        colorStr := Format("{:06X}", this.ColorValue)
        action(this.CoordX, this.CoordY, colorStr)
    }

    OnClose(*) {
        this._DoHide()
    }

    _DoHide() {
        if (this._hkIds.Length > 0) {
            WinHotkey.UnregisterAll(this._hkIds)
            this._hkIds := []
        }
        ; 无论 Enter 热键是否注册过（如仅 AddGui 路径），都清理目标窗口订阅（HideGui 幂等）
        MyTargetGui.HideGui()
        if (this.Gui != "")
            this.Gui.Hide()
        if (MyTargetGui.Gui != "")
            MyTargetGui.Gui.Hide()
    }

    _OnEnter(key) {
        if (!this._IsVisible())
            return
        this._DoHide()
        if (this.SureAction == "")
            return
        action := this.SureAction
        colorStr := Format("{:06X}", this.ColorValue)
        action(this.CoordX, this.CoordY, colorStr)
    }

    RefreshCoord() {
        if (!IsObject(MyTargetGui.Gui) || MyTargetGui.Gui.Hwnd() == 0)
            return
        ; GetPos 失败（陈旧句柄）则放弃本次刷新，避免把 0,0 当真实坐标
        if (MyTargetGui.Gui.GetPos(&x, &y, &w, &h) == 0)
            return

        this.CoordX := x - 1
        this.CoordY := y - 1
        if (IsObject(this.ui))
            this.ui.Update("CoordCon", "Text", Format("{},{}", this.CoordX, this.CoordY))
    }

    RefreshMapImage() {
        if (!IsObject(MyTargetGui.Gui) || MyTargetGui.Gui.Hwnd() == 0)
            return
        ; GetPos 失败（陈旧句柄）则放弃本次刷新，避免用 0,0 坐标调用 GetPixelColorMap（会抛 Gdip 错误）
        if (MyTargetGui.Gui.GetPos(&x, &y, &w, &h) == 0)
            return
        MyTargetGui.Gui.Move(-1000, -1000)
        ColorValueMap := GetPixelColorMap(x - 1, y - 1, this.RowColorNum, this.ColColorNum)
        MyTargetGui.Gui.Move(x, y)

        CoordMode("Pixel", "Screen")

        ; 一次 IPC 批量更新所有色块（GetPixelColorMap 返回 "0xRRGGBB"，WPF 需要 "#RRGGBB"）
        batch := []
        loop this.RowColorNum {
            RowValue := A_Index
            loop this.ColColorNum {
                ColValue := A_Index
                Key := Format("{}-{}", ColValue, RowValue)
                ColorValue := ColorValueMap[Key]
                batch.Push({ControlName: "Cell_" ColValue "_" RowValue, PropertyName: "Background", Value: StrReplace(ColorValue, "0x", "#")})
            }
        }

        Key := Format("{}-{}", Integer((this.ColColorNum + 1) / 2), Integer((this.RowColorNum + 1) / 2))
        this.ColorValue := ColorValueMap[Key]
        batch.Push({ControlName: "ColorCon", PropertyName: "Background", Value: StrReplace(this.ColorValue, "0x", "#")})

        CenterBoxKey := Format("{}-{}", 0, 0)
        ColorValue := this.GetInvertedColor(this.ColorValue)
        batch.Push({ControlName: "Cell_0_0", PropertyName: "Background", Value: StrReplace(ColorValue, "0x", "#")})

        if (IsObject(this.ui))
            this.ui.BatchUpdate(batch)
    }

    GetInvertedColor(color) {
        ; 去除可能的前缀（如0x）
        if (SubStr(color, 1, 2) = "0x") {
            color := SubStr(color, 3)
        }

        ; 确保颜色值是6位十六进制
        if (StrLen(color) = 6) {
            ; 将十六进制转换为RGB分量
            red := Integer("0x" SubStr(color, 1, 2))
            green := Integer("0x" SubStr(color, 3, 2))
            blue := Integer("0x" SubStr(color, 5, 2))

            ; 计算反色
            invertedRed := 255 - red
            invertedGreen := 255 - green
            invertedBlue := 255 - blue

            ; 将RGB分量转换回十六进制
            invertedColor := Format("0x{:02X}{:02X}{:02X}", invertedRed, invertedGreen, invertedBlue)

            return invertedColor
        }
        return "0xFFFFFF"
    }

    ; 静态便捷方法：弹出颜色选择器，返回选中的颜色（#RRGGBB格式），取消返回空字符串
    static PickColor(defaultColor := "") {
        picker := ColorPanelGui()
        if (defaultColor != "" && RegExMatch(defaultColor, "^#?([0-9A-Fa-f]{6})$", &m))
            picker.ColorValue := Integer("0x" m[1])
        result := ""
        picker.SureAction := (x, y, color) => result := "#" color
        ; 确保目标窗口已创建并显示，否则 RefreshCoord/RefreshMapImage 会报错
        if (MyTargetGui.Gui == "")
            MyTargetGui.AddGui()
        MyTargetGui.Gui.Show()
        picker.ShowGui()
        ; 等待用户选择或关闭（最多等待60秒）
        loop 600 {
            if (result != "")
                return result
            Sleep(100)
        }
        return ""
    }
}
