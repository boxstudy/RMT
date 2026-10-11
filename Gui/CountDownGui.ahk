#Requires AutoHotkey v2.0

; =====================================================================
; 倒计时编辑器 —— 其他 / 倒计时（MinTool CountDown 指令化）
; =====================================================================

class CountDownGui {
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
        this._syncing := false
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
        if (!XamlWin.Open(this.ui, "", XamlWin.Owner(this)))
            this._closed := true
        this.ToggleFunc(true)
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
        this._ComboPush(comboName, "ClearItems", "")
        for it in items {
            if (it == "")
                continue
            this._ComboPush(comboName, "AddItem", it)
        }
        this._ComboPush(comboName, "Text", text)
    }

    _Combo(parent, name, width := 90) {
        return parent.Add("ComboBox").Name(name).Width(width).Height(26).MinHeight(26).IsEditable("True")
            .VerticalAlignment("Center").VerticalContentAlignment("Center").FontSize("11")
            .Foreground("{DynamicResource InputText}").Background("{DynamicResource InputBg}")
            .BorderBrush("{DynamicResource InputStroke}").BorderThickness("1")
    }

    _Label(parent, text, col := "", row := "") {
        el := parent.Add("TextBlock").Text(GetLang(text)).VerticalAlignment("Center")
            .Foreground("{DynamicResource TextMain}").FontSize("12")
        if (row != "")
            el.Grid_Row(row)
        if (col != "")
            el.Grid_Column(col)
        return el
    }

    _SliderCell(parent, row, col, sliderName, valName, minv, maxv, defv, span := 1) {
        sl := parent.Add("Grid").Grid_Row(row).Grid_Column(col)
        if (span > 1)
            sl.Grid_ColumnSpan(span)
        sl.Cols("*", "36")
        sl.Add("Slider").Name(sliderName).Grid_Column(0).Height(28).Margin("0,0,6,0")
            .Minimum(minv).Maximum(maxv).Value(defv)
            .IsSnapToTickEnabled("True").TickFrequency("1").IsMoveToPointEnabled("True")
            .VerticalAlignment("Center").Tag("Throttle:50")
        sl.Add("TextBlock").Name(valName).Grid_Column(1).Text(String(defv)).VerticalAlignment("Center")
            .HorizontalAlignment("Center").Foreground("{DynamicResource TextMain}").FontSize("12")
    }

    _BuildAndShow() {
        global MySoftData
        this._closed := false
        title := this.ParentTile GetLang("倒计时编辑器")
        this._title := title
        titleHeight := XAMLHost.CmdTitleBarHeight()

        main := XAML_Generator("Grid").Background("{DynamicResource BgColor}").TextElement_FontSize(XAMLHost.FontSize())
        main.Rows(titleHeight, "*")
        chrome := XAMLHost.AddCmdTitleBar(main, title, titleHeight)

        body := main.Add("Grid").Grid_Row(1).Margin("16,8,16,8")
        body.Rows("32", "32", "32", "32", "44")
        body.Cols("84", "68", "12", "68", "12", "68", "*")

        this._Label(body, "备注：", 0, 0)
        body.Add("TextBox").Grid_Row(0).Grid_Column(1).Grid_ColumnSpan(6).Name("RemarkCon").Height(26).MinHeight(26).MaxHeight(26).VerticalAlignment("Center")
            .VerticalContentAlignment("Center").Padding("2,0")
            .Background("{DynamicResource InputBg}").Foreground("{DynamicResource InputText}")
            .BorderBrush("{DynamicResource InputStroke}").BorderThickness("1")

        this._Label(body, "时长：", 0, 1)
        this._Combo(body, "HourCon", 68).Grid_Row(1).Grid_Column(1).ToolTip(GetLang("时"))
        body.Add("TextBlock").Grid_Row(1).Grid_Column(2).Text("：").HorizontalAlignment("Center").VerticalAlignment("Center")
            .Foreground("{DynamicResource TextMain}").FontSize("12")
        this._Combo(body, "MinCon", 68).Grid_Row(1).Grid_Column(3).ToolTip(GetLang("分"))
        body.Add("TextBlock").Grid_Row(1).Grid_Column(4).Text("：").HorizontalAlignment("Center").VerticalAlignment("Center")
            .Foreground("{DynamicResource TextMain}").FontSize("12")
        this._Combo(body, "SecCon", 68).Grid_Row(1).Grid_Column(5).ToolTip(GetLang("秒"))

        this._Label(body, "坐标：", 0, 2)
        this._Combo(body, "PosXCon", 68).Grid_Row(2).Grid_Column(1)
        this._Combo(body, "PosYCon", 68).Grid_Row(2).Grid_Column(3)
        this._Label(body, "模式：", 5, 2)
        we := body.Add("ComboBox").Grid_Row(2).Grid_Column(6).Name("WaitEndCombo").Height(26).MinHeight(26).VerticalAlignment("Center")
            .VerticalContentAlignment("Center").FontSize("11")
            .Foreground("{DynamicResource InputText}").Background("{DynamicResource InputBg}")
            .BorderBrush("{DynamicResource InputStroke}").BorderThickness("1")
        for t in GetLangArr(["等待结束", "不等待"])
            we.Add("ComboBoxItem").Content(t)

        this._Label(body, "字体大小：", 0, 3)
        this._SliderCell(body, 3, 1, "FontSizeCon", "FontSizeValText", 8, 72, 32, 3)
        this._Label(body, "透明度：", 5, 3)
        this._SliderCell(body, 3, 6, "AlphaCon", "AlphaValText", 0, 100, 70)

        btnRow := body.Add("StackPanel").Grid_Row(4).Grid_ColumnSpan(7).Orientation("Horizontal").HorizontalAlignment("Center").VerticalAlignment("Bottom").Margin("0,0,0,4")
        AddCmdOkBtn(btnRow)

        tmp := StrReplace(XAML_TEMPLATE, "%CaptionHeight%", titleHeight)
        this.ui := XAMLHost(StrReplace(tmp, "%app%", main.ToString()), "", this.OwnerHwnd)
        this.ui.xaml := StrReplace(this.ui.xaml, 'Width="940" Height="700"', 'Title="' this._EscapeXml(title) '" Width="560" SizeToContent="Height" Opacity="0"')
        this.ui.xaml := StrReplace(this.ui.xaml, 'FontFamily="Segoe UI Variable Display, Segoe UI, sans-serif"', 'FontFamily="' MainSoftData.FontType '"')
        this.ui.xaml := StrReplace(this.ui.xaml, '%resources%', '')

        this.ui.OnEvent("Window", "Closing", ObjBindMethod(this, "OnWindowClosing"))
        this.ui.OnEvent("Window", "LoadedHwnd", ObjBindMethod(this, "OnWindowLoad"))
        this.ui.OnEvent("BtnClosePanel", "Click", ObjBindMethod(this, "OnCancelClick"))
        BindCmdEditorChrome(this.ui, "#指令手册", (*) => this.TriggerMacro(), "!l", "", ObjBindMethod(this, "OnF1"))
        this.ui.Track("FontSizeCon")
        this.ui.Track("AlphaCon")
        this.ui.OnEvent("FontSizeCon", "ValueChanged", ObjBindMethod(this, "OnFontSizeChanged"))
        this.ui.OnEvent("AlphaCon", "ValueChanged", ObjBindMethod(this, "OnAlphaChanged"))
        this.ui.OnEvent("BtnOk", "Click", ObjBindMethod(this, "OnClickSureBtn"))
    }

    OnWindowLoad(state, ctrl, event) {
        XamlWin.OnLoadTheme(this.ui)
    }

    OnWindowClosing(state, ctrl, event) {
        this.ToggleFunc(false)
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
        this.ToggleFunc(false)
        if (this.OwnerHwnd != "" && MainSoftData.IsModalSubGui) {
            try SafeGuiFromHwnd(this.OwnerHwnd).Opt("-Disabled")
        }
        if (IsObject(this.ui)) {
            try this.ui.Update("Window", "Close", "")
        }
        this.ui := ""
        this._closed := true
    }

    Init(cmd) {
        cmdArr := cmd != "" ? StrSplit(cmd, "_") : []
        this.SerialStr := cmdArr.Length >= 1 ? cmdArr[1] : GetCMDSerialStr("倒计时")
        this.ui.Update("RemarkCon", "Text", cmdArr.Length >= 2 ? cmdArr[2] : "")
        this.Data := GetMacroCMDData(this.SerialStr)
        vars := GetGuiVarArr()
        h := ObjHasOwnProp(this.Data, "Hour") ? this.Data.Hour : ""
        m := ObjHasOwnProp(this.Data, "Min") ? this.Data.Min : ""
        s := ObjHasOwnProp(this.Data, "Sec") ? this.Data.Sec : ""
        if (h == "" && m == "" && s == "") {
            sec := IsNumber(this.Data.Seconds) ? Integer(this.Data.Seconds) : 10
            if (sec < 0)
                sec := 0
            h := Floor(sec / 3600)
            m := Floor(Mod(sec, 3600) / 60)
            s := Mod(sec, 60)
        }
        this._SetCombo("HourCon", vars, h)
        this._SetCombo("MinCon", vars, m)
        this._SetCombo("SecCon", vars, s)
        this._SetDDL("WaitEndCombo", GetLangArr(["等待结束", "不等待"]), GetLang(this.Data.WaitEnd))
        this._SetCombo("PosXCon", vars, this.Data.PosX)
        this._SetCombo("PosYCon", vars, this.Data.PosY)
        fs := IsNumber(this.Data.FontSize) ? Integer(this.Data.FontSize) : 32
        if (fs < 8)
            fs := 8
        if (fs > 72)
            fs := 72
        al := CountDownUiAlpha(this.Data.Alpha)
        this._ComboPush("FontSizeCon", "Value", String(fs))
        this._ComboPush("FontSizeValText", "Text", String(fs))
        this._ComboPush("AlphaCon", "Value", String(al))
        this._ComboPush("AlphaValText", "Text", String(al))
    }

    ToggleFunc(state) {
        try Hotkey("!l", (*) => this.TriggerMacro(), state ? "On" : "Off")
        try Hotkey("F1", (*) => this.OnF1(), state ? "On" : "Off")
    }

    OnF1(*) {
        CoordMode("Mouse", "Screen")
        MouseGetPos &mouseX, &mouseY
        if (!IsObject(this.ui))
            return
        this.ui.Update("PosXCon", "Text", mouseX)
        this.ui.Update("PosYCon", "Text", mouseY)
    }

    TriggerMacro(*) {
        if (!this.CheckIfValid())
            return
        this.SaveData()
        OnTriggerSepcialItemMacro(this.GetCommandStr())
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

    _ReadInt(name, def := 0) {
        v := this.ui.Query(name)
        return IsNumber(v) ? Integer(v) : def
    }

    _SliderInt(state, name, def) {
        v := (IsObject(state) && state.Has(name)) ? state[name] : this.ui.Query(name)
        return IsNumber(v) ? Integer(v) : def
    }

    OnFontSizeChanged(state, ctrl, event) {
        if (this._syncing)
            return
        val := this._SliderInt(state, "FontSizeCon", 32)
        this._syncing := true
        try this.ui.Update("FontSizeValText", "Text", String(val))
        finally this._syncing := false
    }

    OnAlphaChanged(state, ctrl, event) {
        if (this._syncing)
            return
        val := this._SliderInt(state, "AlphaCon", 70)
        this._syncing := true
        try this.ui.Update("AlphaValText", "Text", String(val))
        finally this._syncing := false
    }

    CheckIfValid() {
        h := this.ui.Query("HourCon")
        m := this.ui.Query("MinCon")
        s := this.ui.Query("SecCon")
        if (IsNumber(h) && IsNumber(m) && IsNumber(s)) {
            if (Number(h) < 0 || Number(m) < 0 || Number(s) < 0 || Number(h) * 3600 + Number(m) * 60 + Number(s) <= 0) {
                MsgBox(GetLang("时长请输入大于0的秒数"))
                return false
            }
        }
        return true
    }

    GetCommandStr() {
        serial := this.Data.SerialStr
        if (serial == "")
            serial := this.SerialStr
        textOnly := RegExReplace(serial, "\d+")
        numbersOnly := RegExReplace(serial, "\D+")
        CommandStr := Format("{}{}", GetLang(textOnly), numbersOnly)
        Remark := this.ui.Query("RemarkCon")
        if (ShouldAutoGenerateRemark(Remark)) {
            sec := this.Data.Seconds
            Remark := CountDownFormatText(sec, sec >= 3600 ? "hhmmss" : (sec >= 60 ? "mmss" : "ss"))
        }
        CommandStr := CorrectRemark(CommandStr, Remark)
        return CommandStr
    }

    SaveData() {
        if (this.Data.SerialStr == "")
            this.Data.SerialStr := this.SerialStr
        h := this.ui.Query("HourCon")
        m := this.ui.Query("MinCon")
        s := this.ui.Query("SecCon")
        this.Data.Hour := h
        this.Data.Min := m
        this.Data.Sec := s
        if (IsNumber(h) && IsNumber(m) && IsNumber(s))
            this.Data.Seconds := Integer(h) * 3600 + Integer(m) * 60 + Integer(s)
        this.Data.WaitEnd := GetLangKey(this.ui.Query("WaitEndCombo"))
        this.Data.PosX := this.ui.Query("PosXCon")
        this.Data.PosY := this.ui.Query("PosYCon")
        fs := this._ReadInt("FontSizeCon", 32)
        if (fs < 8)
            fs := 8
        if (fs > 72)
            fs := 72
        al := CountDownUiAlpha(this._ReadInt("AlphaCon", 70))
        this.Data.FontSize := fs
        this.Data.Alpha := al
        SaveMacroCMDData(this.Data)
    }
}
