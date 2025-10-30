#Requires AutoHotkey v2.0

LoadItemFold(index) {
    tableItem := MySoftData.TableInfo[index]
    FoldInfo := tableItem.FoldInfo
    MyGui := MySoftData.MyGui
    tableItem.UnderPosY := MySoftData.TabPosY
    tableItem.FoldOffsetArr := []
    tableItem.FoldBtnArr := []
    isMenu := CheckIsMenuMacroTable(tableItem.Index)
    titleHeight := isMenu ? 85 : 55
    UpdateUnderPosY(index, 25)
    for foldIndex, IndexSpanStr in FoldInfo.IndexSpanArr {
        tableItem.FoldOffsetArr.Push(0)
        LoadItemFoldTitle(tableItem, foldIndex, tableItem.UnderPosY)
        UpdateUnderPosY(index, titleHeight)
        IndexSpan := StrSplit(IndexSpanStr, "-")
        if (!IsInteger(IndexSpan[1]) || !IsInteger(IndexSpan[2]))
            continue

        LoadItemFoldTip(tableItem, foldIndex, tableItem.UnderPosY)
        CurUnderPosY := tableItem.UnderPosY + 25
        if (!FoldInfo.FoldStateArr[foldIndex])
            UpdateUnderPosY(index, 25)

        loop IndexSpan[2] - IndexSpan[1] + 1 {
            itemIndex := A_Index + IndexSpan[1] - 1
            LoadTabItemUI(tableItem, itemIndex, foldIndex, CurUnderPosY)
            CurUnderPosY += 70
            if (!FoldInfo.FoldStateArr[foldIndex])
                UpdateUnderPosY(index, 70)
        }
        UpdateUnderPosY(index, 5)
    }

    UpdateItemConPos(tableItem, true)
}

LoadItemFoldTitle(tableItem, foldIndex, PosY) {
    FoldInfo := tableItem.FoldInfo
    MyGui := MySoftData.MyGui
    isMenu := CheckIsMenuMacroTable(tableItem.Index)

    GroupHeight := GetFoldGroupHeight(FoldInfo, foldIndex, isMenu)
    con := MyGui.Add("GroupBox", Format("x{} y{} w900 h{}", MySoftData.TabPosX + 10, posY + 2,
        GroupHeight))
    conInfo := ItemConInfo(con, tableItem, foldIndex)
    conInfo.IsTitle := true
    tableItem.AllConArr.Push(conInfo)
    tableItem.AllGroup.InsertAt(foldIndex, con)
    tableItem.ConIndexMap[con] := MacroItemInfo(-10000, conInfo)
    PosY += 20

    con := MyGui.Add("Text", Format("x{} y{}", MySoftData.TabPosX + 20, posY + 2), "备注：")
    conInfo := ItemConInfo(con, tableItem, foldIndex)
    conInfo.IsTitle := true
    tableItem.AllConArr.Push(conInfo)

    con := MyGui.Add("Edit", Format("x{} y{} w150", MySoftData.TabPosX + 60, posY), FoldInfo.RemarkArr[
        foldIndex])
    con.OnEvent("Change", OnFoldRemarkChange.Bind(tableItem))
    conInfo := ItemConInfo(con, tableItem, foldIndex)
    conInfo.IsTitle := true
    tableItem.AllConArr.Push(conInfo)
    tableItem.ConIndexMap[con] := MacroItemInfo(-10000, conInfo)

    con := MyGui.Add("Text", Format("x{} y{}", MySoftData.TabPosX + 230, posY + 2), "前台:")
    conInfo := ItemConInfo(con, tableItem, foldIndex)
    conInfo.IsTitle := true
    tableItem.AllConArr.Push(conInfo)

    FrontCon := MyGui.Add("Edit", Format("x{} y{} w150", MySoftData.TabPosX + 270, posY), FoldInfo.FrontInfoArr[
        foldIndex])
    FrontCon.OnEvent("Change", OnFoldFrontInfoChange.Bind(tableItem))
    conInfo := ItemConInfo(FrontCon, tableItem, foldIndex)
    conInfo.IsTitle := true
    tableItem.AllConArr.Push(conInfo)
    tableItem.ConIndexMap[FrontCon] := MacroItemInfo(-10000, conInfo)

    con := MyGui.Add("Button", Format("x{} y{}", MySoftData.TabPosX + 422, posY - 3), "编辑")
    con.OnEvent("Click", OnFoldFrontInfoEdit.Bind(tableItem, FrontCon))
    conInfo := ItemConInfo(con, tableItem, foldIndex)
    conInfo.IsTitle := true
    tableItem.AllConArr.Push(conInfo)
    tableItem.ConIndexMap[con] := MacroItemInfo(-10000, conInfo)

    con := MyGui.Add("Button", Format("x{} y{}", MySoftData.TabPosX + 490, posY - 3), "新增宏")
    con.OnEvent("Click", OnItemAddMacroBtnClick.Bind(tableItem))
    con.Visible := !isMenu
    conInfo := ItemConInfo(con, tableItem, foldIndex)
    conInfo.IsTitle := true
    tableItem.AllConArr.Push(conInfo)
    tableItem.ConIndexMap[con] := MacroItemInfo(-10000, conInfo)

    con := MyGui.Add("Button", Format("x{} y{}", MySoftData.TabPosX + 560, posY - 3), "新增模块")
    con.OnEvent("Click", OnItemAddFoldBtnClick.Bind(tableItem))
    conInfo := ItemConInfo(con, tableItem, foldIndex)
    conInfo.IsTitle := true
    tableItem.AllConArr.Push(conInfo)
    tableItem.ConIndexMap[con] := MacroItemInfo(-10000, conInfo)

    con := MyGui.Add("Button", Format("x{} y{}", MySoftData.TabPosX + 645, posY - 3), "删除该模块")
    con.OnEvent("Click", OnItemDelFoldBtnClick.Bind(tableItem))
    conInfo := ItemConInfo(con, tableItem, foldIndex)
    conInfo.IsTitle := true
    tableItem.AllConArr.Push(conInfo)
    tableItem.ConIndexMap[con] := MacroItemInfo(-10000, conInfo)

    con := MyGui.Add("CheckBox", Format("x{} y{}", MySoftData.TabPosX + 750, posY + 2), "禁用")
    con.Value := FoldInfo.ForbidStateArr[foldIndex]
    con.OnEvent("Click", OnFoldForbidChange.Bind(tableItem))
    conInfo := ItemConInfo(con, tableItem, foldIndex)
    conInfo.IsTitle := true
    tableItem.AllConArr.Push(conInfo)
    tableItem.ConIndexMap[con] := MacroItemInfo(-10000, conInfo)

    btnStr := FoldInfo.FoldStateArr[foldIndex] ? "🞃" : "❯"
    con := MyGui.Add("Button", Format("x{} y{} w{} +BackgroundTrans", MySoftData.TabPosX + 840, posY - 2, 30),
    btnStr)
    con.OnEvent("Click", OnFoldBtnClick.Bind(tableItem))
    conInfo := ItemConInfo(con, tableItem, foldIndex)
    conInfo.IsTitle := true
    tableItem.AllConArr.Push(conInfo)
    tableItem.ConIndexMap[con] := MacroItemInfo(-10000, conInfo)
    tableItem.FoldBtnArr.InsertAt(foldIndex, con)

    if (isMenu)
        LoadItemFoldTK(tableItem, foldIndex, PosY + 35)
}

LoadItemFoldTK(tableItem, foldIndex, PosY) {
    FoldInfo := tableItem.FoldInfo
    MyGui := MySoftData.MyGui

    con := MyGui.Add("Text", Format("x{} y{}", MySoftData.TabPosX + 20, posY + 2), "菜单触发键：")
    conInfo := ItemConInfo(con, tableItem, foldIndex)
    conInfo.IsTitle := true
    tableItem.AllConArr.Push(conInfo)

    TriggerTypeCon := MyGui.Add("DropDownList", Format("x{} y{} w{}", MySoftData.TabPosX + 100, posY - 3, 70),
    ["按下", "松开", "松止", "开关", "长按"])
    TriggerTypeCon.Value := FoldInfo.TKTypeArr[foldIndex]
    TriggerTypeCon.OnEvent("Change", OnFlodTKTypeChange.Bind(tableItem))
    conInfo := ItemConInfo(TriggerTypeCon, tableItem, foldIndex)
    conInfo.IsTitle := true
    tableItem.AllConArr.Push(conInfo)
    tableItem.ConIndexMap[TriggerTypeCon] := MacroItemInfo(-10000, conInfo)

    TkCon := MyGui.Add("Edit", Format("x{} y{} w{} Center", MySoftData.TabPosX + 175, posY - 3, 100,),
    "")
    TkCon.Value := FoldInfo.TKArr[foldIndex]
    TkCon.OnEvent("Change", OnFlodTKChange.Bind(tableItem))
    conInfo := ItemConInfo(TkCon, tableItem, foldIndex)
    conInfo.IsTitle := true
    tableItem.AllConArr.Push(conInfo)
    tableItem.ConIndexMap[TkCon] := MacroItemInfo(-10000, conInfo)

    btnStr := "触发键"
    TKBtnCon := MyGui.Add("Button", Format("x{} y{} w60 h29", MySoftData.TabPosX + 280, posY - 4), btnStr)
    TKBtnCon.OnEvent("Click", OnFlodTKEditClick.Bind(TkCon, tableItem))
    conInfo := ItemConInfo(TKBtnCon, tableItem, foldIndex)
    conInfo.IsTitle := true
    tableItem.AllConArr.Push(conInfo)
    tableItem.ConIndexMap[TKBtnCon] := MacroItemInfo(-10000, conInfo)
}

LoadItemFoldTip(tableItem, foldIndex, PosY) {
    isNoTriggerKey := CheckIsNoTriggerKey(tableItem.Index)
    offsetPosx := isNoTriggerKey ? -80 : 0

    MyGui := MySoftData.MyGui
    con := MyGui.Add("Text", Format("x{} y{} w100", MySoftData.TabPosX + 30, posY), "宏触发按键")
    con.Visible := !isNoTriggerKey
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, foldIndex))

    con := MyGui.Add("Text", Format("x{} y{}", MySoftData.TabPosX + 130 + offsetPosx, posY), "循环次数")
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, foldIndex))
    con := MyGui.Add("Text", Format("x{} y{}", MySoftData.TabPosX + 215 + offsetPosx, posY), "宏指令")
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, foldIndex))
    con := MyGui.Add("Text", Format("x{} y{}", MySoftData.TabPosX + 525, posY), "宏按键类型")
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, foldIndex))
    con := MyGui.Add("Text", Format("x{} y{}", MySoftData.TabPosX + 700, posY), "指定前台触发")
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, foldIndex))
}

LoadTabItemUI(tableItem, itemIndex, foldIndex, PosY) {
    MyGui := MySoftData.MyGui
    TabPosX := MySoftData.TabPosX
    tableIndex := tableItem.Index
    isMacro := CheckIsMacroTable(tableIndex)
    isNormal := CheckIsNormalTable(tableIndex)
    isSubMacro := CheckIsSubMacroTable(tableIndex)
    isMenu := CheckIsMenuMacroTable(tableIndex)
    isNoTriggerKey := CheckIsNoTriggerKey(tableIndex)
    isTiming := CheckIsTimingMacroTable(tableIndex)
    subMacroWidth := isNoTriggerKey ? 75 : 0
    isTriggerStr := CheckIsStringMacroTable(tableIndex)
    EditTriggerAction := isTriggerStr ? OnItemEditTriggerStr : OnItemEditTriggerKey
    EditTriggerAction := isTiming ? OnItemEditTiming : EditTriggerAction
    EditMacroAction := isMacro ? OnItemEditMacro : OnItemEditReplaceKey
    InfoHeight := 60

    colorCon := MyGui.Add("Pic", Format("x{} y{} w{} h27", TabPosX + 20, posY, 29),
    "Images\Soft\GreenColor.png")
    colorCon.Visible := false
    conInfo := ItemConInfo(colorCon, tableItem, foldIndex)
    tableItem.AllConArr.Push(conInfo)
    tableItem.ConIndexMap[colorCon] := MacroItemInfo(ItemIndex, conInfo)

    IndexCon := MyGui.Add("Text", Format("x{} y{} w{} +BackgroundTrans", TabPosX + 20, posY + 5,
        30), ItemIndex ".")
    conInfo := ItemConInfo(IndexCon, tableItem, foldIndex)
    tableItem.AllConArr.Push(conInfo)
    tableItem.ConIndexMap[IndexCon] := MacroItemInfo(ItemIndex, conInfo)

    TriggerTypeCon := MyGui.Add("DropDownList", Format("x{} y{} w{}", TabPosX + 50, posY, 70),
    ["按下", "松开", "松止", "开关", "长按"])
    TriggerTypeCon.Value := tableItem.TriggerTypeArr[ItemIndex]
    TriggerTypeCon.Enabled := isNormal
    TriggerTypeCon.Visible := isNoTriggerKey ? false : true
    conInfo := ItemConInfo(TriggerTypeCon, tableItem, foldIndex)
    tableItem.AllConArr.Push(conInfo)
    tableItem.ConIndexMap[TriggerTypeCon] := MacroItemInfo(ItemIndex, conInfo)

    TkCon := MyGui.Add("Edit", Format("x{} y{} w{} Center", TabPosX + 20, posY + 33, 100,),
    "")
    TkCon.Visible := isNoTriggerKey ? false : true
    TkCon.Value := tableItem.TKArr[ItemIndex]
    conInfo := ItemConInfo(TkCon, tableItem, foldIndex)
    tableItem.AllConArr.Push(conInfo)
    tableItem.ConIndexMap[TkCon] := MacroItemInfo(ItemIndex, conInfo)

    LoopCon := MyGui.Add("ComboBox", Format("x{} y{} w60 R5 center", TabPosX + 125 - subMacroWidth,
        posY),
    ["无限"])
    conValue := tableItem.LoopCountArr[ItemIndex]
    conValue := conValue == "-1" ? "无限" : conValue
    LoopCon.Text := conValue
    LoopCon.Enabled := isMacro
    conInfo := ItemConInfo(LoopCon, tableItem, foldIndex)
    tableItem.AllConArr.Push(conInfo)
    tableItem.ConIndexMap[LoopCon] := MacroItemInfo(ItemIndex, conInfo)

    btnStr := isTiming ? "定时" : "触发键"
    TKBtnCon := MyGui.Add("Button", Format("x{} y{} w60", TabPosX + 125 - subMacroWidth, posY +
        30), btnStr)
    TKBtnCon.OnEvent("Click", EditTriggerAction.Bind(tableItem))
    TKBtnCon.Enabled := !isSubMacro && !isMenu
    conInfo := ItemConInfo(TKBtnCon, tableItem, foldIndex)
    tableItem.AllConArr.Push(conInfo)
    tableItem.ConIndexMap[TKBtnCon] := MacroItemInfo(ItemIndex, conInfo)

    MacroCon := MyGui.Add("Edit", Format("x{} y{} w{} h{}", TabPosX + 190 - subMacroWidth, posY,
        335 + subMacroWidth,
        InfoHeight), "")
    MacroCon.Value := tableItem.MacroArr[ItemIndex]
    conInfo := ItemConInfo(MacroCon, tableItem, foldIndex)
    tableItem.AllConArr.Push(conInfo)
    tableItem.ConIndexMap[MacroCon] := MacroItemInfo(ItemIndex, conInfo)

    ModeCon := MyGui.Add("DropDownList", Format("x{} y{} w60 Center", TabPosX + 530, posY), [
        "虚拟", "拟真"])
    ModeCon.value := tableItem.ModeArr[ItemIndex]
    conInfo := ItemConInfo(ModeCon, tableItem, foldIndex)
    tableItem.AllConArr.Push(conInfo)
    tableItem.ConIndexMap[ModeCon] := MacroItemInfo(ItemIndex, conInfo)

    ForbidCon := MyGui.Add("Checkbox", Format("x{} y{}", TabPosX + 600, posY + 4), "禁用")
    ForbidCon.value := tableItem.ForbidArr[ItemIndex]
    conInfo := ItemConInfo(ForbidCon, tableItem, foldIndex)
    tableItem.AllConArr.Push(conInfo)
    tableItem.ConIndexMap[ForbidCon] := MacroItemInfo(ItemIndex, conInfo)

    con := MyGui.Add("Text", Format("x{} y{} w60", TabPosX + 660, posY + 4), "前台:")
    conInfo := ItemConInfo(con, tableItem, foldIndex)
    tableItem.AllConArr.Push(conInfo)
    tableItem.ConIndexMap[con] := MacroItemInfo(ItemIndex, conInfo)

    FrontCon := MyGui.Add("Edit", Format("x{} y{} w140", TabPosX + 700, posY), "")
    FrontCon.value := tableItem.FrontInfoArr[ItemIndex]
    conInfo := ItemConInfo(FrontCon, tableItem, foldIndex)
    tableItem.AllConArr.Push(conInfo)
    tableItem.ConIndexMap[FrontCon] := MacroItemInfo(ItemIndex, conInfo)

    con := MyGui.Add("Button", Format("x{} y{} w40 h29", TabPosX + 842, posY - 1), "编辑")
    con.OnEvent("Click", OnItemEditFrontInfo.Bind(tableItem))
    conInfo := ItemConInfo(con, tableItem, foldIndex)
    tableItem.AllConArr.Push(conInfo)
    tableItem.ConIndexMap[con] := MacroItemInfo(ItemIndex, conInfo)

    MacroBtnCon := MyGui.Add("Button", Format("x{} y{} w61", TabPosX + 530, posY + 30),
    "宏指令")
    MacroBtnCon.OnEvent("Click", EditMacroAction.Bind(tableItem))
    conInfo := ItemConInfo(MacroBtnCon, tableItem, foldIndex)
    tableItem.AllConArr.Push(conInfo)
    tableItem.ConIndexMap[MacroBtnCon] := MacroItemInfo(ItemIndex, conInfo)

    DelCon := MyGui.Add("Button", Format("x{} y{} w60", TabPosX + 595, posY + 30),
    "删除")
    DelCon.OnEvent("Click", OnItemDelMacroBtnClick.Bind(tableItem))
    DelCon.Enabled := !isMenu
    conInfo := ItemConInfo(DelCon, tableItem, foldIndex)
    tableItem.AllConArr.Push(conInfo)
    tableItem.ConIndexMap[DelCon] := MacroItemInfo(ItemIndex, conInfo)

    RemarkTipCon := MyGui.Add("Text", Format("x{} y{} w60", TabPosX + 660, posY + 37), "备注:"
    )
    conInfo := ItemConInfo(RemarkTipCon, tableItem, foldIndex)
    tableItem.AllConArr.Push(conInfo)
    tableItem.ConIndexMap[RemarkTipCon] := MacroItemInfo(ItemIndex, conInfo)

    RemarkCon := MyGui.Add("Edit", Format("x{} y{} w181", TabPosX + 700, posY + 32), ""
    )
    RemarkCon.value := tableItem.RemarkArr[ItemIndex]
    conInfo := ItemConInfo(RemarkCon, tableItem, foldIndex)
    tableItem.AllConArr.Push(conInfo)
    tableItem.ConIndexMap[RemarkCon] := MacroItemInfo(ItemIndex, conInfo)

    con := MyGui.Add("Button", Format("x{} y{} w20 h28", TabPosX + 885, posY), "↑")
    con.OnEvent("Click", OnItemMoveUp.Bind(tableItem))
    conInfo := ItemConInfo(con, tableItem, foldIndex)
    tableItem.AllConArr.Push(conInfo)
    tableItem.ConIndexMap[con] := MacroItemInfo(ItemIndex, conInfo)

    con := MyGui.Add("Button", Format("x{} y{} w20 h28", TabPosX + 885, posY + 32), "↓")
    con.OnEvent("Click", OnItemMoveDown.Bind(tableItem))
    conInfo := ItemConInfo(con, tableItem, foldIndex)
    tableItem.AllConArr.Push(conInfo)
    tableItem.ConIndexMap[con] := MacroItemInfo(ItemIndex, conInfo)

    tableItem.MacroBtnConArr.InsertAt(itemIndex, MacroBtnCon)
    tableItem.RemarkConArr.InsertAt(itemIndex, RemarkCon)
    tableItem.RemarkTipConArr.InsertAt(itemIndex, RemarkTipCon)
    tableItem.LoopCountConArr.InsertAt(itemIndex, LoopCon)
    tableItem.TKConArr.InsertAt(itemIndex, TkCon)
    tableItem.MacroConArr.InsertAt(itemIndex, MacroCon)
    tableItem.KeyBtnConArr.InsertAt(itemIndex, TKBtnCon)
    tableItem.DeleteBtnConArr.InsertAt(itemIndex, DelCon)
    tableItem.ModeConArr.InsertAt(itemIndex, ModeCon)
    tableItem.ForbidConArr.InsertAt(itemIndex, ForbidCon)
    tableItem.FrontInfoConArr.InsertAt(itemIndex, FrontCon)
    tableItem.IndexConArr.InsertAt(itemIndex, IndexCon)
    tableItem.ColorConArr.InsertAt(itemIndex, colorCon)
    tableItem.ColorStateArr.InsertAt(itemIndex, 0)
    tableItem.TriggerTypeConArr.InsertAt(itemIndex, TriggerTypeCon)
}

;按钮事件
;增加宏配置
OnItemAddMacroBtnClick(tableItem, btn, *) {
    foldInfo := tableItem.FoldInfo
    foldIndex := tableItem.ConIndexMap[btn].itemConInfo.FoldIndex
    isMenu := CheckIsMenuMacroTable(tableItem.Index)
    titleHeight := isMenu ? 85 : 55
    AddIndex := GetFoldAddItemIndex(foldInfo, foldIndex)
    if (foldInfo.FoldStateArr[foldIndex])  ;没开打的话，自动打开
        OnFoldBtnClick(tableItem, btn)

    isFirst := foldInfo.IndexSpanArr[foldIndex] == "无-无"
    UpdateFoldIndexInfo(foldInfo, AddIndex, foldIndex, true)
    UpdateConItemIndex(tableItem, AddIndex, foldIndex, true)
    tableItem.TKArr.InsertAt(AddIndex, "")
    tableItem.TriggerTypeArr.InsertAt(AddIndex, 1)
    tableItem.MacroArr.InsertAt(AddIndex, "")
    tableItem.ModeArr.InsertAt(AddIndex, 1)
    tableItem.ForbidArr.InsertAt(AddIndex, 0)
    tableItem.FrontInfoArr.InsertAt(AddIndex, "")
    tableItem.RemarkArr.InsertAt(AddIndex, "")
    tableItem.LoopCountArr.InsertAt(AddIndex, "1")
    tableItem.HoldTimeArr.InsertAt(AddIndex, 500)
    tableItem.SerialArr.InsertAt(AddIndex, FormatTime(, "HHmmss"))
    tableItem.TimingSerialArr.InsertAt(AddIndex, GetSerialStr("Timing"))
    tableItem.IsWorkIndexArr.InsertAt(AddIndex, 0)

    PosY := 1000000
    for index, value in tableItem.AllConArr {
        if (foldIndex == value.FoldIndex && PosY > value.OriPosY)
            PosY := value.OriPosY
    }

    PosY += titleHeight
    if (isFirst) {
        MySoftData.TabCtrl.UseTab(tableItem.Index)
        LoadItemFoldTip(tableItem, foldIndex, PosY)
        LoadTabItemUI(tableItem, AddIndex, foldIndex, PosY + 25)
        MySoftData.TabCtrl.UseTab()
    }
    else {
        IndexSpan := StrSplit(foldInfo.IndexSpanArr[foldIndex], "-")
        PosY += (IndexSpan[2] - IndexSpan[1]) * 70 + 25
        MySoftData.TabCtrl.UseTab(tableItem.Index)
        LoadTabItemUI(tableItem, AddIndex, foldIndex, PosY)
        MySoftData.TabCtrl.UseTab()
    }

    afterHei := GetFoldGroupHeight(foldInfo, foldIndex, isMenu)
    tableItem.AllGroup[foldIndex].Move(, , , afterHei)

    addHei := isFirst ? 100 : 70
    tableItem.FoldOffsetArr[foldIndex] += addHei
    for index, value in tableItem.IndexConArr {
        value.Text := index
    }

    MySlider.RefreshTab()
}

;删除宏配置
OnItemDelMacroBtnClick(tableItem, btn, *) {
    foldInfo := tableItem.FoldInfo
    DelIndex := tableItem.ConIndexMap[btn].index
    foldIndex := tableItem.ConIndexMap[btn].itemConInfo.FoldIndex
    result := MsgBox("是否删除当前宏", "提示", 1)
    if (result == "Cancel")
        return

    OnItemDelMacro(tableItem, DelIndex, foldInfo, foldIndex)
    MySlider.RefreshTab()
}

OnItemDelMacro(tableItem, itemIndex, foldInfo, foldIndex) {
    isMenu := CheckIsMenuMacroTable(tableItem.Index)
    beforeHei := GetFoldGroupHeight(foldInfo, foldIndex, isMenu)
    UpdateFoldIndexInfo(foldInfo, itemIndex, foldIndex, false)
    UpdateConItemIndex(tableItem, itemIndex, foldIndex, false)
    afterHei := GetFoldGroupHeight(foldInfo, foldIndex, isMenu)
    tableItem.FoldOffsetArr[foldIndex] += afterHei - beforeHei
    tableItem.AllGroup[foldIndex].Move(, , , afterHei)

    tableItem.ModeArr.RemoveAt(itemIndex)
    tableItem.ModeConArr.RemoveAt(itemIndex)
    tableItem.ForbidArr.RemoveAt(itemIndex)
    tableItem.HoldTimeArr.RemoveAt(itemIndex)
    tableItem.TKArr.RemoveAt(itemIndex)
    tableItem.MacroArr.RemoveAt(itemIndex)
    tableItem.FrontInfoArr.RemoveAt(itemIndex)
    tableItem.LoopCountArr.RemoveAt(itemIndex)
    tableItem.RemarkArr.RemoveAt(itemIndex)
    tableItem.SerialArr.RemoveAt(itemIndex)
    tableItem.TimingSerialArr.RemoveAt(itemIndex)
    tableItem.IndexConArr.RemoveAt(itemIndex)
    tableItem.ColorConArr.RemoveAt(itemIndex)
    tableItem.ColorStateArr.RemoveAt(itemIndex)
    tableItem.TriggerTypeConArr.RemoveAt(itemIndex)
    tableItem.ForbidConArr.RemoveAt(itemIndex)
    tableItem.TKConArr.RemoveAt(itemIndex)
    tableItem.MacroConArr.RemoveAt(itemIndex)
    tableItem.FrontInfoConArr.RemoveAt(itemIndex)
    tableItem.LoopCountConArr.RemoveAt(itemIndex)
    tableItem.RemarkConArr.RemoveAt(itemIndex)
    for index, value in tableItem.IndexConArr {
        value.Text := index
    }
}

;增加宏模块
OnItemAddFoldBtnClick(tableItem, btn, *) {
    isMenu := CheckIsMenuMacroTable(tableItem.Index)
    titleHeidht := isMenu ? 85 : 55
    foldInfo := tableItem.FoldInfo
    foldIndex := tableItem.ConIndexMap[btn].itemConInfo.FoldIndex
    foldInfo.RemarkArr.InsertAt(foldIndex + 1, "")
    foldInfo.FrontInfoArr.InsertAt(foldIndex + 1, "")
    foldInfo.IndexSpanArr.InsertAt(foldIndex + 1, "无-无")
    foldInfo.ForbidStateArr.InsertAt(foldIndex + 1, false)
    foldInfo.FoldStateArr.InsertAt(foldIndex + 1, false)
    foldInfo.TKTypeArr.InsertAt(foldIndex + 1, 1)
    foldInfo.TKArr.InsertAt(foldIndex + 1, "")
    foldInfo.HoldTimeArr.InsertAt(foldIndex + 1, 500)
    tableItem.FoldOffsetArr.InsertAt(foldIndex + 1, titleHeidht)

    UpdateConFoldIndex(tableItem, foldIndex, true)
    LastGroupCon := tableItem.AllGroup[foldIndex]
    LastGroupCon.GetPos(&x, &y, &w, &h)
    LastOriPosY := tableItem.ConIndexMap[LastGroupCon].itemConInfo.OriPosY
    PosY := LastOriPosY + h - tableItem.FoldOffsetArr[foldIndex]
    MySoftData.TabCtrl.UseTab(tableItem.Index)
    LoadItemFoldTitle(tableItem, foldIndex + 1, PosY)
    MySoftData.TabCtrl.UseTab()

    if (isMenu)
        OnItemAddMenuItem(tableItem, foldIndex + 1)

    MySlider.RefreshTab()
}

OnItemAddMenuItem(tableItem, foldIndex) {
    loop 8 {
        foldInfo := tableItem.FoldInfo
        isMenu := CheckIsMenuMacroTable(tableItem.Index)
        titleHeight := isMenu ? 85 : 55
        AddIndex := GetFoldAddItemIndex(foldInfo, foldIndex)

        isFirst := foldInfo.IndexSpanArr[foldIndex] == "无-无"
        UpdateFoldIndexInfo(foldInfo, AddIndex, foldIndex, true)
        UpdateConItemIndex(tableItem, AddIndex, foldIndex, true)
        tableItem.TKArr.InsertAt(AddIndex, "")
        tableItem.TriggerTypeArr.InsertAt(AddIndex, 1)
        tableItem.MacroArr.InsertAt(AddIndex, "")
        tableItem.ModeArr.InsertAt(AddIndex, 1)
        tableItem.ForbidArr.InsertAt(AddIndex, 0)
        tableItem.FrontInfoArr.InsertAt(AddIndex, "")
        tableItem.RemarkArr.InsertAt(AddIndex, "")
        tableItem.LoopCountArr.InsertAt(AddIndex, "1")
        tableItem.HoldTimeArr.InsertAt(AddIndex, 500)
        tableItem.SerialArr.InsertAt(AddIndex, FormatTime(, "HHmmss"))
        tableItem.TimingSerialArr.InsertAt(AddIndex, GetSerialStr("Timing"))
        tableItem.IsWorkIndexArr.InsertAt(AddIndex, 0)

        PosY := 1000000
        for index, value in tableItem.AllConArr {
            if (foldIndex == value.FoldIndex && PosY > value.OriPosY)
                PosY := value.OriPosY
        }

        PosY += titleHeight
        if (isFirst) {
            MySoftData.TabCtrl.UseTab(tableItem.Index)
            LoadItemFoldTip(tableItem, foldIndex, PosY)
            LoadTabItemUI(tableItem, AddIndex, foldIndex, PosY + 25)
            MySoftData.TabCtrl.UseTab()
        }
        else {
            IndexSpan := StrSplit(foldInfo.IndexSpanArr[foldIndex], "-")
            PosY += (IndexSpan[2] - IndexSpan[1]) * 70 + 25
            MySoftData.TabCtrl.UseTab(tableItem.Index)
            LoadTabItemUI(tableItem, AddIndex, foldIndex, PosY)
            MySoftData.TabCtrl.UseTab()
        }

        afterHei := GetFoldGroupHeight(foldInfo, foldIndex, isMenu)
        tableItem.AllGroup[foldIndex].Move(, , , afterHei)

        addHei := isFirst ? 100 : 70
        tableItem.FoldOffsetArr[foldIndex] += addHei
        for index, value in tableItem.IndexConArr {
            value.Text := index
        }
    }
}

;删除模块
OnItemDelFoldBtnClick(tableItem, btn, *) {
    foldInfo := tableItem.FoldInfo
    foldIndex := tableItem.ConIndexMap[btn].itemConInfo.FoldIndex

    result := MsgBox("是否删除当前模块以及模块中所有的宏配置", "提示", 1)
    if (result == "Cancel")
        return

    if (foldInfo.IndexSpanArr.Length == 1) {
        MsgBox("最后一个模块，不可删除！！！")
        return
    }
    hasSetting := foldInfo.IndexSpanArr[foldIndex] != "无-无"
    if (hasSetting) {
        IndexSpan := StrSplit(foldInfo.IndexSpanArr[foldIndex], "-")
        loop IndexSpan[2] - IndexSpan[1] + 1 {
            itemIndex := IndexSpan[2] - A_Index + 1
            OnItemDelMacro(tableItem, itemIndex, foldInfo, foldIndex)
        }
    }

    UpdateConFoldIndex(tableItem, foldIndex, false)
    foldInfo.RemarkArr.RemoveAt(foldIndex)
    foldInfo.FrontInfoArr.RemoveAt(foldIndex)
    foldInfo.IndexSpanArr.RemoveAt(foldIndex)
    foldInfo.ForbidStateArr.RemoveAt(foldIndex)
    foldInfo.FoldStateArr.RemoveAt(foldIndex)
    foldInfo.TKTypeArr.RemoveAt(foldIndex)
    foldInfo.TKArr.RemoveAt(foldIndex)
    foldInfo.HoldTimeArr.RemoveAt(foldIndex)
    tableItem.FoldOffsetArr.RemoveAt(foldIndex)

    MySlider.RefreshTab()
}

;编辑字串宏触发键
OnItemEditTriggerStr(tableItem, btn, *) {
    index := tableItem.ConIndexMap[btn].index
    triggerStr := tableItem.TKConArr[index].Value
    MyTriggerStrGui.SureBtnAction := (sureTriggerStr) => tableItem.TKConArr[index].Value := sureTriggerStr
    MyTriggerStrGui.ShowGui(triggerStr, 0, false)
}

;编辑按键宏触发键
OnItemEditTriggerKey(tableItem, btn, *) {
    index := tableItem.ConIndexMap[btn].index
    triggerKey := tableItem.TKConArr[index].Value

    SureAction(sureTriggerKey, holdTime) {
        tableItem.TKConArr[index].Value := sureTriggerKey
        tableItem.HoldTimeArr[index] := holdTime
    }

    MyTriggerKeyGui.SureBtnAction := SureAction
    MyTriggerKeyGui.ShowGui(triggerKey, tableItem.HoldTimeArr[index], false)
}

;编辑定时器
OnItemEditTiming(tableItem, btn, *) {
    index := tableItem.ConIndexMap[btn].index
    SerialStr := tableItem.TimingSerialArr[index]
    MyTimingGui.ShowGui(SerialStr)
}

OnItemEditMacro(tableItem, btn, *) {
    index := tableItem.ConIndexMap[btn].index
    macro := tableItem.MacroConArr[index].Value
    MyMacroGui.SureBtnAction := (sureMacro) => tableItem.MacroConArr[index].Value := sureMacro
    MyMacroGui.ShowGui(macro, true)
}

OnItemEditReplaceKey(tableItem, btn, *) {
    index := tableItem.ConIndexMap[btn].index
    replaceKey := tableItem.MacroConArr[index].Value
    MyReplaceKeyGui.SureBtnAction := (sureReplaceKey) => tableItem.MacroConArr[index].Value := sureReplaceKey
    MyReplaceKeyGui.ShowGui(replaceKey)
}

OnItemEditFrontInfo(tableItem, btn, *) {
    index := tableItem.ConIndexMap[btn].index
    frontInfoCon := tableItem.FrontInfoConArr[index]
    MyFrontInfoGui.ShowGui(frontInfoCon)
}

OnItemMoveUp(tableItem, btn, *) {
    index := tableItem.ConIndexMap[btn].index
    if (index == 1) {
        MsgBox("上面没有元素，无法上移！！！")
        return
    }
    SwapTableContent(tableItem, index, index - 1)
}

OnItemMoveDown(tableItem, btn, *) {
    index := tableItem.ConIndexMap[btn].index
    lastIndex := tableItem.ModeArr.length
    if (lastIndex == index) {
        MsgBox("下面没有元素，无法下移！！！")
        return
    }
    SwapTableContent(tableItem, index, index + 1)
}

OnFoldRemarkChange(tableItem, con, *) {
    foldInfo := tableItem.FoldInfo
    foldIndex := tableItem.ConIndexMap[con].itemConInfo.FoldIndex
    foldInfo.RemarkArr[foldIndex] := con.text
}

OnFoldFrontInfoChange(tableItem, con, *) {
    foldInfo := tableItem.FoldInfo
    foldIndex := tableItem.ConIndexMap[con].itemConInfo.FoldIndex
    foldInfo.FrontInfoArr[foldIndex] := con.text
}

OnFoldFrontInfoEdit(tableItem, FrontCon, con, *) {
    foldInfo := tableItem.FoldInfo
    foldIndex := tableItem.ConIndexMap[con].itemConInfo.FoldIndex
    MyFrontInfoGui.SureAction := ()=> foldInfo.FrontInfoArr[foldIndex] := FrontCon.text
    MyFrontInfoGui.ShowGui(FrontCon)
}

OnFoldForbidChange(tableItem, con, *) {
    foldInfo := tableItem.FoldInfo
    foldIndex := tableItem.ConIndexMap[con].itemConInfo.FoldIndex
    foldInfo.ForbidStateArr[foldIndex] := con.Value
}

OnFoldBtnClick(tableItem, btn, *) {
    foldInfo := tableItem.FoldInfo
    foldIndex := tableItem.ConIndexMap[btn].itemConInfo.FoldIndex
    isMenu := CheckIsMenuMacroTable(tableItem.Index)
    beforeHei := GetFoldGroupHeight(foldInfo, foldIndex, isMenu)
    state := !foldInfo.FoldStateArr[foldIndex]
    foldInfo.FoldStateArr[foldIndex] := state
    afterHei := GetFoldGroupHeight(foldInfo, foldIndex, isMenu)
    tableItem.FoldOffsetArr[foldIndex] += afterHei - beforeHei

    btnStr := FoldInfo.FoldStateArr[foldIndex] ? "🞃" : "❯"
    tableItem.FoldBtnArr[foldIndex].Text := btnStr

    tableItem.AllGroup[foldIndex].Move(, , , afterHei)

    ; MySlider.SwitchTab(tableItem)
    ; UpdateItemConPos(tableItem, true)
    MySlider.RefreshTab()
}

OnFlodTKTypeChange(tableItem, con, *) {
    foldInfo := tableItem.FoldInfo
    foldIndex := tableItem.ConIndexMap[con].itemConInfo.FoldIndex
    foldInfo.TKTypeArr[foldIndex] := con.Value
}

OnFlodTKChange(tableItem, con, *) {
    foldInfo := tableItem.FoldInfo
    foldIndex := tableItem.ConIndexMap[con].itemConInfo.FoldIndex
    foldInfo.TKArr[foldIndex] := con.Value
}

OnFlodTKEditClick(TKEditCon, tableItem, con, *) {
    foldInfo := tableItem.FoldInfo
    foldIndex := tableItem.ConIndexMap[con].itemConInfo.FoldIndex
    SureAction(sureTriggerKey, holdTime) {
        TKEditCon.Value := sureTriggerKey
        foldInfo.TKArr[foldIndex] := sureTriggerKey
        foldInfo.HoldTimeArr[foldIndex] := holdTime
    }

    MyTriggerKeyGui.SureBtnAction := SureAction
    MyTriggerKeyGui.ShowGui(TKEditCon.Value, foldInfo.HoldTimeArr[foldIndex], false)
}

;刷新函数
UpdateItemConPos(tableItem, isDown) {
    if (isDown) {
        for index, value in tableItem.AllConArr {
            value.UpdatePos(tableItem.OffSetPosY)
        }
    }
    else {
        loop tableItem.AllConArr.Length {
            conInfo := tableItem.AllConArr[tableItem.AllConArr.Length - A_Index + 1]
            conInfo.UpdatePos(tableItem.OffSetPosY)
        }
    }
    for index, value in tableItem.AllGroup {
        value.Redraw()
    }
}

UpdateConItemIndex(tableItem, OperIndex, FoldIndex, IsAdd) {
    DelKeys := []
    for key, value in tableItem.ConIndexMap {
        if (value.index < OperIndex)
            continue

        if (value.index == OperIndex) {
            if (IsAdd) {
                value.index += 1
            }
            else {
                value.itemConInfo.Hide()
                DelKeys.Push(key)
            }
        }
        else if (value.index > OperIndex) {
            if (IsAdd) {
                value.index += 1
            }
            else {
                value.index -= 1
                if (FoldIndex == value.itemConInfo.FoldIndex)
                    value.itemConInfo.DelAfterOffset(70)
            }
        }
    }

    for index, value in DelKeys {
        tableItem.ConIndexMap.Delete(value)
    }
}

UpdateConFoldIndex(tableItem, FoldIndex, IsAdd) {
    tableItem.AllGroup[FoldIndex].GetPos(&x, &y, &w, &h)
    DelOffsetY := h - tableItem.FoldOffsetArr[FoldIndex]

    for index, value in tableItem.AllConArr {
        if (isAdd) {
            if (value.FoldIndex <= FoldIndex)
                continue

            value.FoldIndex += 1
        }
        else {
            if (value.FoldIndex < FoldIndex)
                continue

            if (value.FoldIndex == FoldIndex)
                value.Hide()

            if (value.FoldIndex > FoldIndex) {
                value.FoldIndex -= 1
                value.DelAfterOffset(DelOffsetY)
            }

        }
    }
}

UpdateFoldIndexInfo(FoldInfo, OperIndex, FoldIndex, IsAdd) {
    curMaxItemIndex := 0
    for Index, IndexSpanStr in FoldInfo.IndexSpanArr {
        IndexSpan := StrSplit(IndexSpanStr, "-")
        if (Index < FoldIndex) {
            if (IsInteger(IndexSpan[1]) && IsInteger(IndexSpan[2])) {
                curMaxItemIndex := IndexSpan[2]
            }
            continue
        }
        if (Index == FoldIndex) {
            if (IsAdd) {
                ;已经存在后面数字加1
                if (IsInteger(IndexSpan[1]) && IsInteger(IndexSpan[2])) {
                    IndexSpan[2] := IndexSpan[2] + 1
                }
                else {  ;不存在直接初始化
                    IndexSpan[1] := curMaxItemIndex + 1
                    IndexSpan[2] := curMaxItemIndex + 1
                }
            }
            else {
                IndexSpan[2] := IndexSpan[2] - 1
                if (IndexSpan[2] < IndexSpan[1]) {
                    IndexSpan[1] := "无"
                    IndexSpan[2] := "无"
                }
            }
        }
        if (Index > FoldIndex) {
            Value := IsAdd ? 1 : -1
            if (IsInteger(IndexSpan[1]) && IsInteger(IndexSpan[2])) {
                IndexSpan[1] := IndexSpan[1] + Value
                IndexSpan[2] := IndexSpan[2] + Value
            }
        }
        FoldInfo.IndexSpanArr[Index] := IndexSpan[1] "-" IndexSpan[2]
    }
}

;封装方法
GetFoldGroupHeight(FoldInfo, index, isMenu) {
    height := isMenu ? 85 : 55
    if (FoldInfo.FoldStateArr[index])
        return height
    IndexSpan := StrSplit(FoldInfo.IndexSpanArr[index], "-")
    if (!IsInteger(IndexSpan[1]) || !IsInteger(IndexSpan[2]))
        return height

    height := height + 30
    height := height + (IndexSpan[2] - IndexSpan[1] + 1) * 70
    return height
}

GetFoldAddItemIndex(FoldInfo, FoldIndex) {
    IndexSpan := StrSplit(FoldInfo.IndexSpanArr[FoldIndex], "-")
    if (IsInteger(IndexSpan[1]) && IsInteger(IndexSpan[2])) {
        return IndexSpan[2] + 1
    }

    CurFoldLastIndex := 0
    for index, value in FoldInfo.IndexSpanArr {
        if (index > FoldIndex)
            break

        IndexSpan := StrSplit(value, "-")
        if (IsInteger(IndexSpan[1]) && IsInteger(IndexSpan[2])) {
            CurFoldLastIndex := IndexSpan[2]
        }
    }

    return CurFoldLastIndex + 1
}
