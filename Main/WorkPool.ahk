#Requires AutoHotkey v2.0
class WorkPool {
    __New() {
        this.maxSize := MySoftData.MutiThreadNum
        this.pool := []              ; 对象池数组
        this.hwndMap := Map()
        this.pidMap := Map()
        this.MessageArr := []   ;消息数组，避免消息重复处理
        this.MessageMap := Map()
        loop this.maxSize {
            workPath := A_ScriptDir "\Thread\Work" A_Index ".exe"
            if (!FileExist(workPath) && this.maxSize <= 10) {
                FileCopy(A_ScriptDir "\Thread\Work1.exe", workPath)
            }
            Run (Format("{} {} {}", workPath, MySoftData.MyGui.Hwnd, A_Index))
        }

        OnMessage(WM_LOAD_WORK, this.OnFinishLoad.Bind(this))  ; 工作器完成工作回调
        OnMessage(WM_RELEASE_WORK, this.OnRelease.Bind(this))  ; 工作器完成工作回调
        OnMessage(WM_STOP_MACRO, this.OnStopMacro.Bind(this))  ;终止其他宏
        OnMessage(WM_TR_MACRO, this.OnTriggerMacro.Bind(this)) ;触发宏
        OnMessage(WM_COPYDATA, this.OnGetCmd.Bind(this)) ;接收到命令
    }

    __Delete() {
        this.Clear()
    }

    CheckHasFreeWorker() {
        return this.pool.Length >= 1
    }

    CheckEnableMutiThread() {
        return this.maxSize >= 1
    }

    ; 从池中获取一个对象
    Get() {
        workPath := ""
        if (this.pool.Length >= 1) {
            workPath := this.pool.Pop()
        }
        return workPath
    }

    GetWorkPath(workIndex) {
        return A_ScriptDir "\Thread\Work" workIndex ".exe"
    }

    GetWorkIndex(workPath) {
        workIndex := StrReplace(workPath, A_ScriptDir "\Thread\Work")
        workIndex := StrReplace(workIndex, ".exe")
        return workIndex
    }

    GetWorkHwnd(workPath) {
        if (!this.hwndMap.Has(workPath)) {
            workIndex := StrReplace(workPath, A_ScriptDir "\Thread\Work")
            workIndex := StrReplace(workIndex, ".exe")
            try {
                hwnd := WinGetID("RMTWork" workIndex)
                this.hwndMap.Set(workPath, hwnd)
            }
        }
        return this.hwndMap.Get(workPath, 0)
    }

    ; 清空对象池
    Clear() {
        loop this.maxSize {
            workPath := A_ScriptDir "\Thread\Work" A_Index ".exe"
            this.PostMessage(WM_CLEAR_WORK, workPath, 0, 0)
        }
        this.pool := []
    }

    PostMessage(type, workPath, wParam, lParam) {
        hwnd := this.GetWorkHwnd(workPath)
        try {
            PostMessage(type, wParam, lParam, , "ahk_id " hwnd)
        }
    }

    SendMessage(type, workPath, str) {
        CopyDataStruct := Buffer(3 * A_PtrSize)  ; 分配结构的内存区域.
        ; 首先设置结构的 cbData 成员为字符串的大小, 包括它的零终止符:
        SizeInBytes := (StrLen(str) + 1) * 2
        NumPut("Ptr", SizeInBytes  ; 操作系统要求这个需要完成.
            , "Ptr", StrPtr(str)  ; 设置 lpData 为到字符串自身的指针.
            , CopyDataStruct, A_PtrSize)
        hwnd := this.GetWorkHwnd(workPath)
        try {
            SendMessage(type, 0, CopyDataStruct, , "ahk_id " hwnd)
        }
    }

    OnRelease(wParam, lParam, msg, hwnd) {
        tableIndex := wParam
        itemIndex := lParam
        tableItem := MySoftData.TableInfo[tableIndex]
        workIndex := tableItem.IsWorkIndexArr[itemIndex]
        workPath := A_ScriptDir "\Thread\Work" workIndex ".exe"
        this.pool.Push(workPath)
        tableItem.IsWorkIndexArr[itemIndex] := false
    }

    OnFinishLoad(wParam, lParam, msg, hwnd) {
        workPath := A_ScriptDir "\Thread\Work" wParam ".exe"
        this.pool.Push(workPath)
    }

    OnStopMacro(wParam, lParam, msg, hwnd) {
        tableIndex := wParam
        itemIndex := lParam
        tableItem := MySoftData.TableInfo[tableIndex]
        isWork := tableItem.IsWorkIndexArr[itemIndex]
        if (isWork) {
            workPath := MyWorkPool.GetWorkPath(tableItem.IsWorkIndexArr[itemIndex])
            MyWorkPool.PostMessage(WM_STOP_MACRO, workPath, 0, 0)
            return
        }

        KillTableItemMacro(tableItem, itemIndex)
    }

    OnTriggerMacro(wParam, lParam, msg, hwnd) {
        TriggerMacroHandler(wParam, lParam)
    }

    OnRecordMessage(Timestamp) {
        if (this.MessageMap.Has(Timestamp))
            return

        this.MessageMap.Set(Timestamp, 1)
        this.MessageArr.Push(Timestamp)
        if (this.MessageArr.Length >= 125) {
            delTimestamp := this.MessageArr.RemoveAt(1)
            this.MessageMap.Delete(delTimestamp)
        }
    }

    OnGetCmd(wParam, lParam, msg, hwnd) {
        ;告知一下子进程收到信息
        loop MyWorkPool.maxSize {
            workPath := A_ScriptDir "\Thread\Work" A_Index ".exe"
            MyWorkPool.PostMessage(WM_RECEIVE_INFO, workPath, wParam, 0)
        }

        if (this.MessageMap.Has(wParam))    ;接收过就不用再处理了
            return

        this.OnRecordMessage(wParam)
        StringAddress := NumGet(lParam, 2 * A_PtrSize, "Ptr")  ; 检索 CopyDataStruct 的 lpData 成员.
        Cmd := StrGet(StringAddress)  ; 从结构中复制字符串.
        paramArr := StrSplit(Cmd, "_")
        isSetVari := StrCompare(paramArr[1], "SetVari", false) == 0
        isDelVari := StrCompare(paramArr[1], "DelVari", false) == 0
        isReport := StrCompare(paramArr[1], "Report", false) == 0
        isRMT := StrCompare(paramArr[1], "RMT指令", false) == 0
        isItemState := StrCompare(paramArr[1], "ItemState", false) == 0
        isPauseState := StrCompare(paramArr[1], "PauseState", false) == 0
        isMsgBox := StrCompare(paramArr[1], "MsgBox", false) == 0
        isToolTip := StrCompare(paramArr[1], "ToolTip", false) == 0
        isMacroCount := StrCompare(paramArr[1], "MacroCount", false) == 0
        if (isSetVari) {
            SetGlobalVariable(paramArr[2], paramArr[3], false)
        }
        else if (isDelVari) {
            DelGlobalVariable(paramArr[2])
        }
        else if (isReport) {
            CMDStr := SubStr(Cmd, 8)
            CMDReport(CMDStr)
        }
        else if (isRMT) {
            MyExcuteRMTCMDAction(Cmd)
        }
        else if (isItemState) {
            MySetTableItemState(paramArr[2], paramArr[3], paramArr[4])
        }
        else if (isPauseState) {
            MySetItemPauseState(paramArr[2], paramArr[3], paramArr[4])
        }
        else if (isMsgBox) {
            MyMsgBoxContent(paramArr[2])
        }
        else if (isToolTip) {
            MyToolTipContent(paramArr[2])
        }
        else if (isMacroCount) {
            MyMacroCount(paramArr[2])
        }
    }
}
