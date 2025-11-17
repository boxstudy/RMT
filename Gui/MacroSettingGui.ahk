#Requires AutoHotkey v2.0

class MacroSettingGui {
    __new() {
        this.Gui := ""
        this.tableItem := ""
        this.itemIndex := ""

        this.TKTypeCon := ""
        this.StartTipCon := ""
        this.EndTipCon := ""
    }

    ShowGui(tableIndex, itemIndex) {
        if (this.Gui != "") {
            this.Gui.Show()
        }
        else {
            this.AddGui()
        }
        this.Init(tableIndex, itemIndex)
    }

    Init(tableIndex, itemIndex) {
        this.tableItem := MySoftData.TableInfo[tableIndex]
        this.itemIndex := itemIndex

        this.TKTypeCon.Value := this.tableItem.ModeArr[this.itemIndex]
        this.StartTipCon.Value := this.tableItem.StartTipSoundArr[this.itemIndex]
        this.EndTipCon.Value := this.tableItem.EndTipSoundArr[this.itemIndex]
    }

    AddGui() {
        MyGui := Gui(, "宏高级设置")
        this.Gui := MyGui
        MyGui.SetFont("S11 W550 Q2", MySoftData.FontType)

        PosX := 15
        PosY := 15
        MyGui.Add("Text", Format("x{} y{}", PosX, PosY), "按键类型：")
        PosX += 90
        this.TKTypeCon := MyGui.Add("DropDownList", Format("x{} y{} w150", PosX, PosY - 3), ["虚拟", "拟真"])
        Con := MyGui.Add("Button", Format("x{} y{} w30 h29", PosX + 155, PosY - 4), "?")
        Con.OnEvent("Click", this.OnClickModeHelpBtn.Bind(this))

        PosX := 15
        PosY += 40
        MyGui.Add("Text", Format("x{} y{}", PosX, PosY), "开始提示音：")
        PosX += 90
        this.StartTipCon := MyGui.Add("DropDownList", Format("x{} y{} w150", PosX, PosY - 3), ["无", "触发提示", "循环首次提示"])

        PosX := 15
        PosY += 40
        MyGui.Add("Text", Format("x{} y{}", PosX, PosY), "结束提示音：")
        PosX += 90
        this.EndTipCon := MyGui.Add("DropDownList", Format("x{} y{} w150", PosX, PosY - 3), ["无", "结束提示", "循环结束提示"])

        PosX := 105
        PosY += 40
        con := MyGui.Add("Button", Format("x{} y{} w100 h40", PosX, PosY), "确定")
        con.OnEvent("Click", (*) => this.OnSureBtnClick())
        MyGui.Show(Format("w{} h{}", 300, 190))
    }

    OnClickModeHelpBtn(*) {
        MsgBox("虚拟：通过 AHK 发送虚拟按键`n拟真：调用 Win 系统接口模拟按键，更稳定（需管理员权限）。`n**拟真按键可以作为宏的触发按键，切记自己触发自己导致死循环**")
    }

    OnSureBtnClick() {
        this.tableItem.ModeArr[this.itemIndex] := this.TKTypeCon.Value
        this.tableItem.StartTipSoundArr[this.itemIndex] := this.StartTipCon.Value
        this.tableItem.EndTipSoundArr[this.itemIndex] := this.EndTipCon.Value
        this.Gui.Hide()
    }
}
