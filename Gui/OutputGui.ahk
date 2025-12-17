#Requires AutoHotkey v2.0

class OutputGui {
    __new() {
        this.ParentTile := ""
        this.Gui := ""
        this.SureBtnAction := ""
        this.VariableObjArr := []
        this.RemarkCon := ""
        this.OutputTypeCon := ""
        this.TextTipCon := ""
        this.TextCon := ""
        this.VariTipCon := ""
        this.VariCon := ""
        this.FilePathConArr := []
        this.FilePathCon := ""

        this.ExcelConArr := []
        this.ExcelTypeCon := ""
        this.NameOrSerialCon := ""
        this.RowVarCon := ""
        this.ColVarCon := ""
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
        this.ToggleFunc(true)
    }

    AddGui() {
        MyGui := Gui(, this.ParentTile GetLang("输出编辑器"))
        this.Gui := MyGui
        MyGui.SetFont("S10 W550 Q2", MySoftData.FontType)

        PosX := 10
        PosY := 10
        MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 80), GetLang("快捷方式:"))
        PosX += 80
        con := MyGui.Add("Hotkey", Format("x{} y{} w{}", PosX, PosY - 3, 70), "!l")
        con.Enabled := false

        PosX += 90
        btnCon := MyGui.Add("Button", Format("x{} y{} w{}", PosX, PosY - 5, 80), GetLang("执行指令"))
        btnCon.OnEvent("Click", (*) => this.TriggerMacro())

        PosX += 90
        MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 50), GetLang("备注:"))
        PosX += 50
        this.RemarkCon := MyGui.Add("Edit", Format("x{} y{} w{}", PosX, PosY - 5, 150), "")

        PosX := 10
        PosY += 40
        MyGui.Add("Text", Format("x{} y{} w{} h{}", PosX, PosY, 80, 20), GetLang("输出类型:"))
        PosX += 80
        this.OutputTypeCon := MyGui.Add("DropDownList", Format("x{} y{} w{}", PosX, PosY - 5, 110), GetLangArr(["发送内容",
            "粘贴内容", "临时提示", "指令窗口", "软件弹窗", "系统语音", "复制到剪切板", "文本文件", "Excel"]))
        this.OutputTypeCon.Value := 1
        this.OutputTypeCon.OnEvent("Change", (*) => this.OnOutTypeChange())

        PosX := 10
        PosY += 30
        this.TextTipCon := MyGui.Add("Text", Format("x{} y{} w{} h{}", PosX, PosY, 350, 20), GetLang("输出的文本内容"))
        PosX += 270
        this.VariTipCon := MyGui.Add("Text", Format("x{} y{} w{} h{}", PosX, PosY, 350, 20), GetLang("变量"))

        PosX := 10
        PosY += 20
        this.TextCon := MyGui.Add("Edit", Format("x{} y{} w{} h{}", PosX, PosY, 250, 70))

        PosX += 270
        this.VariCon := MyGui.Add("DropDownList", Format("x{} y{} w{} R5", PosX, PosY, 130), [])
        con := MyGui.Add("Button", Format("x{} y{} w{} h{}", PosX, PosY + 35, 90, 35), GetLang("追加变量名"))
        con.OnEvent("Click", (*) => this.OnClickAddVarNameBtn())
        con := MyGui.Add("Button", Format("x{} y{} w{} h{}", PosX + 100, PosY + 35, 90, 35), GetLang("追加变量值"))
        con.OnEvent("Click", (*) => this.OnClickAddVarValueBtn())

        PosX := 10
        PosY += 80
        con := MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY + 5, 80), GetLang("文件路径:"))
        this.FilePathConArr.Push(con)
        PosX += 80
        this.FilePathCon := MyGui.Add("Edit", Format("x{} y{} w{} h{}", PosX, PosY, 280, 30))
        this.FilePathConArr.Push(this.FilePathCon)
        PosX += 290
        con := MyGui.Add("Button", Format("x{} y{} w{}", PosX, PosY, 80), GetLang("选择路径"))
        con.OnEvent("Click", (*) => this.OnSelectPathBtnClick())
        this.FilePathConArr.Push(con)

        PosX := 10
        PosY += 40
        con := MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY + 5, 80), GetLang("输入类型:"))
        this.ExcelConArr.Push(con)
        PosX += 80
        this.ExcelTypeCon := MyGui.Add("DropDownList", Format("x{} y{} w{}", PosX, PosY, 110), GetLangArr(["指定单元格",
            "行号自增", "列号自增"]))
        this.ExcelConArr.Push(this.ExcelTypeCon)
        this.ExcelTypeCon.OnEvent("Change", (*) => this.OnOutTypeChange())

        PosX += 160
        con := MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY + 5, 80), GetLang("表名或序号:"))
        this.ExcelConArr.Push(con)
        PosX += 80
        this.NameOrSerialCon := MyGui.Add("Edit", Format("x{} y{} w{} h{}", PosX, PosY, 110, 30))
        this.ExcelConArr.Push(this.NameOrSerialCon)

        PosX := 10
        PosY += 40
        con := MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY + 5, 80), GetLang("单元格行号:"))
        this.ExcelConArr.Push(con)
        PosX += 80
        this.RowVarCon := MyGui.Add("ComboBox", Format("x{} y{} w{}", PosX, PosY, 110), [])
        this.ExcelConArr.Push(this.RowVarCon)

        PosX += 160
        con := MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY + 5, 80), GetLang("单元格列号:"))
        this.ExcelConArr.Push(con)
        PosX += 80
        this.ColVarCon := MyGui.Add("ComboBox", Format("x{} y{} w{}", PosX, PosY, 110, 30), [])
        this.ExcelConArr.Push(this.ColVarCon)

        PosY += 40
        PosX := 200
        btnCon := MyGui.Add("Button", Format("x{} y{} w{} h{}", PosX, PosY, 100, 40), GetLang("确定"))
        btnCon.OnEvent("Click", (*) => this.OnClickSureBtn())

        MyGui.OnEvent("Close", (*) => this.ToggleFunc(false))
        MyGui.Show(Format("w{} h{}", 500, 350))
    }

    Init(cmd) {
        cmdArr := cmd != "" ? StrSplit(cmd, "_") : []
        this.SerialStr := cmdArr.Length >= 2 ? cmdArr[2] : GetSerialStr("Output")
        this.RemarkCon.Value := cmdArr.Length >= 3 ? cmdArr[3] : ""
        this.Data := this.GetOutputData(this.SerialStr)

        this.TextCon.Value := GetLangStr(this.Data.Text, 1)
        this.OutputTypeCon.Value := this.Data.OutputType
        this.FilePathCon.Value := this.Data.FilePath
        this.VariCon.Delete()
        this.VariCon.Add(this.VariableObjArr)
        this.VariCon.Value := 1
        this.RowVarCon.Delete()
        this.RowVarCon.Add(this.VariableObjArr)
        this.ColVarCon.Delete()
        this.ColVarCon.Add(this.VariableObjArr)

        this.ExcelTypeCon.Value := this.Data.ExcelType
        this.NameOrSerialCon.Value := this.Data.NameOrSerial
        this.RowVarCon.Text := this.Data.RowVar
        this.ColVarCon.Text := this.Data.ColVar

        this.OnOutTypeChange()
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

    OnClickAddVarNameBtn() {
        this.TextCon.Value .= this.VariCon.Text
    }

    OnClickAddVarValueBtn() {
        this.TextCon.Value .= "{" this.VariCon.Text "}"
    }

    OnOutTypeChange() {
        showFileConArr := this.OutputTypeCon.Value == 8 || this.OutputTypeCon.Value == 9
        showExcelConArr := this.OutputTypeCon.Value == 9
        loop this.FilePathConArr.Length {
            this.FilePathConArr[A_Index].Visible := showFileConArr
        }

        loop this.ExcelConArr.Length {
            this.ExcelConArr[A_Index].Visible := showExcelConArr
        }

        enableRowCon := this.ExcelTypeCon.Value == 1 || this.ExcelTypeCon.Value == 3
        enableColCon := this.ExcelTypeCon.Value == 1 || this.ExcelTypeCon.Value == 2
        this.RowVarCon.Enabled := enableRowCon
        this.ColVarCon.Enabled := enableColCon
    }

    OnSelectPathBtnClick() {
        path := FileSelect(1, , GetLang("选择输出的目标文件"))
        this.FilePathCon.Value := path
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
        if (this.OutputTypeCon.Value == 8 || this.OutputTypeCon.Value == 9) {
            if (this.FilePathCon.Value == "") {
                MsgBox(GetLang("请选择文件路径"))
                return
            }
        }
        return true
    }

    TriggerMacro() {
        this.SaveOutputData()
        OnTriggerSepcialItemMacro(this.GetCommandStr())
    }

    GetCommandStr() {
        CommandStr := Format("{}_{}", GetLang("输出"), this.Data.SerialStr)
        Remark := CorrectRemark(this.RemarkCon.Value)
        if (Remark != "") {
            CommandStr .= "_" Remark
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
        this.Data.Text := GetLangStr(this.TextCon.Value, 2)
        this.Data.OutputType := this.OutputTypeCon.Value
        this.Data.FilePath := this.FilePathCon.Value
        this.Data.ExcelType := this.ExcelTypeCon.Value
        this.Data.NameOrSerial := this.NameOrSerialCon.Value
        this.Data.RowVar := this.RowVarCon.Text
        this.Data.ColVar := this.ColVarCon.Text

        saveStr := JSON.stringify(this.Data, 0)
        IniWrite(saveStr, OutputFile, IniSection, this.Data.SerialStr)
        if (MySoftData.DataCacheMap.Has(this.Data.SerialStr)) {
            MySoftData.DataCacheMap.Delete(this.Data.SerialStr)
        }
    }
}
