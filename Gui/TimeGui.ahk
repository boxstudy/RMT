#Requires AutoHotkey v2.0

; =====================================================================
; 时间编辑器 —— XAML 界面（独立实现）
; 支持 4 种子模式：指定时刻等待、时间区间判断、时间获取、时间计算
; =====================================================================

class TimeGui {
    __new() {
        this.ParentTile := ""
        this.ui := ""
        this.Gui := ""
        this.SureBtnAction := ""
        this.OwnerHwnd := ""
        this._closed := true
        this.Data := ""
        this.SerialStr := ""
        this.ModeKeys := ["指定时刻等待", "时间区间判断", "获取时间变量", "获取时间字符串", "时间计算"]
        this._dayOn := [true, true, true, true, true, true, true]
    }

    ShowGui(cmd) {
        global MySoftData
        if (IsObject(this.ui) && !this._closed)
            this._CloseWindow()
        this._BuildAndShow()
        if (this.OwnerHwnd != "" && MainSoftData.IsModalSubGui) {
            try SafeGuiFromHwnd(this.OwnerHwnd).Opt("+Disabled")
        }
        this.Init(cmd)
        this.OnModeChange()
        this._ShowWindow()
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

    _Lab(parent, text, width := 88, margin := "0") {
        return parent.Add("TextBlock").Text(GetLang(text)).Width(String(width)).VerticalAlignment("Center")
            .Foreground("{DynamicResource TextMain}").FontSize("12").Margin(margin)
    }

    _Edit(parent, name, width := "") {
        el := parent.Add("TextBox").Name(name).Height(26).MinHeight(26).MaxHeight(26).VerticalAlignment("Center")
            .VerticalContentAlignment("Center").Padding("2,0").TextAlignment("Center")
            .Background("{DynamicResource InputBg}").Foreground("{DynamicResource InputText}")
            .BorderBrush("{DynamicResource InputStroke}").BorderThickness("1")
        if (width != "")
            el.Width(width)
        return el
    }

    _Combo(parent, name, editable := true, width := "") {
        el := parent.Add("ComboBox").Name(name).Height(26).MinHeight(26).VerticalAlignment("Center")
            .VerticalContentAlignment("Center").FontSize("11")
            .Foreground("{DynamicResource InputText}").Background("{DynamicResource InputBg}")
            .BorderBrush("{DynamicResource InputStroke}").BorderThickness("1")
        if (editable)
            el.IsEditable("True")
        if (width != "")
            el.Width(width)
        return el
    }

    _AddHms(parent, prefix) {
        this._Combo(parent, prefix "HourCon", true, 68).ToolTip(GetLang("时"))
        parent.Add("TextBlock").Text("：").VerticalAlignment("Center").Margin("2,0,2,0").Foreground("{DynamicResource TextMain}")
        this._Combo(parent, prefix "MinCon", true, 68).ToolTip(GetLang("分"))
        parent.Add("TextBlock").Text("：").VerticalAlignment("Center").Margin("2,0,2,0").Foreground("{DynamicResource TextMain}")
        this._Combo(parent, prefix "SecCon", true, 68).ToolTip(GetLang("秒"))
    }

    _BuildAndShow() {
        global MySoftData
        this._closed := false
        title := this.ParentTile GetLang("时间编辑器")
        this._title := title
        titleHeight := XAMLHost.CmdTitleBarHeight()

        main := XAML_Generator("Grid").Background("{DynamicResource BgColor}").TextElement_FontSize(XAMLHost.FontSize())
        main.Rows(titleHeight, "*")

        ; === 标题栏 ===
        chrome := XAMLHost.AddCmdTitleBar(main, title, titleHeight)

        body := main.Add("Grid").Grid_Row(1).Margin("16,8,16,8")
        body.Rows("32", "32", "Auto", "44")
        body.Cols("*")

        r0 := body.Add("StackPanel").Grid_Row(0).Orientation("Horizontal").VerticalAlignment("Center")
        this._Lab(r0, "备注：")
        this._Edit(r0, "RemarkCon").Width(420).TextAlignment("Left")

        r1 := body.Add("StackPanel").Grid_Row(1).Orientation("Horizontal").VerticalAlignment("Center")
        this._Lab(r1, "时间模式：")
        tm := this._Combo(r1, "TimeModeCon", false, 200)
        for t in GetLangArr(this.ModeKeys)
            tm.Add("ComboBoxItem").Content(t)

        pStack := body.Add("StackPanel").Grid_Row(2).Margin("0,4,0,0")

        p1 := pStack.Add("StackPanel").Name("WaitPanel")
        p1r1 := p1.Add("StackPanel").Orientation("Horizontal").Height("32").VerticalAlignment("Center")
        this._Lab(p1r1, "类型：")
        wunit := this._Combo(p1r1, "WaitUnitCon", false, 160)
        for u in GetLangArr(TimeGui.WaitUnitKeys)
            wunit.Add("ComboBoxItem").Content(u)

        p1Time := p1.Add("StackPanel").Name("WaitTimeRow").Orientation("Horizontal").Height("32").VerticalAlignment("Center")
        this._Lab(p1Time, "目标时间：")
        this._AddHms(p1Time, "Wait")

        p1Dur := p1.Add("StackPanel").Name("WaitDurRow").Orientation("Horizontal").Height("32").VerticalAlignment("Center").Visibility("Collapsed")
        this._Lab(p1Dur, "时长：")
        this._AddHms(p1Dur, "")

        p1Var := p1.Add("StackPanel").Name("WaitVarRow").Orientation("Horizontal").Height("32").VerticalAlignment("Center").Visibility("Collapsed")
        this._Lab(p1Var, "时间变量：")
        this._Combo(p1Var, "WaitVarCon", true, 200)

        p1r2 := p1.Add("StackPanel").Orientation("Horizontal").Height("32").VerticalAlignment("Center")
        this._Lab(p1r2, "超时(ms)：")
        this._Edit(p1r2, "TimeoutCon", 90)
        this._Lab(p1r2, "轮询间隔(ms)：", 108, "16,0,0,0")
        this._Edit(p1r2, "CheckIntervalCon", 90)

        p2 := pStack.Add("StackPanel").Name("WindowPanel").Visibility("Collapsed")
        p2r1 := p2.Add("StackPanel").Orientation("Horizontal").Height("32").VerticalAlignment("Center")
        this._Lab(p2r1, "开始时间：")
        this._AddHms(p2r1, "Start")

        p2r1b := p2.Add("StackPanel").Orientation("Horizontal").Height("32").VerticalAlignment("Center")
        this._Lab(p2r1b, "结束时间：")
        this._AddHms(p2r1b, "End")

        p2r2 := p2.Add("StackPanel").Orientation("Horizontal").Height("32").VerticalAlignment("Center")
        this._Lab(p2r2, "允许星期：")
        for i, d in ["一", "二", "三", "四", "五", "六", "日"] {
            p2r2.Add("Button").Name("Day" i "Con").Content(GetLang(d)).Width("32").Height("28")
                .Margin("0,0,6,0").Cursor("Hand").FontSize("12")
                .Background("{DynamicResource ControlBg}").Foreground("{DynamicResource TextMain}")
                .BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1")
                .VerticalAlignment("Center").HorizontalContentAlignment("Center").VerticalContentAlignment("Center")
        }

        p2r3 := p2.Add("StackPanel").Orientation("Horizontal").Height("32").VerticalAlignment("Center")
        this._Lab(p2r3, "不满足时：")
        act := this._Combo(p2r3, "MismatchActionCon", false, 140)
        for a in GetLangArr(TimeGui.MismatchActionKeys)
            act.Add("ComboBoxItem").Content(a)

        p3 := pStack.Add("StackPanel").Name("GetVarPanel").Visibility("Collapsed")
        p3r1 := p3.Add("StackPanel").Orientation("Horizontal").Height("32").VerticalAlignment("Center")
        this._Lab(p3r1, "时间变量名：")
        this._Combo(p3r1, "GetTimeVarCon", true, 140)
        this._Lab(p3r1, "来源时间(可选)：", 108, "16,0,0,0")
        this._Combo(p3r1, "GetTimeVarSrcCon", true, 140)

        p4 := pStack.Add("StackPanel").Name("GetStrPanel").Visibility("Collapsed")
        p4r1 := p4.Add("StackPanel").Orientation("Horizontal").Height("32").VerticalAlignment("Center")
        this._Lab(p4r1, "目标变量名：")
        this._Combo(p4r1, "GetStrVarCon", true, 140)
        this._Lab(p4r1, "时间源(可选)：", 108, "16,0,0,0")
        this._Combo(p4r1, "GetStrSrcCon", true, 140)
        p4r2 := p4.Add("StackPanel").Orientation("Horizontal").Height("32").VerticalAlignment("Center")
        this._Lab(p4r2, "格式化模板：")
        gfmt := this._Combo(p4r2, "GetStrFormatCon", true, 220)
        for f in GetLangArr(TimeGui.FormatNames)
            gfmt.Add("ComboBoxItem").Content(f)

        p5 := pStack.Add("StackPanel").Name("MathPanel").Visibility("Collapsed")
        p5r1 := p5.Add("StackPanel").Orientation("Horizontal").Height("32").VerticalAlignment("Center")
        this._Lab(p5r1, "时间变量1：")
        this._Combo(p5r1, "MathSrc1Con", true, 160)
        this._Lab(p5r1, "操作：", 56, "16,0,0,0")
        mop := this._Combo(p5r1, "MathOpCon", false, 100)
        for o in GetLangArr(TimeGui.MathOpKeys)
            mop.Add("ComboBoxItem").Content(o)
        p5r2 := p5.Add("StackPanel").Orientation("Horizontal").Height("32").VerticalAlignment("Center")
        this._Lab(p5r2, "时间变量2/偏移：", 108)
        this._Combo(p5r2, "MathSrc2Con", true, 200)
        p5r3 := p5.Add("StackPanel").Orientation("Horizontal").Height("32").VerticalAlignment("Center")
        this._Lab(p5r3, "保存变量：")
        this._Combo(p5r3, "MathTargetCon", true, 140)
        this._Lab(p5r3, "单位/格式：", 88, "16,0,0,0")
        munit := this._Combo(p5r3, "MathUnitCon", false, 120)
        for u in GetLangArr(TimeGui.MathUnitKeys)
            munit.Add("ComboBoxItem").Content(u)

        btnRow := body.Add("StackPanel").Grid_Row(3).Orientation("Horizontal").HorizontalAlignment("Center").VerticalAlignment("Center")
        AddCmdOkBtn(btnRow)

        tmp := StrReplace(XAML_TEMPLATE, "%CaptionHeight%", titleHeight)
        this.ui := XAMLHost(StrReplace(tmp, "%app%", main.ToString()), "", this.OwnerHwnd)
        this.ui.xaml := StrReplace(this.ui.xaml, 'Width="940" Height="700"', 'Title="' this._EscapeXml(title) '" Width="560" Height="280" SizeToContent="Height" Opacity="0"')
        this.ui.xaml := StrReplace(this.ui.xaml, 'FontFamily="Segoe UI Variable Display, Segoe UI, sans-serif"', 'FontFamily="' MainSoftData.FontType '"')
        this.ui.xaml := StrReplace(this.ui.xaml, '%resources%', '')

        this.ui.OnEvent("Window", "Closing", ObjBindMethod(this, "OnWindowClosing"))
        this.ui.OnEvent("Window", "LoadedHwnd", ObjBindMethod(this, "OnWindowLoad"))
        this.ui.OnEvent("BtnClosePanel", "Click", ObjBindMethod(this, "OnClickCancelBtn"))
        BindCmdEditorChrome(this.ui, "#指令手册/27-时间", (*) => this.TriggerMacro(), "!l")
        this.ui.OnEvent("BtnOk", "Click", ObjBindMethod(this, "OnClickSureBtn"))
        this.ui.OnEvent("TimeModeCon", "SelectionChanged", ObjBindMethod(this, "OnModeChange"))
        this.ui.OnEvent("WaitUnitCon", "SelectionChanged", ObjBindMethod(this, "OnWaitTypeChange"))
        loop 7
            this.ui.OnEvent("Day" A_Index "Con", "Click", ObjBindMethod(this, "OnDayClick", A_Index))
    }

    _ShowWindow() {
        if (!XamlWin.Open(this.ui, "", XamlWin.Owner(this)))
            this._closed := true
    }

    ToggleFunc(state) {
        try Hotkey("!l", (*) => this.TriggerMacro(), state ? "On" : "Off")
    }

    _CloseWindow() {
        this.ToggleFunc(false)
        if (IsObject(this.ui)) {
            try this.ui.Update("Window", "Close", "")
        }
        if (this.OwnerHwnd != "" && MainSoftData.IsModalSubGui) {
            try SafeGuiFromHwnd(this.OwnerHwnd).Opt("-Disabled")
        }
        this.ui := ""
        this._closed := true
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

    OnClickCancelBtn(state := "", ctrl := "", event := "") {
        this._CloseWindow()
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

    static WaitUnitKeys := ["指定时刻", "时长", "时间变量"]
    static MismatchActionKeys := ["跳过", "等待", "终止"]
    static MathOpKeys := ["差值", "增加", "减少"]
    static MathUnitKeys := ["秒", "毫秒", "分钟", "小时", "天", "时:分:秒"]
    static FormatKeys := ["yyyy-MM-dd HH:mm:ss", "UnixTimestamp", "HH:mm:ss", "yyyyMMdd", "yyyy/MM/dd HH:mm:ss", "EEEE", "EEE", "E"]
    static FormatNames := ["标准日期时间", "Unix时间戳", "时分秒", "年月日", "斜杠日期时间", "星期几", "星期缩写", "星期数字"]

    _GetSelectedKey(comboName, keysArray) {
        if (!IsObject(this.ui))
            return keysArray[1]
        try {
            idx := Integer(this.ui.Query(comboName ">SelectedIndex"))
            if (idx >= 0 && idx < keysArray.Length)
                return keysArray[idx + 1]
        }
        text := this.ui.Query(comboName)
        return GetLangKey(text)
    }

    _SetSelectedByKey(comboName, key, keysArray) {
        engKey := GetLangKey(key)
        for i, k in keysArray {
            if (k == engKey) {
                this.ui.Update(comboName, "SelectedIndex", i - 1)
                return
            }
        }
        this.ui.Update(comboName, "Text", GetLang(key))
    }

    Init(cmd) {
        cmdArr := cmd != "" ? SplitCommand(cmd) : []
        this.SerialStr := cmdArr.Length >= 1 ? cmdArr[1] : GetCMDSerialStr("时间")
        this.Data := GetMacroCMDData(this.SerialStr)
        this.ui.Update("RemarkCon", "Text", cmdArr.Length >= 2 ? cmdArr[2] : "")

        modeIdx := Integer(this.Data.SubMode)
        if (modeIdx < 1 || modeIdx > 5)
            modeIdx := 1
        this.ui.Update("TimeModeCon", "SelectedIndex", modeIdx - 1)

        waitType := TimeNormWaitType(this.Data.Param2 != "" ? this.Data.Param2 : "指定时刻")
        this._SetSelectedByKey("WaitUnitCon", waitType, TimeGui.WaitUnitKeys)
        vars := GetGuiVarArr()
        this._SetCombo("WaitVarCon", vars, waitType == "时间变量" ? this.Data.Param1 : "")
        wh := 14, wm := 30, ws := 0
        this._ParseClockToHMS(waitType == "指定时刻" ? this.Data.Param1 : "", 14, 30, 0, &wh, &wm, &ws)
        this._SetCombo("WaitHourCon", vars, wh)
        this._SetCombo("WaitMinCon", vars, wm)
        this._SetCombo("WaitSecCon", vars, ws)
        h := 0, m := 0, s := 10
        this._ParseDurationToHMS(this.Data.Param1, this.Data.Param2, &h, &m, &s)
        this._SetCombo("HourCon", vars, h)
        this._SetCombo("MinCon", vars, m)
        this._SetCombo("SecCon", vars, s)
        this.ui.Update("TimeoutCon", "Text", String(this.Data.Timeout))
        this.ui.Update("CheckIntervalCon", "Text", String(this.Data.CheckInterval))

        sh := 9, sm := 0, ss := 0
        this._ParseClockToHMS(this.Data.SubMode == 2 ? this.Data.Param1 : "", 9, 0, 0, &sh, &sm, &ss)
        this._SetCombo("StartHourCon", vars, sh)
        this._SetCombo("StartMinCon", vars, sm)
        this._SetCombo("StartSecCon", vars, ss)
        eh := 18, em := 0, es := 0
        this._ParseClockToHMS(this.Data.SubMode == 2 ? this.Data.Param2 : "", 18, 0, 0, &eh, &em, &es)
        this._SetCombo("EndHourCon", vars, eh)
        this._SetCombo("EndMinCon", vars, em)
        this._SetCombo("EndSecCon", vars, es)
        days := this.Data.Param3 != "" ? this.Data.Param3 : "1,2,3,4,5,6,7"
        loop 7 {
            this._dayOn[A_Index] := InStr("," days ",", "," A_Index ",") ? true : false
            this._ApplyDayBtn(A_Index)
        }
        mismatch := TimeNormMismatch(this.Data.Param4 != "" ? this.Data.Param4 : "跳过")
        this._SetSelectedByKey("MismatchActionCon", mismatch, TimeGui.MismatchActionKeys)

        this._SetCombo("GetTimeVarCon", vars, this.Data.Param1 != "" ? this.Data.Param1 : "TimeVar1")
        this._SetCombo("GetTimeVarSrcCon", GetGuiVarArr(7), this.Data.Param2 != "" ? this.Data.Param2 : "")

        this._SetCombo("GetStrVarCon", vars, this.Data.Param1 != "" ? this.Data.Param1 : "TimeStr1")
        this._SetCombo("GetStrSrcCon", GetGuiVarArr(7), this.Data.Param2 != "" ? this.Data.Param2 : "")
        fmt := this.Data.Param3 != "" ? this.Data.Param3 : "yyyy-MM-dd HH:mm:ss"
        this._SetFormatCombo(fmt)

        this._SetCombo("MathSrc1Con", GetGuiVarArr(7), this.Data.Param1)
        this._SetCombo("MathSrc2Con", GetGuiVarArr(7), this.Data.Param2)
        op := TimeNormMathOp(this.Data.Param3 != "" ? this.Data.Param3 : "差值")
        this._SetSelectedByKey("MathOpCon", op, TimeGui.MathOpKeys)
        this._SetCombo("MathTargetCon", vars, this.Data.Param4 != "" ? this.Data.Param4 : "TimeRes")
        mathUnit := TimeNormMathUnit(this.Data.Param5 != "" ? this.Data.Param5 : "秒")
        this._SetSelectedByKey("MathUnitCon", mathUnit, TimeGui.MathUnitKeys)
        this.OnWaitTypeChange()
    }

    OnModeChange(state := "", ctrl := "", event := "") {
        m := this._ModeValue()
        panelMap := Map(1, "WaitPanel", 2, "WindowPanel", 3, "GetVarPanel", 4, "GetStrPanel", 5, "MathPanel")
        show := panelMap.Has(m) ? panelMap[m] : "WaitPanel"
        batch := []
        for name in ["WaitPanel", "WindowPanel", "GetVarPanel", "GetStrPanel", "MathPanel"] {
            batch.Push({ControlName: name, PropertyName: "Visibility", Value: (name == show) ? "Visible" : "Collapsed"})
        }
        this.ui.BatchUpdate(batch)
        if (m == 1)
            this.OnWaitTypeChange()
    }

    OnWaitTypeChange(state := "", ctrl := "", event := "") {
        t := this._GetSelectedKey("WaitUnitCon", TimeGui.WaitUnitKeys)
        t := TimeNormWaitType(t)
        this.ui.Update("WaitTimeRow", "Visibility", t == "指定时刻" ? "Visible" : "Collapsed")
        this.ui.Update("WaitDurRow", "Visibility", t == "时长" ? "Visible" : "Collapsed")
        this.ui.Update("WaitVarRow", "Visibility", t == "时间变量" ? "Visible" : "Collapsed")
    }

    TriggerMacro(*) {
        if (!this.CheckIfValid())
            return
        this.SaveTimeData()
        OnTriggerSepcialItemMacro(this.GetCommandStr())
    }

    _ModeValue() {
        v := IsObject(this.ui) ? this.ui.Query("TimeModeCon>SelectedIndex") : ""
        return (IsNumber(v) && v >= 0) ? (Integer(v) + 1) : 1
    }

    GetCommandStr() {
        textOnly := RegExReplace(this.Data.SerialStr, "\d+")
        numbersOnly := RegExReplace(this.Data.SerialStr, "\D+")
        CommandStr := Format("{}{}", GetLang(textOnly), numbersOnly)
        CommandStr := CorrectRemark(CommandStr, this.ui.Query("RemarkCon"))
        return CommandStr
    }

    OnClickSureBtn(state, ctrl, event) {
        if (!this.CheckIfValid())
            return
        this.SaveTimeData()
        CommandStr := this.GetCommandStr()
        action := this.SureBtnAction
        this._CloseWindow()
        if (action != "")
            action(CommandStr)
    }

    OnDayClick(day, state := "", ctrl := "", event := "") {
        this._dayOn[day] := !this._dayOn[day]
        this._ApplyDayBtn(day)
    }

    _ApplyDayBtn(day) {
        if (!IsObject(this.ui))
            return
        on := this._dayOn[day]
        name := "Day" day "Con"
        this.ui.Update(name, "Background", on ? "{DynamicResource Accent}" : "{DynamicResource ControlBg}")
        this.ui.Update(name, "Foreground", on ? "White" : "{DynamicResource TextMain}")
        this.ui.Update(name, "BorderBrush", on ? "{DynamicResource Accent}" : "{DynamicResource ControlBorder}")
    }

    _ParseClockToHMS(raw, defH, defM, defS, &h, &m, &s) {
        h := defH, m := defM, s := defS
        raw := Trim(String(raw))
        if (raw == "")
            return
        if (RegExMatch(raw, "(\d{1,2}):(\d{1,2}):(\d{1,2})\s*$", &mt)) {
            h := Integer(mt[1]), m := Integer(mt[2]), s := Integer(mt[3])
            return
        }
        arr := StrSplit(raw, ":")
        if (arr.Length >= 3) {
            h := arr[1], m := arr[2], s := arr[3]
            return
        }
        if (arr.Length == 2) {
            h := arr[1], m := arr[2], s := 0
        }
    }

    _ReadHms(hName, mName, sName) {
        return this.ui.Query(hName) ":" this.ui.Query(mName) ":" this.ui.Query(sName)
    }

    _HmsEmpty(hName, mName, sName) {
        return Trim(this.ui.Query(hName)) == "" && Trim(this.ui.Query(mName)) == "" && Trim(this.ui.Query(sName)) == ""
    }

    _ParseDurationToHMS(param1, unit, &h, &m, &s) {
        h := 0, m := 0, s := 10
        u := TimeNormWaitType(unit)
        raw := Trim(String(param1))
        if (u != "时长")
            return
        nu := GetLangKey(unit)
        if (nu == "Minutes" || nu == "分钟") {
            if (IsNumber(raw)) {
                tot := Integer(raw) * 60
                h := Floor(tot / 3600), m := Floor(Mod(tot, 3600) / 60), s := Mod(tot, 60)
            }
            return
        }
        if (nu == "Hours" || nu == "小时") {
            if (IsNumber(raw)) {
                tot := Integer(raw) * 3600
                h := Floor(tot / 3600), m := Floor(Mod(tot, 3600) / 60), s := Mod(tot, 60)
            }
            return
        }
        if (nu == "Days" || nu == "天") {
            if (IsNumber(raw)) {
                tot := Integer(raw) * 86400
                h := Floor(tot / 3600), m := Floor(Mod(tot, 3600) / 60), s := Mod(tot, 60)
            }
            return
        }
        if (RegExMatch(raw, "^(\d+):(\d+):(\d+)$", &mt)) {
            h := Integer(mt[1]), m := Integer(mt[2]), s := Integer(mt[3])
            return
        }
        if (IsNumber(raw)) {
            tot := Integer(raw)
            h := Floor(tot / 3600), m := Floor(Mod(tot, 3600) / 60), s := Mod(tot, 60)
        }
    }

    _SetFormatCombo(fmt) {
        for i, k in TimeGui.FormatKeys {
            if (k == fmt) {
                this.ui.Update("GetStrFormatCon", "SelectedIndex", i - 1)
                return
            }
        }
        this.ui.Update("GetStrFormatCon", "Text", fmt)
    }

    _ReadDays() {
        arr := []
        loop 7 {
            if (this._dayOn[A_Index])
                arr.Push(A_Index)
        }
        if (arr.Length == 0)
            return "1,2,3,4,5,6,7"
        out := ""
        for v in arr
            out .= (out == "" ? "" : ",") v
        return out
    }

    _ReadFormat() {
        try {
            idx := Integer(this.ui.Query("GetStrFormatCon>SelectedIndex"))
            if (idx >= 0 && idx < TimeGui.FormatKeys.Length)
                return TimeGui.FormatKeys[idx + 1]
        }
        t := this.ui.Query("GetStrFormatCon")
        for i, name in TimeGui.FormatNames {
            if (t == GetLang(name))
                return TimeGui.FormatKeys[i]
        }
        return t != "" ? t : "yyyy-MM-dd HH:mm:ss"
    }

    CheckIfValid() {
        m := this._ModeValue()
        switch m {
            case 1:
                t := TimeNormWaitType(this._GetSelectedKey("WaitUnitCon", TimeGui.WaitUnitKeys))
                if (t == "指定时刻" && this._HmsEmpty("WaitHourCon", "WaitMinCon", "WaitSecCon")) {
                    MsgBox(GetLang("请输入目标时间或时长"))
                    return false
                }
                if (t == "时长") {
                    hh := this.ui.Query("HourCon"), mm := this.ui.Query("MinCon"), ss := this.ui.Query("SecCon")
                    if (IsNumber(hh) && IsNumber(mm) && IsNumber(ss) && Number(hh) * 3600 + Number(mm) * 60 + Number(ss) <= 0) {
                        MsgBox(GetLang("时长请输入大于0的秒数"))
                        return false
                    }
                }
                if (t == "时间变量" && this.ui.Query("WaitVarCon") == "") {
                    MsgBox(GetLang("请输入目标时间或时长"))
                    return false
                }
            case 2:
                if (this._HmsEmpty("StartHourCon", "StartMinCon", "StartSecCon") || this._HmsEmpty("EndHourCon", "EndMinCon", "EndSecCon")) {
                    MsgBox(GetLang("请输入开始与结束时间"))
                    return false
                }
            case 3:
                varName := GetVarName(this.ui.Query("GetTimeVarCon"))
                if (!CheckVarNameIfValid(varName))
                    return false
            case 4:
                varName := GetVarName(this.ui.Query("GetStrVarCon"))
                if (!CheckVarNameIfValid(varName))
                    return false
            case 5:
                varName := GetVarName(this.ui.Query("MathTargetCon"))
                if (this.ui.Query("MathSrc1Con") == "" || !CheckVarNameIfValid(varName))
                    return false
        }
        return true
    }

    SaveTimeData() {
        m := this._ModeValue()
        this.Data.SubMode := m

        switch m {
            case 1:
                t := TimeNormWaitType(this._GetSelectedKey("WaitUnitCon", TimeGui.WaitUnitKeys))
                this.Data.Param2 := t
                if (t == "时长")
                    this.Data.Param1 := this._ReadHms("HourCon", "MinCon", "SecCon")
                else if (t == "时间变量")
                    this.Data.Param1 := this.ui.Query("WaitVarCon")
                else
                    this.Data.Param1 := this._ReadHms("WaitHourCon", "WaitMinCon", "WaitSecCon")
                this.Data.Timeout := Integer(this.ui.Query("TimeoutCon") != "" ? this.ui.Query("TimeoutCon") : 0)
                this.Data.CheckInterval := Integer(this.ui.Query("CheckIntervalCon") != "" ? this.ui.Query("CheckIntervalCon") : 500)
            case 2:
                this.Data.Param1 := this._ReadHms("StartHourCon", "StartMinCon", "StartSecCon")
                this.Data.Param2 := this._ReadHms("EndHourCon", "EndMinCon", "EndSecCon")
                this.Data.Param3 := this._ReadDays()
                this.Data.Param4 := this._GetSelectedKey("MismatchActionCon", TimeGui.MismatchActionKeys)
            case 3:
                this.Data.Param1 := GetVarName(this.ui.Query("GetTimeVarCon"))
                this.Data.Param2 := GetVarName(this.ui.Query("GetTimeVarSrcCon"))
            case 4:
                this.Data.Param1 := GetVarName(this.ui.Query("GetStrVarCon"))
                this.Data.Param2 := GetVarName(this.ui.Query("GetStrSrcCon"))
                this.Data.Param3 := this._ReadFormat()
            case 5:
                this.Data.Param1 := this.ui.Query("MathSrc1Con")
                this.Data.Param2 := this.ui.Query("MathSrc2Con")
                this.Data.Param3 := this._GetSelectedKey("MathOpCon", TimeGui.MathOpKeys)
                this.Data.Param4 := GetVarName(this.ui.Query("MathTargetCon"))
                this.Data.Param5 := this._GetSelectedKey("MathUnitCon", TimeGui.MathUnitKeys)
        }

        SaveMacroCMDData(this.Data)
    }
}
