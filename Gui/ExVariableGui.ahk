#Requires AutoHotkey v2.0
#Include ExVariableEditGui.ahk

class ExVariableGui {
    __new() {
        this.ParentTile := ""
        this.Gui := ""
        this.SureBtnAction := ""
        this.VariableObjArr := []
        this.RemarkCon := ""
        this.SetAreaAction := (x1, y1, x2, y2) => this.OnSetSearchArea(x1, y1, x2, y2)

        this.IsIgnoreExistCon := ""
        this.ToggleConArr := []
        this.VariableConArr := []
        this.SelectToggleCon := ""
        this.ExtractStrCon := ""
        this.ExtractTypeCon := ""
        this.StartPosXCon := ""
        this.StartPosYCon := ""
        this.EndPosXCon := ""
        this.EndPosYCon := ""
        this.SearchCountCon := ""
        this.SearchIntervalCon := ""
        this.OCRTypeCon := ""
        this.Data := ""

        this.OCROptConArr := []
        this.MyEditGui := ExVariableEditGui()
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
        this.OnTypeChange()
    }

    AddGui() {
        MyGui := Gui(, this.ParentTile GetLang("变量提取编辑器"))
        this.Gui := MyGui
        MyGui.SetFont("S10 W550 Q2", MySoftData.FontType)

        PosX := 10
        PosY := 10
        this.FocusCon := MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 80, 20), GetLang("快捷方式:"))
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

        PosY += 35
        PosX := 20
        MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY + 3, 75), GetLang("提取来源："))
        this.ExtractTypeCon := MyGui.Add("DropDownList", Format("x{} y{} w{}", PosX + 75, PosY - 2, 75), GetLangArr([
            "屏幕", "剪切板"]))
        this.ExtractTypeCon.OnEvent("Change", this.OnTypeChange.Bind(this))
        this.ExtractTypeCon.Value := 1

        PosX += 180
        MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 75), GetLang("提取文本："))
        this.ExtractStrCon := MyGui.Add("Edit", Format("x{} y{} w{}", PosX + 75, PosY - 3, 190), "")
        con := MyGui.Add("Button", Format("x{} y{} w{}", PosX + 270, PosY - 4, 50), "编辑")
        con.OnEvent("Click", this.OnClickExtractBtn.Bind(this))

        PosX := 20
        PosY += 35
        MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 75), GetLang("提取次数:"))
        PosX += 75
        this.SearchCountCon := MyGui.Add("ComboBox", Format("x{} y{} w{} Center", PosX, PosY - 5, 75))

        PosX := 200
        MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 75), GetLang("每次间隔:"))
        this.SearchIntervalCon := MyGui.Add("Edit", Format("x{} y{} w{} Center", PosX + 75, PosY - 5, 50))

        PosX := 10
        PosY += 30
        con := MyGui.Add("GroupBox", Format("x{} y{} w{} h{}", PosX, PosY, 510, 95), GetLang("屏幕提取选项:"))

        PosX := 20
        PosY += 25
        con := MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY + 3, 75), GetLang("识别模型:"))
        this.OCROptConArr.Push(con)
        PosX += 75
        this.OCRTypeCon := MyGui.Add("DropDownList", Format("x{} y{} w{} Center", PosX, PosY - 2, 75), GetLangArr(["中文",
            "英文"]))
        this.OCRTypeCon.Value := 1
        this.OCROptConArr.Push(this.OCRTypeCon)

        PosX := 200
        con := MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 75), GetLang("起始坐标X:"))
        this.OCROptConArr.Push(con)
        PosX += 75
        this.StartPosXCon := MyGui.Add("Edit", Format("x{} y{} w{} Center", PosX, PosY - 5, 50))
        this.OCROptConArr.Push(this.StartPosXCon)

        PosX += 110
        con := MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 75), GetLang("起始坐标Y:"))
        this.OCROptConArr.Push(con)
        PosX += 75
        this.StartPosYCon := MyGui.Add("Edit", Format("x{} y{} w{} Center", PosX, PosY - 5, 50))
        this.OCROptConArr.Push(this.StartPosYCon)

        PosX := 20
        PosY += 35
        con := MyGui.Add("Edit", Format("x{} y{} w{}", PosX, PosY, 25), "F1")
        con.Enabled := false
        PosX += 30
        this.SelectToggleCon := MyGui.Add("Checkbox", Format("x{} y{} w{} h{} Left", PosX, PosY, 150, 25),
        GetLang("左键框选搜索范围"))
        this.SelectToggleCon.OnEvent("Click", (*) => this.OnClickSelectToggle())
        this.OCROptConArr.Push(this.SelectToggleCon)

        PosX := 200
        con := MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 75), GetLang("终止坐标X:"))
        this.OCROptConArr.Push(con)
        PosX += 75
        this.EndPosXCon := MyGui.Add("Edit", Format("x{} y{} w{} Center", PosX, PosY - 5, 50))
        this.OCROptConArr.Push(this.EndPosXCon)

        PosX += 110
        con := MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 75), GetLang("终止坐标Y:"))
        this.OCROptConArr.Push(con)
        PosX += 75
        this.EndPosYCon := MyGui.Add("Edit", Format("x{} y{} w{} Center", PosX, PosY - 5, 50))
        this.OCROptConArr.Push(this.EndPosYCon)

        PosX := 10
        PosY += 40
        MyGui.Add("GroupBox", Format("x{} y{} w{} h{}", PosX, PosY, 510, 135), GetLang("结果保存选项:"))

        PosX := 40
        PosY += 20
        this.IsIgnoreExistCon := MyGui.Add("Checkbox", Format("x{} y{} w{}", PosX, PosY, 150), GetLang("变量存在忽略操作"))

        PosX := 30
        PosY += 25
        MyGui.Add("Text", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("开关      变量名"))

        PosX := 20
        PosY += 20
        MyGui.Add("Text", Format("x{} y{}", PosX, PosY + 3), "1.")
        PosX += 20
        con := MyGui.Add("Checkbox", Format("x{} y{} -Wrap w15", PosX, PosY + 3), "")
        this.ToggleConArr.Push(con)

        PosX += 20
        con := MyGui.Add("ComboBox", Format("x{} y{} w{} R5 Center", PosX, PosY - 2, 100), [])
        this.VariableConArr.Push(con)

        PosX += 130
        MyGui.Add("Text", Format("x{} y{}", PosX, PosY + 3), "2.")
        PosX += 20
        con := MyGui.Add("Checkbox", Format("x{} y{} -Wrap w15", PosX, PosY + 3), "")
        this.ToggleConArr.Push(con)

        PosX += 20
        con := MyGui.Add("ComboBox", Format("x{} y{} w{} R5 Center", PosX, PosY - 2, 100), [])
        this.VariableConArr.Push(con)

        PosX += 130
        MyGui.Add("Text", Format("x{} y{}", PosX, PosY + 3), "3.")
        PosX += 20
        con := MyGui.Add("Checkbox", Format("x{} y{} -Wrap w15", PosX, PosY + 3), "")
        this.ToggleConArr.Push(con)

        PosX += 20
        con := MyGui.Add("ComboBox", Format("x{} y{} w{} R5 Center", PosX, PosY - 2, 100), [])
        this.VariableConArr.Push(con)

        PosX := 20
        PosY += 35
        MyGui.Add("Text", Format("x{} y{}", PosX, PosY + 3), "4.")
        PosX += 20
        con := MyGui.Add("Checkbox", Format("x{} y{} -Wrap w15", PosX, PosY + 3), "")
        this.ToggleConArr.Push(con)

        PosX += 20
        con := MyGui.Add("ComboBox", Format("x{} y{} w{} R5 Center", PosX, PosY - 2, 100), [])
        this.VariableConArr.Push(con)

        PosX += 130
        MyGui.Add("Text", Format("x{} y{}", PosX, PosY + 3), "5.")
        PosX += 20
        con := MyGui.Add("Checkbox", Format("x{} y{} -Wrap w15", PosX, PosY + 3), "")
        this.ToggleConArr.Push(con)

        PosX += 20
        con := MyGui.Add("ComboBox", Format("x{} y{} w{} R5 Center", PosX, PosY - 2, 100), [])
        this.VariableConArr.Push(con)

        PosX += 130
        MyGui.Add("Text", Format("x{} y{}", PosX, PosY + 3), "6.")
        PosX += 20
        con := MyGui.Add("Checkbox", Format("x{} y{} -Wrap w15", PosX, PosY + 3), "")
        this.ToggleConArr.Push(con)

        PosX += 20
        con := MyGui.Add("ComboBox", Format("x{} y{} w{} R5 Center", PosX, PosY - 2, 100), [])
        this.VariableConArr.Push(con)

        PosY += 45
        PosX := 210
        btnCon := MyGui.Add("Button", Format("x{} y{} w{} h{} Center", PosX, PosY, 100, 40), GetLang("确定"))
        btnCon.OnEvent("Click", (*) => this.OnClickSureBtn())

        MyGui.OnEvent("Close", (*) => this.ToggleFunc(false))
        MyGui.Show(Format("w{} h{}", 535, 405))
    }

    Init(cmd) {
        cmdArr := cmd != "" ? StrSplit(cmd, "_") : []
        this.SerialStr := cmdArr.Length >= 2 ? cmdArr[2] : GetSerialStr("ExVariable")
        this.RemarkCon.Value := cmdArr.Length >= 3 ? cmdArr[3] : ""
        this.Data := this.GetExVariableData(this.SerialStr)

        loop 6 {
            this.ToggleConArr[A_Index].Value := this.Data.ToggleArr[A_Index]
            this.VariableConArr[A_Index].Delete()
            this.VariableConArr[A_Index].Add(RemoveInVariable(this.VariableObjArr))
            this.VariableConArr[A_Index].Text := this.Data.VariableArr[A_Index]
        }
        this.IsIgnoreExistCon.Value := this.Data.IsIgnoreExist
        this.ExtractStrCon.Value := this.Data.ExtractStr
        this.ExtractTypeCon.Value := this.Data.ExtractType
        this.OCRTypeCon.Value := this.Data.OCRType
        this.StartPosXCon.Value := this.Data.StartPosX
        this.StartPosYCon.Value := this.Data.StartPosY
        this.EndPosXCon.Value := this.Data.EndPosX
        this.EndPosYCon.Value := this.Data.EndPosY
        this.SearchCountCon.Delete()
        this.SearchCountCon.Add([GetLang("无限")])
        this.SearchCountCon.Text := this.Data.SearchCount == -1 ? GetLang("无限") : this.Data.SearchCount
        this.SearchIntervalCon.Value := this.Data.SearchInterval
    }

    ToggleFunc(state) {
        MacroAction := (*) => this.TriggerMacro()
        if (state) {
            Hotkey("!l", MacroAction, "On")
            Hotkey("F1", (*) => this.OnF1(), "On")
        }
        else {
            Hotkey("!l", MacroAction, "Off")
            Hotkey("F1", (*) => this.OnF1(), "Off")
        }
    }

    OnTypeChange(*) {
        isEnable := this.ExtractTypeCon.Value == 1
        for index, value in this.OCROptConArr {
            value.Enabled := isEnable
        }
    }

    OnClickExtractBtn(*) {
        this.MyEditGui.SureAction := this.OnSureExtractAction.Bind(this)
        this.MyEditGui.ShowGui()
    }

    OnSureExtractAction(ExtractStr, VariNum) {
        this.ExtractStrCon.Value := ExtractStr
        loop 6 {
            isTog := VariNum >= A_Index
            this.ToggleConArr[A_Index].Value := isTog
        }
    }

    OnClickSureBtn() {
        valid := this.CheckIfValid()
        if (!valid)
            return
        this.SaveExVariableData()
        this.ToggleFunc(false)
        CommandStr := this.GetCommandStr()
        action := this.SureBtnAction
        action(CommandStr)
        this.Gui.Hide()
    }

    OnClickSelectToggle() {
        state := this.SelectToggleCon.Value
        if (state == 1)
            TogSelectArea(true, this.SetAreaAction)
        else
            TogSelectArea(false)
    }

    OnF1() {
        this.SelectToggleCon.Value := 1
        TogSelectArea(true, this.SetAreaAction)
    }

    OnSetSearchArea(x1, y1, x2, y2) {
        this.SelectToggleCon.Value := 0
        this.StartPosXCon.Value := x1
        this.StartPosYCon.Value := y1
        this.EndPosXCon.Value := x2
        this.EndPosYCon.Value := y2
    }

    CheckIfValid() {
        if (!InStr(this.ExtractStrCon.Value, "&x") && !InStr(this.ExtractStrCon.Value, "&c")) {
            if (this.ExtractStrCon.Value != "") {
                MsgBox(GetLang("提取文本：不包含&x 或 &c 无法提取内容到变量中"))
                return false
            }
        }

        ToggleArr := []
        loop 6 {
            ToggleArr.Push(this.ToggleConArr[A_Index].Value)
            if (this.ToggleConArr[A_Index].Value) {
                if (IsNumber(this.VariableConArr[A_Index].Text)) {
                    MsgBox(Format(GetLang("{}. 变量名不规范：变量名不能是纯数字"), A_Index))
                    return false
                }
            }
        }

        ActiveLength := GetExVariableActiveLength(ToggleArr)
        if (ActiveLength > 1) {
            ExtractStr := this.ExtractStrCon.Value
            ExtractStr := StrReplace(ExtractStr, "&x", "", true, &XCount)
            ExtractStr := StrReplace(ExtractStr, "&c", "", true, &YCount)
            if (XCount + YCount < ActiveLength) {
                MsgBox(Format(GetLang("提取文本中包含的&x和&c个数少于结果保存变量中勾选的个数")))
                return false
            }
        }

        return true
    }

    TriggerMacro() {
        valid := this.CheckIfValid()
        if (!valid)
            return
        this.SaveExVariableData()
        CommandStr := this.GetCommandStr()
        tableItem := MySoftData.SpecialTableItem
        tableItem.KilledArr[1] := false
        tableItem.PauseArr[1] := 0
        tableItem.ActionCount[1] := 0
        tableItem.VariableMapArr[1] := Map()
        tableItem.index := 1

        this.TestExVariable(this.Data)
    }

    TestExVariable(Data) {
        X1 := Data.StartPosX
        Y1 := Data.StartPosY
        X2 := Data.EndPosX
        Y2 := Data.EndPosY
        if (Data.ExtractType == 1) {
            TextObjs := GetScreenTextObjArr(X1, Y1, X2, Y2, Data.OCRType)
            TextObjs := TextObjs == "" ? [] : TextObjs
        }
        else {
            TextObjs := []
            if (!IsClipboardText())
                return

            obj := Object()
            obj.Text := A_Clipboard
            TextObjs.Push(obj)
        }

        allText := ""
        for _, value in TextObjs {
            allText .= value.text "`n"
        }
        allText := Trim(allText)

        NameArr := []
        ValueArr := []
        ExtractStr := this.GetReplaceVarText(Data.ExtractStr)
        for _, value in TextObjs {
            VariableValueArr := ExtractNumbers(value.Text, ExtractStr)
            VariableValueArr := ExtractStr == "" && allText != "" ? [allText] : VariableValueArr
            if (VariableValueArr == "")
                continue
            if (GetExVariableActiveLength(Data.ToggleArr) > VariableValueArr.Length)
                continue

            loop VariableValueArr.Length {
                if (Data.ToggleArr[A_Index]) {
                    NameArr.Push(Data.VariableArr[A_Index])
                    ValueArr.Push(VariableValueArr[A_Index])
                }
            }
            break
        }

        if (NameArr.Length == 0) {
            MsgBox(GetLang("变量提取失败"))
        }
        else {
            tipStr := GetLang("已提取以下变量") "`n"
            loop NameArr.Length {
                tipStr .= NameArr[A_Index] " = " ValueArr[A_Index] "`n"
            }
            MsgBox(tipStr)
        }
    }

    GetCommandStr() {
        CommandStr := Format("{}_{}", GetLang("变量提取"), this.Data.SerialStr)
        Remark := CorrectRemark(this.RemarkCon.Value)
        if (Remark != "") {
            CommandStr .= "_" Remark
        }
        return CommandStr
    }

    GetExVariableData(SerialStr) {
        saveStr := IniRead(ExVariableFile, IniSection, SerialStr, "")
        if (!saveStr) {
            data := ExVariableData()
            data.SerialStr := SerialStr
            return data
        }

        data := JSON.parse(saveStr, , false)
        return data
    }

    SaveExVariableData() {
        this.Data.ExtractStr := this.ExtractStrCon.Value
        this.Data.ExtractType := this.ExtractTypeCon.Value
        this.Data.OCRType := this.OCRTypeCon.Value
        this.Data.StartPosX := this.StartPosXCon.Value
        this.Data.StartPosY := this.StartPosYCon.Value
        this.Data.EndPosX := this.EndPosXCon.Value
        this.Data.EndPosY := this.EndPosYCon.Value
        this.Data.SearchCount := this.SearchCountCon.Text == GetLang("无限") ? -1 : this.SearchCountCon.Text
        this.Data.SearchInterval := this.SearchIntervalCon.Value
        this.Data.IsIgnoreExist := this.IsIgnoreExistCon.Value
        loop 6 {
            this.Data.ToggleArr[A_Index] := this.ToggleConArr[A_Index].Value
            this.Data.VariableArr[A_Index] := this.VariableConArr[A_Index].Text
        }

        ; 添加全局变量，方便下拉选取
        loop 6 {
            if (this.Data.ToggleArr[A_Index])
                MySoftData.GlobalVariMap[this.Data.VariableArr[A_Index]] := true
        }

        saveStr := JSON.stringify(this.Data, 0)
        IniWrite(saveStr, ExVariableFile, IniSection, this.Data.SerialStr)
        if (MySoftData.DataCacheMap.Has(this.Data.SerialStr)) {
            MySoftData.DataCacheMap.Delete(this.Data.SerialStr)
        }
    }

    GetReplaceVarText(text) {
        matches := []  ; 初始化空数组
        pos := 1  ; 从字符串开头开始搜索

        while (pos := RegExMatch(text, "\{(.*?)\}", &match, pos)) {
            matches.Push(match[1])  ; 把花括号内的内容存入数组
            pos += match.Len  ; 移动到匹配结束位置，继续搜索
        }

        Content := text
        for index, value in matches {
            hasValue := this.TryGetVariableValue(&variValue, value, false)
            if (hasValue)
                Content := StrReplace(Content, "{" value "}", variValue)
        }
        return Content
    }

    TryGetVariableValue(&Value, variableName, variTip := true) {
        if (IsNumber(variableName)) {
            Value := variableName
            return true
        }

        if (variableName == GetLang("当前鼠标坐标X") || variableName == GetLang("当前鼠标坐标Y")) {
            CoordMode("Mouse", "Screen")
            MouseGetPos &mouseX, &mouseY
            Value := variableName == GetLang("当前鼠标坐标X") ? mouseX : mouseY
            return true
        }

        GlobalVariableMap := MySoftData.VariableMap
        if (GlobalVariableMap.Has(variableName)) {
            Value := GlobalVariableMap[variableName]
            return true
        }

        if (variTip)
            ShowNoVariableTip(variableName)
        return false
    }
}
