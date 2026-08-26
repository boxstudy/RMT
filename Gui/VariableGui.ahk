#Requires AutoHotkey v2.0

; =====================================================================
; 变量编辑器 —— XAML 迁移版（独立实现）
; 公开接口保持：ShowGui(cmd) / SureBtnAction / OwnerHwnd / ParentTile
; =====================================================================

class VariableGui {
    __new() {
        this.ParentTile := ""
        this.ui := ""
        this.Gui := ""
        this.SureBtnAction := ""
        this.OwnerHwnd := ""
        this._closed := true
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
        this.Init(cmd)      ; 在 Show 前设值（wpfHwnd 未建，BatchUpdate 入队，窗口创建时一起应用）
        this._ShowWindow()
        this.OnRefresh()
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

    _BuildAndShow() {
        global MySoftData
        this._closed := false
        title := this.ParentTile GetLang("变量编辑器")
        this._title := title
        titleHeight := "30"

        main := XAML_Generator("Grid").Background("{DynamicResource BgColor}").TextElement_FontSize(XAMLHost.GetDesignFontSize())
        main.Rows(titleHeight, "*")

        ; === 标题栏 ===
        tb := main.Add("Border").Grid_Row(0).Background("{DynamicResource TitleBarColor}").Name("DragArea")
        tbInner := tb.Add("Grid")
        tbInner.Add("TextBlock").Text(title).Foreground("{DynamicResource TitleBarForeground}").FontSize(12).FontWeight("SemiBold").VerticalAlignment("Center").Margin("12,0,0,0")
        BtnGroup := tbInner.Add("StackPanel").Orientation("Horizontal").HorizontalAlignment("Right")
        closeBtn := BtnGroup.Add("Button").Name("BtnClosePanel").WindowChrome_IsHitTestVisibleInChrome("True").Width(40).Background("Transparent").Foreground("{DynamicResource TitleBarForeground}").BorderThickness(0)
        closeBtn.Add("TextBlock").Text(Chr(0xE8BB)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize(10).VerticalAlignment("Center").HorizontalAlignment("Center")

        ; === 内容 ===
        body := main.Add("Grid").Grid_Row(1).Margin("10,6")
        body.Rows("32", "Auto", "*")
        body.Cols("*")

        ; 行0：备注 + IsIgnoreExist + 帮助
        row0 := body.Add("StackPanel").Grid_Row(0).Orientation("Horizontal").VerticalAlignment("Center")
        row0.Add("TextBlock").Text(GetLang("备注：")).VerticalAlignment("Center")
        row0.Add("TextBox").Name("RemarkCon").Width(150).Height(24).MinHeight(24).Margin("4,0,0,0")
        row0.Add("CheckBox").Name("IsIgnoreExist").Content(GetLang("如果变量存在则不改变数值")).VerticalAlignment("Center").Margin("20,0,0,0")
        row0.Add("Button").Name("BtnHelp").Content("?").Width(30).Height(26).MinHeight(26).Margin("8,0,0,0")

        ; 行1：变量 GroupBox
        vg := body.Add("GroupBox").Grid_Row(1).Header(GetLang("变量："))
            .BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1").Foreground("{DynamicResource TextMain}").Margin("0,2,0,2")
        vGrid := vg.Add("Grid").Margin("8,4")
        vGrid.Cols("45", "120", "90", "120", "120", "120")
        vGrid.Rows("26", "30", "30", "30", "30")
        vGrid.Add("TextBlock").Grid_Row(0).Grid_Column(0).Text(GetLang("开关")).HorizontalAlignment("Center").VerticalAlignment("Center")
        vGrid.Add("TextBlock").Grid_Row(0).Grid_Column(1).Text(GetLang("变量名")).VerticalAlignment("Center")
        vGrid.Add("TextBlock").Grid_Row(0).Grid_Column(2).Text(GetLang("变量类型")).VerticalAlignment("Center")
        vGrid.Add("TextBlock").Grid_Row(0).Grid_Column(3).Text(GetLang("选择/输入")).VerticalAlignment("Center")
        vGrid.Add("TextBlock").Grid_Row(0).Grid_Column(4).Text(GetLang("最小值选择/输入")).VerticalAlignment("Center")
        vGrid.Add("TextBlock").Grid_Row(0).Grid_Column(5).Text(GetLang("最大值选择/输入")).VerticalAlignment("Center")
        loop 4 {
            r := A_Index
            vGrid.Add("CheckBox").Grid_Row(r).Grid_Column(0).Name("Tog" r).HorizontalAlignment("Center").VerticalAlignment("Center")
            vGrid.Add("ComboBox").Grid_Row(r).Grid_Column(1).Name("Var" r).Height(24).MinHeight(24).IsEditable("True")
            ot := vGrid.Add("ComboBox").Grid_Row(r).Grid_Column(2).Name("OpType" r).Height(24).MinHeight(24)
            for t in GetLangArr(["数值", "随机数值", "字符", "系统", "删除"])
                ot.Add("ComboBoxItem").Content(t)
            vGrid.Add("ComboBox").Grid_Row(r).Grid_Column(3).Name("Copy" r).Height(24).MinHeight(24).IsEditable("True")
            vGrid.Add("ComboBox").Grid_Row(r).Grid_Column(4).Name("Min" r).Height(24).MinHeight(24).IsEditable("True")
            vGrid.Add("ComboBox").Grid_Row(r).Grid_Column(5).Name("Max" r).Height(24).MinHeight(24).IsEditable("True")
        }

        ; 行2：确定
        btnRow := body.Add("StackPanel").Grid_Row(2).Orientation("Horizontal").HorizontalAlignment("Center").VerticalAlignment("Center")
        btnRow.Add("Button").Name("BtnOk").Content(GetLang("确定")).Width(100).Height(36).MinHeight(36)

        ; === 创建 XAMLHost ===
        tmp := StrReplace(XAML_TEMPLATE, "%CaptionHeight%", titleHeight)
        this.ui := XAMLHost(StrReplace(tmp, "%app%", main.ToString()), "", this.OwnerHwnd)
        this.ui.xaml := StrReplace(this.ui.xaml, 'Width="940" Height="700"', 'Title="' this._EscapeXml(title) '" Width="700" Height="310" Opacity="0"')
        this.ui.xaml := StrReplace(this.ui.xaml, 'FontFamily="Segoe UI Variable Display, Segoe UI, sans-serif"', 'FontFamily="' MainSoftData.FontType '"')
        this.ui.xaml := StrReplace(this.ui.xaml, '%resources%', '')

        ; === 事件 ===
        this.ui.OnEvent("Window", "Closing", ObjBindMethod(this, "OnWindowClosing"))
        this.ui.OnEvent("Window", "LoadedHwnd", ObjBindMethod(this, "OnWindowLoad"))
        this.ui.OnEvent("BtnClosePanel", "Click", ObjBindMethod(this, "OnCancelClick"))
        this.ui.OnEvent("BtnHelp", "Click", ObjBindMethod(this, "OnClickTypeHelpBtn"))
        loop 4 {
            this.ui.OnEvent("OpType" A_Index, "SelectionChanged", ObjBindMethod(this, "OnRefresh"))
        }
        this.ui.OnEvent("BtnOk", "Click", ObjBindMethod(this, "OnClickSureBtn"))
    }

    _ShowWindow() {
        this.ui.Show()

        gotHwnd := false
        loop 40 {
            if (this.ui.HasProp("wpfHwnd") && this.ui.wpfHwnd) {
                gotHwnd := true
                if (this.OwnerHwnd != "")
                    try this.ui.Update("Window", "NativeOwner", String(this.OwnerHwnd))
                try WinActivate("ahk_id " this.ui.wpfHwnd)
                try SetTimer((*) => this.ui.Update("Window", "Opacity", "1"), -10)
                break
            }
            Sleep(50)
        }
        if (!gotHwnd)
            this._closed := true
    }

    OnWindowLoad(state, ctrl, event) {
        try {
            themeName := MainSoftData.HasProp("Theme") ? MainSoftData.Theme : "RMT_Light"
            ApplyXamlTheme(this.ui, themeName)
        } catch {
        } finally {
        }
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
        if (IsObject(this.ui)) {
            try this.ui.Update("Window", "Close", "")
        }
        if (this.OwnerHwnd != "" && MainSoftData.IsModalSubGui) {
            try SafeGuiFromHwnd(this.OwnerHwnd).Opt("-Disabled")
        }
        this.ui := ""
        this._closed := true
    }

    _SetCombo(comboName, items, text) {
        if (!IsObject(this.ui))
            return
        this.ui.Update(comboName, "ClearItems", "")
        for it in items {
            if (it == "")
                continue
            this.ui.Update(comboName, "AddItem", it)
        }
        this.ui.Update(comboName, "Text", text)
    }

    ; 批量设置 ComboBox（把 ClearItems/AddXamlItem/Text 合并进 batch，最后一次性 BatchUpdate）
    _BatchSetCombo(batch, comboName, items, text) {
        batch.Push({ControlName: comboName, PropertyName: "ClearItems", Value: ""})
        for it in items {
            if (it == "")
                continue
            batch.Push({ControlName: comboName, PropertyName: "AddItem", Value: it})
        }
        batch.Push({ControlName: comboName, PropertyName: "Text", Value: text})
    }

    _OpTypeValue(i) {
        v := IsObject(this.ui) ? this.ui.Query("OpType" i ">SelectedIndex") : ""
        return IsNumber(v) ? Integer(v) + 1 : 1
    }

    Init(cmd) {
        cmdArr := cmd != "" ? SplitCommand(cmd) : []
        this.SerialStr := cmdArr.Length >= 1 ? cmdArr[1] : GetCMDSerialStr("变量")
        this.Data := GetMacroCMDData(this.SerialStr)
        this.DLVariableArr := GetGuiVarArr(1)

        batch := []
        batch.Push({ControlName: "RemarkCon", PropertyName: "Text", Value: cmdArr.Length >= 2 ? cmdArr[2] : ""})
        batch.Push({ControlName: "IsIgnoreExist", PropertyName: "IsChecked", Value: this.Data.IsIgnoreExist ? "True" : "False"})
        loop 4 {
            i := A_Index
            batch.Push({ControlName: "Tog" i, PropertyName: "IsChecked", Value: this.Data.ToggleArr[i] ? "True" : "False"})
            this._BatchSetCombo(batch, "Var" i, GetGuiVarArr(), GetLang(this.Data.VariableArr[i]))
            batch.Push({ControlName: "OpType" i, PropertyName: "SelectedIndex", Value: String(this.Data.OperaTypeArr[i] - 1)})
            this._BatchSetCombo(batch, "Copy" i, this.GetGuiVarArrByType(this.Data.OperaTypeArr[i]), GetLang(this.Data.CopyVariableArr[i]))
            this._BatchSetCombo(batch, "Min" i, GetGuiVarArr(), GetLang(this.Data.MinVariableArr[i]))
            this._BatchSetCombo(batch, "Max" i, GetGuiVarArr(), GetLang(this.Data.MaxVariableArr[i]))
        }
        this.ui.BatchUpdate(batch)
    }

    GetGuiVarArrByType(type) {
        switch type {
            case 1:
                return GetGuiVarArr()
            case 2:
                return []
            case 3:
                return []
            case 4:
                return GetSystemVarArr()
            case 5:
                return []
        }
        return []
    }

    OnRefresh(state := "", ctrl := "", event := "") {
        if (!IsObject(this.ui))
            return
        batch := []
        loop 4 {
            i := A_Index
            OperaTypeValue := this._OpTypeValue(i)
            EnableCopy := OperaTypeValue == 1 || OperaTypeValue == 3 || OperaTypeValue == 4
            EnableMinMax := OperaTypeValue == 2
            batch.Push({ControlName: "Copy" i, PropertyName: "IsEnabled", Value: EnableCopy ? "True" : "False"})
            batch.Push({ControlName: "Min" i, PropertyName: "IsEnabled", Value: EnableMinMax ? "True" : "False"})
            batch.Push({ControlName: "Max" i, PropertyName: "IsEnabled", Value: EnableMinMax ? "True" : "False"})
            CurValue := GetLang(this.ui.Query("Copy" i))
            DLArr := this.GetGuiVarArrByType(OperaTypeValue)
            this._BatchSetCombo(batch, "Copy" i, DLArr, CurValue)
        }
        this.ui.BatchUpdate(batch)
    }

    OnClickTypeHelpBtn(state := "", ctrl := "", event := "") {
        str1 := GetLang("循环次数：如指令上级存在 循环 指令，则该变量为该循环体执行的次数")
        str2 := GetLang("宏循环次数：配置整体执行的次数")
        str3 := GetLang("句柄ID：实时获取当前鼠标窗口句柄ID")
        str4 := GetLang("当前鼠标颜色：实时获取当前鼠标指针下颜色（形如EEFF44）")
        str5 := GetLang("当前鼠标坐标X：实时获取当前鼠标X")
        str6 := GetLang("当前鼠标坐标Y：实时获取当前鼠标Y")
        str7 := GetLang("当前日期：实时获取当前日期（形如2026-04-12）")
        str8 := GetLang("当前时间：实时获取当前时间（形如19:46）")
        str9 := GetLang("当前时间秒：实时获取当前时间(秒)（形如19:46:58）")
        str10 := GetLang("当前秒：实时获取当前秒（形如58）")
        str := Format("{}`n{}`n{}`n{}`n{}`n{}`n{}`n{}`n{}`n{}", str1, str2, str3, str4, str5, str6, str7, str8, str9, str10)
        MsgBox(str, GetLang("系统变量说明"), "Owner" this.Hwnd())
    }

    OnClickSureBtn(state, ctrl, event) {
        if (!this.CheckIfValid())
            return
        this.SaveVariableData()
        CommandStr := this.GetCommandStr()
        action := this.SureBtnAction
        this._CloseWindow()
        if (action != "")
            action(CommandStr)
    }

    CheckIfValid() {
        loop 4 {
            if (this.ui.Query("Tog" A_Index) == "True" && !CheckVarNameIfValid(this.ui.Query("Var" A_Index)))
                return false
        }
        return true
    }

    GetCommandStr() {
        textOnly := RegExReplace(this.Data.SerialStr, "\d+")
        numbersOnly := RegExReplace(this.Data.SerialStr, "\D+")
        CommandStr := Format("{}{}", GetLang(textOnly), numbersOnly)
        Remark := this.ui.Query("RemarkCon")
        if (ShouldAutoGenerateRemark(Remark)) {
            Remark := ""
            loop 4 {
                i := A_Index
                if (this.ui.Query("Tog" i) == "True") {
                    CurVarRemark := this.ui.Query("Var" i)
                    if (this._OpTypeValue(i) == 1) {
                        if (IsNumber(this.ui.Query("Copy" i))) {
                            CurVarRemark .= "=" this.ui.Query("Copy" i)
                        }
                    }
                    else if (this._OpTypeValue(i) == 2) {
                        CurVarRemark .= GetLang("随机")
                        isNumSpan := IsNumber(this.ui.Query("Min" i)) && IsNumber(this.ui.Query("Max" i))
                        if (isNumSpan)
                            CurVarRemark .= this.ui.Query("Min" i) "~" this.ui.Query("Max" i)
                    }
                    else if (this._OpTypeValue(i) == 5) {
                        CurVarRemark .= GetLang("删除")
                    }
                    Remark .= CurVarRemark "&"
                }
            }
            Remark := RTrim(Remark, "&")
        }
        CommandStr := CorrectRemark(CommandStr, Remark)
        return CommandStr
    }

    SaveVariableData() {
        this.Data.IsIgnoreExist := this.ui.Query("IsIgnoreExist") == "True" ? 1 : 0
        loop 4 {
            i := A_Index
            this.Data.ToggleArr[i] := this.ui.Query("Tog" i) == "True" ? 1 : 0
            this.Data.VariableArr[i] := GetLangKey(this.ui.Query("Var" i))
            this.Data.OperaTypeArr[i] := this._OpTypeValue(i)
            this.Data.CopyVariableArr[i] := GetLangKey(this.ui.Query("Copy" i))
            this.Data.MinVariableArr[i] := GetLangKey(this.ui.Query("Min" i))
            this.Data.MaxVariableArr[i] := GetLangKey(this.ui.Query("Max" i))
        }
        loop 4 {
            if (this.Data.ToggleArr[A_Index])
                MySoftData.GlobalVariMap[this.Data.VariableArr[A_Index]] := true
        }
        SaveMacroCMDData(this.Data)
    }
}
