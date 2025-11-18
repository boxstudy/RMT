#Requires AutoHotkey v2.0

;资源保存
OnSaveSetting(*) {
    global MySoftData
    isValid := CheckFloatSettingValid()
    if (!isValid)
        return

    if (ObjHasOwnProp(MyWorkPool, "Clear"))
        MyWorkPool.Clear()

    loop MySoftData.TabNameArr.Length {
        SaveTableItemInfo(A_Index)
    }

    IniWrite(MySoftData.HoldFloatCtrl.Value, IniFile, IniSection, "HoldFloat")
    IniWrite(MySoftData.PreIntervalFloatCtrl.Value, IniFile, IniSection, "PreIntervalFloat")
    IniWrite(MySoftData.IntervalFloatCtrl.Value, IniFile, IniSection, "IntervalFloat")
    IniWrite(MySoftData.CoordXFloatCon.Value, IniFile, IniSection, "CoordXFloat")
    IniWrite(MySoftData.CoordYFloatCon.Value, IniFile, IniSection, "CoordYFloat")
    IniWrite(MySoftData.SuspendHotkeyCtrl.Value, IniFile, IniSection, "SuspendHotkey")
    IniWrite(MySoftData.PauseHotkeyCtrl.Value, IniFile, IniSection, "PauseHotkey")
    IniWrite(MySoftData.KillMacroHotkeyCtrl.Value, IniFile, IniSection, "KillMacroHotkey")
    IniWrite(MySoftData.ShowWinCtrl.Value, IniFile, IniSection, "IsExecuteShow")
    IniWrite(MySoftData.BootStartCtrl.Value, IniFile, IniSection, "IsBootStart")
    IniWrite(MySoftData.SplitLineCtrl.Value, IniFile, IniSection, "ShowSplitLine")
    IniWrite(MySoftData.FixedMenuWheelCtrl.Value, IniFile, IniSection, "FixedMenuWheel")
    IniWrite(MySoftData.MutiThreadNumCtrl.Value, IniFile, IniSection, "MutiThreadNum")
    IniWrite(MySoftData.SoftBGColorCon.Value, IniFile, IniSection, "SoftBGColor")
    IniWrite(MySoftData.NoVariableTipCtrl.Value, IniFile, IniSection, "NoVariableTip")
    IniWrite(MySoftData.CMDTipCtrl.Value, IniFile, IniSection, "CMDTip")
    IniWrite(MySoftData.ScreenShotTypeCtrl.Value, IniFile, IniSection, "ScreenShotType")
    IniWrite(ToolCheckInfo.ToolCheckHotKeyCtrl.Value, IniFile, IniSection, "ToolCheckHotKey")
    IniWrite(ToolCheckInfo.ToolRecordMacroHotKeyCtrl.Value, IniFile, IniSection, "RecordMacroHotKey")
    IniWrite(ToolCheckInfo.ToolTextFilterHotKeyCtrl.Value, IniFile, IniSection, "ToolTextFilterHotKey")
    IniWrite(ToolCheckInfo.ScreenShotHotKeyCtrl.Value, IniFile, IniSection, "ScreenShotHotKey")
    IniWrite(ToolCheckInfo.FreePasteHotKeyCtrl.Value, IniFile, IniSection, "FreePasteHotKey")
    IniWrite(ToolCheckInfo.RecordKeyboard, IniFile, IniSection, "RecordKeyboard")
    IniWrite(ToolCheckInfo.RecordMouse, IniFile, IniSection, "RecordMouse")
    IniWrite(ToolCheckInfo.RecordJoy, IniFile, IniSection, "RecordJoy")
    IniWrite(ToolCheckInfo.RecordMouseRelative, IniFile, IniSection, "RecordMouseRelative")
    IniWrite(ToolCheckInfo.RecordMouseTrail, IniFile, IniSection, "RecordMouseTrail")
    IniWrite(ToolCheckInfo.RecordMouseTrailLen, IniFile, IniSection, "RecordMouseTrailLen")
    IniWrite(ToolCheckInfo.RecordMouseTrailSpeed, IniFile, IniSection, "RecordMouseTrailSpeed")
    IniWrite(ToolCheckInfo.RecordHoldMuti, IniFile, IniSection, "RecordHoldMuti")
    IniWrite(ToolCheckInfo.RecordAutoLoosen, IniFile, IniSection, "RecordAutoLoosen")
    IniWrite(ToolCheckInfo.RecordMouseTrailInterval, IniFile, IniSection, "MouseTrailInterval")
    IniWrite(ToolCheckInfo.RecordJoyInterval, IniFile, IniSection, "RecordJoyInterval")
    IniWrite(ToolCheckInfo.OCRTypeCtrl.Value, IniFile, IniSection, "OCRType")
    IniWrite(MySoftData.TabCtrl.Value, IniFile, IniSection, "TableIndex")
    IniWrite(MySoftData.FontTypeCtrl.Text, IniFile, IniSection, "FontType")
    IniWrite(MySoftData.MacroTotalCount, IniFile, IniSection, "MacroTotalCount")
    IniWrite(MySoftData.LastShowMonth, IniFile, IniSection, "LastShowMonth")
    IniWrite(true, IniFile, IniSection, "HasSaved")
    IniWrite(true, IniFile, IniSection, "IsReload")
    SaveCurWinPos()

    MySoftData.CMDPosX := IniWrite(MySoftData.CMDPosX, IniFile, IniSection, "CMDPosX")
    MySoftData.CMDPosY := IniWrite(MySoftData.CMDPosY, IniFile, IniSection, "CMDPosY")
    MySoftData.CMDWidth := IniWrite(MySoftData.CMDWidth, IniFile, IniSection, "CMDWidth")
    MySoftData.CMDHeight := IniWrite(MySoftData.CMDHeight, IniFile, IniSection, "CMDHeight")
    MySoftData.CMDLineNum := IniWrite(MySoftData.CMDLineNum, IniFile, IniSection, "CMDLineNum")
    MySoftData.CMDBGColor := IniWrite(MySoftData.CMDBGColor, IniFile, IniSection, "CMDBGColor")
    MySoftData.CMDTransparency := IniWrite(MySoftData.CMDTransparency, IniFile, IniSection, "CMDTransparency")
    MySoftData.CMDFontColor := IniWrite(MySoftData.CMDFontColor, IniFile, IniSection, "CMDFontColor")
    MySoftData.CMDFontSize := IniWrite(MySoftData.CMDFontSize, IniFile, IniSection, "CMDFontSize")
    Reload()
}

CheckFloatSettingValid() {
    if (IsFloat(MySoftData.HoldFloatCtrl.Value)) {
        MsgBox("按住时间浮动值只能是整数")
        return false
    }

    if (IsFloat(MySoftData.PreIntervalFloatCtrl.Value)) {
        MsgBox("每次间隔浮动值只能是整数")
        return false
    }

    if (IsFloat(MySoftData.IntervalFloatCtrl.Value)) {
        MsgBox("间隔指令浮动值只能是整数")
        return false
    }

    if (IsFloat(MySoftData.CoordXFloatCon.Value)) {
        MsgBox("坐标X浮动值只能是整数")
        return false
    }

    if (IsFloat(MySoftData.CoordYFloatCon.Value)) {
        MsgBox("坐标Y浮动值只能是整数")
        return false
    }

    return true
}

SaveCurWinPos() {
    MyGui := MySoftData.MyGui
    MyGui.GetPos(&x, &y, &w, &h)
    IniWrite(Format("{}π{}", x, y), IniFile, IniSection, "LastWinPos")
}

OnEditCMDTipGui() {
    MyCMDTipSettingGui.ShowGui()
}

OnTabValueChanged(*) {
    tableItem := MySoftData.TableInfo[MySoftData.TabCtrl.Value]
    MySlider.SwitchTab(tableItem)
}

SwapTableContent(tableItem, indexA, indexB) {
    SwapArrValue(tableItem.SerialArr, indexA, indexB)
    SwapArrValue(tableItem.RemarkConArr, indexA, indexB, 2)
    SwapArrValue(tableItem.TKConArr, indexA, indexB, 3)
    SwapArrValue(tableItem.TKArr, indexA, indexB)
    SwapArrValue(tableItem.TriggerTypeConArr, indexA, indexB, 2)
    SwapArrValue(tableItem.HoldTimeArr, indexA, indexB)
    SwapArrValue(tableItem.LoopCountConArr, indexA, indexB, 3)
    SwapArrValue(tableItem.ForbidConArr, indexA, indexB, 2)
}

SwapArrValue(Arr, indexA, indexB, valueType := 1) {
    if (valueType == 3) {
        temp := Arr[indexA].Text
        Arr[indexA].Text := Arr[indexB].Text
        Arr[indexB].Text := temp
    }
    else if (valueType == 2) {
        temp := Arr[indexA].Value
        Arr[indexA].Value := Arr[indexB].Value
        Arr[indexB].Value := temp
    }
    else {
        temp := Arr[indexA]
        Arr[indexA] := Arr[indexB]
        Arr[indexB] := temp
    }
}

BindSave() {
    MyTriggerKeyGui.SaveBtnAction := OnSaveSetting
    MyTriggerStrGui.SaveBtnAction := OnSaveSetting
    MyMacroGui.SaveBtnAction := OnSaveSetting
}

PluginInit() {
    global MyWorkPool := WorkPool()
    global MyChineseOcr := RapidOcr(A_ScriptDir)
    global MyEnglishOcr := RapidOcr(A_ScriptDir, 2)
    global MyPToken := Gdip_Startup()

    dllpath := A_ScriptDir "\Plugins\OpenCV\x64\ImageFinder.dll"
    ; 构建包含 DLL 文件的目录路径
    dllDir := A_ScriptDir "\Plugins\OpenCV\x64"
    ; 使用 SetDllDirectory 将 dllDir 添加到 DLL 搜索路径中
    DllCall("SetDllDirectory", "Str", dllDir)
    DllCall('LoadLibrary', 'str', dllpath, "Ptr")
}

OnToolAlwaysOnTop(*) {
    global MySoftData, ToolCheckInfo
    state := ToolCheckInfo.AlwaysOnTopCtrl.Value
    if (state) {
        MySoftData.MyGui.Opt("+AlwaysOnTop")
    }
    else {
        MySoftData.MyGui.Opt("-AlwaysOnTop")
    }
}

InitFilePath() {
    if (!DirExist(A_WorkingDir "\Setting")) {
        DirCreate(A_WorkingDir "\Setting")
    }
    if (!DirExist(A_WorkingDir "\Setting\" MySoftData.CurSettingName)) {
        DirCreate(A_WorkingDir "\Setting\" MySoftData.CurSettingName)
    }

    if (!DirExist(A_WorkingDir "\Setting\" MySoftData.CurSettingName "\Images\ScreenShot")) {
        DirCreate(A_WorkingDir "\Setting\" MySoftData.CurSettingName "\Images\ScreenShot")
    }

    filePath := A_WorkingDir "\Setting\" MySoftData.CurSettingName "\使用说明&署名.txt"
    if (!FileExist(filePath)) {
        FileAppend("资源名称：`n`n" .
            "原作者：`n" .
            "功能：`n" .
            "   `n" .
            "操作说明：`n" .
            "   `n" .
            "协议：CC BY - NC - SA 4.0`n" .
            "原始来源：RMT(若梦兔) 软件导出`n" .
            "说明：仅限非商业用途，转载请注明来源并保持相同协议 `n", filePath, "UTF-8")
    }

    if (!DirExist(A_WorkingDir "\Images")) {
        DirCreate(A_WorkingDir "\Images")
    }
    if (!DirExist(A_WorkingDir "\Images\Soft")) {
        DirCreate(A_WorkingDir "\Images\Soft")
    }

    if (!DirExist(A_WorkingDir "\Images\ScreenShot")) {
        DirCreate(A_WorkingDir "\Images\ScreenShot")
    }

    if (!DirExist(A_WorkingDir "\Images\FreePaste")) {
        DirCreate(A_WorkingDir "\Images\FreePaste")
    }

    FileInstall("Images\Soft\WeiXin.png", "Images\Soft\WeiXin.png", 1)
    FileInstall("Images\Soft\ZhiFuBao.png", "Images\Soft\ZhiFuBao.png", 1)
    FileInstall("Images\Soft\rabit.ico", "Images\Soft\rabit.ico", 1)
    FileInstall("Images\Soft\IcoPause.ico", "Images\Soft\IcoPause.ico", 1)
    FileInstall("Images\Soft\GreenColor.png", "Images\Soft\GreenColor.png", 1)
    FileInstall("Images\Soft\RedColor.png", "Images\Soft\RedColor.png", 1)
    FileInstall("Images\Soft\YellowColor.png", "Images\Soft\YellowColor.png", 1)
    FileInstall("Images\Soft\Target.png", "Images\Soft\Target.png", 1)

    ;图标
    FileInstall("Images\Soft\Key.png", "Images\Soft\Key.png", 1)
    FileInstall("Images\Soft\Interval.png", "Images\Soft\Interval.png", 1)
    FileInstall("Images\Soft\Search.png", "Images\Soft\Search.png", 1)
    FileInstall("Images\Soft\SearchPro.png", "Images\Soft\SearchPro.png", 1)
    FileInstall("Images\Soft\Move.png", "Images\Soft\Move.png", 1)
    FileInstall("Images\Soft\MovePro.png", "Images\Soft\MovePro.png", 1)
    FileInstall("Images\Soft\Output.png", "Images\Soft\Output.png", 1)
    FileInstall("Images\Soft\Run.png", "Images\Soft\Run.png", 1)
    FileInstall("Images\Soft\Var.png", "Images\Soft\Var.png", 1)
    FileInstall("Images\Soft\Extract.png", "Images\Soft\Extract.png", 1)
    FileInstall("Images\Soft\Operation.png", "Images\Soft\Operation.png", 1)
    FileInstall("Images\Soft\If.png", "Images\Soft\If.png", 1)
    FileInstall("Images\Soft\rabit.png", "Images\Soft\rabit.png", 1)
    FileInstall("Images\Soft\Sub.png", "Images\Soft\Sub.png", 1)
    FileInstall("Images\Soft\Mouse.png", "Images\Soft\Mouse.png", 1)
    FileInstall("Images\Soft\True.png", "Images\Soft\True.png", 1)
    FileInstall("Images\Soft\False.png", "Images\Soft\False.png", 1)

    FileInstall("Audio\End.wav", "Audio\End.wav", 1)
    FileInstall("Audio\Start.wav", "Audio\Start.wav", 1)

    global VBSPath := A_WorkingDir "\VBS\PlayAudio.vbs"
    global StartTipAudio := A_WorkingDir "\Audio\Start.wav"
    global EndTipAudio := A_WorkingDir "\Audio\End.wav"
    global MacroFile := A_WorkingDir "\Setting\" MySoftData.CurSettingName "\MacroFile.ini"
    global SearchFile := A_WorkingDir "\Setting\" MySoftData.CurSettingName "\SearchFile.ini"
    global SearchProFile := A_WorkingDir "\Setting\" MySoftData.CurSettingName "\SearchProFile.ini"
    global CompareFile := A_WorkingDir "\Setting\" MySoftData.CurSettingName "\CompareFile.ini"
    global MMProFile := A_WorkingDir "\Setting\" MySoftData.CurSettingName "\MMProFile.ini"
    global BGKeyFile := A_WorkingDir "\Setting\" MySoftData.CurSettingName "\BGKeyFile.ini"
    global TimingFile := A_WorkingDir "\Setting\" MySoftData.CurSettingName "\TimingFile.ini"
    global RunFile := A_WorkingDir "\Setting\" MySoftData.CurSettingName "\RunFile.ini"
    global OutputFile := A_WorkingDir "\Setting\" MySoftData.CurSettingName "\OutputFile.ini"
    global StopFile := A_WorkingDir "\Setting\" MySoftData.CurSettingName "\StopFile.ini"
    global VariableFile := A_WorkingDir "\Setting\" MySoftData.CurSettingName "\VariableFile.ini"
    global ExVariableFile := A_WorkingDir "\Setting\" MySoftData.CurSettingName "\ExVariableFile.ini"
    global SubMacroFile := A_WorkingDir "\Setting\" MySoftData.CurSettingName "\SubMacroFile.ini"
    global LoopFile := A_WorkingDir "\Setting\" MySoftData.CurSettingName "\LoopFile.ini"
    global OperationFile := A_WorkingDir "\Setting\" MySoftData.CurSettingName "\OperationFile.ini"
    global BGMouseFile := A_WorkingDir "\Setting\" MySoftData.CurSettingName "\BGMouseFile.ini"
}

SubMacroStopAction(tableIndex, itemIndex) {
    tableItem := MySoftData.TableInfo[tableIndex]
    workPath := MyWorkPool.GetWorkPath(tableItem.IsWorkIndexArr[itemIndex])
    ; tableItem.IsWorkIndexArr[itemIndex] := false
    MyWorkPool.PostMessage(WM_STOP_MACRO, workPath, 0, 0)
}

SetGlobalVariable(Name, Value, ignoreExist) {
    global MySoftData
    if (ignoreExist && MySoftData.VariableMap.Has(Name))
        return
    MySoftData.VariableMap[Name] := Value
    MyVarListenGui.Refresh()
    IsMuti := MyWorkPool.CheckEnableMutiThread()
    if (IsMuti) {
        loop MyWorkPool.maxSize {
            workPath := A_ScriptDir "\Thread\Work" A_Index ".exe"
            str := Format("SetVari_{}_{}", Name, Value)
            MyWorkPool.SendMessage(WM_COPYDATA, workPath, str)
        }
    }
}

DelGlobalVariable(Name) {
    global MySoftData
    if (!MySoftData.VariableMap.Has(Name))
        return

    MySoftData.VariableMap.Delete(Name)
    MyVarListenGui.Refresh()
    IsMuti := MyWorkPool.CheckEnableMutiThread()
    if (IsMuti) {
        loop MyWorkPool.maxSize {
            workPath := A_ScriptDir "\Thread\Work" A_Index ".exe"
            str := Format("DelVari_{}", Name)
            MyWorkPool.SendMessage(WM_COPYDATA, workPath, str)
        }
    }
}

SetCMDTipValue(value) {
    IsMuti := MyWorkPool.CheckEnableMutiThread()
    if (IsMuti) {
        loop MyWorkPool.maxSize {
            workPath := A_ScriptDir "\Thread\Work" A_Index ".exe"
            str := Format("CMDTip_{}", value)
            MyWorkPool.SendMessage(WM_COPYDATA, workPath, str)
        }
    }
}

CMDReport(CMDStr) {
    MyCMDTipGui.ShowGui(CMDStr)
}

;0默认状态 1运行 2暂停 3取消暂停 4终止
SetTableItemState(tableIndex, itemIndex, state) {
    tableItem := MySoftData.TableInfo[tableIndex]
    LastColorState := tableItem.ColorStateArr[itemIndex]
    ColorCon := tableItem.ColorConArr[itemIndex]
    isVisible := state != 0
    tableItem.ColorStateArr[itemIndex] := state
    if (state == 1) {
        ColorCon.Value := "Images\Soft\GreenColor.png"
    }
    else if (state == 2) {
        if (!ColorCon.Visible || LastColorState != 1) { ;非运行状态忽略
            tableItem.ColorStateArr[itemIndex] := LastColorState
            return
        }

        ColorCon.Value := "Images\Soft\YellowColor.png"
    }
    else if (state == 3) {
        if (!ColorCon.Visible || LastColorState == 3) { ;终止状态忽略
            tableItem.ColorStateArr[itemIndex] := LastColorState
            return
        }

        ColorCon.Value := "Images\Soft\RedColor.png"
        SetTimer(CancelTableItemStopState.Bind(tableIndex, itemIndex), -5000)
    }
    ColorCon.Visible := isVisible
}

CancelTableItemStopState(tableIndex, itemIndex) {
    tableItem := MySoftData.TableInfo[tableIndex]
    ColorState := tableItem.ColorStateArr[itemIndex]
    ColorCon := tableItem.ColorConArr[itemIndex]
    if (ColorCon.Visible && ColorState == 3) {
        ColorCon.Visible := false
        tableItem.ColorStateArr[itemIndex] := 0
    }
}

SetItemPauseState(tableIndex, itemIndex, state) {
    tableItem := MySoftData.TableInfo[tableIndex]
    tableItem.PauseArr[itemIndex] := state
    isWork := tableItem.IsWorkIndexArr[itemIndex]

    LastColorState := tableItem.ColorStateArr[itemIndex]
    if (LastColorState == 1 && state == 1)
        SetTableItemState(tableIndex, itemIndex, 2)
    else if (LastColorState == 2 && state == 0)
        SetTableItemState(tableIndex, itemIndex, 1)

    if (isWork) {
        workPath := MyWorkPool.GetWorkPath(tableItem.IsWorkIndexArr[itemIndex])
        str := Format("PauseState_{}_{}_{}", tableIndex, itemIndex, state)
        MyWorkPool.SendMessage(WM_COPYDATA, workPath, str)
    }
}

MsgBoxContent(content) {
    MySoftData.MyGui.Flash()
    SoundPlay "*-1"
    MyMsgboxGui.ShowGui(content)
    ; MsgBox(content)
}

MacroCount(content) {
    if (content == "Add") {
        MySoftData.MacroTotalCount += 1
    }
}

ToolTipContent(content) {
    MySoftData.ToolTipText := content
    MySoftData.ToolTipEndTime := A_TickCount + 5000  ; 设置5秒后结束的时间戳
    SetTimer(ToolTipTimer, 100)  ; 启动/重置定时器，每100ms执行一次
}

ToolTipTimer() {
    if (A_TickCount >= MySoftData.ToolTipEndTime) {
        ; 超过显示时间，隐藏ToolTip并停止定时器
        ToolTip
        SetTimer(ToolTipTimer, 0)
    } else {
        ; 仍在显示时间内，更新ToolTip
        ToolTip(MySoftData.ToolTipText)
    }
}

ExcuteRMTCMDAction(Cmd) {
    paramArr := StrSplit(Cmd, "_")
    cmdStr := paramArr[2]
    if (cmdStr == "截图") {
        OnToolScreenShot()
    }
    else if (cmdStr == "截图提取文本") {
        OnToolTextFilterScreenShot()
    }
    else if (cmdStr == "自由贴") {
        OnToolFreePaste()
    }
    else if (cmdStr == "开启指令显示") {
        MySoftData.CMDTipCtrl.Value := true
        MySoftData.CMDTip := true
        SetCMDTipValue(true)
        if (!IsObject(MyCMDTipGui.Gui))
            return
        MyCMDTipGui.ShowGui("开启指令显示")
    }
    else if (cmdStr == "关闭指令显示") {
        MySoftData.CMDTipCtrl.Value := false
        MySoftData.CMDTip := false
        SetCMDTipValue(false)
        if (!IsObject(MyCMDTipGui.Gui))
            return

        try {
            style := WinGetStyle(MyCMDTipGui.Gui.Hwnd)
            isVisible := (style & 0x10000000)  ; 0x10000000 = WS_VISIBLE
            if (isVisible)
                MyCMDTipGui.Gui.Hide()
        }
    }
    else if (cmdStr == "显示菜单") {
        OpenMenuWheel(paramArr[3])
    }
    else if (cmdStr == "关闭菜单") {
        CloseMenuWheel()
    }
    else if (cmdStr == "启用键鼠") {
        BlockInput false
    }
    else if (cmdStr == "禁用键鼠") {
        BlockInput true
    }
    else if (cmdStr == "休眠") {
        OnSuspendHotkey()
    }
    else if (cmdStr == "暂停所有宏") {
        SetPauseState(true)
    }
    else if (cmdStr == "恢复所有宏") {
        SetPauseState(false)
    }
    else if (cmdStr == "终止所有宏") {
        OnKillAllMacro()
    }
    else if (cmdStr == "重载") {
        MenuReload()
    }
    else if (cmdStr == "关闭软件") {
        ExitApp()
    }
}

ScreenShot(X1, Y1, X2, Y2, FileName) {
    width := X2 - X1
    height := Y2 - Y1
    pBitmap := Gdip_BitmapFromScreen(X1 "|" Y1 "|" width "|" height)
    Gdip_SaveBitmapToFile(pBitmap, FileName)
    ; 释放位图资源
    Gdip_DisposeImage(pBitmap)
}

OnToolTextFilterGetArea(x1, y1, x2, y2) {
    filePath := A_WorkingDir "\Images\ScreenShot\TextFilter.png"
    ScreenShot(x1, y1, x2, y2, filePath)
    ocr := ToolCheckInfo.OCRTypeCtrl.Value == 1 ? MyChineseOcr : MyEnglishOcr
    result := ocr.ocr_from_file(filePath)
    ToolCheckInfo.ToolTextCtrl.Value := result
    A_Clipboard := result
}

OnToolTextCheckScreenShot() {
    ; 如果剪贴板中有图像
    if DllCall("IsClipboardFormatAvailable", "uint", 8)  ; 8 是 CF_BITMAP 格式
    {
        filePath := A_WorkingDir "\Images\ScreenShot\TextFilter.png"
        SaveClipToBitmap(filePath)
        ocr := ToolCheckInfo.OCRTypeCtrl.Value == 1 ? MyChineseOcr : MyEnglishOcr
        result := ocr.ocr_from_file(filePath)
        ToolCheckInfo.ToolTextCtrl.Value := result
        A_Clipboard := result
        ; 停止监听
        SetTimer(, 0)
    }
}

TogGetSelectArea(isEnable, action := "") {
    if (isEnable && action != "") {
        MySoftData.GetAreaAction := action
    }
    else {
        MySoftData.GetAreaAction := ""
    }
}

OnGetSelectAreaDown(kye, *) {
    CoordMode("Mouse", "Screen")
    MouseGetPos(&startX, &startY)
    MySoftData.StartAreaPosX := startX
    MySoftData.StartAreaPosY := startY
}

OnGetSelectAreaUp(key, *) {
    action := MySoftData.GetAreaAction
    TogGetSelectArea(false)
    CoordMode("Mouse", "Screen")
    MouseGetPos(&endX, &endY)

    x1 := Min(MySoftData.StartAreaPosX, endX)
    y1 := Min(MySoftData.StartAreaPosY, endY)
    x2 := Max(MySoftData.StartAreaPosX, endX)
    y2 := Max(MySoftData.StartAreaPosY, endY)
    action(x1, y1, x2, y2)
}

TogSelectArea(isEnable, action := "") {
    if (isEnable && action != "") {
        MySoftData.SelectAreaAction := action
        ToolTipContent("请框选截图范围")
        actionDown := OnBindKeyDown.Bind("LButton")
        Hotkey("LButton", actionDown)
    }
    else {
        MySoftData.ToolTipEndTime := 0
        MySoftData.SelectAreaAction := ""
    }
}

SelectArea() {
    action := MySoftData.SelectAreaAction
    TogSelectArea(false)
    actionDown := OnBindKeyDown.Bind("LButton")
    Hotkey("~LButton", actionDown, "On")
    ; 获取起始点坐标
    startX := startY := endX := endY := 0
    CoordMode("Mouse", "Screen")
    MouseGetPos(&startX, &startY)

    ; 创建 GUI 用于绘制矩形框
    MyGui := Gui("+ToolWindow -Caption +AlwaysOnTop -DPIScale")
    MyGui.BackColor := "Red"
    WinSetTransColor(" 150", MyGui)
    MyGui.Opt("+LastFound")
    GuiHwnd := WinExist()

    ; 显示初始 GUI
    MyGui.Show("NA x" startX " y" startY " w1 h1")

    ; 跟踪鼠标移动
    while GetKeyState("LButton", "P") {
        CoordMode("Mouse", "Screen")
        MouseGetPos(&endX, &endY)
        width := Abs(endX - startX)
        height := Abs(endY - startY)
        x := Min(startX, endX)
        y := Min(startY, endY)

        MyGui.Show("NA x" x " y" y " w" width " h" height)
    }
    ; 销毁 GUI
    MyGui.Destroy()
    ; 返回坐标

    x1 := Min(startX, endX)
    y1 := Min(startY, endY)
    x2 := Max(startX, endX)
    y2 := Max(startY, endY)
    action(x1, y1, x2, y2)
}

;DataType 1:SearchData
RepairPath(SettingName, FilePath, DataType) {
    SymbolArr := ["Search"]
    Symbol := SymbolArr[DataType]
    if (!FileExist(FilePath))
        return false

    hasRepair := false
    loop read, FilePath {
        LineStr := A_LoopReadLine
        if (SubStr(LineStr, 1, StrLen(Symbol)) != Symbol)
            continue

        SerialStr := SubStr(LineStr, 1, StrLen(Symbol) + 7)
        saveStr := IniRead(FilePath, IniSection, SerialStr, "")
        Data := JSON.parse(saveStr, , false)

        if (Data == "")
            continue

        if (DataType == 1 && Data.SearchImagePath != "") {
            StartPos := InStr(Data.SearchImagePath, "Setting", 1)
            SubPath := SubStr(Data.SearchImagePath, StartPos)
            NewPath1 := A_WorkingDir "\" SubPath

            FileNameArr := StrSplit(NewPath1, "\")
            NewPath2 := ""
            for index, value in FileNameArr {
                if (value == "Setting" && index + 2 <= FileNameArr.Length && FileNameArr[index + 2] == "Images") {
                    FileNameArr[index + 1] := SettingName
                }
                NewPath2 .= value "\"
            }

            NewPath := RTrim(NewPath2, "\")
            if (FileExist(NewPath)) {
                Data.SearchImagePath := NewPath
                saveStr := JSON.stringify(Data, 0)
                IniWrite(saveStr, SearchProFile, IniSection, Data.SerialStr)
                if (MySoftData.DataCacheMap.Has(Data.SerialStr)) {
                    MySoftData.DataCacheMap.Delete(Data.SerialStr)
                }
                hasRepair := true
            }
        }
    }
    return hasRepair
}

SimpleRecordMacroStr(MacroStr) {
    CmdArr := SplitMacro(MacroStr)
    SimpleCmdArr := []
    loop CmdArr.Length {
        paramArr := SplitKeyCommand(CmdArr[A_Index])
        isPressKey := paramArr[1] == "按键" && paramArr[3] == 1
        if (isPressKey && A_Index + 1 < CmdArr.Length) {
            next1ParamArr := SplitKeyCommand(CmdArr[A_Index + 1])
            next2ParamArr := SplitKeyCommand(CmdArr[A_Index + 2])
            isMatchFormat := next1ParamArr[1] == "间隔" && next2ParamArr[1] == "按键"
            if (isMatchFormat && paramArr[2] == next2ParamArr[2] && next2ParamArr[3] == 2) {
                SimpleCmdStr := Format("按键_{}_3_{}", paramArr[2], next1ParamArr[2])
                SimpleCmdArr.Push(SimpleCmdStr)
                A_Index := A_Index + 2
                continue
            }
        }
        SimpleCmdArr.Push(CmdArr[A_Index])
    }

    return GetMacroStrByCmdArr(SimpleCmdArr)
}

DiscardRecordTriggerKey(MacroStr, isFront) {
    triggerMap := GetRecordTriggerKeyMap()
    CmdArr := SplitMacro(MacroStr)
    SimpleCmdArr := []
    hasDiscard := false
    loop CmdArr.Length {
        cmd := isFront ? CmdArr[A_Index] : CmdArr[CmdArr.Length - A_Index + 1]

        if (!hasDiscard) {
            if (isFront && MySoftData.IsTogStartRecord) {
                hasDiscard := true
            }
            else if (!isFront && MySoftData.IsTogEndRecord) {
                hasDiscard := true
            }
            else {
                if (InStr(cmd, "间隔"))
                    continue

                if (CheckIfDiscardCMD(triggerMap, cmd))
                    continue

                hasDiscard := true
            }
        }

        if (isFront)
            SimpleCmdArr.Push(cmd)
        else
            SimpleCmdArr.InsertAt(1, cmd)
    }

    return GetMacroStrByCmdArr(SimpleCmdArr)
}

CheckIfDiscardCMD(triggerMap, cmd) {
    if (!InStr(cmd, "按键"))
        return false

    paramArr := SplitKeyCommand(cmd)
    if (triggerMap.Has(paramArr[2]) && triggerMap[paramArr[2]] < 2) {
        triggerMap[paramArr[2]] += 1
        return true
    }

    return false
}

FullCopyCmd(cmd, CopyedMap := Map()) {
    paramArr := SplitKeyCommand(cmd)
    if (InStr(paramArr[1], "间隔"))
        return cmd
    if (InStr(paramArr[1], "按键"))
        return cmd
    if (paramArr[1] == "移动")
        return cmd
    if (InStr(paramArr[1], "RMT指令"))
        return cmd

    if (CopyedMap.Has(paramArr[2])) {
        paramArr[2] := CopyedMap[paramArr[2]]
        return GetCmdByParams(paramArr)
    }

    DataFileMap := Map("搜索", SearchFile, "搜索Pro", SearchProFile, "移动Pro", MMProFile,
        "输出", OutputFile, "运行", RunFile, "变量", VariableFile, "变量提取", ExVariableFile, "运算", OperationFile,
        "如果", CompareFile, "宏操作", SubMacroFile, "后台鼠标", BGMouseFile)

    dataFile := DataFileMap[paramArr[1]]
    Data := GetMacroCMDData(dataFile, paramArr[2])
    Data.SerialStr := SubStr(Data.SerialStr, 1, StrLen(Data.SerialStr) - 7) GetRandomStr(7)
    CopyedMap.Set(paramArr[2], Data.SerialStr)
    paramArr[2] := Data.SerialStr

    if (ObjHasOwnProp(Data, "TrueMacro")) {
        Data.TrueMacro := FullCopyMacro(Data.TrueMacro, CopyedMap)
    }

    if (ObjHasOwnProp(Data, "FalseMacro")) {
        Data.FalseMacro := FullCopyMacro(Data.FalseMacro, CopyedMap)
    }
    saveStr := JSON.stringify(Data, 0)
    IniWrite(saveStr, dataFile, IniSection, Data.SerialStr)

    return GetCmdByParams(paramArr)
}

FullCopyMacro(MacroStr, CopyedMap) {
    if (MacroStr == "")
        return MacroStr
    cmdArr := SplitMacro(MacroStr)
    loop cmdArr.Length {
        cmdArr[A_Index] := FullCopyCmd(cmdArr[A_Index], CopyedMap)
    }

    result := ""
    for index, value in cmdArr {
        result .= value
        if (index != cmdArr.Length)
            result .= ","
    }
    return result
}

GetPixelColorMap(CentPosX, CentPosY, Row, Col) {
    width := Col
    height := Row
    PosX := Integer(CentPosX - (Col - 1) / 2)
    PosY := Integer(CentPosY - (Row - 1) / 2)
    pBitmap := Gdip_BitmapFromScreen(PosX "|" PosY "|" width "|" height)
    ResultMap := Map()
    loop Row {
        rowValue := A_Index
        loop Col {
            colValue := A_Index
            Value := Gdip_GetPixel(pBitmap, colValue - 1, rowValue - 1)
            Key := Format("{}-{}", colValue, rowValue)
            RGB_Value := Value & 0xFFFFFF  ; 移除Alpha通道，保留RGB
            hexStr := Format("0x{:X}", RGB_Value)
            ResultMap.Set(Key, hexStr)
        }
    }
    return ResultMap
}

SavePixelImage(PosX, PosY, SavePath) {
    ; 创建位图
    RowNum := 9
    ColNum := 13
    width := 130, height := 90
    pBitmap := Gdip_CreateBitmap(width, height)
    G := Gdip_GraphicsFromImage(pBitmap)
    CoordMode("Pixel", "Screen")

    loop RowNum {
        RowValue := A_Index
        loop ColNum {
            ColValue := A_Index

            CurPosX := PosX - (ColNum - 1) / 2 + ColValue
            CurPosY := PosY - (RowNum - 1) / 2 + RowValue
            ColorValue := PixelGetColor(CurPosX, CurPosY)
            ColorValue := "0xFF" SubStr(ColorValue, 3)
            pBrush := Gdip_BrushCreateSolid(ColorValue)
            Gdip_FillRectangle(G, pBrush, (ColValue - 1) * 10, (RowValue - 1) * 10, 10, 10)
            Gdip_DeleteBrush(pBrush)
        }
    }

    ; 保存临时图片文件
    Gdip_SaveBitmapToFile(pBitmap, SavePath)

    ; 清理资源
    Gdip_DeleteGraphics(G)
    Gdip_DisposeImage(pBitmap)
}

FormatIntegerWithCommas(num) {
    return RegExReplace(num, "(\d)(?=(\d{3})+$)", "$1,")
}

OpenMenuWheel(MenuIndex) {
    if (MySoftData.CurMenuWheelIndex == MenuIndex)
        return

    MySoftData.CurMenuWheelIndex := MenuIndex
    MyMenuWheel.ShowGui(MenuIndex)
}

CloseMenuWheel() {
    MySoftData.CurMenuWheelIndex := -1
    if (!IsObject(MyMenuWheel.Gui))
        return

    style := WinGetStyle(MyMenuWheel.Gui.Hwnd)
    isVisible := (style & 0x10000000)  ; 0x10000000 = WS_VISIBLE
    if (isVisible) {
        MyMenuWheel.ToggleFunc(false)
        MyMenuWheel.Gui.Hide()
    }

}
