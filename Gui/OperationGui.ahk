#Requires AutoHotkey v2.0
#Include OperationSubGui.ahk

; =====================================================================
; 运算编辑器 —— XAML 迁移版（独立实现）
; 公开接口保持：ShowGui(cmd) / SureBtnAction / OwnerHwnd / ParentTile
; =====================================================================

class OperationGui {
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
        this.OperationSubGui := ""
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
        title := this.ParentTile GetLang("运算编辑器")
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
        body := main.Add("Grid").Grid_Row(1).Margin("10,8")
        body.Rows("32", "26", "34", "34", "34", "34", "*")
        body.Cols("40", "310", "55", "130")

        ; 行0：备注
        row0 := body.Add("StackPanel").Grid_Row(0).Grid_ColumnSpan(4).Orientation("Horizontal").VerticalAlignment("Center")
        row0.Add("TextBlock").Text(GetLang("备注：")).VerticalAlignment("Center")
        row0.Add("TextBox").Name("RemarkCon").Width(150).Height(24).MinHeight(24).Margin("4,0,0,0")

        ; 行1：表头
        body.Add("TextBlock").Grid_Row(1).Grid_Column(0).Text(GetLang("开关")).VerticalAlignment("Center")
        body.Add("TextBlock").Grid_Row(1).Grid_Column(1).Text(GetLang("运算表达式")).VerticalAlignment("Center")
        body.Add("TextBlock").Grid_Row(1).Grid_Column(3).Text(GetLang("结果保存变量")).VerticalAlignment("Center")

        ; 行2-5：4 行表达式
        loop 4 {
            r := A_Index + 1
            body.Add("CheckBox").Grid_Row(r).Grid_Column(0).Name("Toggle" A_Index).VerticalAlignment("Center")
            body.Add("TextBox").Grid_Row(r).Grid_Column(1).Name("Expr" A_Index).Height(26).MinHeight(26).Margin("0,0,4,0")
                .IsReadOnly("True").VerticalContentAlignment("Center")
                .Background("{DynamicResource InputBg}").Foreground("{DynamicResource InputText}")
                .BorderBrush("{DynamicResource InputStroke}").BorderThickness("1")
            body.Add("Button").Grid_Row(r).Grid_Column(2).Name("EditBtn" A_Index).Content(GetLang("编辑")).Height(26).MinHeight(26).Margin("4,0,0,0")
            body.Add("ComboBox").Grid_Row(r).Grid_Column(3).Name("UpdateName" A_Index).Height(26).MinHeight(26).Margin("4,0,0,0").IsEditable("True")
        }

        ; 行6：确定
        btnRow := body.Add("StackPanel").Grid_Row(6).Grid_ColumnSpan(4).Orientation("Horizontal").HorizontalAlignment("Center").VerticalAlignment("Center")
        btnRow.Add("Button").Name("BtnOk").Content(GetLang("确定")).Width(100).Height(36).MinHeight(36)

        ; === 创建 XAMLHost ===
        tmp := StrReplace(XAML_TEMPLATE, "%CaptionHeight%", titleHeight)
        this.ui := XAMLHost(StrReplace(tmp, "%app%", main.ToString()), "", this.OwnerHwnd)
        this.ui.xaml := StrReplace(this.ui.xaml, 'Width="940" Height="700"', 'Title="' this._EscapeXml(title) '" Width="560" Height="292" Opacity="0"')
        this.ui.xaml := StrReplace(this.ui.xaml, 'FontFamily="Segoe UI Variable Display, Segoe UI, sans-serif"', 'FontFamily="' MainSoftData.FontType '"')
        this.ui.xaml := StrReplace(this.ui.xaml, '%resources%', '')

        ; === 事件 ===
        this.ui.OnEvent("Window", "Closing", ObjBindMethod(this, "OnWindowClosing"))
        this.ui.OnEvent("Window", "LoadedHwnd", ObjBindMethod(this, "OnWindowLoad"))
        this.ui.OnEvent("BtnClosePanel", "Click", ObjBindMethod(this, "OnCancelClick"))
        loop 4 {
            this.ui.OnEvent("EditBtn" A_Index, "Click", this.OnEditVariableBtnClick.Bind(this, A_Index))
        }
        this.ui.OnEvent("BtnOk", "Click", ObjBindMethod(this, "OnClickSureBtn"))

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
        if (this.OwnerHwnd != "" && MainSoftData.IsModalSubGui) {
            try SafeGuiFromHwnd(this.OwnerHwnd).Opt("-Disabled")
        }
        if (IsObject(this.ui)) {
            try this.ui.Update("Window", "Close", "")
        }
        this.ui := ""
        this._closed := true
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
        this.SerialStr := cmdArr.Length >= 1 ? cmdArr[1] : GetCMDSerialStr("运算")
        this.ui.Update("RemarkCon", "Text", cmdArr.Length >= 2 ? cmdArr[2] : "")
        this.Data := GetMacroCMDData(this.SerialStr)
        this.DLVariableArr := GetGuiVarArr()

        loop this.Data.ToggleArr.Length {
            i := A_Index
            this.ui.Update("Toggle" i, "IsChecked", this.Data.ToggleArr[i] ? "True" : "False")
            this.ui.Update("Expr" i, "Text", GetLangStr(this.Data.ExpressionArr[i], 1))
            this._SetCombo("UpdateName" i, this.DLVariableArr, GetLang(this.Data.UpdateNameArr[i]))
        }
    }

    GetCommandStr() {
        textOnly := RegExReplace(this.Data.SerialStr, "\d+")
        numbersOnly := RegExReplace(this.Data.SerialStr, "\D+")
        CommandStr := Format("{}{}", GetLang(textOnly), numbersOnly)
        Remark := this.ui.Query("RemarkCon")
        if (ShouldAutoGenerateRemark(Remark)) {
            Remark := GetLang("更新")
            loop 4 {
                if (this.ui.Query("Toggle" A_Index) == "True") {
                    Remark .= this.ui.Query("UpdateName" A_Index) "&"
                }
            }
            Remark := RTrim(Remark, "&")
        }
        CommandStr := CorrectRemark(CommandStr, Remark)
        return CommandStr
    }

    OnEditVariableBtnClick(Index, state := "", ctrl := "", event := "") {
        if (this.OperationSubGui == "") {
            this.OperationSubGui := OperationSubGui()
        }

        ParentTile := StrReplace(this._title, GetLang("编辑器"), "")
        this.OperationSubGui.ParentTile := ParentTile "-"

        if (MainSoftData.IsModalSubGui && this.ui != "") {
            this.OperationSubGui.OwnerHwnd := this.Hwnd()
        }
        else {
            this.OperationSubGui.OwnerHwnd := ""
        }

        this.OperationSubGui.SureBtnAction := (Index, ExpressStr) => this.OnSureOperationBtnClick(
            Index, ExpressStr)

        this.OperationSubGui.ShowGui(Index, this.ui.Query("Expr" Index))
    }

    OnSureOperationBtnClick(Index, ExpressStr) {
        if (IsObject(this.ui))
            this.ui.Update("Expr" Index, "Text", ExpressStr)
    }

    OnClickSureBtn(state, ctrl, event) {
        if (!this.CheckIfValid())
            return
        this.SaveOperationData()
        action := this.SureBtnAction
        action(this.GetCommandStr())
        this._CloseWindow()
    }

    CheckIfValid() {
        loop 4 {
            IsOn := this.ui.Query("Toggle" A_Index) == "True"
            if (IsOn && !CheckVarNameIfValid(this.ui.Query("UpdateName" A_Index))) {
                return false
            }
        }
        return true
    }

    SaveOperationData() {
        loop this.Data.ToggleArr.Length {
            i := A_Index
            this.Data.ToggleArr[i] := this.ui.Query("Toggle" i) == "True"
            this.Data.ExpressionArr[i] := GetLangStr(this.ui.Query("Expr" i), 2)
            this.Data.UpdateNameArr[i] := GetVarName(this.ui.Query("UpdateName" i))
        }

        loop this.Data.ToggleArr.Length {
            if (this.Data.ToggleArr[A_Index])
                MySoftData.GlobalVariMap[this.Data.UpdateNameArr[A_Index]] := true
        }
        SaveMacroCMDData(this.Data)
    }
}
