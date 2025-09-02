#Requires AutoHotkey v2.0

;添加正常按键宏UI
LoadTabConent(index) {
    global MySoftData
    tableItem := MySoftData.TableInfo[index]
    isNoTriggerKey := CheckIsNoTriggerKey(index)
    offsetPosx := isNoTriggerKey ? -60 : 0
    tableItem.underPosY := MySoftData.TabPosY
    ; 配置规则说明
    UpdateUnderPosY(index, 30)

    MyGui := MySoftData.MyGui
    con := MyGui.Add("Text", Format("x{} y{} w100", MySoftData.TabPosX + 20, tableItem.underPosY), "宏触发按键")
    con.Visible := !isNoTriggerKey
    tableItem.AllConArr.Push(ItemConInfo(con))

    con := MyGui.Add("Text", Format("x{} y{} w80", MySoftData.TabPosX + 120 + offsetPosx, tableItem.underPosY), "循环次数")
    tableItem.AllConArr.Push(ItemConInfo(con))
    con := MyGui.Add("Text", Format("x{} y{} w550", MySoftData.TabPosX + 205 + offsetPosx, tableItem.underPosY), "宏指令")
    tableItem.AllConArr.Push(ItemConInfo(con))
    con := MyGui.Add("Text", Format("x{} y{} w550", MySoftData.TabPosX + 515, tableItem.underPosY), "宏按键类型")
    tableItem.AllConArr.Push(ItemConInfo(con))
    con := MyGui.Add("Text", Format("x{} y{}", MySoftData.TabPosX + 690, tableItem.underPosY), "指定前台触发")
    tableItem.AllConArr.Push(ItemConInfo(con))

    UpdateUnderPosY(index, 20)
    LoadTabItem(index)
}

LoadTabItem(index) {
    tableItem := MySoftData.TableInfo[index]
    isMacro := CheckIsMacroTable(index)
    isNormal := CheckIsNormalTable(index)
    isSubMacro := CheckIsSubMacroTable(index)
    isNoTriggerKey := CheckIsNoTriggerKey(index)
    isTiming := CheckIsTimingMacroTable(index)
    curIndex := 0
    MyGui := MySoftData.MyGui
    TabPosX := MySoftData.TabPosX
    subMacroWidth := isNoTriggerKey ? 75 : 0
    isTriggerStr := CheckIsStringMacroTable(index)
    EditTriggerAction := isTriggerStr ? OnTableEditTriggerStr : OnTableEditTriggerKey
    EditTriggerAction := isTiming ? OnTableEditTiming : EditTriggerAction
    EditMacroAction := isMacro ? OnTableEditMacro : OnTableEditReplaceKey
    loop tableItem.ModeArr.Length {
        LoadTabItemUI(tableItem, A_Index, false)
    }
}

OnAddTabItem(*) {
    global MySoftData
    TableIndex := MySoftData.TabCtrl.Value
    if (!CheckIfAddSetTable(TableIndex)) {
        MsgBox("该页签不可添加配置啊喂")
        return
    }
    tableItem := MySoftData.TableInfo[TableIndex]
    tableItem.TKArr.Push("")
    tableItem.TriggerTypeArr.Push(1)
    tableItem.MacroArr.Push("")
    tableItem.ModeArr.Push(1)
    tableItem.ForbidArr.Push(0)
    tableItem.ProcessNameArr.Push("")
    tableItem.RemarkArr.Push("")
    tableItem.LoopCountArr.Push("1")
    tableItem.HoldTimeArr.Push(500)
    tableItem.SerialArr.Push(FormatTime(, "HHmmss"))
    tableItem.TimingSerialArr.Push(GetSerialStr("Timing"))
    tableItem.IsWorkIndexArr.Push(0)

    MySoftData.TabCtrl.UseTab(TableIndex)
    itemIndex := tableItem.ModeArr.Length
    LoadTabItemUI(tableItem, itemIndex, true)
    MySoftData.TabCtrl.UseTab()
    MySlider.RefreshTab()
    IniWrite(MySoftData.TabCtrl.Value, IniFile, IniSection, "TableIndex")
}

LoadTabItemUI(tableItem, itemIndex, isAdd) {
    MyGui := MySoftData.MyGui
    TabPosX := MySoftData.TabPosX
    tableIndex := tableItem.Index
    isMacro := CheckIsMacroTable(tableIndex)
    isNormal := CheckIsNormalTable(tableIndex)
    isSubMacro := CheckIsSubMacroTable(tableIndex)
    isNoTriggerKey := CheckIsNoTriggerKey(tableIndex)
    isTiming := CheckIsTimingMacroTable(tableIndex)
    subMacroWidth := isNoTriggerKey ? 75 : 0
    isTriggerStr := CheckIsStringMacroTable(tableIndex)
    EditTriggerAction := isTriggerStr ? OnTableEditTriggerStr : OnTableEditTriggerKey
    EditTriggerAction := isTiming ? OnTableEditTiming : EditTriggerAction
    EditMacroAction := isMacro ? OnTableEditMacro : OnTableEditReplaceKey
    HeightValue := 70
    InfoHeight := 60

    colorCon := MyGui.Add("Pic", Format("x{} y{} w{} h27", TabPosX + 10, tableItem.underPosY, 29),
    "Images\Soft\GreenColor.png")
    colorCon.Visible := false
    tableItem.AllConArr.Push(ItemConInfo(colorCon))

    IndexCon := MyGui.Add("Text", Format("x{} y{} w{} +BackgroundTrans", TabPosX + 10, tableItem.underPosY + 5,
        30), ItemIndex ".")
    tableItem.AllConArr.Push(ItemConInfo(IndexCon))

    TriggerTypeCon := MyGui.Add("DropDownList", Format("x{} y{} w{}", TabPosX + 40, tableItem.underPosY, 70),
    ["按下", "松开", "松止", "开关", "长按"])
    TriggerTypeCon.Value := tableItem.TriggerTypeArr.Length >= ItemIndex ? tableItem.TriggerTypeArr[ItemIndex] : 1
    TriggerTypeCon.Enabled := isNormal
    TriggerTypeCon.Visible := isNoTriggerKey ? false : true
    tableItem.AllConArr.Push(ItemConInfo(TriggerTypeCon))

    TkCon := MyGui.Add("Edit", Format("x{} y{} w{} Center", TabPosX + 10, tableItem.underPosY + 33, 100,),
    "")
    TkCon.Visible := isNoTriggerKey ? false : true
    TkCon.Value := tableItem.TKArr.Length >= ItemIndex ? tableItem.TKArr[ItemIndex] : ""
    tableItem.AllConArr.Push(ItemConInfo(TkCon))

    LoopCon := MyGui.Add("ComboBox", Format("x{} y{} w60 R5 center", TabPosX + 115 - subMacroWidth,
        tableItem.underPosY),
    ["无限"])
    conValue := tableItem.LoopCountArr.Length >= ItemIndex ? tableItem.LoopCountArr[ItemIndex] : "1"
    conValue := conValue == "-1" ? "无限" : conValue
    LoopCon.Text := conValue
    LoopCon.Enabled := isMacro
    tableItem.AllConArr.Push(ItemConInfo(LoopCon))

    btnStr := isTiming ? "定时" : "触发键"
    TKBtnCon := MyGui.Add("Button", Format("x{} y{} w60", TabPosX + 115 - subMacroWidth, tableItem.underPosY +
        30), btnStr)
    TKBtnCon.OnEvent("Click", GetTableClosureAction(EditTriggerAction, tableItem, ItemIndex))
    TKBtnCon.Enabled := !isSubMacro
    tableItem.AllConArr.Push(ItemConInfo(TKBtnCon))

    MacroCon := MyGui.Add("Edit", Format("x{} y{} w{} h{}", TabPosX + 180 - subMacroWidth, tableItem.underPosY,
        335 + subMacroWidth,
        InfoHeight), "")
    MacroCon.Value := tableItem.MacroArr.Length >= ItemIndex ? tableItem.MacroArr[ItemIndex] : ""
    tableItem.AllConArr.Push(ItemConInfo(MacroCon))

    ModeCon := MyGui.Add("DropDownList", Format("x{} y{} w60 Center", TabPosX + 520, tableItem.underPosY), [
        "虚拟", "拟真"])
    ModeCon.value := tableItem.ModeArr[ItemIndex]
    tableItem.AllConArr.Push(ItemConInfo(ModeCon))

    ForbidCon := MyGui.Add("Checkbox", Format("x{} y{}", TabPosX + 590, tableItem.underPosY + 4), "禁用")
    ForbidCon.value := tableItem.ForbidArr[ItemIndex]
    tableItem.AllConArr.Push(ItemConInfo(ForbidCon))

    con := MyGui.Add("Text", Format("x{} y{} w60", TabPosX + 650, tableItem.underPosY + 4), "前台:")
    tableItem.AllConArr.Push(ItemConInfo(con))
    FrontCon := MyGui.Add("Edit", Format("x{} y{} w140", TabPosX + 690, tableItem.underPosY), "")
    FrontCon.value := tableItem.ProcessNameArr.Length >= ItemIndex ? tableItem.ProcessNameArr[ItemIndex] :
        ""
    tableItem.AllConArr.Push(ItemConInfo(FrontCon))

    con := MyGui.Add("Button", Format("x{} y{} w40 h29", TabPosX + 832, tableItem.underPosY - 1), "编辑")
    con.OnEvent("Click", OnItemEditFrontInfo.Bind(tableItem, ItemIndex))
    tableItem.AllConArr.Push(ItemConInfo(con))

    MacroBtnCon := MyGui.Add("Button", Format("x{} y{} w61", TabPosX + 520, tableItem.underPosY + 30),
    "宏指令")
    MacroBtnCon.OnEvent("Click", GetTableClosureAction(EditMacroAction, tableItem, ItemIndex))
    tableItem.AllConArr.Push(ItemConInfo(MacroBtnCon))

    DelCon := MyGui.Add("Button", Format("x{} y{} w60", TabPosX + 585, tableItem.underPosY + 30),
    "删除")
    DelCon.OnEvent("Click", GetTableClosureAction(OnTableDelete, tableItem, ItemIndex))
    tableItem.AllConArr.Push(ItemConInfo(DelCon))

    RemarkTipCon := MyGui.Add("Text", Format("x{} y{} w60", TabPosX + 650, tableItem.underPosY + 37), "备注:"
    )
    tableItem.AllConArr.Push(ItemConInfo(RemarkTipCon))

    RemarkCon := MyGui.Add("Edit", Format("x{} y{} w181", TabPosX + 690, tableItem.underPosY + 32), ""
    )
    RemarkCon.value := tableItem.RemarkArr.Length >= ItemIndex ? tableItem.RemarkArr[ItemIndex] : ""
    tableItem.AllConArr.Push(ItemConInfo(RemarkCon))

    con := MyGui.Add("Button", Format("x{} y{} w20 h28", TabPosX + 875, tableItem.underPosY), "↑")
    con.OnEvent("Click", OnTableMoveUp.Bind(tableItem, ItemIndex))
    tableItem.AllConArr.Push(ItemConInfo(con))
    con := MyGui.Add("Button", Format("x{} y{} w20 h28", TabPosX + 875, tableItem.underPosY + 32), "↓")
    con.OnEvent("Click", OnTableMoveDown.Bind(tableItem, ItemIndex))
    tableItem.AllConArr.Push(ItemConInfo(con))

    tableItem.MacroBtnConArr.Push(MacroBtnCon)
    tableItem.RemarkConArr.Push(RemarkCon)
    tableItem.RemarkTipConArr.Push(RemarkTipCon)
    tableItem.LoopCountConArr.Push(LoopCon)
    tableItem.TKConArr.Push(TkCon)
    tableItem.MacroConArr.Push(MacroCon)
    tableItem.KeyBtnConArr.Push(TKBtnCon)
    tableItem.DeleteBtnConArr.Push(DelCon)
    tableItem.ModeConArr.Push(ModeCon)
    tableItem.ForbidConArr.Push(ForbidCon)
    tableItem.ProcessNameConArr.Push(FrontCon)
    tableItem.IndexConArr.Push(IndexCon)
    tableItem.ColorConArr.push(colorCon)
    tableItem.ColorStateArr.push(0)
    tableItem.TriggerTypeConArr.Push(TriggerTypeCon)
    UpdateUnderPosY(tableIndex, HeightValue)
}

RefreshTabContent(tableItem, isDown) {
    if (isDown) {
        for index, value in tableItem.AllConArr {
            value.UpdatePos(tableItem.OffSetPosY)
            ; value.Con.Redraw()
        }
    }
    else {
        loop tableItem.AllConArr.Length {
            conInfo := tableItem.AllConArr[tableItem.AllConArr.Length - A_Index + 1]
            conInfo.UpdatePos(tableItem.OffSetPosY)
            ; conInfo.Con.Redraw()
        }
    }
}
