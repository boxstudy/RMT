#Requires AutoHotkey v2.0

BindKey() {
    BindSuspendHotkey()
    BindShortcut(MySoftData.PauseHotkey, OnPauseHotKey)
    BindShortcut(MySoftData.KillMacroHotkey, OnKillAllMacro)
    BindShortcut(ToolCheckInfo.ToolCheckHotKey, OnToolCheckHotkey)
    BindShortcut(ToolCheckInfo.ToolTextFilterHotKey, OnToolTextFilterScreenShot)
    BindShortcut(ToolCheckInfo.ScreenShotHotKey, OnToolScreenShot)
    BindShortcut(ToolCheckInfo.FreePasteHotKey, OnToolFreePaste)
    BindShortcut(ToolCheckInfo.ToolRecordMacroHotKey, OnHotToolRecordMacro)
    BindTabHotKey()
    BindSave()
    OnExit(OnExitSoft)
}

BindSuspendHotkey() {
    global MySoftData
    if (MySoftData.SuspendHotkey != "") {
        key := "$*~" MySoftData.SuspendHotkey
        Hotkey(key, OnSuspendHotkey, "S")
    }
}

OnSuspendHotkey(*) {
    global MySoftData ; 访问全局变量
    MySoftData.IsSuspend := !MySoftData.IsSuspend
    MySoftData.SuspendToggleCtrl.Value := MySoftData.IsSuspend
    if (MySoftData.IsSuspend) {
        OnKillAllMacro()
        SetTimer(TimingChecker, 0)
        TraySetIcon("Images\Soft\IcoPause.ico")
    }
    else {
        TimingCheck()
        TraySetIcon("Images\Soft\rabit.ico")
    }

    Suspend(MySoftData.IsSuspend)
}

OnPauseHotKey(*) {
    MySoftData.IsPause := !MySoftData.IsPause
    MySoftData.PauseToggleCtrl.Value := MySoftData.IsPause

    loop MySoftData.TableInfo.Length {
        tableItem := MySoftData.TableInfo[A_Index]
        for index, value in tableItem.ModeArr {
            SetItemPauseState(tableItem.index, index, MySoftData.IsPause)
        }
    }

    MySoftData.SpecialTableItem.PauseArr[1] := MySoftData.IsPause
}

SetPauseState(state) {
    MySoftData.PauseToggleCtrl.Value := state
    MySoftData.IsPause := state

    loop MySoftData.TableInfo.Length {
        tableItem := MySoftData.TableInfo[A_Index]
        for index, value in tableItem.ModeArr {
            SetItemPauseState(tableItem.index, index, state)
        }
    }

    MySoftData.SpecialTableItem.PauseArr[1] := state
}

OnKillAllMacro(*) {
    global MySoftData ; 访问全局变量

    loop MySoftData.TableInfo.Length {
        tableItem := MySoftData.TableInfo[A_Index]
        KillSingleTableMacro(tableItem)
        for index, value in tableItem.ModeArr {
            isWork := tableItem.IsWorkIndexArr[index]
            if (isWork) {
                workPath := MyWorkPool.GetWorkPath(tableItem.IsWorkIndexArr[index])
                MyWorkPool.PostMessage(WM_STOP_MACRO, workPath, 0, 0)
                return
            }
        }
    }

    KillSingleTableMacro(MySoftData.SpecialTableItem)
}

OnToolCheckHotkey(*) {
    global ToolCheckInfo
    ToolCheckInfo.IsToolCheck := !ToolCheckInfo.IsToolCheck
    ToolCheckInfo.ToolCheckCtrl.Value := ToolCheckInfo.IsToolCheck

    if (ToolCheckInfo.IsToolCheck) {
        ToolCheckInfo.MouseInfoTimer := Timer(SetToolCheckInfo, 100)
        ToolCheckInfo.MouseInfoTimer.On()
    }
    else
        ToolCheckInfo.MouseInfoTimer := ""
}

SetToolCheckInfo() {
    global ToolCheckInfo
    CoordMode("Mouse", "Screen")
    MouseGetPos &mouseX, &mouseY, &winId
    try {
        ToolCheckInfo.PosStr := mouseX . "," . mouseY
        ToolCheckInfo.ProcessName := WinGetProcessName(winId)
        ToolCheckInfo.ProcessTile := WinGetTitle(winId)
        ToolCheckInfo.ProcessPid := WinGetPID(winId)
        ToolCheckInfo.ProcessClass := WinGetClass(winId)
        ToolCheckInfo.ProcessId := winId
        ToolCheckInfo.Color := StrReplace(PixelGetColor(mouseX, mouseY, "Slow"), "0x", "")

        WinPosArr := GetWinPos()
        ToolCheckInfo.WinPosStr := WinPosArr[1] . "," . WinPosArr[2]
        RefreshToolUI()
    }
}

OnClickToolRecordSettingBtn(*) {
    MyToolRecordSettingGui.ShowGui()
}

OnToolTextFilterScreenShot(*) {
    if (MySoftData.ScreenShotTypeCtrl.Value == 1) {
        A_Clipboard := ""  ; 清空剪贴板
        Run("ms-screenclip:")
        SetTimer(OnToolTextCheckScreenShot, 500)  ; 每 500 毫秒检查一次剪贴板
    }
    else {
        EnableSelectAerea(OnToolTextFilterGetArea)
    }
}

OnToolScreenShot(*) {
    if (MySoftData.ScreenShotTypeCtrl.Value == 1) {
        Run("ms-screenclip:")
    }
    else {
        EnableSelectAerea(OnToolScreenShotGetArea)
    }
}

OnToolScreenShotGetArea(x1, y1, x2, y2) {
    width := X2 - X1
    height := Y2 - Y1
    pBitmap := Gdip_BitmapFromScreen(X1 "|" Y1 "|" width "|" height)
    Gdip_SetBitmapToClipboard(pBitmap)
    Gdip_DisposeImage(pBitmap)
}

OnToolFreePaste(*) {
    MyFreePasteGui.ShowGui()
}

OnHotToolRecordMacro(isHotkey, *) {
    action := OnToolRecordMacro.Bind(isHotkey)
    SetTimer(action, -1)
}

OnToolRecordMacro(isHotkey, *) {
    global ToolCheckInfo, MySoftData
    spacialKeyArr := ["NumpadEnter"]
    if (isHotkey) {
        LastState := ToolCheckInfo.ToolCheckRecordMacroCtrl.Value
        ToolCheckInfo.ToolCheckRecordMacroCtrl.Value := !LastState
    }
    state := ToolCheckInfo.ToolCheckRecordMacroCtrl.Value

    if (MySoftData.MacroEditGui != "") {
        MySoftData.RecordToggleCon.Value := state
    }

    if (state) {
        CoordMode("Mouse", "Screen")
        MouseGetPos &mouseX, &mouseY
        ToolCheckInfo.RecordMacroStr := ""
        ToolCheckInfo.RecordLastTime := GetCurMSec()
        ToolCheckInfo.RecordLastMousePos := [mouseX, mouseY]
    }

    StateSymbol := state ? "On" : "Off"
    loop 255 {
        key := Format("$*~vk{:X}", A_Index)
        if (ToolCheckInfo.RecordSpecialKeyMap.Has(A_Index)) {
            keyName := GetKeyName(Format("vk{:X}", A_Index))
            key := Format("$*~sc{:X}", GetKeySC(keyName))
        }

        try {
            Hotkey(key, OnRecordMacroKeyDown, StateSymbol)
            Hotkey(key " Up", OnRecordMacroKeyUp, StateSymbol)
        }
        catch {
            continue
        }
    }

    loop spacialKeyArr.Length {
        key := Format("$*~sc{:X}", GetKeySC(spacialKeyArr[A_Index]))
        Hotkey(key, OnRecordMacroKeyDown, StateSymbol)
        Hotkey(key " Up", OnRecordMacroKeyUp, StateSymbol)
    }

    if (state) {
        if (ToolCheckInfo.RecordJoy)
            RecordJoy()

        if (ToolCheckInfo.RecordMouse && ToolCheckInfo.RecordMouseTrail)
            RecordMouseTrail
    }
    else {
        OnFinishRecordMacro()
    }
}

RecordMouseTrail() {
    if (!ToolCheckInfo.ToolCheckRecordMacroCtrl.Value)
        return
    CoordMode("Mouse", "Screen")
    MouseGetPos &mouseX, &mouseY
    if (ToolCheckInfo.RecordLastMousePos[1] != mouseX || ToolCheckInfo.RecordLastMousePos[2] != mouseY) {   ;鼠标位置发生改变
        len := Abs(ToolCheckInfo.RecordLastMousePos[1] - mouseX)
        len += Abs(ToolCheckInfo.RecordLastMousePos[2] - mouseY)
        if (len <= ToolCheckInfo.RecordMouseTrailLen) {
            SetTimer(RecordMouseTrail, -ToolCheckInfo.RecordMouseTrailInterval)
            return
        }

        speed := ToolCheckInfo.RecordMouseTrailSpeed
        IsRelative := ToolCheckInfo.RecordMouseRelative
        symbol := IsRelative ? "_" speed "_1" : "_" speed
        targetX := mouseX
        targetY := mouseY
        if (IsRelative) {   ;相对位移，坐标变化
            targetX := mouseX - ToolCheckInfo.RecordLastMousePos[1]
            targetY := mouseY - ToolCheckInfo.RecordLastMousePos[2]
        }
        ToolCheckInfo.RecordMacroStr .= "移动_" targetX "_" targetY symbol ","
        ToolCheckInfo.RecordLastMousePos := [mouseX, mouseY]

        span := GetCurMSec() - ToolCheckInfo.RecordLastTime
        ToolCheckInfo.RecordLastTime := GetCurMSec()
        ToolCheckInfo.RecordMacroStr .= "间隔_" span ","
    }
    SetTimer(RecordMouseTrail, -ToolCheckInfo.RecordMouseTrailInterval)
}

OnRecordMacroKeyDown(*) {

    key := StrReplace(A_ThisHotkey, "$", "")
    key := StrReplace(key, "*~", "")
    keyName := GetKeyName(key)
    OnRecordAddMacroStr(keyName, true)
}

OnRecordMacroKeyUp(*) {
    key := StrReplace(A_ThisHotkey, "$", "")
    key := StrReplace(key, "*~", "")
    key := StrReplace(key, " Up", "")
    keyName := GetKeyName(key)
    OnRecordAddMacroStr(keyName, false)
}

OnRecordAddMacroStr(keyName, isDown) {
    if (keyName == "WheelUp" || keyName == "WheelDown") {
        ; 处理鼠标滚轮事件（暂时留空，根据需求补充）
    }
    ; 处理按键按下事件
    else if (isDown) {
        ; 如果已按下且不记录长按多次，则直接返回
        if (!ToolCheckInfo.RecordHoldMuti && ToolCheckInfo.RecordHoldKeyMap.Has(keyName))
            return
        ; 记录当前按键为按下状态
        ToolCheckInfo.RecordHoldKeyMap[keyName] := true
    }
    ; 处理按键释放事件（仅在存在记录时删除）
    else if (ToolCheckInfo.RecordHoldKeyMap.Has(keyName)) {
        ToolCheckInfo.RecordHoldKeyMap.Delete(keyName)
    }

    span := GetCurMSec() - ToolCheckInfo.RecordLastTime
    keySymbol := isDown ? 1 : 2
    ToolCheckInfo.RecordLastTime := GetCurMSec()
    IsJoy := InStr(keyName, "Joy")
    IsMouse := keyName == "LButton" || keyName == "RButton" || keyName == "MButton"
    IsKeyboard := !IsMouse && !IsJoy

    if (IsJoy || (IsKeyboard && ToolCheckInfo.RecordKeyboard)) {
        keyName := keyName == "," ? "逗号" : keyName
        ToolCheckInfo.RecordMacroStr .= "间隔_" span ","
        ToolCheckInfo.RecordMacroStr .= "按键_" keyName "_" keySymbol ","
    }

    if (IsMouse && ToolCheckInfo.RecordMouse) {
        CoordMode("Mouse", "Screen")
        MouseGetPos &mouseX, &mouseY
        if (ToolCheckInfo.RecordLastMousePos[1] != mouseX || ToolCheckInfo.RecordLastMousePos[2] != mouseY) {   ;鼠标位置发生改变
            speed := Max(100 - Integer(span * 0.02), 90)
            speed := ToolCheckInfo.RecordMouseTrail ? 100 : speed
            IsRelative := ToolCheckInfo.RecordMouseRelative
            symbol := IsRelative ? "_" speed "_1" : "_" speed
            targetX := mouseX
            targetY := mouseY
            if (IsRelative) {   ;相对位移，坐标变化
                targetX := mouseX - ToolCheckInfo.RecordLastMousePos[1]
                targetY := mouseY - ToolCheckInfo.RecordLastMousePos[2]
            }
            ToolCheckInfo.RecordMacroStr .= "移动_" targetX "_" targetY symbol ","
            ToolCheckInfo.RecordLastMousePos := [mouseX, mouseY]
        }
        ToolCheckInfo.RecordMacroStr .= "间隔_" span ","
        ToolCheckInfo.RecordMacroStr .= "按键_" keyName "_" keySymbol ","
    }
}

OnFinishRecordMacro() {
    if (ToolCheckInfo.RecordAutoLoosen) {
        for Key, Value in ToolCheckInfo.RecordHoldKeyMap {
            keyName := Key == "," ? "逗号" : Key
            ToolCheckInfo.RecordMacroStr .= "按键_" keyName "_2,"
        }
    }
    macroStr := Trim(ToolCheckInfo.RecordMacroStr, ",")
    macroStr := SimpleRecordMacroStr(macroStr)

    if (MySoftData.MacroEditGui != "") {
        MySoftData.MacroEditGui.InitTreeView(macroStr)
    }
    macroLineStr := StrReplace(macroStr, ",", "`n")
    ToolCheckInfo.ToolTextCtrl.Value := macroLineStr
    A_Clipboard := macroLineStr
}

;绑定热键
OnExitSoft(*) {
    global MyPToken, MyChineseOcr
    Gdip_Shutdown(MyPToken)
    MyChineseOcr := ""
    MyEnglishOcr := ""
    MyWorkPool.Clear()
}

BindTabHotKey() {
    tableIndex := 0
    loop MySoftData.TabNameArr.Length {
        tableItem := MySoftData.TableInfo[A_Index]
        tableIndex := A_Index
        for index, value in tableItem.ModeArr {
            if (tableItem.TKArr.Length < index || tableItem.TKArr[index] == "" || (Integer)(tableItem.ForbidArr[index]))
                continue

            if (tableItem.MacroArr.Length < index || tableItem.MacroArr[index] == "")
                continue

            key := "$*" tableItem.TKArr[index]
            actionArr := GetMacroAction(tableIndex, index)
            isJoyKey := RegExMatch(tableItem.TKArr[index], "Joy")
            isHotstring := SubStr(tableItem.TKArr[index], 1, 1) == ":"
            curProcessName := tableItem.ProcessNameArr.Length >= index ? tableItem.ProcessNameArr[index] : ""

            if (curProcessName != "") {
                HotIfWinActive(GetParamsWinInfoStr(curProcessName))
            }

            if (isJoyKey) {
                MyJoyMacro.AddMacro(tableItem.TKArr[index], actionArr[1], curProcessName)
            }
            else if (isHotstring) {
                Hotstring(tableItem.TKArr[index], actionArr[1])
            }
            else {
                if (actionArr[1] != "")
                    Hotkey(key, actionArr[1])

                if (actionArr[2] != "")
                    Hotkey(key " up", actionArr[2])
            }

            if (curProcessName != "") {
                HotIfWinActive
            }
        }
    }
}

GetMacroAction(tableIndex, index) {
    tableItem := MySoftData.TableInfo[tableIndex]
    macro := tableItem.MacroArr[index]
    tableSymbol := GetTableSymbol(tableIndex)
    actionDown := ""
    actionUp := ""

    if (tableSymbol == "Normal") {
        actionDown := GetClosureActionNew(tableIndex, index, OnTriggerKeyDown)
        actionUp := GetClosureActionNew(tableIndex, index, OnTriggerKeyUp)
    }
    else if (tableSymbol == "String") {
        actionDown := GetClosureActionNew(tableIndex, index, TriggerMacroHandler)
    }
    else if (tableSymbol == "Replace") {
        actionDown := GetClosureAction(tableItem, macro, index, OnReplaceDownKey)
        actionUp := GetClosureAction(tableItem, macro, index, OnReplaceUpKey)
    }
    return [actionDown, actionUp]
}

OnTriggerKeyDown(tableIndex, itemIndex) {
    tableItem := MySoftData.TableInfo[tableIndex]
    macro := tableItem.MacroArr[itemIndex]

    if (tableItem.TriggerTypeArr[itemIndex] == 1) { ;按下触发
        if (SubStr(tableItem.TKArr[itemIndex], 1, 1) != "~")
            LoosenModifyKey(tableItem.TKArr[itemIndex])
        TriggerMacroHandler(tableIndex, itemIndex)
    }
    else if (tableItem.TriggerTypeArr[itemIndex] == 3) { ;松开停止
        TriggerMacroHandler(tableIndex, itemIndex)
    }
    else if (tableItem.TriggerTypeArr[itemIndex] == 4) {  ;开关
        if (tableItem.IsWorkIndexArr[itemIndex]) {       ;关闭开关
            MySubMacroStopAction(tableIndex, itemIndex)
            return
        }
        OnToggleTriggerMacro(tableIndex, itemIndex)
    }
    else if (tableItem.TriggerTypeArr[itemIndex] == 5) {    ;长按
        Sleep(tableItem.HoldTimeArr[itemIndex])

        keyCombo := LTrim(tableItem.TKArr[itemIndex], "~")
        if (AreKeysPressed(keyCombo))
            TriggerMacroHandler(tableIndex, itemIndex)
    }
}

;松开停止
OnTriggerKeyUp(tableIndex, itemIndex) {
    tableItem := MySoftData.TableInfo[tableIndex]
    isWork := tableItem.IsWorkIndexArr[itemIndex]
    if (tableItem.TriggerTypeArr[itemIndex] == 2 && !isWork) { ;松开触发
        TriggerMacroHandler(tableIndex, itemIndex)
    }
    else if (tableItem.TriggerTypeArr[itemIndex] == 3) {  ;松开停止
        if (isWork) {
            workPath := MyWorkPool.GetWorkPath(tableItem.IsWorkIndexArr[itemIndex])
            MyWorkPool.PostMessage(WM_STOP_MACRO, workPath, 0, 0)
            return
        }

        KillTableItemMacro(tableItem, itemIndex)
    }
}

OnToggleTriggerMacro(tableIndex, itemIndex) {
    tableItem := MySoftData.TableInfo[tableIndex]
    macro := tableItem.MacroArr[itemIndex]
    hasWork := MyWorkPool.CheckHasWork()

    if (hasWork) {
        workPath := MyWorkPool.Get()
        workIndex := MyWorkPool.GetWorkIndex(workPath)
        tableItem.IsWorkIndexArr[itemIndex] := workIndex
        MyWorkPool.PostMessage(WM_TR_MACRO, workPath, tableIndex, itemIndex)
        return
    }

    isTrigger := tableItem.ToggleStateArr[itemIndex]
    if (!isTrigger) {
        tableItem.ToggleStateArr[itemIndex] := true
        action := OnTriggerMacroKeyAndInit.Bind(tableItem, macro, itemIndex)
        tableItem.ToggleActionArr[itemIndex] := action
        SetTimer(action, -1)
    }
    else {
        action := tableItem.ToggleActionArr[itemIndex]
        if (action == "")
            return

        KillTableItemMacro(tableItem, itemIndex)
        SetTimer(action, 0)
    }
}

TriggerMacroHandler(tableIndex, itemIndex) {
    tableItem := MySoftData.TableInfo[tableIndex]
    macro := tableItem.MacroArr[itemIndex]
    isWork := tableItem.IsWorkIndexArr[itemIndex]
    hasWork := MyWorkPool.CheckHasWork()
    if (isWork)
        return

    if (hasWork) {
        workPath := MyWorkPool.Get()
        workIndex := MyWorkPool.GetWorkIndex(workPath)
        tableItem.IsWorkIndexArr[itemIndex] := workIndex
        MyWorkPool.PostMessage(WM_TR_MACRO, workPath, tableIndex, itemIndex)
    }
    else {
        OnTriggerMacroKeyAndInit(tableItem, macro, itemIndex)
    }
}
