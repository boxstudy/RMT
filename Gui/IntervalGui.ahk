#Requires AutoHotkey v2.0

class IntervalGui {
    __new() {
        this.ParentTile := ""
        this.Gui := ""
        this.SureBtnAction := ""
        this.VariableObjArr := []
        this.TimeVarCon := ""
    }

    ShowGui(cmd) {
        if (this.Gui != "") {
            this.Gui.Show()
        }
        else {
            this.AddGui()
        }
        this.Init(cmd)
    }

    Init(cmd) {
        cmdArr := cmd != "" ? StrSplit(cmd, "_") : []
        this.TimeVarCon.Delete()
        this.TimeVarCon.Add(this.VariableObjArr)
        this.TimeVarCon.Text := "空"
        if (cmdArr.Length == 2) {
            this.TimeVarCon.Text := cmdArr[2]
        }
        else if (cmdArr.Length == 3) {
            this.TimeVarCon.Text := cmdArr[3]
        }
        else {
            this.TimeVarCon.Text := "500"
        }
    }

    AddGui() {
        MyGui := Gui(,this.ParentTile "间隔编辑器")
        this.Gui := MyGui
        MyGui.SetFont("S10 W550 Q2", MySoftData.FontType)

        PosX := 40
        PosY := 20
        MyGui.Add("Text", Format("x{} y{} w{} h{}", PosX, PosY, 90, 20), "时间(毫秒)：")

        PosX += 90
        this.TimeVarCon := MyGui.Add("ComboBox", Format("x{} y{} w{} R5 Center", PosX, PosY - 2, 130), [])

        PosY += 40
        PosX := 110
        btnCon := MyGui.Add("Button", Format("x{} y{} w{} h{}", PosX, PosY, 100, 40), "确定")
        btnCon.OnEvent("Click", (*) => this.OnClickSureBtn())

        MyGui.Show(Format("w{} h{}", 320, 120))
    }

    OnClickSureBtn() {
        if (this.SureBtnAction == "")
            return

        timeText := this.TimeVarCon.Text
        if (IsNumber(timeText)) {
            if (IsFloat(timeText) || timeText < 0) {
                MsgBox("请输入大于0的整数")
                return
            }
        }

        action := this.SureBtnAction
        action(this.GetCmdStr())
        this.Gui.Hide()
    }

    GetCmdStr() {
        if (IsNumber(this.TimeVarCon.Text)) {
            return "间隔_" this.TimeVarCon.Text
        }

        return "间隔_变量_" this.TimeVarCon.Text
    }
}
