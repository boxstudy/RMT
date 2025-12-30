;按键宏命令
OnTriggerMacroKeyAndInit(tableItem, macro, index) {
    MyMacroCount("Add")
    tableItem.KilledArr[index] := false
    tableItem.PauseArr[index] := false
    tableItem.ActionCount[index] := 0
    tableItem.VariableMapArr[index]["宏循环次数"] := 1
    tableItem.VariableMapArr[index]["指令循环次数"] := 0
    isContinue := tableItem.TKArr.Has(index) && MySoftData.ContinueKeyMap.Has(tableItem.TKArr[index]) && tableItem.LoopCountArr[
        index] == 1
    isLoop := tableItem.LoopCountArr[index] == -1
    loop {
        isFirst := tableItem.ActionCount[index] == 0
        isLast := tableItem.ActionCount[index] == tableItem.LoopCountArr[index] - 1
        isOver := tableItem.ActionCount[index] >= tableItem.LoopCountArr[index]
        WaitIfPaused(tableItem, index)

        if (tableItem.KilledArr[index])
            break

        if (!isLoop && !isContinue && isOver)
            break

        if (!isFirst && isContinue && isOver) {
            key := MySoftData.ContinueKeyMap[tableItem.TKArr[index]]
            Sleep(MySoftData.ContinueIntervale)

            if (!GetKeyState(key, "P")) {
                break
            }
        }

        HandTipSound(tableItem, index, 1, isFirst, isLast)
        OnTriggerMacroOnce(tableItem, macro, index)
        HandTipSound(tableItem, index, 2, isFirst, isLast)
        tableItem.ActionCount[index]++
        tableItem.VariableMapArr[index]["宏循环次数"] += 1
    }
    OnFinishMacro(tableItem, macro, index)
}

OnFinishMacro(tableItem, macro, index) {
    if (tableItem.TriggerTypeArr[index] == 4) { ;开关状态下
        tableItem.ToggleStateArr[index] := false
    }

    itemState := tableItem.KilledArr[index] ? 3 : 0
    MySetTableItemState(tableItem.index, index, itemState)
}

OnTriggerMacroOnce(tableItem, macro, index) {
    global MySoftData
    cmdArr := SplitMacro(macro)

    for value in cmdArr {
        if (tableItem.KilledArr[index])
            break

        WaitIfPaused(tableItem, index)
        paramArr := StrSplit(cmdArr[A_Index], "_")
        if (SubStr(paramArr[1], 1, 2) == "🚫")
            continue
        IsMouseMove := StrCompare(paramArr[1], "移动", false) == 0
        IsSearch := StrCompare(paramArr[1], "搜索", false) == 0
        IsSearchPro := StrCompare(paramArr[1], "搜索Pro", false) == 0
        IsPressKey := StrCompare(paramArr[1], "按键", false) == 0
        IsInterval := StrCompare(paramArr[1], "间隔", false) == 0
        IsRun := StrCompare(paramArr[1], "运行", false) == 0
        IsIf := StrCompare(paramArr[1], "如果", false) == 0
        IsIfPro := StrCompare(paramArr[1], "如果Pro", false) == 0
        IsMMPro := StrCompare(paramArr[1], "移动Pro", false) == 0
        IsOutput := StrCompare(paramArr[1], "输出", false) == 0
        IsVariable := StrCompare(paramArr[1], "变量", false) == 0
        IsExVariable := StrCompare(paramArr[1], "变量提取", false) == 0
        IsSubMacro := StrCompare(paramArr[1], "宏操作", false) == 0
        IsOperation := StrCompare(paramArr[1], "运算", false) == 0
        IsBGMouse := StrCompare(paramArr[1], "后台鼠标", false) == 0
        IsBGKey := StrCompare(paramArr[1], "后台按键", false) == 0
        IsRMT := StrCompare(paramArr[1], "RMT指令", false) == 0
        IsLoop := StrCompare(paramArr[1], "循环", false) == 0
        IsTextProcess := StrCompare(paramArr[1], "文本处理", false) == 0

        if (MySoftData.CMDTip) {
            NoRemark := IsMouseMove || IsPressKey || IsInterval || IsRMT
            hasRemark := !NoRemark && paramArr.Length > 2
            tipStr := hasRemark ? paramArr[1] "_" paramArr[3] : cmdArr[A_Index]
            MyCMDReportAciton(tipStr)
        }

        if (IsInterval) {
            OnInterval(tableItem, cmdArr[A_Index], index)
        }
        else if (IsPressKey) {
            OnPressKey(tableItem, cmdArr[A_Index], index)
        }
        else if (IsSearch || IsSearchPro) {
            isLoopFound := OnSearch(tableItem, cmdArr[A_Index], index)
            if (isLoopFound != "" && isLoopFound == false) {
                cmdArr.InsertAt(A_Index + 1, cmdArr[A_Index])
            }
        }
        else if (IsMouseMove) {
            OnMouseMove(tableItem, cmdArr[A_Index], index)
        }
        else if (IsMMPro) {
            OnMMPro(tableItem, cmdArr[A_Index], index)
        }
        else if (IsRun) {
            OnRunFile(tableItem, cmdArr[A_Index], index)
        }
        else if (IsIf) {
            OnCompare(tableItem, cmdArr[A_Index], index)
        }
        else if (IsIfPro) {
            OnComparePro(tableItem, cmdArr[A_Index], index)
        }
        else if (IsOutput) {
            OnOutput(tableItem, cmdArr[A_Index], index)
        }
        else if (IsVariable) {
            OnVariable(tableItem, cmdArr[A_Index], index)
        }
        else if (IsExVariable) {
            isLoopFound := OnExVariable(tableItem, cmdArr[A_Index], index)
            if (isLoopFound != "" && isLoopFound == false) {
                cmdArr.InsertAt(A_Index + 1, cmdArr[A_Index])
            }
        }
        else if (IsSubMacro) {
            newCmdArr := OnSubMacro(tableItem, cmdArr[A_Index], index)
            if (newCmdArr != "") {
                cmdArr.InsertAt(A_Index + 1, newCmdArr*)
            }
        }
        else if (IsOperation) {
            OnOperation(tableItem, cmdArr[A_Index], index)
        }
        else if (IsBGMouse) {
            OnBGMouse(tableItem, cmdArr[A_Index], index)
        }
        else if (IsRMT) {
            OnRMTCMD(tableItem, cmdArr[A_Index], index)
        }
        else if (IsBGKey) {
            OnBGKey(tableItem, cmdArr[A_Index], index)
        }
        else if (IsLoop) {
            OnLoop(tableItem, cmdArr[A_Index], index)
        }
        else if (IsTextProcess) {
            OnTextProcess(tableItem, cmdArr[A_Index], index)
        }
    }
}

OnSearch(tableItem, cmd, index) {
    paramArr := StrSplit(cmd, "_")
    dataFile := StrCompare(paramArr[1], "搜索", false) == 0 ? SearchFile : SearchProFile
    Data := GetMacroCMDData(dataFile, paramArr[2])
    if (Data.SearchCount == -1) {
        isLoopFound := OnSearchOnce(tableItem, Data, index)
        if (!isLoopFound) {
            FloatInterval := GetFloatTime(Data.SearchInterval, MySoftData.PreIntervalFloat)
            Sleep(FloatInterval)
        }
        return isLoopFound
    }
    else {
        loop Data.SearchCount {
            WaitIfPaused(tableItem, index)

            if (tableItem.KilledArr[index])
                return

            isFound := OnSearchOnce(tableItem, Data, index)
            if (isFound)
                return

            if (Data.SearchCount > A_Index) {
                FloatInterval := GetFloatTime(Data.SearchInterval, MySoftData.PreIntervalFloat)
                Sleep(FloatInterval)
            }
        }

        if (Data.ResultToggle) {
            MySetGlobalVariable([Data.ResultSaveName], [Data.FalseValue], false)
        }

        if (Data.FalseMacro == "")
            return
        OnTriggerMacroOnce(tableItem, Data.FalseMacro, index)
    }
}

; 定义OpenCV图片搜索函数原型
FindImage(targetPath, searchX, searchY, searchW, searchH, matchThreshold, x, y) {
    return DllCall("ImageFinder.dll\FindImage", "AStr", targetPath,
        "Int", searchX, "Int", searchY, "Int", searchW, "Int", searchH,
        "Int", matchThreshold, "Int*", x, "Int*", y, "Cdecl Int")
}

OnSearchOnce(tableItem, Data, index) {
    X1 := Integer(Data.StartPosX)
    Y1 := Integer(Data.StartPosY)
    X2 := Integer(Data.EndPosX)
    Y2 := Integer(Data.EndPosY)
    VariableMap := tableItem.VariableMapArr[index]

    CoordMode("Pixel", "Screen")
    if (Data.SearchType == 1) {
        if (Data.SearchImageType == 1) {
            OutputVarX := 0
            OutputVarY := 0
            found := FindImage(Data.SearchImagePath, X1, Y1, X2 - X1, Y2 - Y1, Data.Similar, &OutputVarX, &
                OutputVarY)
        }
        else {
            Similar := Integer(-2.55 * Data.Similar + 255)
            SearchInfo := Format("*{} *w0 *h0 {}", Similar, Data.SearchImagePath)
            found := ImageSearch(&OutputVarX, &OutputVarY, X1, Y1, X2, Y2, SearchInfo)
        }
    }
    else if (Data.SearchType == 2) {
        color := "0X" Data.SearchColor
        Similar := Integer(-2.55 * Data.Similar + 255)
        found := PixelSearch(&OutputVarX, &OutputVarY, X1, Y1, X2, Y2, color, Similar)
    }
    else if (Data.SearchType == 3) {
        text := Data.SearchText
        hasValue := TryGetVariableValue(&text, tableItem, index, Data.SearchText, false)
        found := CheckScreenContainText(&OutputVarX, &OutputVarY, X1, Y1, X2, Y2, text, Data.OCRType)
    }

    if (found) {
        ;自动移动鼠标
        CoordMode("Mouse", "Screen")
        SendMode("Event")
        Speed := 100 - Data.Speed
        Pos := [OutputVarX, OutputVarY]
        if (Data.SearchType == 1) {
            imageSize := GetImageSize(Data.SearchImagePath)
            Pos := [OutputVarX + imageSize[1] / 2, OutputVarY + imageSize[2] / 2]
        }

        if (Data.ResultToggle) {
            MySetGlobalVariable([Data.ResultSaveName], [Data.TrueValue], false)
        }

        if (Data.CoordToogle) {
            MySetGlobalVariable([Data.CoordXName], [Pos[1]], false)
            MySetGlobalVariable([Data.CoordYName], [Pos[2]], false)
        }

        Pos[1] := GetFloatValue(Pos[1], MySoftData.CoordXFloat)
        Pos[2] := GetFloatValue(Pos[2], MySoftData.CoordYFloat)
        if (Data.MouseActionType == 4) {
            SetDefaultMouseSpeed(Speed)
            Click(Format("{} {} {}"), Pos[1], Pos[2], 2)
        }
        if (Data.MouseActionType == 3) {
            SetDefaultMouseSpeed(Speed)
            Click(Format("{} {} {}"), Pos[1], Pos[2], Data.ClickCount)
        }
        else if (Data.MouseActionType == 2) {
            MouseMove(Pos[1], Pos[2], Speed)
        }

        if (Data.TrueMacro == "")
            return true

        OnTriggerMacroOnce(tableItem, Data.TrueMacro, index)
        return true
    }

    return false
}

OnRunFile(tableItem, cmd, index) {
    paramArr := StrSplit(cmd, "_")
    Data := GetMacroCMDData(RunFile, paramArr[2])

    isMp3 := RegExMatch(Data.RunPath, ".mp3$")
    if (isMp3 && Data.BackPlay) {
        playAudioCmd := Format('wscript.exe "{}" "{}"', VBSPath, Data.RunPath)
        Run(playAudioCmd)
        return
    }

    Run(Data.RunPath)
}

OnCompare(tableItem, cmd, index) {
    paramArr := StrSplit(cmd, "_")
    Data := GetMacroCMDData(CompareFile, paramArr[2])
    VariableMap := tableItem.VariableMapArr[index]
    result := Data.LogicalType == 1 ? true : false
    loop 4 {
        if (!Data.ToggleArr[A_Index])
            continue

        if (Data.CompareTypeArr[A_Index] == 7) {        ;变量是否存在
            hasValue := TryGetVariableValue(&Value, tableItem, index, Data.NameArr[A_Index], false)
            currentComparison := hasValue
        }
        else {
            hasValue := TryGetVariableValue(&Value, tableItem, index, Data.NameArr[A_Index])
            if (!hasValue)
                return
            if (Data.CompareTypeArr[A_Index] == 6) {  ;字符包含的时候可以直接使用字符
                hasOtherValue := TryGetVariableValue(&OtherValue, tableItem, index, Data.VariableArr[A_Index], false)
                OtherValue := hasOtherValue ? OtherValue : Data.VariableArr[A_Index]
                hasOtherValue := true
            }
            else {
                hasOtherValue := TryGetVariableValue(&OtherValue, tableItem, index, Data.VariableArr[A_Index])
            }

            if (!hasOtherValue)
                return

            switch Data.CompareTypeArr[A_Index] {
                case 1: currentComparison := Value > OtherValue
                case 2: currentComparison := Value >= OtherValue
                case 3: currentComparison := Value == OtherValue
                case 4: currentComparison := Value <= OtherValue
                case 5: currentComparison := Value < OtherValue
                case 6: currentComparison := CheckContainText(Value, OtherValue)
            }
        }

        if (Data.LogicalType == 1) {
            result := result && currentComparison
            if (!result)
                break
        } else {
            result := result || currentComparison
            if (result)
                break
        }
    }

    if (Data.SaveToggle) {
        SaveValue := result ? Data.TrueValue : Data.FalseValue
        MySetGlobalVariable([Data.SaveName], [SaveValue], Data.IsIgnoreExist)
    }

    macro := ""
    macro := result && Data.TrueMacro != "" ? Data.TrueMacro : macro
    macro := !result && Data.FalseMacro != "" ? Data.FalseMacro : macro
    if (macro == "")
        return

    OnTriggerMacroOnce(tableItem, macro, index)
}

OnComparePro(tableItem, cmd, index) {
    paramArr := StrSplit(cmd, "_")
    Data := GetMacroCMDData(CompareProFile, paramArr[2])

    loop Data.VariNameArr.Length {
        NameArr := Data.VariNameArr[A_Index]
        CompareTypeArr := Data.CompareTypeArr[A_Index]
        VariableArr := Data.VariableArr[A_Index]
        LogicType := Data.LogicTypeArr[A_Index]
        Macro := Data.MacroArr[A_Index]
        result := LogicType == 1 ? true : false
        loop NameArr.Length {
            if (CompareTypeArr[A_Index] == 7) {
                hasValue := TryGetVariableValue(&Value, tableItem, index, NameArr[A_Index], false)
                currentComparison := hasValue
            }
            else {
                hasValue := TryGetVariableValue(&Value, tableItem, index, NameArr[A_Index])
                if (CompareTypeArr[A_Index] == 6) {  ;字符包含的时候可以直接使用字符
                    hasOtherValue := TryGetVariableValue(&OtherValue, tableItem, index, VariableArr[A_Index],
                        false)
                    OtherValue := hasOtherValue ? OtherValue : VariableArr[A_Index]
                    hasOtherValue := true
                }
                else {
                    hasOtherValue := TryGetVariableValue(&OtherValue, tableItem, index, VariableArr[A_Index])
                }

                if (!hasValue || !hasOtherValue) {
                    return
                }

                switch CompareTypeArr[A_Index] {
                    case 1: currentComparison := Value > OtherValue
                    case 2: currentComparison := Value >= OtherValue
                    case 3: currentComparison := Value == OtherValue
                    case 4: currentComparison := Value <= OtherValue
                    case 5: currentComparison := Value < OtherValue
                    case 6: currentComparison := CheckContainText(Value, OtherValue)
                }
            }

            if (LogicType == 1) {
                result := result && currentComparison
                if (!result)
                    break
            } else {
                result := result || currentComparison
                if (result)
                    break
            }
        }

        if (result) {
            if (Macro != "")
                OnTriggerMacroOnce(tableItem, Macro, index)
            return
        }
    }
    OnTriggerMacroOnce(tableItem, Data.DefaultMacro, index)
}

OnMMPro(tableItem, cmd, index) {
    paramArr := StrSplit(cmd, "_")
    Data := GetMacroCMDData(MMProFile, paramArr[2])

    LastSumTime := 0
    loop Data.Count {
        WaitIfPaused(tableItem, index)

        if (tableItem.KilledArr[index])
            return

        FloatInterval := GetFloatTime(Data.Interval, MySoftData.PreIntervalFloat)
        OnMMProOnce(tableItem, index, Data)
        if (A_Index != Data.Count)
            Sleep(FloatInterval)
    }
}

OnMMProOnce(tableItem, index, Data) {
    SendMode("Event")
    CoordMode("Mouse", "Screen")
    Speed := 100 - Data.Speed

    hasPosVarX := TryGetVariableValue(&PosX, tableItem, index, Data.PosVarX)
    hasPosVarY := TryGetVariableValue(&PosY, tableItem, index, Data.PosVarY)
    if (!hasPosVarX || !hasPosVarY) {
        return
    }

    PosX := GetFloatValue(PosX, MySoftData.CoordXFloat)
    PosY := GetFloatValue(PosY, MySoftData.CoordYFloat)
    ClickCount := Data.ActionType == 2 ? 1 : 2
    if (Data.IsGameView) {
        MOUSEEVENTF_MOVE := 0x0001
        DllCall("mouse_event", "UInt", MOUSEEVENTF_MOVE, "UInt", PosX, "UInt", PosY, "UInt", 0, "UInt", 0)
    }
    else if (Data.ActionType == 1) {
        if (Data.IsRelative) {
            MouseMove(PosX, PosY, Speed, "R")
        }
        else
            MouseMove(PosX, PosY, Speed)
    }
    else if (Data.ActionType == 2 || Data.ActionType == 3) {
        SetDefaultMouseSpeed(Speed)
        if (Data.IsRelative) {
            Click(Format("{} {} {} Relative"), PosX, PosY, ClickCount)
        }
        else {
            Click(Format("{} {} {}"), PosX, PosY, ClickCount)
        }
    }
}

OnOutput(tableItem, cmd, index) {
    paramArr := StrSplit(cmd, "_")
    Data := GetMacroCMDData(OutputFile, paramArr[2])
    Content := GetReplaceVarText(tableItem, index, Data.Text)

    if (Data.OutputType == 1) {     ;send
        SendText(Content)
    }
    else if (Data.OutputType == 2) {    ;粘贴文本
        A_Clipboard := Content
        Send "{Blind}^v"
    }
    else if (Data.OutputType == 3) {    ;提示
        MyToolTipContent(Content)
    }
    else if (Data.OutputType == 4) {    ;指令窗口
        MyCMDReportAciton(Content)
    }
    else if (Data.OutputType == 5) {    ;弹窗
        MyMsgBoxContent(Content)
    }
    else if (Data.OutputType == 6) {    ;语音
        spovice := ComObject("sapi.spvoice")
        spovice.Speak(Content)
    }
    else if (Data.OutputType == 7) {    ;剪切板
        A_Clipboard := Content
    }
    else if (Data.OutputType == 8) {    ;文本文件
        FileObj := FileOpen(Data.FilePath, "a")
        FileObj.WriteLine(Content)
        FileObj.Close()
    }
    else if (Data.OutputType == 9) {    ;Excel
        hasRowValue := TryGetVariableValue(&RowValue, tableItem, index, Data.RowVar)
        hasColValue := TryGetVariableValue(&ColValue, tableItem, index, Data.ColVar)
        if (Data.ExcelType == 1) {
            if (hasRowValue && hasColValue)
                ExcelCellToWrite(Data.FilePath, Data.NameOrSerial, RowValue, ColValue, Content)
        }
        else if (Data.ExcelType == 2) {
            if (hasColValue)
                ExcelRowToWrite(Data.FilePath, Data.NameOrSerial, ColValue, Content)
        }
        else if (Data.ExcelType == 3) {
            if (hasRowValue)
                ExcelColToWrite(Data.FilePath, Data.NameOrSerial, RowValue, Content)
        }
    }
}

OnLoop(tableItem, cmd, index) {
    paramArr := StrSplit(cmd, "_")
    Data := GetMacroCMDData(LoopFile, paramArr[2])

    if (Data.LoopCount == -1) {
        loop {
            tableItem.VariableMapArr[index]["指令循环次数"] := A_Index
            if (!GetLoopState(tableItem, cmd, index, Data))
                break

            if (tableItem.KilledArr[index])
                break

            WaitIfPaused(tableItem, index)

            OnTriggerMacroOnce(tableItem, Data.LoopBody, index)
        }
    }
    else {
        hasValue := TryGetVariableValue(&Value, tableItem, index, Data.LoopCount)
        if (!hasValue)
            return

        loop Value {
            tableItem.VariableMapArr[index]["指令循环次数"] := A_Index
            if (!GetLoopState(tableItem, cmd, index, Data))
                break

            if (tableItem.KilledArr[index])
                break

            WaitIfPaused(tableItem, index)

            OnTriggerMacroOnce(tableItem, Data.LoopBody, index)
        }
    }
}

GetLoopState(tableItem, cmd, index, Data) {
    if (Data.CondiType == 1)
        return true

    result := Data.LogicType == 1 ? true : false
    loop 4 {
        if (!Data.ToggleArr[A_Index])
            continue

        if (Data.CompareTypeArr[A_Index] == 7) {        ;变量是否存在
            hasValue := TryGetVariableValue(&Value, tableItem, index, Data.NameArr[A_Index], false)
            currentComparison := hasValue
        }
        else {
            hasValue := TryGetVariableValue(&Value, tableItem, index, Data.NameArr[A_Index])
            if (Data.CompareTypeArr[A_Index] == 6) {  ;字符包含的时候可以直接使用字符
                hasOtherValue := TryGetVariableValue(&OtherValue, tableItem, index, Data.VariableArr[A_Index], false)
                OtherValue := hasOtherValue ? OtherValue : Data.VariableArr[A_Index]
                hasOtherValue := true
            }
            else {
                hasOtherValue := TryGetVariableValue(&OtherValue, tableItem, index, Data.VariableArr[A_Index])
            }

            if (!hasValue || !hasOtherValue) {
                result := false
                break
            }

            switch Data.CompareTypeArr[A_Index] {
                case 1: currentComparison := Value > OtherValue
                case 2: currentComparison := Value >= OtherValue
                case 3: currentComparison := Value == OtherValue
                case 4: currentComparison := Value <= OtherValue
                case 5: currentComparison := Value < OtherValue
                case 6: currentComparison := CheckContainText(Value, OtherValue)
            }
        }

        if (Data.LogicType == 1) {
            result := result && currentComparison
            if (!result)
                break
        } else {
            result := result || currentComparison
            if (result)
                break
        }
    }

    if (Data.CondiType == 2)
        return result

    if (Data.CondiType == 3)
        return !result
}

OnSubMacro(tableItem, cmd, index) {
    global MySoftData
    paramArr := StrSplit(cmd, "_")
    Data := GetMacroCMDData(SubMacroFile, paramArr[2])
    macroIndex := Data.MacroType == 1 ? index : Data.Index
    macroTableIndex := Data.MacroType == 1 ? tableItem.Index : Data.MacroType - 1
    macroItem := Data.MacroType == 1 ? tableItem : MySoftData.TableInfo[macroTableIndex]

    redirect := Data.MacroType != 1 && (macroItem.SerialArr.Length < Data.Index || macroItem.SerialArr[Data.Index] !=
        Data.MacroSerial)
    if (redirect) {
        loop macroItem.ModeArr.Length {
            if (Data.MacroSerial == macroItem.SerialArr[A_Index]) {
                macroIndex := A_Index
                break
            }
        }
    }

    if (Data.CallType == 1) {   ;插入
        macro := macroItem.MacroArr[macroIndex]
        resultMacro := macro
        loop Data.InsertCount {
            if (A_Index == 1)
                continue
            resultMacro .= "," macro
        }
        return SplitMacro(resultMacro)
    }
    else if (Data.CallType == 2) {  ;触发
        MyTriggerSubMacro(macroTableIndex, macroIndex)
    }
    else if (Data.CallType == 3) {  ;暂停
        MySetItemPauseState(macroTableIndex, macroIndex, 1)
    }
    else if (Data.CallType == 4) {  ;取消暂停
        MySetItemPauseState(macroTableIndex, macroIndex, 0)
    }
    else if (Data.CallType == 5) {  ;终止
        isWork := macroItem.IsWorkIndexArr[macroIndex]
        if (isWork || MySoftData.isWork) {
            MySubMacroStopAction(macroTableIndex, macroIndex)
            return
        }

        KillTableItemMacro(macroItem, macroIndex)
    }
}

OnVariable(tableItem, cmd, index) {
    paramArr := StrSplit(cmd, "_")
    Data := GetMacroCMDData(VariableFile, paramArr[2])
    LocalVariableMap := tableItem.VariableMapArr[index]
    DeleteNameArr := []
    VariableNameArr := []
    ValueArr := []
    loop 4 {
        if (!Data.ToggleArr[A_Index])
            continue
        VariableName := Data.VariableArr[A_Index]
        if (Data.OperaTypeArr[A_Index] == 4) {  ;删除
            DeleteNameArr.Push(VariableName)
            continue
        }

        Value := 0
        if (Data.OperaTypeArr[A_Index] == 1) {   ;数值
            hasValue := TryGetVariableValue(&Value, tableItem, index, Data.CopyVariableArr[A_Index])
            if (!hasValue)
                return
        }
        if (Data.OperaTypeArr[A_Index] == 2) {  ;随机
            hasMin := TryGetVariableValue(&minValue, tableItem, index, Data.MinVariableArr[A_Index])
            hasMax := TryGetVariableValue(&maxValue, tableItem, index, Data.MaxVariableArr[A_Index])
            if (!hasMin || !hasMax)
                return
            Value := Random(minValue, maxValue)
        }
        if (Data.OperaTypeArr[A_Index] == 3) {  ;字符
            Value := Data.CopyVariableArr[A_Index]
        }

        VariableNameArr.Push(VariableName)
        ValueArr.Push(Value)
    }

    if (DeleteNameArr.Length != 0)
        MyDelGlobalVariable(DeleteNameArr)

    if (VariableNameArr.Length != 0)
        MySetGlobalVariable(VariableNameArr, ValueArr, Data.IsIgnoreExist)
}

OnExVariable(tableItem, cmd, index) {
    paramArr := StrSplit(cmd, "_")
    Data := GetMacroCMDData(ExVariableFile, paramArr[2])
    count := Data.SearchCount
    interval := Data.SearchInterval

    ;变量初始化默认值0
    NameArr := []
    ValueArr := []
    loop Data.ToggleArr.Length {
        if (Data.ToggleArr[A_Index]) {
            NameArr.Push(Data.VariableArr[A_Index])
            ValueArr.Push(0)
        }
    }
    MySetGlobalVariable(NameArr, ValueArr, true)

    if (Data.SearchCount == -1) {
        return OnExVariableOnce(tableItem, index, Data)
    }
    else {
        loop Data.SearchCount {
            WaitIfPaused(tableItem, index)

            if (tableItem.KilledArr[index])
                return

            isFound := OnExVariableOnce(tableItem, index, Data)
            if (isFound)
                return

            if (Data.SearchCount > A_Index) {
                FloatInterval := GetFloatTime(Data.SearchInterval, MySoftData.PreIntervalFloat)
                Sleep(FloatInterval)
            }
        }
    }
}

OnExVariableOnce(tableItem, index, Data) {
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

    isOk := false
    allText := ""
    for _, value in TextObjs {
        allText .= value.text "`n"
    }
    allText := Trim(allText)
    ExtractStr := GetReplaceVarText(tableItem, index, Data.ExtractStr)
    for _, value in TextObjs {
        VariableValueArr := ExtractNumbers(value.Text, ExtractStr)
        VariableValueArr := ExtractStr == "" && allText != "" ? [allText] : VariableValueArr
        if (VariableValueArr == "")
            continue

        if (GetExVariableActiveLength(Data.ToggleArr) > VariableValueArr.Length)
            continue

        RealNameArr := []
        RealValueArr := []
        loop VariableValueArr.Length {
            if (Data.ToggleArr[A_Index]) {
                RealNameArr.Push(Data.VariableArr[A_Index])
                RealValueArr.Push(VariableValueArr[A_Index])
            }
        }
        MySetGlobalVariable(RealNameArr, RealValueArr, Data.IsIgnoreExist)
        isOk := true
        break
    }

    return isOk
}

OnOperation(tableItem, cmd, index) {
    paramArr := StrSplit(cmd, "_")
    Data := GetMacroCMDData(OperationFile, paramArr[2])
    loop 4 {
        if (!Data.ToggleArr[A_Index])
            continue
        Name := Data.NameArr[A_Index]
        SymbolArr := Data.SymbolGroups[A_Index]
        ValueArr := Data.ValueGroups[A_Index]
        Value := GetVariableOperationResult(tableItem, index, Name, SymbolArr, ValueArr)

        MySetGlobalVariable([Data.UpdateNameArr[A_Index]], [Value], Data.IsIgnoreExist)
    }
}

OnBGMouse(tableItem, cmd, index) {
    paramArr := StrSplit(cmd, "_")
    Data := GetMacroCMDData(BGMouseFile, paramArr[2])

    WM_DOWN_ARR := [0x201, 0x204, 0x207]    ;左键，中键，右键
    WM_UP_ARR := [0x202, 0x205, 0x208]    ;左键，中键，右键
    WM_DCLICK_ARR := [0x203, 0x206, 0x209]    ;左键，中键，右键
    hasPosVarX := TryGetVariableValue(&PosX, tableItem, index, Data.PosVarX)
    hasPosVarY := TryGetVariableValue(&PosY, tableItem, index, Data.PosVarY)
    if (!hasPosVarX || !hasPosVarY) {
        return
    }
    PosX := GetFloatValue(PosX, MySoftData.CoordXFloat)
    PosY := GetFloatValue(PosY, MySoftData.CoordYFloat)

    frontStr := GetParamsWinInfoStr(Data.TargetTitle)
    hwndList := WinGetList(frontStr)
    loop hwndList.Length {
        hwnd := hwndList[A_Index]
        ; 点击位置（窗口客户区坐标）
        lParam := (PosY << 16) | (PosX & 0xFFFF)

        if (Data.MouseType == 4) {  ;滚轮
            if (Data.ScrollV != 0) {
                value := 120 * Data.ScrollV
                PostMessage(0x020A, (value << 16), lParam, , "ahk_id " hwnd)
            }
            else if (Data.ScrollH != 0) {
                value := 120 * Data.ScrollH
                PostMessage(0x020E, (value << 16), lParam, , "ahk_id " hwnd)
            }
            return
        }

        if (Data.OperateType == 1) {    ;点击
            PostMessage WM_DOWN_ARR[Data.MouseType], 1, lParam, , "ahk_id " hwnd
            Sleep Data.ClickTime
            PostMessage WM_UP_ARR[Data.MouseType], 0, lParam, , "ahk_id " hwnd
        }
        else if (Data.OperateType == 2) {   ;双击
            PostMessage WM_DCLICK_ARR[Data.MouseType], 1, lParam, , "ahk_id " hwnd
            Sleep Data.ClickTime
            PostMessage WM_UP_ARR[Data.MouseType], 0, lParam, , "ahk_id " hwnd
        }
        else if (Data.OperateType == 3) {   ;按下
            PostMessage WM_DOWN_ARR[Data.MouseType], 1, lParam, , "ahk_id " hwnd
        }
        else if (Data.OperateType == 4) {   ;松开
            PostMessage WM_UP_ARR[Data.MouseType], 0, lParam, , "ahk_id " hwnd
        }
    }
}

OnBGKey(tableItem, cmd, index) {
    paramArr := StrSplit(cmd, "_")
    Data := GetMacroCMDData(BGKeyFile, paramArr[2])
    loop Data.ClickCount {
        WaitIfPaused(tableItem, index)

        if (tableItem.KilledArr[index])
            break

        FloatHold := GetFloatTime(Data.ClickTime, MySoftData.HoldFloat)
        FloatInterval := GetFloatTime(Data.ClickInterval, MySoftData.PreIntervalFloat)
        SendBGKey(Data, tableItem, index)
        if (Data.Type == 3 && A_Index != Data.ClickCount)
            Sleep(FloatInterval)
    }
}

SendBGKey(Data, tableItem, index) {
    frontStr := GetParamsWinInfoStr(Data.FrontStr)
    hwndList := WinGetList(frontStr)

    if (Data.Type == 1 || Data.Type == 3) {
        for hwnd in hwndList {
            for key in Data.KeyArr {
                SendBGKeyState(hwnd, key, 1, tableItem, index)
            }
        }

    }

    if (Data.Type == 3) {
        Sleep(Data.ClickTime)
    }

    if (Data.Type == 2 || Data.Type == 3) {
        for hwnd in hwndList {
            for key in Data.KeyArr {
                SendBGKeyState(hwnd, key, 0, tableItem, index)
            }
        }
    }
}

SendBGKeyState(hwnd, Key, state, tableItem, index) {
    if (Key == "逗号")
        Key := ","
    VKCode := GetKeyVK(Key)
    VSCode := GetKeySC(Key)
    lParamDown := (VSCode << 16) | 1
    lParamUp := (VSCode << 16) | 0xC0000001

    if (MySoftData.SpecialNumKeyMap.Has(Key)) {
        if (state == 0)
            return
        try {
            PostMessage 0x100, VKCode, lParamDown, , "ahk_id " hwnd
        }

        return
    }

    if (state == 1) {
        try {
            PostMessage 0x100, VKCode, lParamDown, , "ahk_id " hwnd
        }
    }
    else {
        try {
            PostMessage 0x101, VKCode, lParamUp, , "ahk_id " hwnd
        }
    }

    if (state == 1) {
        tableItem.HoldKeyArr[index][Key] := "Normal"
    }
    else {
        if (tableItem.HoldKeyArr[index].Has(Key)) {
            tableItem.HoldKeyArr[index].Delete(Key)
        }
    }
}

OnMouseMove(tableItem, cmd, index) {
    paramArr := StrSplit(cmd, "_")
    PosX := Integer(paramArr[2])
    PosY := Integer(paramArr[3])
    Speed := paramArr.Length >= 4 ? 100 - Integer(paramArr[4]) : 0
    IsRelative := paramArr.Length >= 5 ? Integer(paramArr[5]) : 0

    PosX := GetFloatValue(PosX, MySoftData.CoordXFloat)
    PosY := GetFloatValue(PosY, MySoftData.CoordYFloat)
    SendMode("Event")
    CoordMode("Mouse", "Screen")
    if (IsRelative) {
        MouseMove(PosX, PosY, Speed, "R")
    }
    else {
        MouseMove(PosX, PosY, Speed)
    }
}

OnRMTCMD(tableItem, cmd, index) {
    paramArr := StrSplit(cmd, "_")
    cmdStr := paramArr[2]
    if (cmdStr == "启用键鼠") {
        BlockInput false
    }
    else if (cmdStr == "禁用键鼠") {
        BlockInput true
    }
    else {
        MyExcuteRMTCMDAction(cmd)
    }
}

OnInterval(tableItem, cmd, index) {
    paramArr := StrSplit(cmd, "_")
    isVar := !IsNumber(paramArr[2])
    interval := isVar ? 0 : Integer(paramArr[2])
    if (isVar) {
        hasInterval := TryGetVariableValue(&interval, tableItem, index, paramArr[2])
        if (!hasInterval)
            return
    }

    FloatInterval := GetFloatTime(interval, MySoftData.IntervalFloat)
    curTime := 0
    clip := Min(500, FloatInterval)
    while (curTime < FloatInterval) {
        WaitIfPaused(tableItem, index)

        if (tableItem.KilledArr[index])
            break
        Sleep(clip)
        curTime += clip
        clip := Min(500, FloatInterval - curTime)
    }
}

OnPressKey(tableItem, cmd, index) {
    paramArr := SplitKeyCommand(cmd)
    isJoyKey := SubStr(paramArr[2], 1, 3) == "Joy"
    isJoyAxis := StrCompare(SubStr(paramArr[2], 1, 7), "JoyAxis", false) == 0
    actionMap := Map(1, SendNormalKeyClick, 2, SendGameModeKeyClick, 3, SendLogicKeyClick)
    action := actionMap[Integer(tableItem.ModeArr[index])]
    action := isJoyKey ? SendJoyBtnClick : action
    action := isJoyAxis ? SendJoyAxisClick : action

    keyType := Integer(paramArr[3])
    holdTime := paramArr.Length >= 4 ? Integer(paramArr[4]) : 100
    count := paramArr.Length >= 5 ? Integer(paramArr[5]) : 1
    IntervalTime := paramArr.Length >= 6 ? Integer(paramArr[6]) : 1000

    loop count {
        WaitIfPaused(tableItem, index)

        if (tableItem.KilledArr[index])
            break

        FloatHold := GetFloatTime(holdTime, MySoftData.HoldFloat)
        FloatInterval := GetFloatTime(IntervalTime, MySoftData.PreIntervalFloat)
        action(paramArr[2], FloatHold, tableItem, index, keyType)
        if (keyType == 3 && A_Index != count)
            Sleep(FloatInterval)
    }
}

;按键替换
OnReplaceDownKey(tableItem, info, index, *) {
    infos := StrSplit(info, ",")
    mode := tableItem.ModeArr[index]

    loop infos.Length {
        assistKey := infos[A_Index]
        if (mode == 2) {
            SendGameModeKey(assistKey, 1, tableItem, index)
        }
        else {
            SendNormalKey(assistKey, 1, tableItem, index)
        }
    }

}

OnReplaceUpKey(tableItem, info, index, *) {
    infos := StrSplit(info, ",")
    mode := tableItem.ModeArr[index]

    loop infos.Length {
        assistKey := infos[A_Index]
        if (mode == 2) {
            SendGameModeKey(assistKey, 0, tableItem, index)
        }
        else {
            SendNormalKey(assistKey, 0, tableItem, index)
        }
    }

}

;按钮回调
GetTableClosureAction(action, TableItem, index) {
    funcObj := action.Bind(TableItem, index)
    return (*) => funcObj()
}

MenuReload(*) {
    IniWrite(MySoftData.TabCtrl.Value, IniFile, IniSection, "TableIndex")
    IniWrite(true, IniFile, IniSection, "IsReload")
    Reload()
}

OnToolTextFilterSelectImage(*) {
    global ToolCheckInfo
    path := FileSelect(, , GetLang("选择图片"))
    if (path == "")
        return
    ocr := ToolCheckInfo.OCRTypeCtrl.Value == 1 ? MyChineseOcr : MyEnglishOcr
    result := ocr.ocr_from_file(path)
    ToolCheckInfo.ToolTextCtrl.Value := result
    A_Clipboard := result
}

OnClearToolText(*) {
    ToolCheckInfo.ToolTextCtrl.Value := ""
}

OnBootStartChanged(*) {
    global MySoftData ; 访问全局变量
    MySoftData.IsBootStart := MySoftData.BootStartCtrl.Value
    regPath := "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run"
    softPath := A_ScriptFullPath
    if (MySoftData.IsBootStart) {
        RegWrite(softPath, "REG_SZ", regPath, "RMT")
    }
    else {
        RegDelete(regPath, "RMT")
    }
    IniWrite(MySoftData.BootStartCtrl.Value, IniFile, IniSection, "IsBootStart")
}

OnMenuWheelPosChanged(*) {
    global MySoftData ; 访问全局变量
    MySoftData.FixedMenuWheel := !MySoftData.FixedMenuWheel
    IniWrite(MySoftData.FixedMenuWheel, IniFile, IniSection, "FixedMenuWheel")
}

;按键模拟
SendGameModeKeyClick(KeyArrStr, holdTime, tableItem, index, keyType) {
    KeyArr := GetPressKeyArr(KeyArrStr)
    if (keyType == 1 || keyType == 3) {
        for key in KeyArr {
            SendGameModeKey(key, 1, tableItem, index)
        }
    }

    if (keyType == 3) {
        Sleep(holdTime)
    }

    if (keyType == 2 || keyType == 3) {
        for key in KeyArr {
            SendGameModeKey(key, 0, tableItem, index)
        }
    }
}

SendGameModeKey(Key, state, tableItem, index) {
    if (Key == "逗号")
        Key := ","
    VK := GetKeyVK(Key)
    SC := GetKeySC(Key)

    if (VK == 1 || VK == 2 || VK == 4 || VK == 158 || VK == 159 || VK == 5 || VK == 6) {   ; 鼠标左键、右键、中键、下滑，上滑
        SendGameMouseKey(key, state, tableItem, index)
        return
    }

    ; 检测是否为扩展键
    isExtendedKey := false
    extendedArr := [0x25, 0x26, 0x27, 0x28, 0X2D, 0X2E, 0X23, 0X24, 0X21, 0X22]    ; 左、上、右、下箭头
    for index, value in extendedArr {
        if (VK == value) {
            isExtendedKey := true
            break
        }
    }

    if (state == 1) {
        DllCall("keybd_event", "UChar", VK, "UChar", SC, "UInt", isExtendedKey ? 0x1 : 0, "UPtr", 0)
        tableItem.HoldKeyArr[index][key] := "Game"
    }
    else {
        DllCall("keybd_event", "UChar", VK, "UChar", SC, "UInt", (isExtendedKey ? 0x3 : 0x2), "UPtr", 0)
        if (tableItem.HoldKeyArr[index].Has(key)) {
            tableItem.HoldKeyArr[index].Delete(key)
        }
    }
}

SendGameMouseKey(key, state, tableItem, index) {
    scrollStep := 0
    mouseData := 0  ; 用于存储滚轮或侧键的数据（120/-120 或 0x0001/0x0002）

    if (StrCompare(Key, "LButton", false) == 0) {
        mouseDown := 0x0002  ; MOUSEEVENTF_LEFTDOWN
        mouseUp := 0x0004    ; MOUSEEVENTF_LEFTUP
    }
    else if (StrCompare(Key, "RButton", false) == 0) {
        mouseDown := 0x0008  ; MOUSEEVENTF_RIGHTDOWN
        mouseUp := 0x0010    ; MOUSEEVENTF_RIGHTUP
    }
    else if (StrCompare(Key, "MButton", false) == 0) {
        mouseDown := 0x0020  ; MOUSEEVENTF_MIDDLEDOWN
        mouseUp := 0x0040    ; MOUSEEVENTF_MIDDLEUP
    }
    else if (StrCompare(Key, "WheelUp", false) == 0) {
        mouseDown := 0x0800  ; MOUSEEVENTF_WHEEL
        mouseUp := 0x0000    ; 滚轮没有 "UP" 事件
        mouseData := 120     ; +120 表示向上滚动
    }
    else if (StrCompare(Key, "WheelDown", false) == 0) {
        mouseDown := 0x0800  ; MOUSEEVENTF_WHEEL
        mouseUp := 0x0000    ; 滚轮没有 "UP" 事件
        mouseData := -120    ; -120 表示向下滚动
    }
    else if (StrCompare(Key, "XButton1", false) == 0) {
        mouseDown := 0x0080  ; MOUSEEVENTF_XDOWN
        mouseUp := 0x0100    ; MOUSEEVENTF_XUP
        mouseData := 0x0001  ; 表示 XButton1
    }
    else if (StrCompare(Key, "XButton2", false) == 0) {
        mouseDown := 0x0080  ; MOUSEEVENTF_XDOWN
        mouseUp := 0x0100    ; MOUSEEVENTF_XUP
        mouseData := 0x0002  ; 表示 XButton2
    }

    if (state == 1) {
        DllCall("mouse_event", "UInt", mouseDown, "UInt", 0, "UInt", 0, "UInt", mouseData, "UInt", 0)
        tableItem.HoldKeyArr[index][key] := "GameMouse"
    }
    else {
        if (mouseUp != 0) {  ; 只有非滚轮事件才发送 UP
            DllCall("mouse_event", "UInt", mouseUp, "UInt", 0, "UInt", 0, "UInt", mouseData, "UInt", 0)
        }
        if (tableItem.HoldKeyArr[index].Has(key)) {
            tableItem.HoldKeyArr[index].Delete(key)
        }
    }
}

SendNormalKeyClick(KeyArrStr, holdTime, tableItem, index, keyType) {
    KeyArr := GetPressKeyArr(KeyArrStr)
    if (keyType == 1 || keyType == 3) {
        for key in KeyArr {
            SendNormalKey(key, 1, tableItem, index)
        }
    }

    if (keyType == 3) {
        Sleep(holdTime)
    }

    if (keyType == 2 || keyType == 3) {
        for key in KeyArr {
            SendNormalKey(key, 0, tableItem, index)
        }
    }
}

SendNormalKey(Key, state, tableItem, index) {
    if (Key == "逗号")
        Key := ","
    if (MySoftData.SpecialNumKeyMap.Has(Key)) {
        if (state == 0)
            return
        keySymbol := "{Blind}{" Key " 1}"
        Send(keySymbol)
        return
    }

    if (state == 1) {
        keySymbol := "{Blind}{" Key " down}"
    }
    else {
        keySymbol := "{Blind}{" Key " up}"
    }

    Send(keySymbol)
    if (state == 1) {
        tableItem.HoldKeyArr[index][Key] := "Normal"
    }
    else {
        if (tableItem.HoldKeyArr[index].Has(Key)) {
            tableItem.HoldKeyArr[index].Delete(Key)
        }
    }
}

SendLogicKeyClick(KeyArrStr, holdTime, tableItem, index, keyType) {
    if (!InitLogitechGHubNew())
        return
    KeyArr := GetPressKeyArr(KeyArrStr)
    ;罗技部分按键没有，就降级为AHK_Send把
    SpecialKeyMap := Map("Volume_Up", 1, "Volume_Down", 1, "Volume_Mute", 1)
    if (keyType == 1 || keyType == 3) {
        for key in KeyArr {
            if (SpecialKeyMap.Has(key))
                SendNormalKey(key, 1, tableItem, index)
            else {
                SendLogicKey(key, 1, tableItem, index)
            }
        }
    }

    if (keyType == 3) {
        Sleep(holdTime)
    }

    if (keyType == 2 || keyType == 3) {
        for key in KeyArr {
            if (SpecialKeyMap.Has(key))
                SendNormalKey(key, 0, tableItem, index)
            else {
                SendLogicKey(key, 0, tableItem, index)
            }
        }
    }
}

SendLogicKey(Key, state, tableItem, index) {
    if (Key == "逗号")
        Key := ","
    if (MySoftData.SpecialNumKeyMap.Has(Key)) {
        if (state == 0)
            return
        keySymbol := "{Blind}{" Key " 1}"
        IbSend(keySymbol)
        return
    }

    if (state == 1) {
        keySymbol := "{Blind}{" Key " down}"
    }
    else {
        keySymbol := "{Blind}{" Key " up}"
    }

    IbSend(keySymbol)
    if (state == 1) {
        tableItem.HoldKeyArr[index][Key] := "Logic"
    }
    else {
        if (tableItem.HoldKeyArr[index].Has(Key)) {
            tableItem.HoldKeyArr[index].Delete(Key)
        }
    }
}

SendJoyBtnClick(KeyArrStr, holdTime, tableItem, index, keyType) {
    if (!CheckIfInstallVjoy()) {
        MsgBox(GetLang("使用手柄功能前,请先安装Joy目录下的vJoy驱动!"))
        return
    }

    if (Type(MyvJoy) == "String") {
        MsgBox(GetLang("vjoy加载失败，请安装或卸载后重新安装vjoy，然后尝试使用手柄功能"))
        return
    }

    KeyArr := GetPressKeyArr(KeyArrStr)
    if (keyType == 1 || keyType == 3) {
        for key in KeyArr {
            SendJoyBtnKey(key, 1, tableItem, index)
        }
    }

    if (keyType == 3) {
        Sleep(holdTime)
    }

    if (keyType == 2 || keyType == 3) {
        for key in KeyArr {
            SendJoyBtnKey(key, 0, tableItem, index)
        }
    }
}

SendJoyBtnKey(key, state, tableItem, index) {
    joyIndex := SubStr(key, 4)
    MyvJoy.SetBtn(state, joyIndex)

    if (state == 1) {
        tableItem.HoldKeyArr[index][key] := "Joy"
    }
    else {
        if (tableItem.HoldKeyArr[index].Has(key)) {
            tableItem.HoldKeyArr[index].Delete(key)
        }
    }
}

SendJoyAxisClick(KeyArrStr, holdTime, tableItem, index, keyType) {
    if (!CheckIfInstallVjoy()) {
        MsgBox(GetLang("使用手柄功能前,请先安装Joy目录下的vJoy驱动!"))
        return
    }

    if (Type(MyvJoy) == "String") {
        MsgBox(GetLang("vjoy加载失败，请安装或卸载后重新安装vjoy，然后尝试使用手柄功能"))
        return
    }

    KeyArr := GetPressKeyArr(KeyArrStr)
    if (keyType == 1 || keyType == 3) {
        for key in KeyArr {
            SendJoyAxisKey(key, 1, tableItem, index)
        }
    }

    if (keyType == 3) {
        Sleep(holdTime)
    }

    if (keyType == 2 || keyType == 3) {
        for key in KeyArr {
            SendJoyAxisKey(key, 0, tableItem, index)
        }
    }
}

SendJoyAxisKey(key, state, tableItem, index) {
    percent := 50
    if (state == 1) {
        percent := MyvJoy.JoyAxisMap.Get(key)
    }
    value := percent * 327.68
    axisIndex := Integer(SubStr(key, 8, StrLen(key) - 10))
    MyvJoy.SetAxisByIndex(value, axisIndex)

    if (state == 1) {
        tableItem.HoldKeyArr[index][key] := "JoyAxis"
    }
    else {
        if (tableItem.HoldKeyArr[index].Has(key)) {
            tableItem.HoldKeyArr[index].Delete(key)
        }

    }
}

OnTextProcess(tableItem, cmd, index) {
    paramArr := StrSplit(cmd, "_")
    Data := GetMacroCMDData(TextProcessFile, paramArr[2])
    
    ; 获取源变量值
    sourceText := ""
    if (!TryGetVariableValue(&sourceText, tableItem, index, Data.SourceVariable, false)) {
        return
    }
    
    if (sourceText == "") {
        return
    }
    
    NameArr := []
    ValueArr := []
    
    ; 处理文本
    switch Data.ProcessType {
        case 1: ; 文本分割
            parts := ProcessTextSplitWithParams(sourceText, Data)
            partIndex := 1
            loop Data.ToggleArr.Length {
                if (Data.ToggleArr[A_Index] && partIndex <= parts.Length) {
                    NameArr.Push(Data.VariableArr[A_Index])
                    ValueArr.Push(parts[partIndex])
                    partIndex++
                }
            }
            
        case 2: ; 文本替换
            processedText := ProcessTextReplace(sourceText, Data.SearchText, Data.ReplaceText, Data.CaseSensitive, Data.UseRegex)
            SaveSingleResultMacro(Data, tableItem, index, &NameArr, &ValueArr, processedText)
            
        case 3: ; 数字提取
            extractedText := ExtractDigits(sourceText)
            SaveSingleResultMacro(Data, tableItem, index, &NameArr, &ValueArr, extractedText)
            
        case 4: ; 字母提取
            extractedText := ExtractAlphabets(sourceText)
            SaveSingleResultMacro(Data, tableItem, index, &NameArr, &ValueArr, extractedText)
            
        case 5: ; 中文提取
            extractedText := ExtractChineseChars(sourceText)
            SaveSingleResultMacro(Data, tableItem, index, &NameArr, &ValueArr, extractedText)
            
        case 6: ; 去空格处理
            processedText := ProcessWhitespace(sourceText, Data.SplitParam)
            SaveSingleResultMacro(Data, tableItem, index, &NameArr, &ValueArr, processedText)
            
        case 7: ; 大小写转换
            processedText := ProcessCaseConversion(sourceText, Data.SplitParam)
            SaveSingleResultMacro(Data, tableItem, index, &NameArr, &ValueArr, processedText)
            
        case 8: ; URL编解码
            processedText := ProcessURLEncode(sourceText, Data.SplitParam)
            SaveSingleResultMacro(Data, tableItem, index, &NameArr, &ValueArr, processedText)
            
        case 9: ; Base64编解码
            processedText := ProcessBase64(sourceText, Data.SplitParam)
            SaveSingleResultMacro(Data, tableItem, index, &NameArr, &ValueArr, processedText)
            
        case 10: ; 文本统计
            statsText := GetTextStatistics(sourceText, Data.SplitParam)
            SaveSingleResultMacro(Data, tableItem, index, &NameArr, &ValueArr, statsText)
            
        case 11: ; 固定长度分割
            length := Data.SplitParam ? Integer(Data.SplitParam) : 10
            maxCount := Data.MaxSplitCount ? Integer(Data.MaxSplitCount) : 0
            parts := SplitByLength(sourceText, length, maxCount)
            partIndex := 1
            loop 4 {
                if (Data.ToggleArr[A_Index] && partIndex <= parts.Length) {
                    NameArr.Push(Data.VariableArr[A_Index])
                    ValueArr.Push(parts[partIndex])
                    partIndex++
                }
            }
            
        case 12: ; 多字符分割
            delimiters := Data.SplitParam ? Data.SplitParam : ",|;"
            maxCount := Data.MaxSplitCount ? Integer(Data.MaxSplitCount) : 0
            parts := SplitByMultipleDelimiters(sourceText, delimiters, maxCount)
            partIndex := 1
            loop 4 {
                if (Data.ToggleArr[A_Index] && partIndex <= parts.Length) {
                    NameArr.Push(Data.VariableArr[A_Index])
                    ValueArr.Push(parts[partIndex])
                    partIndex++
                }
            }
            
        case 13: ; 行过滤
            filteredText := FilterLines(sourceText, Data.SearchText)
            SaveSingleResultMacro(Data, tableItem, index, &NameArr, &ValueArr, filteredText)
            
        case 14: ; 去重处理
            processedText := RemoveDuplicates(sourceText)
            SaveSingleResultMacro(Data, tableItem, index, &NameArr, &ValueArr, processedText)
            
        case 15: ; 排序处理
            processedText := SortText(sourceText, Data.ReverseProcess)
            SaveSingleResultMacro(Data, tableItem, index, &NameArr, &ValueArr, processedText)
            
        case 16: ; 随机文本
            length := Data.SplitParam ? Integer(Data.SplitParam) : 10
            randomText := GenerateRandomText(length)
            SaveSingleResultMacro(Data, tableItem, index, &NameArr, &ValueArr, randomText)
            
        case 17: ; 日期时间
            format := Data.SplitParam ? Data.SplitParam : "yyyy-MM-dd HH:mm:ss"
            dateTimeText := GetDateTime(format)
            SaveSingleResultMacro(Data, tableItem, index, &NameArr, &ValueArr, dateTimeText)
    }
    
    ; 将结果保存到变量
    if (NameArr.Length > 0) {
        loop NameArr.Length {
            MySetGlobalVariable([NameArr[A_Index]], [ValueArr[A_Index]], false)
        }
    }
}

