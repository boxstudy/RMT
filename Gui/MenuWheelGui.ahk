#Requires AutoHotkey v2.0

class MenuWheelGui {
    __new() {
        this.Gui := ""
        this.MenuIndex := 1
        this.BtnConArr := []
        this.FocusCon := ""
        this.CurCenterPosX := 500
        this.CurCenterPosY := 500

        this.BtnRegions := Map() ; ✅按钮区域表
        this.DrawAction := this.DrawLine.Bind(this)
    }

    ShowGui(MenuIndex) {
        if (this.Gui != "") {
            this.Gui.Show(this.GetGuiShowPos())
        }
        else {
            this.AddGui()
        }
        this.Init(MenuIndex)
    }

    Init(MenuIndex) {
        this.MenuIndex := MenuIndex
        tableItem := MySoftData.TableInfo[3]
        loop 8 {
            remark := tableItem.RemarkArr[(MenuIndex - 1) * 8 + A_Index]
            btnName := remark != "" ? remark : "菜单配置" A_Index
            this.BtnConArr[A_Index].Text := btnName
        }
        if (!MySoftData.FixedMenuWheel)
            this.ToggleFunc(true)
    }

    AddGui() {
        MyGui := Gui("-Caption +AlwaysOnTop +ToolWindow", "菜单轮")
        MyGui.SetFont("S11 W550 Q2", MySoftData.FontType)
        MyGui.BackColor := "EEAA99"
        WinSetTransColor("EEAA99", MyGui)
        this.Gui := MyGui
        PosX := 0
        PosY := 0
        this.FocusCon := MyGui.Add("Text", Format("x{} y{}", PosX, PosY), "")

        PosX := 130  ; 调整
        PosY := 10   ; 调整
        con := MyGui.Add("Button", Format("x{} y{} w80", PosX, PosY), "菜单配置1")
        con.OnEvent("Click", (*) => this.OnBtnClick(1))
        this.BtnConArr.Push(con)
        this.BtnRegions[1] := { X: PosX, Y: PosY, W: 80, H: 30 } ; ✅记录区域

        PosX := 225  ; 调整
        PosY := 55   ; 调整
        con := MyGui.Add("Button", Format("x{} y{} w80", PosX, PosY), "菜单配置2")
        con.OnEvent("Click", (*) => this.OnBtnClick(2))
        this.BtnConArr.Push(con)
        this.BtnRegions[2] := { X: PosX, Y: PosY, W: 80, H: 30 } ; ✅记录区域

        PosX := 260  ; 调整
        PosY := 110  ; 调整
        con := MyGui.Add("Button", Format("x{} y{} w80", PosX, PosY), "菜单配置3")
        con.OnEvent("Click", (*) => this.OnBtnClick(3))
        this.BtnConArr.Push(con)
        this.BtnRegions[3] := { X: PosX, Y: PosY, W: 80, H: 30 } ; ✅记录区域

        PosX := 225  ; 调整
        PosY := 165  ; 调整
        con := MyGui.Add("Button", Format("x{} y{} w80", PosX, PosY), "菜单配置4")
        con.OnEvent("Click", (*) => this.OnBtnClick(4))
        this.BtnConArr.Push(con)
        this.BtnRegions[4] := { X: PosX, Y: PosY, W: 80, H: 30 } ; ✅记录区域

        PosX := 130  ; 调整
        PosY := 210  ; 调整
        con := MyGui.Add("Button", Format("x{} y{} w80", PosX, PosY), "菜单配置5")
        con.OnEvent("Click", (*) => this.OnBtnClick(5))
        this.BtnConArr.Push(con)
        this.BtnRegions[5] := { X: PosX, Y: PosY, W: 80, H: 30 } ; ✅记录区域

        PosX := 35   ; 调整
        PosY := 165  ; 调整
        con := MyGui.Add("Button", Format("x{} y{} w80", PosX, PosY), "菜单配置6")
        con.OnEvent("Click", (*) => this.OnBtnClick(6))
        this.BtnConArr.Push(con)
        this.BtnRegions[6] := { X: PosX, Y: PosY, W: 80, H: 30 } ; ✅记录区域

        PosX := 0    ; 调整
        PosY := 110  ; 调整
        con := MyGui.Add("Button", Format("x{} y{} w80", PosX, PosY), "菜单配置7")
        con.OnEvent("Click", (*) => this.OnBtnClick(7))
        this.BtnConArr.Push(con)
        this.BtnRegions[7] := { X: PosX, Y: PosY, W: 80, H: 30 } ; ✅记录区域

        PosX := 35   ; 调整
        PosY := 55   ; 调整
        con := MyGui.Add("Button", Format("x{} y{} w80", PosX, PosY), "菜单配置8")
        con.OnEvent("Click", (*) => this.OnBtnClick(8))
        this.BtnConArr.Push(con)
        this.BtnRegions[8] := { X: PosX, Y: PosY, W: 80, H: 30 } ; ✅记录区域

        MyGui.OnEvent("Close", (*) => this.ToggleFunc(false))
        MyGui.Show(Format("{} w{} h{}", this.GetGuiShowPos(), 340, 260))
    }

    GetGuiShowPos() {
        if (MySoftData.FixedMenuWheel) {
            this.CurCenterPosX := A_ScreenWidth * 0.5
            this.CurCenterPosY := A_ScreenHeight * 0.70
        }
        else {
            CoordMode("Mouse", "Screen")
            MouseGetPos &mouseX, &mouseY
            this.CurCenterPosX := mouseX
            this.CurCenterPosY := mouseY
        }
        return Format("x{} y{}", this.CurCenterPosX - 170, this.CurCenterPosY - 130)
    }

    OnBtnClick(index) {
        MySoftData.CurMenuWheelIndex := -1
        this.FocusCon.Focus()
        this.ToggleFunc(false)
        this.Gui.Hide()
        macroIndex := (this.MenuIndex - 1) * 8 + index
        TriggerSubMacro(3, macroIndex)
    }

    ToggleFunc(state) {
        if (state) {
            LineOverlay.Init()
            SetTimer(this.DrawAction, 16) ; 60fps
        } else {
            SetTimer(this.DrawAction, 0)
            LineOverlay.Clear()
        }
    }

    DrawLine() {
        CoordMode("Mouse", "Screen")
        MouseGetPos &mx, &my

        LineOverlay.Clear()
        LineOverlay.DrawLine(this.CurCenterPosX, this.CurCenterPosY, mx, my)
        this.CheckMouseHover(mx, my) ; ✅检测悬停
    }

    CheckMouseHover(mx, my) {
        for index, rect in this.BtnRegions {
            ScreenRectX := this.CurCenterPosX - 170 + rect.X
            ScreenRectY := this.CurCenterPosY - 130 + rect.Y
            if (mx >= ScreenRectX && mx <= ScreenRectX + rect.W
                && my >= ScreenRectY && my <= ScreenRectY + rect.H) {
                this.OnBtnClick(index)
                return
            }
        }
    }
}
