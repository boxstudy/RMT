#Requires AutoHotkey v2.0

; =====================================================================
; 输入编辑器 —— XAML 迁移版（独立实现）
; 公开接口保持：ShowGui(cmd) / SureBtnAction / OwnerHwnd / ParentTile
; =====================================================================

class InputGui {
    __new() {
        this.ParentTile := ""
        this.ui := ""
        this.Gui := ""
        this.SureBtnAction := ""
        this.OwnerHwnd := ""
        this._closed := true
        this._batch := []
        this._batching := false
        this.Data := ""
        this.SerialStr := ""
    }

    ShowGui(cmd) {
        global MySoftData
        if (IsObject(this.ui) && !this._closed)
            this._CloseWindow()
        this._BuildAndShow()
        if (this.OwnerHwnd != "" && MainSoftData.IsModalSubGui) {
            try SafeGuiFromHwnd(this.OwnerHwnd).Opt("+Disabled")
        }
        this._batching := true
        try this.Init(cmd)
        finally {
            this._flushBatch()
        }
        this.RefreshConVisable()
        if (!XamlWin.Open(this.ui, "", XamlWin.Owner(this)))
            this._closed := true
    }

    Hwnd() {
        return (IsObject(this.ui) && this.ui.HasProp("wpfHwnd")) ? this.ui.wpfHwnd : 0
    }

    _EscapeXml(s) {
        s := StrReplace(s, "&", "&amp;")
        s := StrReplace(s, "<", "&lt;")
        s := StrReplace(s, ">", "&gt;")
        s := StrReplace(s, '"', "&quot;")
        return s
    }

    ; batching 中入队，_flushBatch 一次性 BatchUpdate（合并 Init 的多次 Update 为一次 IPC）
    _ComboPush(comboName, propertyName, value) {
        if (this._batching)
            this._batch.Push({ControlName: comboName, PropertyName: propertyName, Value: value})
        else
            this.ui.Update(comboName, propertyName, value)
    }

    _flushBatch() {
        this._batching := false
        if (IsObject(this.ui) && this._batch.Length > 0) {
            this.ui.BatchUpdate(this._batch)
            this._batch := []
        }
    }

    _BuildAndShow() {
        global MySoftData
        this._closed := false
        title := this.ParentTile GetLang("输入编辑器")
        this._title := title
        titleHeight := XAMLHost.CmdTitleBarHeight()

        main := XAML_Generator("Grid").Background("{DynamicResource BgColor}").TextElement_FontSize(XAMLHost.FontSize())
        main.Rows(titleHeight, "*")

        ; === 标题栏 ===
        chrome := XAMLHost.AddCmdTitleBar(main, title, titleHeight)

        ; === 内容 ===
        body := main.Add("Grid").Grid_Row(1).Margin("16,10,16,12")
        body.Rows("36", "36", "60")
        body.Cols("80", "150", "12", "80", "150")

        ; 行0：输入类型 + 备注（白底，内边距与下拉框一致）
        body.Add("TextBlock").Grid_Row(0).Grid_Column(0).Text(GetLang("输入类型:")).VerticalAlignment("Center")
        tc := body.Add("ComboBox").Grid_Row(0).Grid_Column(1).Name("TypeCombo").Height(26).MinHeight(26).VerticalAlignment("Center")
        for t in GetLangArr(["弹窗", "状态", "继续", "继续&取消"])
            tc.Add("ComboBoxItem").Content(t)
        body.Add("TextBlock").Grid_Row(0).Grid_Column(3).Text(GetLang("备注：")).VerticalAlignment("Center")
        body.Add("TextBox").Grid_Row(0).Grid_Column(4).Name("RemarkCon").Height(26).MinHeight(26).MaxHeight(26).VerticalAlignment("Center")
            .VerticalContentAlignment("Center").Padding("2,0")
            .Background("{DynamicResource InputBg}").Foreground("{DynamicResource InputText}")
            .BorderBrush("{DynamicResource InputStroke}").BorderThickness("1")

        ; 行1：交互时 + 结果变量 / 取消时（互斥，同一位置顺延）
        body.Add("TextBlock").Grid_Row(1).Grid_Column(0).Text(GetLang("交互时:")).VerticalAlignment("Center")
        pt := body.Add("ComboBox").Grid_Row(1).Grid_Column(1).Name("PauseTypeCombo").Height(26).MinHeight(26).VerticalAlignment("Center")
        for t in GetLangArr(["暂停当前宏", "暂停所有宏"])
            pt.Add("ComboBoxItem").Content(t)

        slot := body.Add("Grid").Grid_Row(1).Grid_Column(3).Grid_ColumnSpan(2)

        resultRow := slot.Add("Grid").Name("ResultRow")
        resultRow.Cols("80", "150")
        resultRow.Add("TextBlock").Grid_Column(0).Text(GetLang("结果变量：")).VerticalAlignment("Center")
        resultRow.Add("ComboBox").Grid_Column(1).Name("SaveNameCombo").Height(26).MinHeight(26).IsEditable("True").VerticalAlignment("Center")

        cancelRow := slot.Add("Grid").Name("CancelRow").Visibility("Collapsed")
        cancelRow.Cols("80", "150")
        cancelRow.Add("TextBlock").Grid_Column(0).Text(GetLang("取消时:")).VerticalAlignment("Center")
        ct := cancelRow.Add("ComboBox").Grid_Column(1).Name("CancelTypeCombo").Height(26).MinHeight(26).VerticalAlignment("Center")
        for t in GetLangArr(["终止当前宏", "终止所有宏"])
            ct.Add("ComboBoxItem").Content(t)

        ; 行2：确定
        btnRow := body.Add("StackPanel").Grid_Row(2).Grid_ColumnSpan(5).Orientation("Horizontal").HorizontalAlignment("Center").VerticalAlignment("Bottom").Margin("0,0,0,6")
        AddCmdOkBtn(btnRow)

        ; === 创建 XAMLHost ===
        tmp := StrReplace(XAML_TEMPLATE, "%CaptionHeight%", titleHeight)
        this.ui := XAMLHost(StrReplace(tmp, "%app%", main.ToString()), "", this.OwnerHwnd)
        this.ui.xaml := StrReplace(this.ui.xaml, 'Width="940" Height="700"', 'Title="' this._EscapeXml(title) '" Width="520" Height="204" Opacity="0"')
        this.ui.xaml := StrReplace(this.ui.xaml, 'FontFamily="Segoe UI Variable Display, Segoe UI, sans-serif"', 'FontFamily="' MainSoftData.FontType '"')
        this.ui.xaml := StrReplace(this.ui.xaml, '%resources%', '')

        ; === 事件 ===
        this.ui.OnEvent("Window", "Closing", ObjBindMethod(this, "OnWindowClosing"))
        this.ui.OnEvent("Window", "LoadedHwnd", ObjBindMethod(this, "OnWindowLoad"))
        this.ui.OnEvent("BtnClosePanel", "Click", ObjBindMethod(this, "OnCancelClick"))
        BindCmdEditorChrome(this.ui, "#指令手册/7-输入", ObjBindMethod(this, "TriggerMacro"))
        this.ui.OnEvent("TypeCombo", "SelectionChanged", ObjBindMethod(this, "OnRefreshType"))
        this.ui.OnEvent("BtnOk", "Click", ObjBindMethod(this, "OnClickSureBtn"))

    }

    OnWindowLoad(state, ctrl, event) {
        XamlWin.OnLoadTheme(this.ui)
    }

    OnWindowClosing(state, ctrl, event) {
        if (this.OwnerHwnd != "" && MainSoftData.IsModalSubGui) {
            try SafeGuiFromHwnd(this.OwnerHwnd).Opt("-Disabled")
        }
        this.ui := ""
        this._closed := true
    }

    OnCancelClick(state, ctrl, event) {
        this._CloseWindow()
    }

    _CloseWindow() {
        if (this.OwnerHwnd != "" && MainSoftData.IsModalSubGui) {
            try SafeGuiFromHwnd(this.OwnerHwnd).Opt("-Disabled")
        }
        if (IsObject(this.ui)) {
            try this.ui.Update("Window", "Close", "")
        }
        this.ui := ""
        this._closed := true
    }

    _SetDDL(comboName, items, text) {
        if (!IsObject(this.ui))
            return
        this._ComboPush(comboName, "ClearItems", "")
        for it in items {
            if (it == "")
                continue
            this._ComboPush(comboName, "AddItem", it)
        }
        for i, it in items {
            if (it == text) {
                this._ComboPush(comboName, "SelectedIndex", String(i - 1))
                return
            }
        }
        this._ComboPush(comboName, "SelectedIndex", "0")
    }

    _SetCombo(comboName, items, text) {
        if (!IsObject(this.ui))
            return
        this._ComboPush(comboName, "ClearItems", "")
        for it in items {
            if (it == "")
                continue
            this._ComboPush(comboName, "AddItem", it)
        }
        this._ComboPush(comboName, "Text", text)
    }

    Init(cmd) {
        cmdArr := cmd != "" ? StrSplit(cmd, "_") : []
        this.SerialStr := cmdArr.Length >= 1 ? cmdArr[1] : GetCMDSerialStr("输入")
        this.ui.Update("RemarkCon", "Text", cmdArr.Length >= 2 ? cmdArr[2] : "")
        this.Data := GetMacroCMDData(this.SerialStr)
        this.DLVariableArr := GetGuiVarArr(1)
        this.DLArrayArr := GetGuiArrNameArr()

        this._SetDDL("TypeCombo", GetLangArr(["弹窗", "状态", "继续", "继续&取消"]), GetLang(this.Data.Type))
        this._SetDDL("PauseTypeCombo", GetLangArr(["暂停当前宏", "暂停所有宏"]), GetLang(this.Data.PauseType))
        this._SetDDL("CancelTypeCombo", GetLangArr(["终止当前宏", "终止所有宏"]), GetLang(this.Data.CancelType))
        this._SetCombo("SaveNameCombo", GetGuiVarArr(), this.Data.SaveName)
    }

    OnRefreshType(state := "", ctrl := "", event := "") {
        this.RefreshConVisable()
    }

    RefreshConVisable() {
        if (!IsObject(this.ui))
            return
        typeText := this.ui.Query("TypeCombo")
        IsPopUp := typeText == GetLang("弹窗")
        IsState := typeText == GetLang("状态")
        IsGoOn := typeText == GetLang("继续")
        IsGoOnAndCancel := typeText == GetLang("继续&取消")

        HasInter := IsPopUp || IsState || IsGoOn || IsGoOnAndCancel
        HasCancel := IsGoOnAndCancel
        HasRes := IsPopUp || IsState

        ; 交互时恒显示；结果变量 / 取消时按类型互斥，同一位置顺延
        this.ui.Update("CancelRow", "Visibility", HasCancel ? "Visible" : "Collapsed")
        this.ui.Update("ResultRow", "Visibility", HasRes ? "Visible" : "Collapsed")
    }

    OnClickSureBtn(state, ctrl, event) {
        if (!this.CheckIfValid())
            return
        this.SaveData()
        CommandStr := this.GetCommandStr()
        action := this.SureBtnAction
        action(CommandStr)
        this._CloseWindow()
    }

    CheckIfValid() {
        if (this.ui.Query("ResultRow>Visibility") != "Collapsed") {
            if (!CheckVarNameIfValid(this.ui.Query("SaveNameCombo")))
                return false
        }
        return true
    }

    TriggerMacro(state := "", ctrl := "", event := "") {
        this.SaveData()
        CommandStr := this.GetCommandStr()
        OnTriggerSepcialItemMacro(CommandStr)

        typeText := this.ui.Query("TypeCombo")
        IsPopUp := typeText == GetLang("弹窗")
        IsState := typeText == GetLang("状态")
        HasRes := IsPopUp || IsState
        if (HasRes) {
            Res := ""
            if (MySoftData.VariableMap.Has(this.Data.SaveName))
                Res := MySoftData.VariableMap[this.Data.SaveName]

            if (Res != "") {
                tip1 := Format(GetLang("变量：{}"), this.Data.SaveName)
                tip2 := Format(GetLang("值：{}"), Res)
                MsgBox(tip1 "`n" tip2)
            }
        }
    }

    GetCommandStr() {
        textOnly := RegExReplace(this.Data.SerialStr, "\d+")
        numbersOnly := RegExReplace(this.Data.SerialStr, "\D+")
        CommandStr := Format("{}{}", GetLang(textOnly), numbersOnly)
        Remark := this.ui.Query("RemarkCon")
        if (ShouldAutoGenerateRemark(Remark)) {
            Remark := this.ui.Query("TypeCombo")
        }
        CommandStr := CorrectRemark(CommandStr, Remark)
        return CommandStr
    }

    SaveData() {
        this.Data.Type := GetLangKey(this.ui.Query("TypeCombo"))
        this.Data.PauseType := GetLangKey(this.ui.Query("PauseTypeCombo"))
        this.Data.CancelType := GetLangKey(this.ui.Query("CancelTypeCombo"))
        this.Data.SaveName := GetVarName(this.ui.Query("SaveNameCombo"))

        if (this.ui.Query("ResultRow>Visibility") != "Collapsed") {
            MySoftData.GlobalVariMap[this.Data.SaveName] := true
        }
        SaveMacroCMDData(this.Data)
    }
}
