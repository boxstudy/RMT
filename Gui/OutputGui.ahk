#Requires AutoHotkey v2.0

class OutputGui {
    __new() {
        this.Gui := ""
        this.SureBtnAction := ""
        this.VariableObjArr := []
        this.RemarkCon := ""
        this.OutputTypeCon := ""
        this.ContentTypeCon := ""
        this.TextTipCon := ""
        this.TextCon := ""
        this.VariTipCon := ""
        this.VariCon := ""
        this.Data := ""
    }

    ShowGui(cmd) {
        if (this.Gui != "") {
            this.Gui.Show()
        }
        else {
            this.AddGui()
        }

        this.Init(cmd)
        this.OnChangeType()
        this.ToggleFunc(true)
    }

    AddGui() {
        MyGui := Gui(, "输出指令编辑")
        this.Gui := MyGui
        MyGui.SetFont("S10 W550 Q2", MySoftData.FontType)

        PosX := 10
        PosY := 10
        MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 80), "快捷方式:")
        PosX += 80
        con := MyGui.Add("Hotkey", Format("x{} y{} w{}", PosX, PosY - 3, 70), "!l")
        con.Enabled := false

        PosX += 90
        btnCon := MyGui.Add("Button", Format("x{} y{} w{}", PosX, PosY - 5, 80), "执行指令")
        btnCon.OnEvent("Click", (*) => this.TriggerMacro())

        PosX += 90
        MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 50), "备注:")
        PosX += 50
        this.RemarkCon := MyGui.Add("Edit", Format("x{} y{} w{}", PosX, PosY - 5, 150), "")

        PosX := 10
        PosY += 40
        MyGui.Add("Text", Format("x{} y{} w{} h{}", PosX, PosY, 80, 20), "输出类型:")
        PosX += 80
        this.OutputTypeCon := MyGui.Add("DropDownList", Format("x{} y{} w{}", PosX, PosY - 5, 110), ["发送内容",
            "粘贴", "Win粘贴", "临时提示", "复制到剪切板", "软件弹窗", "系统语音"])
        this.OutputTypeCon.Value := 1
        this.OutputTypeCon.OnEvent("Change", this.OnChangeType.Bind(this))

        PosX += 160
        MyGui.Add("Text", Format("x{} y{} w{} h{}", PosX, PosY, 80, 20), "输出内容:")
        PosX += 80
        this.ContentTypeCon := MyGui.Add("DropDownList", Format("x{} y{} w{}", PosX, PosY - 5, 110), ["文本",
            "变量", "文本+变量"])
        this.ContentTypeCon.Value := 1
        this.ContentTypeCon.OnEvent("Change", this.OnChangeType.Bind(this))

        PosX := 10
        PosY += 30
        this.TextTipCon := MyGui.Add("Text", Format("x{} y{} w{} h{}", PosX, PosY, 350, 20), "文本")
        PosX += 240
        this.VariTipCon := MyGui.Add("Text", Format("x{} y{} w{} h{}", PosX, PosY, 350, 20), "变量")

        PosX := 10
        PosY += 20
        this.TextCon := MyGui.Add("Edit", Format("x{} y{} w{} h{}", PosX, PosY, 200, 50))

        PosX += 240
        this.VariCon := MyGui.Add("ComboBox", Format("x{} y{} w{} R5", PosX, PosY, 130), [])
    
        PosX := 10
        PosY += 60
        MyGui.Add("Text", Format("x{} y{} w{} h{}", PosX, PosY, 350, 20), "提示：文本中{变量名}表示变量值、例如：变量1 = {变量1}")

        PosY += 30
        PosX := 200
        btnCon := MyGui.Add("Button", Format("x{} y{} w{} h{}", PosX, PosY, 100, 40), "确定")
        btnCon.OnEvent("Click", (*) => this.OnClickSureBtn())

        MyGui.OnEvent("Close", (*) => this.ToggleFunc(false))
        MyGui.Show(Format("w{} h{}", 500, 240))
    }

    Init(cmd) {
        cmdArr := cmd != "" ? StrSplit(cmd, "_") : []
        this.SerialStr := cmdArr.Length >= 2 ? cmdArr[2] : GetSerialStr("Output")
        this.RemarkCon.Value := cmdArr.Length >= 3 ? cmdArr[3] : ""
        this.Data := this.GetOutputData(this.SerialStr)

        this.TextCon.Value := this.Data.Text
        this.OutputTypeCon.Value := this.Data.OutputType
        this.ContentTypeCon.Value := this.Data.ContentType
        this.VariCon.Delete()
        this.VariCon.Add(this.VariableObjArr)
        this.VariCon.Text := this.Data.VariName
    }

    ToggleFunc(state) {
        MacroAction := (*) => this.TriggerMacro()
        if (state) {
            Hotkey("!l", MacroAction, "On")
        }
        else {
            Hotkey("!l", MacroAction, "Off")
        }
    }

    OnChangeType(*) {
        showText := this.ContentTypeCon.Value == 1 || this.ContentTypeCon.Value == 3
        showVari := this.ContentTypeCon.Value == 2 || this.ContentTypeCon.Value == 3
        this.TextTipCon.Enabled := showText
        this.TextCon.Enabled := showText
        this.VariTipCon.Enabled := showVari
        this.VariCon.Enabled := showVari
    }

    OnClickSureBtn() {
        valid := this.CheckIfValid()
        if (!valid)
            return
        this.SaveOutputData()
        this.ToggleFunc(false)
        CommandStr := this.GetCommandStr()
        action := this.SureBtnAction
        action(CommandStr)
        this.Gui.Hide()
    }

    CheckIfValid() {
        return true
    }

    TriggerMacro() {
        this.SaveOutputData()
        CommandStr := this.GetCommandStr()
        tableItem := MySoftData.SpecialTableItem
        tableItem.KilledArr[1] := false
        tableItem.PauseArr[1] := 0
        tableItem.ActionCount[1] := 0
        tableItem.VariableMapArr[1] := Map()
        tableItem.index := 1

        OnOutput(tableItem, CommandStr, 1)
    }

    GetCommandStr() {
        hasRemark := this.RemarkCon.Value != ""
        CommandStr := "输出_" this.Data.SerialStr
        if (hasRemark) {
            CommandStr .= "_" this.RemarkCon.Value
        }
        return CommandStr
    }

    GetOutputData(SerialStr) {
        saveStr := IniRead(OutputFile, IniSection, SerialStr, "")
        if (!saveStr) {
            data := OutputData()
            data.SerialStr := SerialStr
            return data
        }

        data := JSON.parse(saveStr, , false)
        return data
    }

    SaveOutputData() {
        this.Data.Text := this.TextCon.Value
        this.Data.OutputType := this.OutputTypeCon.Value
        this.Data.ContentType := this.ContentTypeCon.Value
        this.Data.VariName := this.VariCon.Text

        saveStr := JSON.stringify(this.Data, 0)
        IniWrite(saveStr, OutputFile, IniSection, this.Data.SerialStr)
        if (MySoftData.DataCacheMap.Has(this.Data.SerialStr)) {
            MySoftData.DataCacheMap.Delete(this.Data.SerialStr)
        }
    }
}
