#Requires AutoHotkey v2.0

class CMDTipSettingGui {
    __new() {
        this.Gui := ""
        this.PosAction := () => this.RefreshMouseInfo()
        this.SureBtnAction := ""

        this.PosXCon := ""
        this.PosYCon := ""
        this.WidthCon := ""
        this.HeightCon := ""
        this.BGColorCon := ""
        this.TransparencyCon := ""
        this.FontSizeCon := ""
        this.FontColorCon := ""

        this.BGColorTipCon := ""
        this.FontColorTipCon := ""
        this.MousePosCon := ""
        this.MouseColorCon := ""
        this.MouseColorTipCon := ""
    }

    ShowGui() {
        if (this.Gui != "") {
            this.Gui.Show()
        }
        else {
            this.AddGui()
        }
        this.PosXCon.Value := MySoftData.CMDPosX
        this.PosYCon.Value := MySoftData.CMDPosY
        this.WidthCon.Value := MySoftData.CMDWidth
        this.HeightCon.Value := MySoftData.CMDHeight
        this.BGColorCon.Value := MySoftData.CMDBGColor
        this.TransparencyCon.Value := MySoftData.CMDTransparency
        this.FontSizeCon.Value := MySoftData.CMDFontSize
        this.FontColorCon.Value := MySoftData.CMDFontColor

        this.BGColorTipCon.Opt(Format("+Background0x{}", this.BGColorCon.Value))
        this.BGColorTipCon.Redraw()
        this.FontColorTipCon.Opt(Format("+Background0x{}", this.FontColorCon.Value))
        this.FontColorTipCon.Redraw()

        this.ToggleFunc(true)
    }

    AddGui() {
        MyGui := Gui(, GetLang("指令显示编辑器"))
        this.Gui := MyGui
        MyGui.SetFont("S11 W550 Q2", MySoftData.FontType)

        PosX := 10
        PosY := 15
        this.MousePosCon := MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 200), GetLang("当前鼠标坐标：0,0"))
        PosX += 230
        this.MouseColorCon := MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 170), GetLang("当前鼠标颜色：FFFFFF"))
        PosX += 170
        this.MouseColorTipCon := MyGui.Add("Text", Format("x{} y{} w{} Background{}", PosX, PosY, 20, "FF0000"), "")

        PosX := 10
        PosY += 25
        con := MyGui.Add("Edit", Format("x{} y{} w{}", PosX, PosY, 30), "F1")
        con.Enabled := false
        PosX += 30
        MyGui.Add("Text", Format("x{} y{} h{}", PosX, PosY + 3, 25), GetLang("选取字体颜色"))

        PosX += 200
        con := MyGui.Add("Edit", Format("x{} y{} w{}", PosX, PosY, 30), "F2")
        con.Enabled := false
        PosX += 30
        MyGui.Add("Text", Format("x{} y{} h{}", PosX, PosY + 3, 25), GetLang("选取背景颜色"))

        PosX := 10
        PosY += 35
        MyGui.Add("Text", Format("x{} y{}", PosX, PosY), GetLang("显示位置X："))
        PosX += 90
        this.PosXCon := MyGui.Add("Edit", Format("x{} y{} w80", PosX, PosY - 3), "")

        PosX += 140
        MyGui.Add("Text", Format("x{} y{}", PosX, PosY), GetLang("显示位置Y："))
        PosX += 90
        this.PosYCon := MyGui.Add("Edit", Format("x{} y{} w80", PosX, PosY - 3), "")

        PosX := 10
        PosY += 35
        MyGui.Add("Text", Format("x{} y{}", PosX, PosY), GetLang("显示宽度："))
        PosX += 90
        this.WidthCon := MyGui.Add("Edit", Format("x{} y{} w80", PosX, PosY - 3), "")

        PosX += 140
        MyGui.Add("Text", Format("x{} y{}", PosX, PosY), GetLang("显示高度："))
        PosX += 90
        this.HeightCon := MyGui.Add("Edit", Format("x{} y{} w80", PosX, PosY - 3), "")

        PosX := 10
        PosY += 35
        MyGui.Add("Text", Format("x{} y{}", PosX, PosY), GetLang("字体颜色："))
        PosX += 90
        this.FontColorCon := MyGui.Add("Edit", Format("x{} y{} w80", PosX, PosY - 3), "")
        this.FontColorCon.OnEvent("Change", (*) => this.OnEditColor())
        this.FontColorTipCon := MyGui.Add("Text", Format("x{} y{} w{} Background{}", PosX + 85, PosY, 20, "FF0000"), ""
        )

        PosX += 140
        MyGui.Add("Text", Format("x{} y{}", PosX, PosY), GetLang("字体大小："))
        PosX += 90
        this.FontSizeCon := MyGui.Add("Edit", Format("x{} y{} w80", PosX, PosY - 3), "")

        PosX := 10
        PosY += 35
        MyGui.Add("Text", Format("x{} y{}", PosX, PosY), GetLang("背景颜色："))
        PosX += 90
        this.BGColorCon := MyGui.Add("Edit", Format("x{} y{} w80", PosX, PosY - 3), "")
        this.BGColorCon.OnEvent("Change", (*) => this.OnEditColor())
        this.BGColorTipCon := MyGui.Add("Text", Format("x{} y{} w{} Background{}", PosX + 85, PosY, 20, "FF0000"), "")

        PosX += 140
        MyGui.Add("Text", Format("x{} y{}", PosX, PosY), GetLang("背景透明度："))
        PosX += 90
        this.TransparencyCon := MyGui.Add("Edit", Format("x{} y{} w80", PosX, PosY - 3), "")

        PosX := 10
        PosY += 35
        PosX += 90

        PosX += 140
        PosX += 90
        con := MyGui.Add("Button", Format("x{} y{}", PosX, PosY - 3), GetLang("恢复默认"))
        con.OnEvent("Click", (*) => this.OnClickRestoreBtn())

        PosX := 10
        PosY += 35
        MyGui.Add("Text", Format("x{} y{}", PosX, PosY), GetLang("透明度(0~100)：0完全透明，100完全不透明"))

        PosX := 180
        PosY += 40
        con := MyGui.Add("Button", Format("x{} y{} w100 h40", PosX, PosY), GetLang("确定"))
        con.OnEvent("Click", (*) => this.OnSureBtnClick())
        MyGui.OnEvent("Close", (*) => this.ToggleFunc(false))
        MyGui.Show(Format("w{} h{}", 480, 350))
    }

    ToggleFunc(state) {
        if (state) {
            SetTimer this.PosAction, 100
            Hotkey("F1", (*) => this.SureFontColor(), "On")
            Hotkey("F2", (*) => this.SureBGColor(), "On")
        }
        else {
            SetTimer this.PosAction, 0
            Hotkey("F1", (*) => this.SureFontColor(), "OFF")
            Hotkey("F2", (*) => this.SureBGColor(), "OFF")
        }
    }

    CheckIfValid() {
        if (!RegExMatch(this.FontColorCon.Value, "^([0-9A-Fa-f]{6})$")) {
            MsgBox(GetLang("字体颜色：请输入正确的颜色值"))
            return false
        }

        if (!RegExMatch(this.BGColorCon.Value, "^([0-9A-Fa-f]{6})$")) {
            MsgBox(GetLang("背景颜色：请输入正确的颜色值"))
            return false
        }

        return true
    }

    OnClickRestoreBtn() {
        this.PosXCon.Value := A_ScreenWidth - 225
        this.PosYCon.Value := 0
        this.WidthCon.Value := 225
        this.HeightCon.Value := 120
        this.BGColorCon.Value := "FFFFFF"
        this.TransparencyCon.Value := 50
        this.FontSizeCon.Value := 12
        this.FontColorCon.Value := "000000"
    }

    OnSureBtnClick() {
        isValid := this.CheckIfValid()
        if (!isValid)
            return

        MySoftData.CMDPosX := this.PosXCon.Value
        MySoftData.CMDPosY := this.PosYCon.Value
        MySoftData.CMDWidth := this.WidthCon.Value
        MySoftData.CMDHeight := this.HeightCon.Value
        MySoftData.CMDBGColor := this.BGColorCon.Value
        MySoftData.CMDTransparency := this.TransparencyCon.Value
        MySoftData.CMDFontSize := this.FontSizeCon.Value
        MySoftData.CMDFontColor := this.FontColorCon.Value
        this.ToggleFunc(false)
        this.Gui.Hide()
    }

    SureFontColor() {
        CoordMode("Mouse", "Screen")
        MouseGetPos &mouseX, &mouseY

        CoordMode("Pixel", "Screen")
        Color := PixelGetColor(mouseX, mouseY, "Slow")
        ColorText := StrReplace(Color, "0x", "")
        this.FontColorCon.Value := ColorText
        this.FontColorTipCon.Opt(Format("+Background0x{}", this.FontColorCon.Value))
        this.FontColorTipCon.Redraw()
    }

    SureBGColor() {
        CoordMode("Mouse", "Screen")
        MouseGetPos &mouseX, &mouseY

        CoordMode("Pixel", "Screen")
        Color := PixelGetColor(mouseX, mouseY, "Slow")
        ColorText := StrReplace(Color, "0x", "")
        this.BGColorCon.Value := ColorText
        this.BGColorTipCon.Opt(Format("+Background0x{}", this.BGColorCon.Value))
        this.BGColorTipCon.Redraw()
    }

    OnEditColor() {
        if (RegExMatch(this.FontColorCon.Value, "^([0-9A-Fa-f]{6})$")) {
            this.FontColorTipCon.Opt(Format("+Background0x{}", this.FontColorCon.Value))
            this.FontColorTipCon.Redraw()
        }

        if (!RegExMatch(this.BGColorCon.Value, "^([0-9A-Fa-f]{6})$")) {
            this.BGColorTipCon.Opt(Format("+Background0x{}", this.BGColorCon.Value))
            this.BGColorTipCon.Redraw()
        }
    }

    RefreshMouseInfo() {
        CoordMode("Mouse", "Screen")
        MouseGetPos &mouseX, &mouseY
        this.MousePosCon.Value := Format("{}{},{}", GetLang("当前鼠标坐标："), mouseX, mouseY)

        CoordMode("Pixel", "Screen")
        Color := PixelGetColor(mouseX, mouseY, "Slow")
        ColorText := StrReplace(Color, "0x", "")
        this.MouseColorCon.Value := Format("{}{}", GetLang("当前鼠标颜色："), ColorText)
        this.MouseColorTipCon.Opt(Format("+Background0x{}", ColorText))
        this.MouseColorTipCon.Redraw()
    }
}
