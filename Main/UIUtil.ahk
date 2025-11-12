;窗口&UI刷新
InitUI() {
    global MySoftData
    MyGui := Gui()
    MyGui.Title := "RMTv1.0.8"
    MyGui.SetFont("S10 W550 Q2", MySoftData.FontType)
    isValidCollor := RegExMatch(MySoftData.SoftBGColor, "^([0-9A-Fa-f]{6})$")
    BGColor := isValidCollor ? MySoftData.SoftBGColor : "f0f0f0"
    if (BGColor != "f0f0f0")
        MyGui.BackColor := BGColor

    MySoftData.MyGui := MyGui
    AddUI()
    CustomTrayMenu()
    OnOpen()

}

OnOpen() {
    global MySoftData
    if (!MySoftData.AgreeAgreement) {
        AgreeAgreementStr :=
            '1. 本软件按"原样"提供，开发者不承担因使用、修改或分发导致的任何法律责任。`n2. 严禁用于违法用途，包括但不限于:游戏作弊、未经授权的系统访问或数据篡改`n3. 使用者需自行承担所有风险，开发者对因违反法律或第三方条款导致的后果概不负责。`n4. 通过使用本软件，您确认：不会将其用于任何非法目的、已充分了解并接受所有潜在法律风险、同意免除开发者因滥用行为导致的一切追责权利`n若不同意上述条款，请立即停止使用本软件。'
        result := MsgBox(AgreeAgreementStr, "免责声明", "4")
        if (result == "No")
            ExitApp()
        IniWrite(true, IniFile, IniSection, "AgreeAgreement")
    }

    if (!MySoftData.IsExecuteShow && !MySoftData.IsReload)
        return

    RefreshGui()
}

RefreshGui() {
    IniWrite(false, IniFile, IniSection, "IsReload")
    if (MySoftData.IsReload) {
        LastWinPosStr := IniRead(IniFile, IniSection, "LastWinPos", "")
        WinPosArr := StrSplit(LastWinPosStr, "π")
        if (WinPosArr.Length == 2 && IsNumber(WinPosArr[1]) && IsNumber(WinPosArr[2])) {
            isXValid := WinPosArr[1] > 0 && WinPosArr[1] < A_ScreenWidth
            isYValid := WinPosArr[2] > 0 && WinPosArr[2] < A_ScreenHeight
            if (isXValid && isYValid) {
                MySoftData.MyGui.Show(Format("x{} y{} w{} h{}", WinPosArr[1], WinPosArr[2], 1070, 590))
                return
            }
        }
    }
    if (MySoftData.LastShowMonth != A_Mon) {
        MySoftData.TabCtrl.Value := 9
        MySoftData.LastShowMonth := A_Mon
        IniWrite(MySoftData.LastShowMonth, IniFile, IniSection, "LastShowMonth")
    }

    MySoftData.MyGui.Show(Format("w{} h{}", 1070, 590))
}

RefreshToolUI() {
    global ToolCheckInfo

    ToolCheckInfo.ToolMousePosCtrl.Value := ToolCheckInfo.PosStr
    ToolCheckInfo.ToolProcessNameCtrl.Value := ToolCheckInfo.ProcessName
    ToolCheckInfo.ToolProcessTileCtrl.Value := ToolCheckInfo.ProcessTile
    ToolCheckInfo.ToolProcessPidCtrl.Value := ToolCheckInfo.ProcessPid
    ToolCheckInfo.ToolProcessClassCtrl.Value := ToolCheckInfo.ProcessClass
    ToolCheckInfo.ToolProcessIdCtrl.Value := ToolCheckInfo.ProcessId
    ToolCheckInfo.ToolColorCtrl.Value := ToolCheckInfo.Color
    ToolCheckInfo.ToolMouseWinPosCtrl.Value := ToolCheckInfo.WinPosStr
}

;UI元素相关函数
AddUI() {
    global MySoftData
    MyGui := MySoftData.MyGui
    AddOperBtnUI()
    MySoftData.TabPosY := 10
    MySoftData.TabPosX := 130
    MySoftData.TabCtrl := MyGui.Add("Tab3", Format("x{} y{} w{} Choose{}", MySoftData.TabPosX, MySoftData.TabPosY, 910,
        MySoftData.TableIndex), MySoftData.TabNameArr)

    loop MySoftData.TabNameArr.Length {
        MySoftData.TabCtrl.UseTab(A_Index)
        func := GetUIAddFunc(A_Index)
        func(A_Index)
    }
    MySoftData.TabCtrl.UseTab()
    MySoftData.TabCtrl.Move(MySoftData.TabPosX, MySoftData.TabPosY, 920, 570)
    MySoftData.TabCtrl.OnEvent("Change", OnTabValueChanged)
    AddSliderUI()
}

AddSliderUI() {
    MyGui := MySoftData.MyGui
    areaCon := MyGui.Add("Pic", Format("x{} y{} w{} h{} +Background0x{}", 1045, 37, 15, 541, "d1d1d1"), "")
    barCon := MyGui.Add("Text", Format("x{} y{} w{} h{} +Background0x{}", 1045, 37, 15, 250, "9f9f9f"), "")
    tableItem := MySoftData.TableInfo[MySoftData.TableIndex]
    MySlider.SetSliderCon(areaCon, barCon)
    MySlider.SetStyleParams(2, 2)
    MySlider.SwitchTab(tableItem)
}

AddOperBtnUI() {
    MyGui := MySoftData.MyGui
    posY := 10
    con := MyGui.Add("GroupBox", Format("x{} y{} w{} h{} center", 10, posY, 110, 95), "当前配置")

    ; 当前配置
    posY += 25
    con := MyGui.Add("Text", Format("x{} y{} w{} h{} Center", 15, posY, 100, 40), MySoftData.CurSettingName)
    posY += 30
    con := MyGui.Add("Button", Format("x{} y{} w{} h{} center", 15, posY, 100, 30), "配置管理")
    con.OnEvent("Click", (*) => MySettingMgrGui.ShowGui())

    posY += 50
    con := MyGui.Add("GroupBox", Format("x{} y{} w{} h{} center", 10, posY, 110, 465), "全局操作")

    posY += 25
    ; 休眠
    MySoftData.SuspendToggleCtrl := MyGui.Add("CheckBox", Format("x{} y{} w{} h{}", 15, posY, 100, 20), "休眠")
    MySoftData.SuspendToggleCtrl.Value := MySoftData.IsSuspend
    MySoftData.SuspendToggleCtrl.OnEvent("Click", OnSuspendHotkey)
    posY += 20
    CtrlType := GetHotKeyCtrlType(MySoftData.SuspendHotkey)
    con := MyGui.Add(CtrlType, Format("x{} y{} w{}", 15, posY, 100), MySoftData.SuspendHotkey)
    con.Enabled := false
    posY += 40

    ; 暂停
    MySoftData.PauseToggleCtrl := MyGui.Add("CheckBox", Format("x{} y{} w{} h{}", 15, posY, 100, 20), "暂停")
    MySoftData.PauseToggleCtrl.Value := MySoftData.IsPause
    MySoftData.PauseToggleCtrl.OnEvent("Click", OnPauseHotKey)
    posY += 20
    CtrlType := GetHotKeyCtrlType(MySoftData.PauseHotkey)
    con := MyGui.Add(CtrlType, Format("x{} y{} w{}", 15, posY, 100), MySoftData.PauseHotkey)
    con.Enabled := false
    posY += 40

    ;终止模块
    con := MyGui.Add("Button", Format("x{} y{} w{} h{} center", 15, posY, 100, 30), "终止所有宏")
    con.OnEvent("Click", OnKillAllMacro)
    posY += 31
    CtrlType := GetHotKeyCtrlType(MySoftData.KillMacroHotkey)
    con := MyGui.Add(CtrlType, Format("x{} y{} w{}", 15, posY, 100), MySoftData.KillMacroHotkey)
    con.Enabled := false
    posY += 40

    ReloadBtnCtrl := MyGui.Add("Button", Format("x{} y{} w{} h{} center", 15, posY, 100, 30), "重载")
    ReloadBtnCtrl.OnEvent("Click", MenuReload)
    posY += 40

    posY := 540
    MySoftData.BtnSave := MyGui.Add("Button", Format("x{} y{} w{} h{} center", 15, posY, 100, 30), "应用并保存")
    MySoftData.BtnSave.OnEvent("Click", OnSaveSetting)

    MyTriggerKeyGui.SureFocusCon := MySoftData.BtnSave
    MyTriggerStrGui.SureFocusCon := MySoftData.BtnSave
    MyMacroGui.SureFocusCon := MySoftData.BtnSave
    MyReplaceKeyGui.SureFocusCon := MySoftData.BtnSave
}

GetUIAddFunc(index) {
    UIAddFuncArr := [LoadItemFold, LoadItemFold, LoadItemFold, LoadItemFold, LoadItemFold, LoadItemFold,
        AddToolUI, AddSettingUI, AddHelpUI, AddRewardUI, AddThankUI]
    return UIAddFuncArr[index]
}

;工具
AddToolUI(index) {
    global ToolCheckInfo

    MyGui := MySoftData.MyGui
    tableItem := MySoftData.TableInfo[index]
    posY := MySoftData.TabPosY
    posX := MySoftData.TabPosX
    ; 配置规则说明
    posY += 35
    con := MyGui.Add("Text", Format("x{} y{}", posX + 20, posY), "鼠标信息：")
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    isHotKey := CheckIsNormalHotKey(ToolCheckInfo.ToolCheckHotkey)
    CtrlType := isHotKey ? "Hotkey" : "Text"
    con := MyGui.Add(CtrlType, Format("x{} y{} w{}", posX + 120, posY - 3, 130), ToolCheckInfo.ToolCheckHotkey)
    con.Enabled := false
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    con := MyGui.Add("CheckBox", Format("x{} y{}", posX + 260, posY, 60), "开关")
    ToolCheckInfo.ToolCheckCtrl := con
    ToolCheckInfo.ToolCheckCtrl.Value := ToolCheckInfo.IsToolCheck
    ToolCheckInfo.ToolCheckCtrl.OnEvent("Click", OnToolCheckHotkey)
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    con := MyGui.Add("CheckBox", Format("x{} y{}", posX + 400, posY, 60), "窗口置顶")
    ToolCheckInfo.AlwaysOnTopCtrl := con
    ToolCheckInfo.AlwaysOnTopCtrl.Value := false
    ToolCheckInfo.AlwaysOnTopCtrl.OnEvent("Click", OnToolAlwaysOnTop)
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posY += 35
    con := MyGui.Add("Text", Format("x{} y{}", posX + 20, posY), "屏幕坐标：")
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    con := MyGui.Add("Edit", Format("x{} y{} w240", posX + 120, posY - 5), ToolCheckInfo.PosStr)
    ToolCheckInfo.ToolMousePosCtrl := con
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    con := MyGui.Add("Text", Format("x{} y{}", posX + 400, posY), "窗口坐标：")
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    con := MyGui.Add("Edit", Format("x{} y{} w240", posX + 480, posY - 5), ToolCheckInfo.WinPosStr)
    ToolCheckInfo.ToolMouseWinPosCtrl := con
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posY += 35
    con := MyGui.Add("Text", Format("x{} y{}", posX + 20, posY), "进程窗口标题：")
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    con := MyGui.Add("Edit", Format("x{} y{} w240", posX + 120, posY - 5), ToolCheckInfo.ProcessTile)
    ToolCheckInfo.ToolProcessTileCtrl := con
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    con := MyGui.Add("Text", Format("x{} y{}", posX + 400, posY), "进程名：")
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    con := MyGui.Add("Edit", Format("x{} y{} w240", posX + 480, posY - 5), ToolCheckInfo.ProcessName)
    ToolCheckInfo.ToolProcessNameCtrl := con
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posY += 35
    con := MyGui.Add("Text", Format("x{} y{}", posX + 20, posY), "进程窗口类：")
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    con := MyGui.Add("Edit", Format("x{} y{} w240", posX + 120, posY - 5), ToolCheckInfo.ProcessClass)
    ToolCheckInfo.ToolProcessClassCtrl := con
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    con := MyGui.Add("Text", Format("x{} y{}", posX + 400, posY), "进程PID:")
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    con := MyGui.Add("Edit", Format("x{} y{} w240", posX + 480, posY - 5), ToolCheckInfo.ProcessPid)
    ToolCheckInfo.ToolProcessPidCtrl := con
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posY += 35
    con := MyGui.Add("Text", Format("x{} y{}", posX + 20, posY), "句柄Id:")
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    con := MyGui.Add("Edit", Format("x{} y{} w240", posX + 120, posY - 5), ToolCheckInfo.ProcessId)
    ToolCheckInfo.ToolProcessIdCtrl := con
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    con := MyGui.Add("Text", Format("x{} y{}", posX + 400, posY), "位置颜色：")
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    con := MyGui.Add("Edit", Format("x{} y{} w240", posX + 480, posY - 5), ToolCheckInfo.Color)
    ToolCheckInfo.ToolColorCtrl := con
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posY += 40
    con := MyGui.Add("Text", Format("x{} y{}", posX + 20, posY), "截图和自由贴：")
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    isHotKey := CheckIsNormalHotKey(ToolCheckInfo.ScreenShotHotKey)
    CtrlType := isHotKey ? "Hotkey" : "Text"
    con := MyGui.Add(CtrlType, Format("x{} y{} w{}", posX + 120, posY - 3, 130), ToolCheckInfo.ScreenShotHotKey
    )
    con.Enabled := false
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    con := MyGui.Add("Button", Format("x{} y{} w{}", posX + 260, posY - 5, 100), "截图")
    con.OnEvent("Click", OnToolScreenShot)
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    isHotKey := CheckIsNormalHotKey(ToolCheckInfo.FreePasteHotKey)
    CtrlType := isHotKey ? "Hotkey" : "Text"
    con := MyGui.Add(CtrlType, Format("x{} y{} w{}", posX + 400, posY - 3, 130), ToolCheckInfo.FreePasteHotKey
    )
    con.Enabled := false
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    con := MyGui.Add("Button", Format("x{} y{} w{}", posX + 540, posY - 5, 100), "自由贴")
    con.OnEvent("Click", OnToolFreePaste)
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posY += 40
    con := MyGui.Add("Text", Format("x{} y{}", posX + 20, posY), "指令录制：")
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    isHotKey := CheckIsNormalHotKey(ToolCheckInfo.ToolRecordMacroHotKey)
    CtrlType := isHotKey ? "Hotkey" : "Text"
    con := MyGui.Add(CtrlType, Format("x{} y{} w{}", posX + 120, posY - 3, 130), ToolCheckInfo.ToolRecordMacroHotKey
    )
    con.Enabled := false
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    con := MyGui.Add("CheckBox", Format("x{} y{}", posX + 260, posY, 60), "开关")
    ToolCheckInfo.ToolCheckRecordMacroCtrl := con
    ToolCheckInfo.ToolCheckRecordMacroCtrl.Value := ToolCheckInfo.IsToolRecord
    ToolCheckInfo.ToolCheckRecordMacroCtrl.OnEvent("Click", OnHotToolRecordMacro.Bind(false))
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    con := MyGui.Add("Button", Format("x{} y{} w{}", posX + 400, posY - 5, 100), "录制选项")
    con.OnEvent("Click", OnClickToolRecordSettingBtn)
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posY += 40
    con := MyGui.Add("Text", Format("x{} y{}", posX + 20, posY), "图片文本提取：")
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    isHotKey := CheckIsNormalHotKey(ToolCheckInfo.ToolTextFilterHotKey)
    CtrlType := isHotKey ? "Hotkey" : "Text"
    con := MyGui.Add(CtrlType, Format("x{} y{} w{}", posX + 120, posY - 3, 130), ToolCheckInfo.ToolTextFilterHotKey
    )
    con.Enabled := false
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    con := MyGui.Add("Button", Format("x{} y{} w{}", posX + 260, posY - 5, 100), "截图提取文本")
    con.OnEvent("Click", OnToolTextFilterScreenShot)
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    con := MyGui.Add("Button", Format("x{} y{} w{}", posX + 400, posY - 5, 120), "从图片提取文本")
    con.OnEvent("Click", OnToolTextFilterSelectImage)
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posY += 35
    con := MyGui.Add("Text", Format("x{} y{}", posX + 20, posY), "相关选项：")
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    con := MyGui.Add("Text", Format("x{} y{} w{}", PosX + 120, PosY, 110), "文本识别模型:")
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    con := MyGui.Add("DropDownList", Format("x{} y{} w{}", PosX + 260, PosY - 5, 100), [
        "中文",
        "英文"])
    ToolCheckInfo.OCRTypeCtrl := con
    ToolCheckInfo.OCRTypeCtrl.Value := ToolCheckInfo.OCRTypeValue
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posY += 40
    con := MyGui.Add("Text", Format("x{} y{}", posX + 20, posY), "录制的指令或提取的文本内容：")
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    con := MyGui.Add("Button", Format("x{} y{} w{} h{}", posX + 260, posY - 5, 80, 25), "清空内容")
    con.OnEvent("Click", OnClearToolText)
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posY += 25
    con := ToolCheckInfo.ToolTextCtrl := MyGui.Add("Edit", Format("x{} y{} w{} h{}", posX + 20, posY, 800, 100), "")
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posY += 20
    MySoftData.TableInfo[index].underPosY := posY
}

;设置
AddSettingUI(index) {
    MyGui := MySoftData.MyGui
    tableItem := MySoftData.TableInfo[index]
    posY := MySoftData.TabPosY
    posX := MySoftData.TabPosX

    posY += 30
    posX := MySoftData.TabPosX
    con := MyGui.Add("GroupBox", Format("x{} y{} w870 h140", posX + 10, posY), "快捷键修改")
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    tableItem.AllGroup.Push(con)

    posY += 30
    con := MyGui.Add("Text", Format("x{} y{}", posX + 25, posY), "软件休眠:")
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    CtrlType := GetHotKeyCtrlType(MySoftData.SuspendHotkey)
    showCon := MyGui.Add(CtrlType, Format("x{} y{} w130", posX + 100, posY - 4), MySoftData.SuspendHotkey)
    showCon.Enabled := false
    conInfo := ItemConInfo(showCon, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    con := MyGui.Add("Text", Format("x{} y{} w130", posX + 100, posY), MySoftData.SuspendHotkey)
    MySoftData.SuspendHotkeyCtrl := con
    MySoftData.SuspendHotkeyCtrl.Visible := false
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    con := MyGui.Add("Button", Format("x{} y{} w50", posX + 235, posY - 5), "编辑")
    con.OnEvent("Click", OnOpenEditHotkeyGui.Bind(showCon, MySoftData.SuspendHotkeyCtrl, true))
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    con := MyGui.Add("Text", Format("x{} y{}", posX + 315, posY), "暂停宏:")
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    CtrlType := GetHotKeyCtrlType(MySoftData.PauseHotkey)
    showCon := MyGui.Add(CtrlType, Format("x{} y{} w130", posX + 385, posY - 4), MySoftData.PauseHotkey)
    showCon.Enabled := false
    conInfo := ItemConInfo(showCon, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    con := MyGui.Add("Text", Format("x{} y{} w130", posX + 385, posY), MySoftData.PauseHotkey)
    MySoftData.PauseHotkeyCtrl := con
    MySoftData.PauseHotkeyCtrl.Visible := false
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    con := MyGui.Add("Button", Format("x{} y{} center w50", posX + 520, posY - 5), "编辑")
    con.OnEvent("Click", OnOpenEditHotkeyGui.Bind(showCon, MySoftData.PauseHotkeyCtrl, false))
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    con := MyGui.Add("Text", Format("x{} y{}", posX + 605, posY), "终止宏:")
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    CtrlType := GetHotKeyCtrlType(MySoftData.KillMacroHotkey)
    showCon := MyGui.Add(CtrlType, Format("x{} y{} w130", posX + 680, posY - 4), MySoftData.KillMacroHotkey)
    showCon.Enabled := false
    conInfo := ItemConInfo(showCon, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    con := MyGui.Add("Text", Format("x{} y{} w130", posX + 680, posY), MySoftData.KillMacroHotkey)
    MySoftData.KillMacroHotkeyCtrl := con
    MySoftData.KillMacroHotkeyCtrl.Visible := false
    con := MyGui.Add("Button", Format("x{} y{} center w50", posX + 815, posY - 5), "编辑")
    con.OnEvent("Click", OnOpenEditHotkeyGui.Bind(showCon, MySoftData.KillMacroHotkeyCtrl, false))
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posY += 40
    con := MyGui.Add("Text", Format("x{} y{}", posX + 25, posY), "指令录制:")
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    CtrlType := GetHotKeyCtrlType(ToolCheckInfo.ToolRecordMacroHotKey)
    showCon := MyGui.Add(CtrlType, Format("x{} y{} w130", posX + 100, posY - 4),
    ToolCheckInfo.ToolRecordMacroHotKey)
    showCon.Enabled := false
    conInfo := ItemConInfo(showCon, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    con := MyGui.Add("Text", Format("x{} y{} w130", posX + 100, posY), ToolCheckInfo.ToolRecordMacroHotKey)
    ToolCheckInfo.ToolRecordMacroHotKeyCtrl := con
    ToolCheckInfo.ToolRecordMacroHotKeyCtrl.Visible := false
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    con := MyGui.Add("Button", Format("x{} y{} center w50", posX + 235, posY - 5), "编辑")
    con.OnEvent("Click", OnOpenEditHotkeyGui.Bind(showCon, ToolCheckInfo.ToolRecordMacroHotKeyCtrl, false))
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    con := MyGui.Add("Text", Format("x{} y{}", posX + 315, posY), "文本提取:")
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    CtrlType := GetHotKeyCtrlType(ToolCheckInfo.ToolTextFilterHotKey)
    showCon := MyGui.Add(CtrlType, Format("x{} y{} w130", posX + 385, posY - 4),
    ToolCheckInfo.ToolTextFilterHotKey)
    showCon.Enabled := false
    conInfo := ItemConInfo(showCon, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    con := MyGui.Add("Text", Format("x{} y{} w130", posX + 385, posY), ToolCheckInfo.ToolTextFilterHotKey)
    ToolCheckInfo.ToolTextFilterHotKeyCtrl := con
    ToolCheckInfo.ToolTextFilterHotKeyCtrl.Visible := false
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    con := MyGui.Add("Button", Format("x{} y{} center w50", posX + 520, posY - 5), "编辑")
    con.OnEvent("Click", OnOpenEditHotkeyGui.Bind(showCon, ToolCheckInfo.ToolTextFilterHotKeyCtrl, false))
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    con := MyGui.Add("Text", Format("x{} y{}", posX + 605, posY), "屏幕截图:")
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    CtrlType := GetHotKeyCtrlType(ToolCheckInfo.ScreenShotHotKey)
    showCon := MyGui.Add(CtrlType, Format("x{} y{} w130", posX + 680, posY - 4),
    ToolCheckInfo.ScreenShotHotKey)
    showCon.Enabled := false
    conInfo := ItemConInfo(showCon, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    con := MyGui.Add("Text", Format("x{} y{} w130", posX + 680, posY), ToolCheckInfo.ScreenShotHotKey)
    ToolCheckInfo.ScreenShotHotKeyCtrl := con
    ToolCheckInfo.ScreenShotHotKeyCtrl.Visible := false
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    con := MyGui.Add("Button", Format("x{} y{} center w50", posX + 815, posY - 5), "编辑")
    con.OnEvent("Click", OnOpenEditHotkeyGui.Bind(showCon, ToolCheckInfo.ScreenShotHotKeyCtrl, false))
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posY += 40
    con := MyGui.Add("Text", Format("x{} y{}", posX + 25, posY), "自由贴:")
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    CtrlType := GetHotKeyCtrlType(ToolCheckInfo.FreePasteHotKey)
    showCon := MyGui.Add(CtrlType, Format("x{} y{} w130", posX + 100, posY - 4),
    ToolCheckInfo.FreePasteHotKey)
    showCon.Enabled := false
    conInfo := ItemConInfo(showCon, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    con := MyGui.Add("Text", Format("x{} y{} w130", posX + 100, posY), ToolCheckInfo.FreePasteHotKey)
    ToolCheckInfo.FreePasteHotKeyCtrl := con
    ToolCheckInfo.FreePasteHotKeyCtrl.Visible := false
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    con := MyGui.Add("Button", Format("x{} y{} center w50", posX + 235, posY - 5), "编辑")
    con.OnEvent("Click", OnOpenEditHotkeyGui.Bind(showCon, ToolCheckInfo.FreePasteHotKeyCtrl, false))
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    con := MyGui.Add("Text", Format("x{} y{}", posX + 315, posY), "鼠标信息:")
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    CtrlType := GetHotKeyCtrlType(ToolCheckInfo.ToolCheckHotkey)
    showCon := MyGui.Add(CtrlType, Format("x{} y{} w130", posX + 385, posY - 4),
    ToolCheckInfo.ToolCheckHotkey)
    showCon.Enabled := false
    conInfo := ItemConInfo(showCon, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    con := MyGui.Add("Text", Format("x{} y{} w130", posX + 385, posY), ToolCheckInfo.ToolCheckHotkey)
    ToolCheckInfo.ToolCheckHotKeyCtrl := con
    ToolCheckInfo.ToolCheckHotKeyCtrl.Visible := false
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    con := MyGui.Add("Button", Format("x{} y{} center w50", posX + 520, posY - 5), "编辑")
    con.OnEvent("Click", OnOpenEditHotkeyGui.Bind(showCon, ToolCheckInfo.ToolCheckHotKeyCtrl, false))
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posY += 40
    posX := MySoftData.TabPosX
    con := MyGui.Add("GroupBox", Format("x{} y{} w870 h140", posX + 10, posY), "数值选项")
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    tableItem.AllGroup.Push(con)
    posY += 30
    con := MyGui.Add("Text", Format("x{} y{}", posX + 25, posY), "按住时间浮动(%):")
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    con := MyGui.Add("Edit", Format("x{} y{} w100 center", posX + 145, posY - 4), MySoftData.HoldFloat)
    MySoftData.HoldFloatCtrl := con
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    con := MyGui.Add("Text", Format("x{} y{}", posX + 315, posY), "每次间隔浮动(%):")
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    con := MyGui.Add("Edit", Format("x{} y{} w100 center", posX + 440, posY - 4), MySoftData.PreIntervalFloat)
    MySoftData.PreIntervalFloatCtrl := con
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    con := MyGui.Add("Text", Format("x{} y{}", posX + 635, posY), "间隔指令浮动(%):")
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    con := MyGui.Add("Edit", Format("x{} y{} w100 center", posX + 760, posY - 4), MySoftData.IntervalFloat)
    MySoftData.IntervalFloatCtrl := con
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posY += 40
    con := MyGui.Add("Text", Format("x{} y{}", posX + 25, posY), "坐标X浮动(px):")
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    con := MyGui.Add("Edit", Format("x{} y{} w100 center", posX + 145, posY - 4), MySoftData.CoordXFloat)
    MySoftData.CoordXFloatCon := con
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    con := MyGui.Add("Text", Format("x{} y{}", posX + 315, posY), "坐标Y浮动(px):")
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    con := MyGui.Add("Edit", Format("x{} y{} w100 center", posX + 440, posY - 4), MySoftData.CoordYFloat)
    MySoftData.CoordYFloatCon := con
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    con := MyGui.Add("Text", Format("x{} y{}", posX + 635, posY), "多线程数(0~5):")
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    con := MyGui.Add("Edit", Format("x{} y{} w100 center", posX + 760, posY - 4), MySoftData.MutiThreadNum)
    MySoftData.MutiThreadNumCtrl := con
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posY += 40
    con := MyGui.Add("Text", Format("x{} y{}", posX + 25, posY), "软件背景颜色:")
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    con := MyGui.Add("Edit", Format("x{} y{} w100 center", posX + 145, posY - 4), MySoftData.SoftBGColor)
    MySoftData.SoftBGColorCon := con
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posY += 40
    con := MyGui.Add("GroupBox", Format("x{} y{} w870 h100", posX + 10, posY), "开关选项")
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    tableItem.AllGroup.Push(con)
    posY += 30
    con := MyGui.Add("CheckBox", Format("x{} y{}", posX + 25, posY), "运行后显示窗口")
    MySoftData.ShowWinCtrl := con
    MySoftData.ShowWinCtrl.Value := MySoftData.IsExecuteShow
    MySoftData.ShowWinCtrl.OnEvent("Click", OnShowWinChanged)
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    con := MyGui.Add("CheckBox", Format("x{} y{}", posX + 315, posY), "开机自启")
    MySoftData.BootStartCtrl := con
    MySoftData.BootStartCtrl.Value := MySoftData.IsBootStart
    MySoftData.BootStartCtrl.OnEvent("Click", OnBootStartChanged)
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    con := MyGui.Add("CheckBox", Format("x{} y{} -Wrap w15", posX + 635, posY), "")
    MySoftData.CMDTipCtrl := con
    MySoftData.CMDTipCtrl.Value := MySoftData.CMDTip
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    con := MyGui.Add("Button", Format("x{} y{}", posX + 635 + 15, posY - 5), "指令显示")
    con.OnEvent("Click", (*) => OnEditCMDTipGui())
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posY += 40
    con := MyGui.Add("CheckBox", Format("x{} y{}", posX + 25, posY), "无变量提醒")
    MySoftData.NoVariableTipCtrl := con
    MySoftData.NoVariableTipCtrl.Value := MySoftData.NoVariableTip
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    con := MyGui.Add("CheckBox", Format("x{} y{}", posX + 315, posY), "菜单轮位置固定")
    MySoftData.FixedMenuWheelCtrl := con
    MySoftData.FixedMenuWheelCtrl.Value := MySoftData.FixedMenuWheel
    MySoftData.FixedMenuWheelCtrl.OnEvent("Click", OnMenuWheelPosChanged)
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posY += 40
    con := MyGui.Add("GroupBox", Format("x{} y{} w870 h100", posX + 10, posY), "下拉框选项")
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    tableItem.AllGroup.Push(con)
    posY += 30
    con := MyGui.Add("Text", Format("x{} y{}", posX + 25, posY), "软件字体：")
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    con := MyGui.Add("DropDownList", Format("x{} y{} w180", posX + 100, posY - 5), [])
    MySoftData.FontTypeCtrl := con
    MySoftData.FontTypeCtrl.Delete()
    MySoftData.FontTypeCtrl.Add(MySoftData.FontList)
    MySoftData.FontTypeCtrl.Text := MySoftData.FontType
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    con := MyGui.Add("Text", Format("x{} y{}", posX + 315, posY), "软件截图方式：")
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    con := MyGui.Add("DropDownList", Format("x{} y{} w100", posX + 410, posY - 5), ["微软截图",
        "RMT截图"])
    MySoftData.ScreenShotTypeCtrl := con
    MySoftData.ScreenShotTypeCtrl.Value := MySoftData.ScreenShotType
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posY += 70
    tableItem := MySoftData.TableInfo[index]
    tableItem.UnderPosY := posY
}

;帮助
AddHelpUI(index) {
    MyGui := MySoftData.MyGui
    tableItem := MySoftData.TableInfo[index]
    posY := MySoftData.TabPosY
    posX := MySoftData.TabPosX

    posY += 40
    posX := MySoftData.TabPosX + 15
    con := MyGui.Add("Text", Format("x{} y{} w{} h{} Center", posX, posY, 700, 25),
    "免责声明")
    con.SetFont((Format("S{} W{} Q{}", 14, 600, 2)))
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posY += 25
    posX := MySoftData.TabPosX + 15
    con := MyGui.Add("Text", Format("x{} y{} w{} h{} Center", posX, posY, 700, 35),
    "本文件是对 GNU Affero General Public License v3.0 的补充说明，不影响原协议效力")
    con.SetFont((Format("S{} W{} Q{}", 10, 600, 0)))
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posY += 40
    posX := MySoftData.TabPosX + 15
    con := MyGui.Add("Text", Format("x{} y{} w{} h{}", posX, posY, 800, 25),
    '1. 本软件按"原样"提供，开发者不承担因使用、修改或分发导致的任何法律责任。')
    con.SetFont((Format("S{} W{} Q{}", 12, 600, 0)))
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posY += 25
    posX := MySoftData.TabPosX + 15
    con := MyGui.Add("Text", Format("x{} y{} w{} h{}", posX, posY, 800, 25),
    '2. 严禁用于违法用途，包括但不限于:游戏作弊、未经授权的系统访问或数据篡改')
    con.SetFont((Format("S{} W{} Q{}", 12, 600, 0)))
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posY += 25
    posX := MySoftData.TabPosX + 15
    con := MyGui.Add("Text", Format("x{} y{} w{} h{}", posX, posY, 800, 25),
    '3. 使用者需自行承担所有风险，开发者对因违反法律或第三方条款导致的后果概不负责。')
    con.SetFont((Format("S{} W{} Q{}", 12, 600, 0)))
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posY += 25
    posX := MySoftData.TabPosX + 15
    con := MyGui.Add("Text", Format("x{} y{} w{} h{}", posX, posY, 800, 50),
    '4. 通过使用本软件，您确认：不会将其用于任何非法目的、已充分了解并接受所有潜在法律风险、同意免除开发者因滥用行为导致的一切追责权利')
    con.SetFont((Format("S{} W{} Q{}", 12, 600, 0)))
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posY += 50
    posX := MySoftData.TabPosX + 15
    con := MyGui.Add("Text", Format("x{} y{} w{} h{} Center", posX, posY, 800, 35),
    "若不同意上述条款，请立即停止使用本软件。")
    con.SetFont((Format("cRed  S{} W{} Q{}", 12, 600, 0)))
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posY += 50
    posX := MySoftData.TabPosX + 15
    con := MyGui.Add("Text", Format("x{} y{} w{} h{}", posX, posY, 130, 35),
    "更新视频合集：")
    con.SetFont((Format("S{} W{} Q{}", 12, 600, 0)))
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    con := MyGui.Add("Link", Format("x{} y{} w{} h{}", posX + 130, posY, 500, 35),
    '<a href="https://www.bilibili.com/video/BV1oWVRzaEzk">版本更新视频，直播交流问答</a>')
    con.SetFont((Format("S{} W{} Q{}", 12, 600, 0)))
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posY += 30
    posX := MySoftData.TabPosX + 15
    con := MyGui.Add("Text", Format("x{} y{} w{} h{}", posX, posY, 130, 35),
    "操作说明文档：")
    con.SetFont((Format("S{} W{} Q{}", 12, 600, 0)))
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    con := MyGui.Add("Link", Format("x{} y{} w{} h{}", posX + 130, posY, 500, 35),
    '<a href="https://zclucas.github.io/RMT/">帮助你快速上手，理解词条、指令，10分钟秒变大神</a>')
    con.SetFont((Format("S{} W{} Q{}", 12, 600, 0)))
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posY += 30
    posX := MySoftData.TabPosX + 15
    con := MyGui.Add("Text", Format("x{} y{} w{} h{}", posX, posY, 130, 35),
    "配置共享网址：")
    con.SetFont((Format("S{} W{} Q{}", 12, 600, 0)))
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    con := MyGui.Add("Link", Format("x{} y{} w{} h{}", posX + 130, posY, 500, 35),
    '<a href="https://zclucas.github.io/RMT-Setting/">免费、开放、若梦兔宏配置分享平台</a>')
    con.SetFont((Format("S{} W{} Q{}", 12, 600, 0)))
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posY += 30
    posX := MySoftData.TabPosX + 15
    con := MyGui.Add("Text", Format("x{} y{} w{} h{}", posX, posY, 130, 30),
    "国内开源网址：")
    con.SetFont((Format("S{} W{} Q{}", 12, 600, 0)))
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    con := MyGui.Add("Link", Format("x{} y{} w{} h{}", posX + 130, posY, 500, 30),
    '<a href="https://gitee.com/fateman/RMT">https://gitee.com/fateman/RMT</a>')
    con.SetFont((Format("S{} W{} Q{}", 12, 600, 0)))
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posY += 30
    posX := MySoftData.TabPosX + 15
    con := MyGui.Add("Text", Format("x{} y{} w{} h{}", posX, posY, 130, 30),
    "国外开源网址：")
    con.SetFont((Format("S{} W{} Q{}", 12, 600, 0)))
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    con := MyGui.Add("Link", Format("x{} y{} w{} h{}", posX + 130, posY, 500, 30),
    '<a href="https://github.com/zclucas/RMT">https://github.com/zclucas/RMT</a>')
    con.SetFont((Format("S{} W{} Q{}", 12, 600, 0)))
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posY += 30
    posX := MySoftData.TabPosX + 15
    con := MyGui.Add("Text", Format("x{} y{} w{} h{}", posX, posY, 130, 30),
    "软件检查更新：")
    con.SetFont((Format("S{} W{} Q{}", 12, 600, 0)))
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    con := MyGui.Add("Text", Format("x{} y{} w{} h{}", posX + 130, posY, 500, 30),
    "浏览开源网址，查看右侧发行版处即可知道软件最新版本")
    con.SetFont((Format("S{} W{} Q{}", 12, 600, 0)))
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posY += 30
    posX := MySoftData.TabPosX + 15
    con := MyGui.Add("Text", Format("x{} y{} w{} h{}", posX, posY, 130, 30),
    "软件交流渠道：")
    con.SetFont((Format("S{} W{} Q{}", 12, 600, 0)))
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    con := MyGui.Add("Link", Format("x{} y{} w{} h{}", posX + 130, posY, 700, 30),
    '<a href="https://qm.qq.com/q/DgpDumEPzq">[1群]837661891</a>、<a href="https://qm.qq.com/q/uZszuxabPW">[2群]1050141694</a>、<a href="https://pd.qq.com/s/5wyjvj7zw">[频道]pd63973680</a>'
    )
    con.SetFont((Format("S{} W{} Q{}", 12, 600, 0)))
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posY += 30
    posX := MySoftData.TabPosX + 15
    con := MyGui.Add("Text", Format("x{} y{} w{} h{}", posX, posY, 130, 30),
    "软件反馈表格：")
    con.SetFont((Format("S{} W{} Q{}", 12, 600, 0)))
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    con := MyGui.Add("Link", Format("x{} y{} w{} h{}", posX + 130, posY, 700, 30),
    '<a href="https://docs.qq.com/sheet/DVWJIdEVMV1pHUVJj">bug文档</a>、<a href="https://docs.qq.com/sheet/DVWRQaXBFUVV5bERo">需求文档</a>、<a href="https://docs.qq.com/sheet/DVVNwWHJEd3NOWXhR?tab=BB08J2">使用备注</a>(问题反馈，提出优化方案)'
    )
    con.SetFont((Format("S{} W{} Q{}", 12, 600, 0)))
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posY += 30
    posX := MySoftData.TabPosX + 15
    con := MyGui.Add("Text", Format("x{} y{} w{} h{}", posX, posY, 130, 30),
    "软件开源协议：")
    con.SetFont((Format("S{} W{} Q{}", 12, 600, 0)))
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    con := MyGui.Add("Text", Format("x{} y{} w{} h{}", posX + 130, posY, 500, 30), "AGPL-3.0")
    con.SetFont((Format("S{} W{} Q{}", 12, 600, 0)))
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posY += 35
    MySoftData.TableInfo[index].underPosY := posY
}

;打赏
AddRewardUI(index) {
    MyGui := MySoftData.MyGui
    tableItem := MySoftData.TableInfo[index]
    posY := MySoftData.TabPosY
    posX := MySoftData.TabPosX

    posY += 40
    posX += 15
    countStr := FormatIntegerWithCommas(MySoftData.MacroTotalCount)
    str := Format("若梦兔（RMT）—— 这款完全免费的开源软件，始终陪在你身边。`n至今已为您执行 {:} 次宏指令。`n诚邀本月打赏成为若梦兔的 “守护者”，一起让若梦兔走得更远。", countStr)
    con := MyGui.Add("Text", Format("x{} y{} w{} h{}", posX, posY, 800, 80), str)
    con.SetFont((Format("S{} W{} Q{}", 12, 600, 0)))
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posY += 100
    posX := MySoftData.TabPosX + 100
    con := MyGui.Add("Picture", Format("x{} y{} w{} h{} center", posX, posY, 220, 220), "Images\Soft\WeiXin.png")
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    con := MyGui.Add("Text", Format("x{} y{} w{} h{} center", posX, posY + 230, 220, 50), "微信打赏")
    con.SetFont((Format("S{} W{} Q{}", 12, 600, 0)))
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posX += 450
    con := MyGui.Add("Picture", Format("x{} y{} w{} h{} center", posX, posY, 220, 220), "Images\Soft\ZhiFuBao.png")
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    con := MyGui.Add("Text", Format("x{} y{} w{} h{} center", posX, posY + 230, 220, 50), "支付宝打赏")
    con.SetFont((Format("S{} W{} Q{}", 12, 600, 0)))
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posY += 300
    posX := MySoftData.TabPosX + 15
    con := MyGui.Add("Text", Format("x{} y{} w{} h{}", posX, posY, 860, 80),
    "当然，如果你暂时不方便，分享给朋友也是很棒的支持~`n开发不易，感谢你的每一份温暖！")
    con.SetFont((Format("S{} W{} Q{}", 12, 600, 0)))
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posY += 35
    MySoftData.TableInfo[index].underPosY := posY
}

; 系统托盘优化
CustomTrayMenu() {
    A_TrayMenu.Insert("&Suspend Hotkeys", "显示窗口", (*) => RefreshGui())
    A_TrayMenu.Delete("&Pause Script")
    A_TrayMenu.ClickCount := 1
    A_TrayMenu.Default := "显示窗口"
    TraySetIcon(, , true)
}
