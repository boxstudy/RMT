BindShortcut(triggerInfo, action) {
    if (triggerInfo == "")
        return

    isString := SubStr(triggerInfo, 1, 1) == ":"

    if (isString) {
        Hotstring(triggerInfo, action)
    }
    else {
        key := "$*~" triggerInfo
        Hotkey(key, action)
    }
}

GetClosureActionNew(tableIndex, itemIndex, func) {
    funcObj := func.Bind(tableIndex, itemIndex)
    return (*) => funcObj()
}

GetClosureAction(tableItem, macro, index, func) {     ;获取闭包函数
    funcObj := func.Bind(tableItem, macro, index)
    return (*) => funcObj()
}

;按键宏命令
OnTriggerMacroKeyAndInit(tableItem, macro, index) {
    tableItem.KilledArr[index] := false
    tableItem.PauseArr[index] := false
    tableItem.ActionCount[index] := 0
    tableItem.VariableMapArr[index]["当前循环次数"] := 1
    isContinue := tableItem.TKArr.Has(index) && MySoftData.ContinueKeyMap.Has(tableItem.TKArr[index]) && tableItem.LoopCountArr[
        index] == 1
    isLoop := tableItem.LoopCountArr[index] == -1
    MySetTableItemState(tableItem.index, index, 1)
    loop {
        isOver := tableItem.ActionCount[index] >= tableItem.LoopCountArr[index]
        isFirst := tableItem.ActionCount[index] == 0
        isSecond := tableItem.ActionCount[index] == 1

        WaitIfPaused(tableItem.index, index)

        if (tableItem.KilledArr[index])
            break

        if (!isLoop && !isContinue && isOver)
            break

        if (!isFirst && isContinue) {
            key := MySoftData.ContinueKeyMap[tableItem.TKArr[index]]
            interval := isSecond ? MySoftData.ContinueSecondIntervale : MySoftData.ContinueIntervale
            Sleep(interval)

            if (!GetKeyState(key, "P")) {
                break
            }
        }

        OnTriggerMacroOnce(tableItem, macro, index)
        tableItem.ActionCount[index]++
        tableItem.VariableMapArr[index]["当前循环次数"] += 1
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

        WaitIfPaused(tableItem.index, index)

        paramArr := StrSplit(cmdArr[A_Index], "_")
        IsMouseMove := StrCompare(paramArr[1], "移动", false) == 0
        IsSearch := StrCompare(paramArr[1], "搜索", false) == 0
        IsSearchPro := StrCompare(paramArr[1], "搜索Pro", false) == 0
        IsPressKey := StrCompare(paramArr[1], "按键", false) == 0
        IsInterval := StrCompare(paramArr[1], "间隔", false) == 0
        IsRun := StrCompare(paramArr[1], "运行", false) == 0
        IsIf := StrCompare(paramArr[1], "如果", false) == 0
        IsMMPro := StrCompare(paramArr[1], "移动Pro", false) == 0
        IsOutput := StrCompare(paramArr[1], "输出", false) == 0
        IsVariable := StrCompare(paramArr[1], "变量", false) == 0
        IsExVariable := StrCompare(paramArr[1], "变量提取", false) == 0
        IsSubMacro := StrCompare(paramArr[1], "宏操作", false) == 0
        IsOperation := StrCompare(paramArr[1], "运算", false) == 0
        IsBGMouse := StrCompare(paramArr[1], "后台鼠标", false) == 0
        IsRMT := StrCompare(paramArr[1], "RMT指令", false) == 0

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
            WaitIfPaused(tableItem.index, index)

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
            MySetGlobalVariable(Data.ResultSaveName, Data.FalseValue, false)
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
            MySetGlobalVariable(Data.ResultSaveName, Data.TrueValue, false)
        }

        if (Data.CoordToogle) {
            MySetGlobalVariable(Data.CoordXName, Pos[1], false)
            MySetGlobalVariable(Data.CoordYName, Pos[2], false)
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
            hasOtherValue := TryGetVariableValue(&OtherValue, tableItem, index, Data.VariableArr[A_Index])
            if (!hasValue || !hasOtherValue) {
                return
            }

            currentComparison := false
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
        MySetGlobalVariable(Data.SaveName, SaveValue, Data.IsIgnoreExist)
    }

    macro := ""
    macro := result && Data.TrueMacro != "" ? Data.TrueMacro : macro
    macro := !result && Data.FalseMacro != "" ? Data.FalseMacro : macro
    if (macro == "")
        return

    OnTriggerMacroOnce(tableItem, macro, index)
}

OnMMPro(tableItem, cmd, index) {
    paramArr := StrSplit(cmd, "_")
    Data := GetMacroCMDData(MMProFile, paramArr[2])

    LastSumTime := 0
    loop Data.Count {
        WaitIfPaused(tableItem.index, index)

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
    if (Data.IsGameView) {
        MOUSEEVENTF_MOVE := 0x0001
        DllCall("mouse_event", "UInt", MOUSEEVENTF_MOVE, "UInt", PosX, "UInt", PosY, "UInt", 0, "UInt", 0)
    }
    else if (Data.IsRelative) {
        MouseMove(PosX, PosY, Speed, "R")
    }
    else
        MouseMove(PosX, PosY, Speed)
}

OnOutput(tableItem, cmd, index) {
    paramArr := StrSplit(cmd, "_")
    Data := GetMacroCMDData(OutputFile, paramArr[2])
    Content := ""
    if (Data.ContentType == 1)
        Content := GetOutPutContent(tableItem, index, Data.Text)
    else if (Data.ContentType == 2) {
        hasValue := TryGetVariableValue(&Content, tableItem, index, Data.VariName)
        if (!hasValue)
            return
    }
    else if (Data.ContentType == 3) {
        Content := GetOutPutContent(tableItem, index, Data.Text)
        hasValue := TryGetVariableValue(&VariValue, tableItem, index, Data.VariName, false)
        if (hasValue)
            Content := Content "" VariValue
    }

    if (Data.OutputType == 1) {     ;send
        SendText(Content)
    }
    else if (Data.OutputType == 2) {    ;粘贴
        A_Clipboard := Content
        Send "{Blind}^v"
    }
    else if (Data.OutputType == 3) {    ;粘贴
        A_Clipboard := Content
        MyWinClip.Paste(A_Clipboard)
    }
    else if (Data.OutputType == 4) {    ;提示
        MyToolTipContent(Content)
    }
    else if (Data.OutputType == 5) {    ;剪切板
        A_Clipboard := Content
    }
    else if (Data.OutputType == 6) {    ;弹窗
        MyMsgBoxContent(Content)
    }
    else if (Data.OutputType == 7) {    ;语音
        spovice := ComObject("sapi.spvoice")
        spovice.Speak(Content)
    }
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
        LoopCount := macroItem.LoopCountArr[macroIndex]
        IsLoop := macroItem.LoopCountArr[macroIndex] == -1
        if (!IsLoop) {
            loop LoopCount {
                if (A_Index == 1)
                    continue
                resultMacro .= "," macro
            }
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
    loop 4 {
        if (!Data.ToggleArr[A_Index])
            continue
        VariableName := Data.VariableArr[A_Index]
        if (Data.OperaTypeArr[A_Index] == 4) {  ;删除
            MyDelGlobalVariable(VariableName)
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

        MySetGlobalVariable(VariableName, Value, Data.IsIgnoreExist)
    }
}

OnExVariable(tableItem, cmd, index) {
    paramArr := StrSplit(cmd, "_")
    Data := GetMacroCMDData(ExVariableFile, paramArr[2])
    count := Data.SearchCount
    interval := Data.SearchInterval

    if (Data.SearchCount == -1) {
        return OnExVariableOnce(tableItem, index, Data)
    }
    else {
        loop Data.SearchCount {
            WaitIfPaused(tableItem.index, index)

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

    for _, value in TextObjs {
        VariableValueArr := ExtractNumbers(value.Text, Data.ExtractStr)
        VariableValueArr := Data.ExtractStr == "" && allText != "" ? [allText] : VariableValueArr
        if (VariableValueArr == "")
            continue

        loop VariableValueArr.Length {
            if (Data.ToggleArr[A_Index]) {
                name := Data.VariableArr[A_Index]
                value := VariableValueArr[A_Index]
                MySetGlobalVariable(name, Value, Data.IsIgnoreExist)
            }
        }

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

        MySetGlobalVariable(Data.UpdateNameArr[A_Index], Value, Data.IsIgnoreExist)
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

    hwndList := WinGetList(Data.TargetTitle)
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
    MyExcuteRMTCMDAction(paramArr[2])
}

OnInterval(tableItem, cmd, index) {
    paramArr := StrSplit(cmd, "_")
    if (paramArr.Length == 2) {
        interval := Integer(paramArr[2])
    }
    else {
        hasInterval := TryGetVariableValue(&interval, tableItem, index, paramArr[3])
        if (!hasInterval)
            return
    }
    FloatInterval := GetFloatTime(interval, MySoftData.IntervalFloat)
    curTime := 0
    clip := Min(500, FloatInterval)
    while (curTime < FloatInterval) {
        WaitIfPaused(tableItem.index, index)

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
    action := tableItem.ModeArr[index] == 2 ? SendGameModeKeyClick : SendNormalKeyClick
    action := isJoyKey ? SendJoyBtnClick : action
    action := isJoyAxis ? SendJoyAxisClick : action

    keyType := Integer(paramArr[3])
    holdTime := paramArr.Length >= 4 ? Integer(paramArr[4]) : 100
    count := paramArr.Length >= 5 ? Integer(paramArr[5]) : 1
    IntervalTime := paramArr.Length >= 6 ? Integer(paramArr[6]) : 1000

    loop count {
        WaitIfPaused(tableItem.index, index)

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
OnReplaceDownKey(tableItem, info, index) {
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

OnReplaceUpKey(tableItem, info, index) {
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
    Reload()
}

OnToolTextFilterSelectImage(*) {
    global ToolCheckInfo
    path := FileSelect(, , "选择图片")
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

OnShowWinChanged(*) {
    global MySoftData ; 访问全局变量
    MySoftData.IsExecuteShow := !MySoftData.IsExecuteShow
    IniWrite(MySoftData.IsExecuteShow, IniFile, IniSection, "IsExecuteShow")
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

;按键模拟
SendGameModeKeyClick(ComboKey, holdTime, tableItem, index, keyType) {
    KeyArr := GetComboKeyArr(ComboKey)
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

SendNormalKeyClick(ComboKey, holdTime, tableItem, index, keyType) {
    KeyArr := GetComboKeyArr(ComboKey)
    if (keyType == 1 || keyType == 3) {
        for ComboKey in KeyArr {
            SendNormalKey(ComboKey, 1, tableItem, index)
        }
    }

    if (keyType == 3) {
        Sleep(holdTime)
    }

    if (keyType == 2 || keyType == 3) {
        for ComboKey in KeyArr {
            SendNormalKey(ComboKey, 0, tableItem, index)
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

SendJoyBtnClick(key, holdTime, tableItem, index, keyType) {
    if (!CheckIfInstallVjoy()) {
        MsgBox("使用手柄功能前,请先安装Joy目录下的vJoy驱动!")
        return
    }

    if (Type(MyvJoy) == "String") {
        MsgBox("vjoy加载失败，请安装或卸载后重新安装vjoy，然后尝试使用手柄功能")
        return
    }

    if (keyType == 1 || keyType == 3) {
        SendJoyBtnKey(key, 1, tableItem, index)
    }

    if (keyType == 3) {
        Sleep(holdTime)
    }

    if (keyType == 2 || keyType == 3) {
        SendJoyBtnKey(key, 0, tableItem, index)
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

SendJoyAxisClick(key, holdTime, tableItem, index, keyType) {
    if (!CheckIfInstallVjoy()) {
        MsgBox("使用手柄功能前,请先安装Joy目录下的vJoy驱动!")
        return
    }

    if (Type(MyvJoy) == "String") {
        MsgBox("vjoy加载失败，请安装或卸载后重新安装vjoy，然后尝试使用手柄功能")
        return
    }

    if (keyType == 1 || keyType == 3) {
        SendJoyAxisKey(key, 1, tableItem, index)
    }

    if (keyType == 3) {
        Sleep(holdTime)
    }

    if (keyType == 2 || keyType == 3) {
        SendJoyAxisKey(key, 0, tableItem, index)
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
