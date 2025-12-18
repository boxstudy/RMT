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

OnWorkSetGlobalVariable(NameArr, ValueArr) {
    loop NameArr.Length {
        MySoftData.VariableMap[NameArr[A_Index]] := ValueArr[A_Index]
    }
}

OnWorkDelGlobalVariable(NameArr) {
    loop NameArr.Length {
        if (MySoftData.VariableMap.Has(NameArr[A_Index]))
            MySoftData.VariableMap.Delete(NameArr[A_Index])
    }
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
        NameValueArr := paramArr.Clone()
        NameValueArr.RemoveAt(1)
        NameArr := []
        ValueArr := []
        loop NameValueArr.Length {
            NameArr.Push(NameValueArr[A_Index])
            ValueArr.Push(NameValueArr[A_Index + 1])
            A_Index += 1
        }

        OnWorkSetGlobalVariable(NameArr, ValueArr)
    }
    else if (isDelVari) {
        NameArr := paramArr.Clone()
        NameArr.RemoveAt(1)
        OnWorkDelGlobalVariable(NameArr)
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
        data := ReceiveCheckData()
        data.Timestamp := Timestamp
        data.Str := str
        ReceiveInfoMap.Set(Timestamp, data)
    }
    if (!ReceiveInfoMap.Has(Timestamp))
        return
    data := ReceiveInfoMap[Timestamp]
    data.EnableCheckAction()

    CopyDataStruct := Buffer(3 * A_PtrSize)  ; 分配结构的内存区域.
    ; 首先设置结构的 cbData 成员为字符串的大小, 包括它的零终止符:
    SizeInBytes := (StrLen(str) + 1) * 2
    NumPut("Ptr", SizeInBytes  ; 操作系统要求这个需要完成.
        , "Ptr", StrPtr(str)  ; 设置 lpData 为到字符串自身的指针.
        , CopyDataStruct, A_PtrSize)
    SendMessage(WM_COPYDATA, Timestamp, CopyDataStruct, , "ahk_id " parentHwnd)
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

WorkSetGlobalVariable(NameArr, ValueArr, ignoreExist) {
    RealNameArr := NameArr.Clone()
    RealValueArr := ValueArr.Clone()
    NameValueCMDStr := "SetVari"
    if (ignoreExist) {
        RealNameArr := []
        RealValueArr := []
        loop NameArr.Length {
            if (!MySoftData.VariableMap.Has(NameArr[A_Index])) {
                RealNameArr.Push(NameArr[A_Index])
                RealValueArr.Push(ValueArr[A_Index])
            }
        }
    }
    if (RealNameArr.Length == 0)
        return

    loop RealNameArr.Length {
        if (Type(RealValueArr[A_Index]) == "String") {
            RealValueArr[A_Index] := Trim(RealValueArr[A_Index], "`n")
            RealValueArr[A_Index] := Trim(RealValueArr[A_Index])
        }
        NameValueCMDStr .= Format("_{}_{}", RealNameArr[A_Index], RealValueArr[A_Index])
        MySoftData.VariableMap[RealNameArr[A_Index]] := ValueArr[A_Index]
    }
    MsgSendHandler(NameValueCMDStr)
}

WorkDelGlobalVariable(NameArr) {
    RealNameArr := []
    NameValueCMDStr := "DelVari"
    loop NameArr.Length {
        if (MySoftData.VariableMap.Has(NameArr[A_Index])) {
            NameValueCMDStr .= Format("_{}", NameArr[A_Index])
            MySoftData.VariableMap.Delete(NameArr[A_Index])
            RealNameArr.Push(NameArr[A_Index])
        }
    }

    if (RealNameArr.Length == 0)
        return
    MsgSendHandler(NameValueCMDStr)
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
    ;不存在表示已经接收了，就不用处理
    if (!ReceiveInfoMap.Has(Timestamp))
        return

    MsgSendHandler(ReceiveInfoMap[Timestamp].Str, Timestamp)
}

OnMainReceiveInfo(wParam, lParam, msg, hwnd) {
    Timestamp := String(wParam)

    if (ReceiveInfoMap.Has(Timestamp)) {
        ReceiveInfoMap[Timestamp].Destroy()
    }
}

class ReceiveCheckData {
    __New() {
        this.Timestamp := ""
        this.Str := ""
        this.Count := 0
        this.CheckAction := ""
    }

    EnableCheckAction() {
        this.Count++
        if (this.Count <= 3) {
            action := CheckIfReceiveInfo.Bind(this.Timestamp)
            this.CheckAction := action
            SetTimer(action, -30)
        }
    }

    Destroy() {
        if (ReceiveInfoMap.Has(this.Timestamp)) {
            if (this.CheckAction != "") {
                action := this.CheckAction
                SetTimer(action, 0)
            }

            ReceiveInfoMap.Delete(this.Timestamp)
        }
    }
}
