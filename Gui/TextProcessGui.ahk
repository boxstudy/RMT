#Requires AutoHotkey v2.0

class TextProcessGui {
    __new() {
        this.ParentTile := ""
        this.Gui := ""
        this.SureBtnAction := ""
        this.VariableObjArr := []
        this.RemarkCon := ""

        this.ToggleConArr := []
        this.VariableConArr := []
        this.ProcessTypeCon := ""
        this.SplitDelimiterCon := ""
        this.SearchTextCon := ""
        this.ReplaceTextCon := ""
        this.CaseSensitiveCon := ""
        this.RegexCon := ""
        this.ReverseCon := ""
        this.ResultActionCon := ""
        this.SplitParamCon := ""
        this.MaxSplitCountCon := ""
        this.Data := TextProcessData()
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

    AddGui() {
        MyGui := Gui(, this.ParentTile GetLang("文本处理编辑器"))
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

        PosX += 120
        MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 50), GetLang("备注:"))
        PosX += 50
        this.RemarkCon := MyGui.Add("Edit", Format("x{} y{} w{}", PosX, PosY - 5, 150), "")

        PosX := 20
        PosY += 40
        MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY - 3, 75), GetLang("处理类型:"))
        PosX += 75
        TypeArr := GetLangArr(["文本分割", "文本替换", "数字提取", "字母提取", "中文提取", "去空格处理", "大小写转换", "URL编解码", "Base64编解码", "文本统计",
            "固定长度分割", "去重处理"])
        this.ProcessTypeCon := MyGui.Add("DropDownList", Format("x{} y{} w{}", PosX, PosY - 5, 150), TypeArr)
        this.ProcessTypeCon.OnEvent("Change", (*) => this.OnProcessTypeChange())

        PosX := 275
        MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY - 3, 75), GetLang("文本来源:"))
        PosX += 75
        this.SourceVariableCon := MyGui.Add("ComboBox", Format("x{} y{} w{} R5", PosX, PosY - 5, 150), [])

        PosY += 30
        PosX := 10
        MyGui.Add("GroupBox", Format("x{} y{} w{} h{}", PosX, PosY, 510, 125), GetLang("处理参数"))

        ; 第二行：分割符号
        PosY += 30
        PosX := 20
        this.SplitDelimiterConTip := MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 75), GetLang("分割符号:"))
        PosX += 75
        this.SplitDelimiterCon := MyGui.Add("Edit", Format("x{} y{} w{} Center", PosX, PosY - 5, 150), ",")

        ; 第三行放置查找文本和替换文本
        PosY += 30
        PosX := 20
        this.SearchTextConTip := MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 75), GetLang("查找文本:"))
        PosX += 75
        this.SearchTextCon := MyGui.Add("Edit", Format("x{} y{} w{}", PosX, PosY - 5, 150), "")

        PosX := 275
        this.ReplaceTextConTip := MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 75), GetLang("替换文本:"))
        PosX += 75
        this.ReplaceTextCon := MyGui.Add("Edit", Format("x{} y{} w{}", PosX, PosY - 5, 150), "")

        ; 第四行：分割参数（用于多字符分割、固定长度分割等）
        PosY += 30
        PosX := 20
        this.SplitParamConTip := MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 75), GetLang("类型选项:"))
        PosX += 75
        this.SplitParamCon := MyGui.Add("DropDownList", Format("x{} y{} w{}", PosX, PosY - 5, 150), [])
        this.SplitParamCon.OnEvent("Change", (*) => this.OnSplitParamChange())

        PosX := 275
        this.MaxSplitCountConTip := MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 75), GetLang("最大分割数:"))
        PosX += 75
        this.MaxSplitCountCon := MyGui.Add("Edit", Format("x{} y{} w{} Center", PosX, PosY - 5, 150), "")

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

        MyGui.OnEvent("Close", (*) => this.Gui.Hide())
        MyGui.Show(Format("w{} h{}", 535, 400))
    }

    Init(cmd) {
        cmdArr := cmd != "" ? StrSplit(cmd, "_") : []
        this.SerialStr := cmdArr.Length >= 2 ? cmdArr[2] : GetSerialStr("TextProcess")
        this.RemarkCon.Value := cmdArr.Length >= 3 ? cmdArr[3] : ""
        this.Data := this.GetTextProcessData(this.SerialStr)

        ; 初始化文本来源变量
        this.SourceVariableCon.Delete()
        this.SourceVariableCon.Add(RemoveInVariable(this.VariableObjArr, 2))
        this.SourceVariableCon.Text := this.Data.SourceVariable

        loop this.Data.ToggleArr.Length {
            this.ToggleConArr[A_Index].Value := this.Data.ToggleArr[A_Index]
            this.VariableConArr[A_Index].Delete()
            this.VariableConArr[A_Index].Add(RemoveInVariable(this.VariableObjArr, 2))
            this.VariableConArr[A_Index].Text := this.Data.VariableArr[A_Index]
        }
        this.IsIgnoreExistCon.Value := this.Data.IsIgnoreExist
        this.ProcessTypeCon.Value := this.Data.ProcessType
        this.SplitDelimiterCon.Value := this.Data.SplitDelimiter
        this.SearchTextCon.Value := this.Data.SearchText
        this.ReplaceTextCon.Value := this.Data.ReplaceText
        this.MaxSplitCountCon.Value := this.Data.MaxSplitCount

        ; 先更新界面状态，然后设置参数值
        this.OnProcessTypeChange()

        ; 设置保存的参数值
        this.SplitParamCon.Value := this.Data.SplitParam
    }

    OnClickSureBtn() {
        valid := this.CheckIfValid()
        if (!valid)
            return
        this.SaveTextProcessData()
        CommandStr := this.GetCommandStr()
        action := this.SureBtnAction
        action(CommandStr)
        this.Gui.Hide()
    }

    OnProcessTypeChange() {
        processType := this.ProcessTypeCon.Value

        ; 默认禁用所有控件
        this.SplitDelimiterConTip.Enabled := false
        this.SearchTextConTip.Enabled := false
        this.ReplaceTextConTip.Enabled := false
        this.SplitParamConTip.Enabled := false
        this.MaxSplitCountConTip.Enabled := false
        this.SplitDelimiterCon.Enabled := false
        this.SearchTextCon.Enabled := false
        this.ReplaceTextCon.Enabled := false
        this.SplitParamCon.Enabled := false
        this.MaxSplitCountCon.Enabled := false

        ; 根据处理类型设置参数选项
        paramOptions := []

        switch processType {
            case 1: ; 文本分割
                this.SplitDelimiterConTip.Enabled := true
                this.SplitDelimiterCon.Enabled := true
            case 2: ; 文本替换
                this.SearchTextConTip.Enabled := true
                this.ReplaceTextConTip.Enabled := true
                this.SearchTextCon.Enabled := true
                this.ReplaceTextCon.Enabled := true
            case 3, 4, 5: ; 数字提取、字母提取、中文提取
                ; 无需额外参数
            case 6: ; 去空格处理
                this.SplitParamConTip.Enabled := true
                this.SplitParamCon.Enabled := true
                paramOptions := GetLangArr(["去除前后空格", "去除全部空格", "去除多余空格"])
            case 7: ; 大小写转换
                this.SplitParamConTip.Enabled := true
                this.SplitParamCon.Enabled := true
                paramOptions := GetLangArr(["全部大写", "全部小写", "首字母大写", "标题格式"])
            case 8, 9: ; URL编解码、Base64编解码
                this.SplitParamConTip.Enabled := true
                this.SplitParamCon.Enabled := true
                if (processType == 8) {
                    paramOptions := GetLangArr(["URL编码", "URL解码"])
                } else {
                    paramOptions := GetLangArr(["Base64编码", "Base64解码"])
                }
            case 10: ; 文本统计
                this.SplitParamConTip.Enabled := true
                this.SplitParamCon.Enabled := true
                paramOptions := GetLangArr(["字符数", "单词数", "行数", "完整统计"])
            case 11: ; 固定长度分割
                this.SplitDelimiterConTip.Enabled := false
                this.SplitParamConTip.Enabled := true
                this.MaxSplitCountConTip.Enabled := true
                this.SplitDelimiterCon.Enabled := false
                this.SplitParamCon.Enabled := true
                this.MaxSplitCountCon.Enabled := true
                paramOptions := GetLangArr(["10", "20", "50", "100"])
            case 12: ; 去重处理
                ; 无需额外参数
        }

        ; 更新参数下拉列表
        this.SplitParamCon.Delete()
        this.SplitParamCon.Add(paramOptions)
        if (paramOptions.Length > 0) {
            this.SplitParamCon.Value := 1 ; 默认选择第一个选项
        }
    }

    OnSplitParamChange() {
        ; 处理参数下拉列表变化时的逻辑
        processType := this.ProcessTypeCon.Value
        paramValue := this.SplitParamCon.Value

        ; 处理参数下拉列表变化时的逻辑
        ; 去重处理无需额外参数处理
    }

    OnDateFormatSelected(format) {
        ; 保存自定义格式到当前数据
        this.Data.SplitParamCustom := format
    }

    CheckIfValid() {
        loop 4 {
            if (this.ToggleConArr[A_Index].Value) {
                if (IsNumber(this.VariableConArr[A_Index].Text)) {
                    MsgBox(GetLang(A_Index . ". 变量名不规范：变量名不能是纯数字"))
                    return false
                }
            }
        }
        return true
    }

    TriggerMacro() {
        this.SaveTextProcessData()
        CommandStr := this.GetCommandStr()
        tableItem := MySoftData.SpecialTableItem
        tableItem.KilledArr[1] := false
        tableItem.PauseArr[1] := 0
        tableItem.ActionCount[1] := 0
        tableItem.VariableMapArr[1] := Map()
        tableItem.index := 1

        this.TestTextProcess(this.Data)
    }

    TestTextProcess(Data) {
        NameArr := []
        ValueArr := []

        ; 获取源文本
        sourceText := this.GetSourceText(Data)
        if (sourceText == "" && Data.ProcessType != 13 && Data.ProcessType != 14) {
            return
        }

        ; 处理文本
        switch Data.ProcessType {
            case 1: ; 文本分割
                parts := this.ProcessTextSplit(sourceText, Data)
                partIndex := 1
                loop 4 {
                    if (Data.ToggleArr[A_Index] && partIndex <= parts.Length) {
                        NameArr.Push(Data.VariableArr[A_Index])
                        ValueArr.Push(parts[partIndex])
                        partIndex++
                    }
                }

            case 2: ; 文本替换
                processedText := this.ProcessTextReplace(sourceText, Data.SearchText, Data.ReplaceText)
                this.SaveSingleResult(Data, &NameArr, &ValueArr, processedText)

            case 3: ; 数字提取
                extractedText := this.ExtractDigits(sourceText)
                this.SaveSingleResult(Data, &NameArr, &ValueArr, extractedText)

            case 4: ; 字母提取
                extractedText := this.ExtractAlphabets(sourceText)
                this.SaveSingleResult(Data, &NameArr, &ValueArr, extractedText)

            case 5: ; 中文提取
                extractedText := this.ExtractChineseChars(sourceText)
                this.SaveSingleResult(Data, &NameArr, &ValueArr, extractedText)

            case 6: ; 去空格处理
                processedText := this.ProcessWhitespace(sourceText, Data.SplitParam)
                this.SaveSingleResult(Data, &NameArr, &ValueArr, processedText)

            case 7: ; 大小写转换
                processedText := this.ProcessCaseConversion(sourceText, Data.SplitParam)
                this.SaveSingleResult(Data, &NameArr, &ValueArr, processedText)

            case 8: ; URL编解码
                processedText := this.ProcessURLEncode(sourceText, Data.SplitParam)
                this.SaveSingleResult(Data, &NameArr, &ValueArr, processedText)

            case 9: ; Base64编解码
                processedText := this.ProcessBase64(sourceText, Data.SplitParam)
                this.SaveSingleResult(Data, &NameArr, &ValueArr, processedText)

            case 10: ; 文本统计
                statsText := this.GetTextStatistics(sourceText, Data.SplitParam)
                this.SaveSingleResult(Data, &NameArr, &ValueArr, statsText)

            case 11: ; 固定长度分割
                ; 从下拉列表获取长度值
                lengthOptions := [10, 20, 50, 100]
                length := lengthOptions[Data.SplitParam] ? lengthOptions[Data.SplitParam] : 10
                maxCount := Data.MaxSplitCount ? Integer(Data.MaxSplitCount) : 0
                parts := this.SplitByLength(sourceText, length, maxCount)
                partIndex := 1
                loop 4 {
                    if (Data.ToggleArr[A_Index] && partIndex <= parts.Length) {
                        NameArr.Push(Data.VariableArr[A_Index])
                        ValueArr.Push(parts[partIndex])
                        partIndex++
                    }
                }

            case 12: ; 去重处理
                processedText := this.RemoveDuplicates(sourceText)
                this.SaveSingleResult(Data, &NameArr, &ValueArr, processedText)

        }

        if (NameArr.Length == 0) {
            MsgBox(GetLang("文本处理失败"))
        }
        else {
            ; 将结果保存到全局变量
            loop NameArr.Length {
                MySoftData.VariableMap[NameArr[A_Index]] := ValueArr[A_Index]
            }

            tipStr := GetLang("已处理以下变量") "`n"
            loop NameArr.Length {
                tipStr .= NameArr[A_Index] " = " ValueArr[A_Index] "`n"
            }
            MsgBox(tipStr)

            ; 刷新变量监视器
            if (MyVarListenGui.Gui != "") {
                MyVarListenGui.Refresh()
            }
        }
    }

    GetCommandStr() {
        CommandStr := Format("{}_{}", GetLang("文本处理"), this.Data.SerialStr)
        Remark := CorrectRemark(this.RemarkCon.Value)
        if (Remark != "") {
            CommandStr .= "_" Remark
        }
        return CommandStr
    }

    GetTextProcessData(SerialStr) {
        saveStr := IniRead(TextProcessFile, IniSection, SerialStr, "")
        if (!saveStr) {
            data := TextProcessData()
            data.SerialStr := SerialStr
            return data
        }

        data := JSON.parse(saveStr, , false)
        return data
    }

    SaveTextProcessData() {
        this.Data.SourceVariable := this.SourceVariableCon.Text
        this.Data.ProcessType := this.ProcessTypeCon.Value
        this.Data.SplitDelimiter := this.SplitDelimiterCon.Value
        this.Data.SearchText := this.SearchTextCon.Value
        this.Data.ReplaceText := this.ReplaceTextCon.Value
        this.Data.SplitParam := this.SplitParamCon.Value
        this.Data.MaxSplitCount := this.MaxSplitCountCon.Value
        this.Data.IsIgnoreExist := this.IsIgnoreExistCon.Value
        loop 4 {
            this.Data.ToggleArr[A_Index] := this.ToggleConArr[A_Index].Value
            this.Data.VariableArr[A_Index] := this.VariableConArr[A_Index].Text
        }

        ; 添加全局变量，方便下拉选取
        if (this.Data.SourceVariable != "")
            MySoftData.GlobalVariMap[this.Data.SourceVariable] := true

        loop 4 {
            if (this.Data.ToggleArr[A_Index])
                MySoftData.GlobalVariMap[this.Data.VariableArr[A_Index]] := true
        }

        saveStr := JSON.stringify(this.Data, 0)
        IniWrite(saveStr, TextProcessFile, IniSection, this.Data.SerialStr)
        if (MySoftData.DataCacheMap.Has(this.Data.SerialStr)) {
            MySoftData.DataCacheMap.Delete(this.Data.SerialStr)
        }
    }

    GetReplaceVarText(text) {
        matches := []  ; 初始化空数组
        pos := 1  ; 从字符串开头开始搜索

        while (pos := RegExMatch(text, "\\{(.*?)\\}", &match, pos)) {
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

    OnClickAddVarNameBtn() {
        ; 追加变量名到查找文本或替换文本
        if (this.SearchTextCon.Enabled) {
            this.SearchTextCon.Value .= this.SourceVariableCon.Text
        } else if (this.ReplaceTextCon.Enabled) {
            this.ReplaceTextCon.Value .= this.SourceVariableCon.Text
        }
    }

    OnClickAddVarValueBtn() {
        ; 追加变量值（带花括号）到查找文本或替换文本
        if (this.SearchTextCon.Enabled) {
            this.SearchTextCon.Value .= "{" this.SourceVariableCon.Text "}"
        } else if (this.ReplaceTextCon.Enabled) {
            this.ReplaceTextCon.Value .= "{" this.SourceVariableCon.Text "}"
        }
    }

    ReverseString(text) {
        ; 反转字符串
        reversed := ""
        for i in StrSplit(text, "") {
            reversed := i . reversed
        }
        return reversed
    }

    ProcessTextReplace(sourceText, searchText, replaceText) {
        ; 文本替换处理 - 简化为普通文本替换
        return StrReplace(sourceText, searchText, replaceText)
    }

    RegExEscape(text) {
        ; 转义正则表达式特殊字符
        specialChars := ".^$*+?()[]\{}|"
        escaped := text
        for char in StrSplit(specialChars, "") {
            escaped := StrReplace(escaped, char, "\" char)
        }
        return escaped
    }

    ApplyResultAction(originalValue, newValue, action) {
        ; 应用结果处理方式
        switch action {
            case 1: ; 覆盖变量
                return newValue
            case 2: ; 追加结果
                return originalValue . newValue
            case 3: ; 前置结果
                return newValue . originalValue
            default:
                return newValue
        }
    }

    SaveSingleResult(Data, &NameArr, &ValueArr, result) {
        ; 保存单个结果到第一个选中的变量 - 简化为直接覆盖
        loop 4 {
            if (Data.ToggleArr[A_Index]) {
                NameArr.Push(Data.VariableArr[A_Index])
                ValueArr.Push(result)
                break
            }
        }
    }

    ProcessTextSplit(sourceText, Data) {
        ; 文本分割处理
        if (Data.ReverseProcess) {
            reversedText := this.ReverseString(sourceText)
            parts := StrSplit(reversedText, Data.SplitDelimiter)
            reversedParts := []
            for i in parts {
                reversedParts.InsertAt(1, this.ReverseString(parts[i]))
            }
            return reversedParts
        } else {
            return StrSplit(sourceText, Data.SplitDelimiter)
        }
    }

    ExtractDigits(text) {
        ; 提取所有数字
        numbers := ""
        for char in StrSplit(text, "") {
            if (RegExMatch(char, "^[0-9]$")) {
                numbers .= char
            }
        }
        return numbers
    }

    ExtractAlphabets(text) {
        ; 提取所有字母
        letters := ""
        for char in StrSplit(text, "") {
            if (RegExMatch(char, "^[a-zA-Z]$")) {
                letters .= char
            }
        }
        return letters
    }

    ExtractChineseChars(text) {
        ; 提取中文字符
        chinese := ""
        for char in StrSplit(text, "") {
            if (this.IsChineseChar(char)) {
                chinese .= char
            }
        }
        return chinese
    }

    IsChineseChar(char) {
        ; 判断是否为中文字符
        code := Ord(char)
        return (code >= 0x4E00 && code <= 0x9FFF) || (code >= 0x3400 && code <= 0x4DBF)
    }

    ProcessWhitespace(text, mode) {
        ; 处理空格
        switch mode {
            case 1: ; 去除前后空格
                return Trim(text)
            case 2: ; 去除所有空格
                return StrReplace(text, " ", "")
            case 3: ; 去除多余空格
                return RegExReplace(text, "\s+", " ")
            default:
                return Trim(text)
        }
    }

    ProcessCaseConversion(text, mode) {
        ; 大小写转换
        switch mode {
            case 1: ; 全部大写
                return StrUpper(text)
            case 2: ; 全部小写
                return StrLower(text)
            case 3: ; 首字母大写
                return StrUpper(SubStr(text, 1, 1)) . StrLower(SubStr(text, 2))
            case 4: ; 标题格式
                ; 将每个单词的首字母大写
                words := StrSplit(text, " ")
                result := ""
                for word in words {
                    if (word != "") {
                        result .= (result ? " " : "") . StrUpper(SubStr(word, 1, 1)) . StrLower(SubStr(word, 2))
                    }
                }
                return result
            default:
                return text
        }
    }

    ProcessURLEncode(text, mode) {
        ; URL编解码
        switch mode {
            case 1: ; URL编码
                encoded := ""
                for char in StrSplit(text, "") {
                    code := Ord(char)
                    if ((code >= 48 && code <= 57) || (code >= 65 && code <= 90) || (code >= 97 && code <= 122) || char ==
                    "-" || char == "_" || char == "." || char == "~") {
                        encoded .= char
                    } else {
                        encoded .= "%" . Format("{:02X}", code)
                    }
                }
                return encoded
            case 2: ; URL解码
                decoded := ""
                i := 1
                while (i <= StrLen(text)) {
                    char := SubStr(text, i, 1)
                    if (char == "%") {
                        hex := SubStr(text, i + 1, 2)
                        decoded .= Chr("0x" . hex)
                        i += 3
                    } else {
                        decoded .= char
                        i++
                    }
                }
                return decoded
            default:
                return text
        }
    }

    ProcessBase64(text, mode) {
        ; Base64编解码
        switch mode {
            case 1: ; Base64编码
                return this.Base64Encode(text)
            case 2: ; Base64解码
                return this.Base64Decode(text)
            default:
                return text
        }
    }

    Base64Encode(text) {
        ; 使用标准的Base64编码实现
        return this.SimpleBase64Encode(text)
    }

    Base64Decode(encoded) {
        ; 使用标准的Base64解码实现
        return this.SimpleBase64Decode(encoded)
    }

    SimpleBase64Encode(text) {
        ; 简化的Base64编码（备用实现）
        charset := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        encoded := ""

        ; 处理空字符串
        if (text == "") {
            return ""
        }

        ; 将文本转换为字节数组
        bytes := []
        for i in StrSplit(text, "") {
            bytes.Push(Ord(i))
        }

        i := 1
        while (i <= bytes.Length) {
            ; 处理3个字节
            b1 := bytes[i]
            b2 := (i + 1 <= bytes.Length) ? bytes[i + 1] : 0
            b3 := (i + 2 <= bytes.Length) ? bytes[i + 2] : 0

            combined := (b1 << 16) | (b2 << 8) | b3

            ; 获取4个6位值
            encoded .= SubStr(charset, ((combined >> 18) & 0x3F) + 1, 1)
            encoded .= SubStr(charset, ((combined >> 12) & 0x3F) + 1, 1)
            encoded .= (i + 1 <= bytes.Length) ? SubStr(charset, ((combined >> 6) & 0x3F) + 1, 1) : "="
            encoded .= (i + 2 <= bytes.Length) ? SubStr(charset, (combined & 0x3F) + 1, 1) : "="

            i += 3
        }
        return encoded
    }

    SimpleBase64Decode(encoded) {
        ; 简化的Base64解码（备用实现）
        charset := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        decoded := ""

        ; 处理空字符串
        if (encoded == "") {
            return ""
        }

        ; 移除可能的换行符和空格
        encoded := RegExReplace(encoded, "[\r\n\s]+", "")

        ; 检查Base64字符串长度是否为4的倍数
        if (Mod(StrLen(encoded), 4) != 0) {
            return ""  ; 无效的Base64字符串
        }

        i := 1
        while (i <= StrLen(encoded)) {
            char1 := SubStr(encoded, i, 1)
            char2 := SubStr(encoded, i + 1, 1)
            char3 := SubStr(encoded, i + 2, 1)
            char4 := SubStr(encoded, i + 3, 1)

            ; 获取每个字符的值
            v1 := InStr(charset, char1) - 1
            v2 := InStr(charset, char2) - 1
            v3 := (char3 != "=" && char3 != "") ? InStr(charset, char3) - 1 : 0
            v4 := (char4 != "=" && char4 != "") ? InStr(charset, char4) - 1 : 0

            combined := (v1 << 18) | (v2 << 12) | (v3 << 6) | v4

            ; 解码3个字节
            byte1 := (combined >> 16) & 0xFF
            byte2 := (combined >> 8) & 0xFF
            byte3 := combined & 0xFF

            ; 根据填充字符确定实际字节数
            if (char4 == "=") {
                ; 2个填充字符，只有1个有效字节
                decoded .= Chr(byte1)
            } else if (char3 == "=") {
                ; 1个填充字符，有2个有效字节
                decoded .= Chr(byte1) . Chr(byte2)
            } else {
                ; 没有填充字符，有3个有效字节
                decoded .= Chr(byte1) . Chr(byte2) . Chr(byte3)
            }

            i += 4
        }
        return decoded
    }

    GetTextStatistics(text, mode) {
        ; 文本统计
        switch mode {
            case 1: ; 字符数
                return StrLen(text)
            case 2: ; 单词数
                words := StrSplit(text, [" ", "`t", "`n", "`r"])
                count := 0
                for word in words {
                    if (StrLen(word) > 0) {
                        count++
                    }
                }
                return count
            case 3: ; 行数
                lines := StrSplit(text, ["`n", "`r"])
                return lines.Length
            case 4: ; 完整统计
                charCount := StrLen(text)
                words := StrSplit(text, [" ", "`t", "`n", "`r"])
                wordCount := 0
                for word in words {
                    if (StrLen(word) > 0) {
                        wordCount++
                    }
                }
                lines := StrSplit(text, ["`n", "`r"])
                lineCount := lines.Length

                chineseCount := 0
                for char in StrSplit(text, "") {
                    if (this.IsChineseChar(char)) {
                        chineseCount++
                    }
                }

                stats := GetLang("字符数") . ": " . charCount . "`n" . GetLang("单词数") . ": " . wordCount . "`n" . GetLang(
                    "行数") . ": " . lineCount . "`n" . GetLang("中文字符数") . ": " . chineseCount
                return stats
            default:
                return StrLen(text)
        }
    }

    SplitByLength(text, length, maxCount) {
        ; 按固定长度分割
        parts := []
        current := 1
        while (current <= StrLen(text)) {
            part := SubStr(text, current, length)
            parts.Push(part)
            current += length
            if (maxCount > 0 && parts.Length >= maxCount) {
                break
            }
        }
        return parts
    }

    SplitByMultipleDelimiters(text, delimiters, maxCount) {
        ; 按多个分隔符分割
        delimiterList := StrSplit(delimiters, "|")
        result := [text]

        for delimiter in delimiterList {
            newResult := []
            for part in result {
                subParts := StrSplit(part, delimiter)
                for subPart in subParts {
                    newResult.Push(subPart)
                }
            }
            result := newResult
        }

        if (maxCount > 0 && result.Length > maxCount) {
            loop result.Length - maxCount {
                result[maxCount] .= delimiterList[1] . result[maxCount + A_Index]
            }
            while (result.Length > maxCount) {
                result.RemoveAt(result.Length)
            }
        }

        return result
    }

    FilterLines(text, filter) {
        ; 过滤行
        if (!filter) {
            return text
        }

        lines := StrSplit(text, ["`n", "`r"])
        filtered := []

        for line in lines {
            if (InStr(line, filter)) {
                filtered.Push(line)
            }
        }

        resultText := ""
        for i, value in filtered {
            if (i > 1) {
                resultText .= "`n"
            }
            resultText .= value
        }
        return resultText
    }

    RemoveDuplicates(text) {
        ; 去重处理
        lines := StrSplit(text, ["`n", "`r"])
        unique := Map()
        result := []

        for line in lines {
            key := StrLen(line) > 0 ? line : ""
            if (!unique.Has(key)) {
                unique[key] := true
                result.Push(line)
            }
        }

        resultText := ""
        for i, value in result {
            if (i > 1) {
                resultText .= "`n"
            }
            resultText .= value
        }
        return resultText
    }

    SortText(text, reverse) {
        ; 排序处理
        lines := StrSplit(text, ["`n", "`r"])
        lines.Sort()

        if (reverse) {
            reversed := []
            loop lines.Length {
                reversed.Push(lines[lines.Length - A_Index + 1])
            }
            lines := reversed
        }

        resultText := ""
        for i, value in lines {
            if (i > 1) {
                resultText .= "`n"
            }
            resultText .= value
        }
        return resultText
    }

    GenerateRandomText(length) {
        ; 生成随机文本
        chars := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        randomText := ""

        length := length > 0 ? length : 10

        loop length {
            randomIndex := Random(1, StrLen(chars))
            randomText .= SubStr(chars, randomIndex, 1)
        }

        return randomText
    }

    GetDateTime(format) {
        ; 获取格式化的日期时间
        now := A_Now
        if (!format) {
            format := "yyyy-MM-dd HH:mm:ss"
        }

        ; 简单的格式替换
        result := format
        result := StrReplace(result, "yyyy", FormatTime(now, "yyyy"))
        result := StrReplace(result, "MM", FormatTime(now, "MM"))
        result := StrReplace(result, "dd", FormatTime(now, "dd"))
        result := StrReplace(result, "HH", FormatTime(now, "HH"))
        result := StrReplace(result, "mm", FormatTime(now, "mm"))
        result := StrReplace(result, "ss", FormatTime(now, "ss"))

        return result
    }

    GetSourceText(Data) {
        ; 获取源文本，对于需要输入的功能检查变量，对于生成类功能直接返回空字符串
        switch Data.ProcessType {
            case 13, 14: ; 随机文本、日期时间 - 不需要输入变量
                return ""
            default: ; 其他功能需要输入变量
                sourceText := ""
                sourceVariableName := Data.SourceVariable

                if (sourceVariableName == "") {
                    MsgBox(GetLang("文本处理失败：请指定文本来源变量"))
                    return ""
                }

                if (!this.TryGetVariableValue(&sourceText, sourceVariableName, false)) {
                    errorText := GetLang("文本处理失败：源变量不存在：") . sourceVariableName
                    MsgBox(errorText)
                    return ""
                }

                if (sourceText == "") {
                    MsgBox(GetLang("文本处理失败：源变量为空"))
                    return ""
                }

                return sourceText
        }
    }
}
