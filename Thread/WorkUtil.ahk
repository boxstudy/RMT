#Requires AutoHotkey v2.0

OnWorkTriggerMacro(wParam, lParam, msg, hwnd) {
    TriggerMacro(wParam, lParam)
    MsgPostHandler(WM_RELEASE_WORK, wParam, lParam)
}

OnExit(wParam, lParam, msg, hwnd) {
    ExitApp()
}

OnWorkStopMacro(wParam, lParam, msg, hwnd) {
    loop MySoftData.TableInfo.Length {
        tableItem := MySoftData.TableInfo[A_Index]
        KillSingleTableMacro(tableItem)
    }
}

OnWorkSetGlobalVariable(Name, Value) {
    global MySoftData
    MySoftData.VariableMap[Name] := Value
}

OnWorkDelGlobalVariable(Name) {
    global MySoftData
    if (MySoftData.VariableMap.Has(Name))
        MySoftData.VariableMap.Delete(Name)
}

OnWorkGetCmdStr(wParam, lParam, msg, hwnd) {
    StringAddress := NumGet(lParam, 2 * A_PtrSize, "Ptr")  ; 检索 CopyDataStruct 的 lpData 成员.
    Cmd := StrGet(StringAddress)  ; 从结构中复制字符串.
    paramArr := StrSplit(cmd, "_")
    isSetVari := StrCompare(paramArr[1], "SetVari", false) == 0
    isDelVari := StrCompare(paramArr[1], "DelVari", false) == 0
    isCMDTip := StrCompare(paramArr[1], "CMDTip", false) == 0
    isPauseState := StrCompare(paramArr[1], "PauseState", false) == 0
    if (isSetVari) {
        OnWorkSetGlobalVariable(paramArr[2], paramArr[3])
    }
    else if (isDelVari) {
        OnWorkDelGlobalVariable(paramArr[2])
    }
    else if (isCMDTip) {
        MySoftData.CMDTip := paramArr[2]
    }
    else if (isPauseState) {
        tableItem := MySoftData.TableInfo[paramArr[2]]
        tableItem.PauseArr[paramArr[3]] := paramArr[4]
    }
}

TriggerMacro(tableIndex, itemIndex) {
    tableItem := MySoftData.TableInfo[tableIndex]
    macro := tableItem.MacroArr[itemIndex]
    OnTriggerMacroKeyAndInit(tableItem, macro, itemIndex)
}

MsgPostHandler(type, wParam, lParam) {
    PostMessage(type, wParam, lParam, , "ahk_id " parentHwnd)
}

MsgSendHandler(str, Timestamp := "") {
    if (Timestamp == "") {
        currentDateTime := FormatTime(, "HHmmss")
        randomNum := Random(0, 9) Random(0, 9) Random(0, 9)
        Timestamp := CurrentDateTime randomNum
        ReceiveInfoMap.Set(Timestamp, str)
    }

    CopyDataStruct := Buffer(3 * A_PtrSize)  ; 分配结构的内存区域.
    ; 首先设置结构的 cbData 成员为字符串的大小, 包括它的零终止符:
    SizeInBytes := (StrLen(str) + 1) * 2
    NumPut("Ptr", SizeInBytes  ; 操作系统要求这个需要完成.
        , "Ptr", StrPtr(str)  ; 设置 lpData 为到字符串自身的指针.
        , CopyDataStruct, A_PtrSize)
    SendMessage(WM_COPYDATA, Timestamp, CopyDataStruct, , "ahk_id " parentHwnd)

    action := CheckIfReceiveInfo.Bind(Timestamp)
    ReceiveCheckMap.Set(Timestamp, action)
    SetTimer(action, -50)
}

InitWorkFilePath() {
    global VBSPath := A_WorkingDir "\..\VBS\PlayAudio.vbs"
    global StartTipAudio := A_WorkingDir "\..\Audio\Start.wav"
    global EndTipAudio := A_WorkingDir "\..\Audio\End.wav"
    global MacroFile := A_WorkingDir "\..\Setting\" MySoftData.CurSettingName "\MacroFile.ini"
    global SearchFile := A_WorkingDir "\..\Setting\" MySoftData.CurSettingName "\SearchFile.ini"
    global SearchProFile := A_WorkingDir "\..\Setting\" MySoftData.CurSettingName "\SearchProFile.ini"
    global CompareFile := A_WorkingDir "\..\Setting\" MySoftData.CurSettingName "\CompareFile.ini"
    global CompareProFile := A_WorkingDir "\..\Setting\" MySoftData.CurSettingName "\CompareProFile.ini"
    global MMProFile := A_WorkingDir "\..\Setting\" MySoftData.CurSettingName "\MMProFile.ini"
    global BGKeyFile := A_WorkingDir "\..\Setting\" MySoftData.CurSettingName "\BGKeyFile.ini"
    global RunFile := A_WorkingDir "\..\Setting\" MySoftData.CurSettingName "\RunFile.ini"
    global OutputFile := A_WorkingDir "\..\Setting\" MySoftData.CurSettingName "\OutputFile.ini"
    global StopFile := A_WorkingDir "\..\Setting\" MySoftData.CurSettingName "\StopFile.ini"
    global VariableFile := A_WorkingDir "\..\Setting\" MySoftData.CurSettingName "\VariableFile.ini"
    global ExVariableFile := A_WorkingDir "\..\Setting\" MySoftData.CurSettingName "\ExVariableFile.ini"
    global SubMacroFile := A_WorkingDir "\..\Setting\" MySoftData.CurSettingName "\SubMacroFile.ini"
    global LoopFile := A_WorkingDir "\..\Setting\" MySoftData.CurSettingName "\LoopFile.ini"
    global OperationFile := A_WorkingDir "\..\Setting\" MySoftData.CurSettingName "\OperationFile.ini"
    global BGMouseFile := A_WorkingDir "\..\Setting\" MySoftData.CurSettingName "\BGMouseFile.ini"
    global IniSection := "UserSettings"
}

InitWork() {
    global MySoftData
    MySoftData.isWork := true
}

WorkOpenCVLoadDll() {
    dllpath := A_ScriptDir "\..\Plugins\OpenCV\x64\ImageFinder.dll"
    ibDllPath := A_ScriptDir "\..\Plugins\IbInputSimulator.dll"

    ; 构建包含 DLL 文件的目录路径
    dllDir := A_ScriptDir "\..\Plugins\OpenCV\x64"

    ; 使用 SetDllDirectory 将 dllDir 添加到 DLL 搜索路径中
    DllCall("SetDllDirectory", "Str", dllDir)
    DllCall('LoadLibrary', 'str', dllpath, "Ptr")
    DllCall('LoadLibrary', 'str', ibDllPath)
}

WorkSubMacroStopAction(tableIndex, itemIndex) {
    MsgPostHandler(WM_STOP_MACRO, tableIndex, itemIndex)
}

WorkTriggerSubMacro(tableIndex, itemIndex) {
    MsgPostHandler(WM_TR_MACRO, tableIndex, itemIndex)
}

WorkSetGlobalVariable(Name, Value, ignoreExist) {
    global MySoftData
    if (ignoreExist && MySoftData.VariableMap.Has(Name))
        return
    MySoftData.VariableMap[Name] := Value
    str := Format("SetVari_{}_{}", Name, Value)
    MsgSendHandler(str)
}

WorkDelGlobalVariable(Name) {
    str := Format("DelVari_{}", Name)
    MsgSendHandler(str)
}

WorkCMDReport(cmdStr) {
    str := Format("Report_{}", cmdStr)
    MsgSendHandler(str)
}

WorkExcuteRMTCMDAction(cmdStr) {
    MsgSendHandler(cmdStr)
}

WorkSetTableItemState(tableIndex, itemIndex, state) {
    str := Format("ItemState_{}_{}_{}", tableIndex, itemIndex, state)
    MsgSendHandler(str)
}

WorkSetItemPauseState(tableIndex, itemIndex, state) {
    str := Format("PauseState_{}_{}_{}", tableIndex, itemIndex, state)
    MsgSendHandler(str)
}

WorkMsgBoxContent(content) {
    str := Format("MsgBox_{}", content)
    MsgSendHandler(str)
}

WorkToolTipContent(content) {
    str := Format("ToolTip_{}", content)
    MsgSendHandler(str)
}

WorkMacroCount(content) {
    str := Format("MacroCount_{}", content)
    MsgSendHandler(str)
}

CheckIfReceiveInfo(Timestamp) {
    if (ReceiveCheckMap.Has(Timestamp))
        ReceiveCheckMap.Delete(Timestamp)
    ;不存在表示已经接收了，就不用处理
    if (!ReceiveInfoMap.Has(Timestamp))
        return

    MsgSendHandler(ReceiveInfoMap[Timestamp], Timestamp)
}

OnMainReceiveInfo(wParam, lParam, msg, hwnd) {
    Timestamp := String(wParam)

    if (ReceiveInfoMap.Has(Timestamp))
        ReceiveInfoMap.Delete(Timestamp)

    if (ReceiveCheckMap.Has(Timestamp)) {
        SetTimer(ReceiveCheckMap[Timestamp], 0)
        ReceiveCheckMap.Delete(Timestamp)
    }
}
