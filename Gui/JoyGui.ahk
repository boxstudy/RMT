#Requires AutoHotkey v2.0

; =====================================================================
; 手柄指令编辑器 —— 可视化手柄，点击按键/摇杆/扳机生成
; 指令格式：
;   手柄_A_点击_100[_次数[_间隔]]
;   手柄_A+B_按下
;   手柄_上_按下
;   手柄_LX:80[_LY:20]
;   手柄_LT:50
; =====================================================================

class JoyGui {
    __new() {
        this.ParentTile := ""
        this.ui := ""
        this.Gui := ""
        this.SureBtnAction := ""
        this.OwnerHwnd := ""
        this._closed := true
        this.TriggerAction := (*) => this.TriggerMacro()

        this.SelectColor := "#19C930"
        this.CheckedArr := []          ; 数字按键短名：A、上、LB…
        this.AxisMap := Map()          ; 轴短名 → 数值  LX/LY/RX/RY/LT/RT
        this.Mode := "digital"         ; digital | analog
        this.CommandStr := ""
        this._btnDefBg := Map()        ; 控件名 → 默认背景
        this._btnKeyMap := Map()       ; 控件名 → 短名或 AxisLS 等
        this._axisGroup := ""          ; AxisLS / AxisRS / AxisLT / AxisRT
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

    ShowGui(cmd) {
        global MySoftData
        if (IsObject(this.ui) && !this._closed)
            this._CloseWindow()
        this._BuildAndShow()
        if (this.OwnerHwnd != "" && MainSoftData.IsModalSubGui) {
            try SafeGuiFromHwnd(this.OwnerHwnd).Opt("+Disabled")
        }
        this.Init(cmd)
        this.Refresh()
        if (!XamlWin.Open(this.ui, "", XamlWin.Owner(this)))
            this._closed := true
        this.ToggleFunc(true)
    }

    _BuildAndShow() {
        global MySoftData
        this._closed := false
        this._btnDefBg := Map()
        this._btnKeyMap := Map()
        title := this.ParentTile GetLang("手柄编辑器")
        this._title := title
        titleHeight := "30"

        main := XAML_Generator("Grid").Background("{DynamicResource BgColor}").TextElement_FontSize(XAMLHost.FontSize())
        main.Rows(titleHeight, "*")
        XAMLHost.AddCmdTitleBar(main, title, titleHeight)

        body := main.Add("Grid").Grid_Row(1).Margin("14,10,14,12")
        body.Rows("Auto", "Auto", "Auto", "Auto", "Auto")

        top := body.Add("StackPanel").Grid_Row(0).Orientation("Horizontal").Margin("0,0,0,8").VerticalAlignment("Center")
        simBtn := top.Add("Button").Name("BtnSim").Content(GetLang("模拟指令")).Height(28).MinHeight(28).Padding("14,0").Cursor("Hand")
            .Background("{DynamicResource ActionBg}").Foreground("{DynamicResource ActionText}")
            .BorderBrush("{DynamicResource ActionStroke}").BorderThickness("1")
        simBtn.InjectResources(FrontInfoGui._OkBtnHoverStyle())
        top.Add("TextBlock").Text("F1").VerticalAlignment("Center").Margin("8,0,0,0").Opacity("0.55").Foreground("{DynamicResource TextMain}").FontSize("12")
        top.Add("TextBlock").Text(GetLang("点击手柄上的按键进行选择，可组合多个按键；摇杆与扳机轴用于设置轴值")).VerticalAlignment("Center")
            .Margin("16,0,0,0").Foreground("{DynamicResource TextSub}").FontSize("11")

        padCard := body.Add("Border").Grid_Row(1).CornerRadius("10").Padding("10,8")
            .Background("{DynamicResource ControlBg}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1")
        padHost := padCard.Add("Grid")
        padHost.Add("Border").HorizontalAlignment("Center").VerticalAlignment("Center").Width("620").Height("236")
            .CornerRadius("78").Background("#1C222C").BorderBrush("#3A4454").BorderThickness("2")
            .IsHitTestVisible("False")
        this._pad := padHost.Add("Canvas").Width("620").Height("236").HorizontalAlignment("Center")
        this._BuildPad()

        paramCard := body.Add("Border").Grid_Row(2).CornerRadius("8").Padding("12,10").Margin("0,10,0,0")
            .Background("{DynamicResource ControlBg}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1")
        param := paramCard.Add("StackPanel")

        digitalRow := param.Add("StackPanel").Name("DigitalRow").Orientation("Horizontal").VerticalAlignment("Center")
        typeBox := digitalRow.Add("StackPanel").Name("TypeBox").Orientation("Horizontal").VerticalAlignment("Center").ToolTip(this._TypeHelpText())
        typeBox.Add("TextBlock").Text(GetLang("类型:")).VerticalAlignment("Center").Foreground("{DynamicResource TextMain}").FontSize("12")
        kt := typeBox.Add("ComboBox").Name("KeyTypeCon").Width(80).Height(26).MinHeight(26).Margin("4,0,0,0")
            .VerticalContentAlignment("Center").FontSize("11").Foreground("{DynamicResource InputText}").Background("{DynamicResource InputBg}")
            .BorderBrush("{DynamicResource InputStroke}").BorderThickness("1")
        for t in GetLangArr(["按下", "松开", "点击"])
            kt.Add("ComboBoxItem").Content(t)
        digitalRow.Add("TextBlock").Name("HoldTimeTipCon").Text(GetLang("点击时长:")).VerticalAlignment("Center").Margin("14,0,0,0").Foreground("{DynamicResource TextMain}").FontSize("12")
        this._AddNumBox(digitalRow, "HoldTimeCon", "60")
        digitalRow.Add("TextBlock").Name("KeyCountTipCon").Text(GetLang("点击次数：")).VerticalAlignment("Center").Margin("14,0,0,0").Foreground("{DynamicResource TextMain}").FontSize("12")
        this._AddNumBox(digitalRow, "KeyCountCon", "60")
        digitalRow.Add("TextBlock").Name("PerIntervalTipCon").Text(GetLang("每次间隔：")).VerticalAlignment("Center").Margin("14,0,0,0").Foreground("{DynamicResource TextMain}").FontSize("12")
        this._AddNumBox(digitalRow, "PerIntervalCon", "60")

        analogRow := param.Add("StackPanel").Name("AnalogRow").Orientation("Horizontal").VerticalAlignment("Center").Margin("0,8,0,0")
        analogRow.Add("TextBlock").Name("AxisTip1").Text("LX").VerticalAlignment("Center").Foreground("{DynamicResource TextMain}").FontSize("12").Width("28")
        analogRow.Add("Slider").Name("AxisSlider1").Width("180").Height("26").Minimum("-100").Maximum("100").Value("100").IsMoveToPointEnabled("True").VerticalAlignment("Center")
        analogRow.Add("TextBox").Name("AxisVal1").Width("48").Height(26).MinHeight(26).Margin("6,0,16,0")
            .VerticalContentAlignment("Center").TextAlignment("Center").FontSize("11").Padding("2,0")
            .Foreground("{DynamicResource InputText}").Background("{DynamicResource InputBg}")
            .BorderBrush("{DynamicResource InputStroke}").BorderThickness("1")
        analogRow.Add("TextBlock").Name("AxisTip2").Text("LY").VerticalAlignment("Center").Foreground("{DynamicResource TextMain}").FontSize("12").Width("28")
        analogRow.Add("Slider").Name("AxisSlider2").Width("180").Height("26").Minimum("-100").Maximum("100").Value("0").IsMoveToPointEnabled("True").VerticalAlignment("Center")
        analogRow.Add("TextBox").Name("AxisVal2").Width("48").Height(26).MinHeight(26).Margin("6,0,0,0")
            .VerticalContentAlignment("Center").TextAlignment("Center").FontSize("11").Padding("2,0")
            .Foreground("{DynamicResource InputText}").Background("{DynamicResource InputBg}")
            .BorderBrush("{DynamicResource InputStroke}").BorderThickness("1")
        analogRow.Add("TextBlock").Name("AxisRangeTip").Text("-100 ~ 100").VerticalAlignment("Center").Margin("12,0,0,0").Foreground("{DynamicResource TextSub}").FontSize("11")

        param.Add("TextBlock").Name("CommandStrCon").Text(GetLang("当前指令：无")).Margin("0,8,0,0").Foreground("{DynamicResource TextMain}").FontSize("12")

        btnRow := body.Add("StackPanel").Grid_Row(3).Orientation("Horizontal").HorizontalAlignment("Center").Margin("0,10,0,0")
        btnRow.Add("Button").Name("BtnClear").Content(GetLang("清空")).Height(32).MinHeight(32).Padding("16,0").Margin("4,0").Cursor("Hand")
        AddCmdOkBtn(btnRow, "BtnOk", "8,0")

        tmp := StrReplace(XAML_TEMPLATE, "%CaptionHeight%", titleHeight)
        this.ui := XAMLHost(StrReplace(tmp, "%app%", main.ToString()), "", this.OwnerHwnd)
        this.ui.xaml := StrReplace(this.ui.xaml, 'Width="940" Height="700"', 'Title="' this._EscapeXml(title) '" Width="680" SizeToContent="Height" Opacity="0"')
        this.ui.xaml := StrReplace(this.ui.xaml, 'FontFamily="Segoe UI Variable Display, Segoe UI, sans-serif"', 'FontFamily="' MainSoftData.FontType '"')
        this.ui.xaml := StrReplace(this.ui.xaml, '%resources%', '')

        this._RegisterPadEvents()
        this.ui.OnEvent("Window", "Closing", ObjBindMethod(this, "OnWindowClosing"))
        this.ui.OnEvent("Window", "LoadedHwnd", ObjBindMethod(this, "OnWindowLoad"))
        this.ui.OnEvent("BtnClosePanel", "Click", ObjBindMethod(this, "OnCancelClick"))
        BindCmdEditorChrome(this.ui, "#指令手册/28-手柄")
        this.ui.OnEvent("BtnSim", "Click", (*) => this.TriggerMacro())
        this.ui.OnEvent("KeyTypeCon", "SelectionChanged", ObjBindMethod(this, "OnChangeEditValue"))
        this.ui.OnEvent("HoldTimeCon", "TextChanged", ObjBindMethod(this, "OnChangeEditValue"))
        this.ui.OnEvent("KeyCountCon", "TextChanged", ObjBindMethod(this, "OnChangeEditValue"))
        this.ui.OnEvent("PerIntervalCon", "TextChanged", ObjBindMethod(this, "OnChangeEditValue"))
        this.ui.OnEvent("AxisSlider1", "ValueChanged", ObjBindMethod(this, "OnAxisSlider", 1))
        this.ui.OnEvent("AxisSlider2", "ValueChanged", ObjBindMethod(this, "OnAxisSlider", 2))
        this.ui.OnEvent("AxisVal1", "TextChanged", ObjBindMethod(this, "OnAxisText", 1))
        this.ui.OnEvent("AxisVal2", "TextChanged", ObjBindMethod(this, "OnAxisText", 2))
        this.ui.OnEvent("BtnClear", "Click", (*) => this.ClearAll())
        this.ui.OnEvent("BtnOk", "Click", ObjBindMethod(this, "OnSureBtnClick"))
        this.ui.Update("KeyTypeCon", "SelectedIndex", "2")
    }

    _AddNumBox(parent, name, width) {
        parent.Add("TextBox").Name(name).Width(width).Height(26).MinHeight(26).Margin("6,0,0,0")
            .VerticalContentAlignment("Center").TextAlignment("Center").FontSize("11").Padding("4,0")
            .Foreground("{DynamicResource InputText}").Background("{DynamicResource InputBg}")
            .BorderBrush("{DynamicResource InputStroke}").BorderThickness("1")
    }

    _PadBtnStyle(radius) {
        return Format('<Style TargetType="Button"><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border x:Name="bd" Background="{{TemplateBinding Background}}" BorderBrush="{{TemplateBinding BorderBrush}}" BorderThickness="{{TemplateBinding BorderThickness}}" CornerRadius="{1}" SnapsToDevicePixels="True"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bd" Property="Opacity" Value="0.88"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>', radius)
    }

    _PlacePadBtn(id, label, x, y, w, h, bg, fg := "#FFFFFFFF", radius := 6) {
        name := "Pad_" id
        btn := this._pad.Add("Button").Name(name).Content(label).Width(String(w)).Height(String(h))
            .SetProp("Canvas.Left", String(x)).SetProp("Canvas.Top", String(y))
            .FontSize(11).FontWeight("SemiBold").Cursor("Hand").Padding("0")
            .Background(bg).Foreground(fg).BorderBrush("#66FFFFFF").BorderThickness("1")
        btn.InjectResources(this._PadBtnStyle(radius))
        this._btnKeyMap.Set(name, id)
        this._btnDefBg.Set(name, bg)
    }

    _PlaceStickWell(id, x, y, size) {
        name := "Pad_" id
        this._pad.Add("Ellipse").Name(name "Bg").Width(String(size)).Height(String(size))
            .Fill("#2B3340").Stroke("#5A6A7C").StrokeThickness("2")
            .SetProp("Canvas.Left", String(x)).SetProp("Canvas.Top", String(y)).IsHitTestVisible("False")
        btn := this._pad.Add("Button").Name(name).Content("").Width(String(size)).Height(String(size))
            .SetProp("Canvas.Left", String(x)).SetProp("Canvas.Top", String(y))
            .Background("Transparent").BorderThickness("0").Cursor("Hand")
        btn.InjectResources(this._PadBtnStyle(Integer(size / 2)))
        this._btnKeyMap.Set(name, id)
        this._btnDefBg.Set(name "Bg", "#2B3340")
    }

    _BuildPad() {
        global MySoftData
        ; 肩键 / 扳机
        this._PlacePadBtn("AxisLT", "LT轴", 58, 8, 78, 22, "#3D4A5C", "#FFE8EEF5", 8)
        this._PlacePadBtn("AxisRT", "RT轴", 484, 8, 78, 22, "#3D4A5C", "#FFE8EEF5", 8)
        this._PlacePadBtn("LB", MySoftData.GetJoyDisplayName("JoyLB"), 58, 34, 38, 24, "#455264", "#FFFFFFFF", 6)
        this._PlacePadBtn("LT", MySoftData.GetJoyDisplayName("JoyLT"), 98, 34, 38, 24, "#455264", "#FFFFFFFF", 6)
        this._PlacePadBtn("RT", MySoftData.GetJoyDisplayName("JoyRT"), 484, 34, 38, 24, "#455264", "#FFFFFFFF", 6)
        this._PlacePadBtn("RB", MySoftData.GetJoyDisplayName("JoyRB"), 524, 34, 38, 24, "#455264", "#FFFFFFFF", 6)

        ; 左摇杆 + L3
        this._PlaceStickWell("AxisLS", 72, 92, 78)
        this._PlacePadBtn("LS", MySoftData.GetJoyDisplayName("JoyLS"), 91, 111, 40, 40, "#1A2028", "#FFD0D8E0", 20)

        ; 十字键
        this._PlacePadBtn("上", GetLang("上"), 228, 96, 32, 26, "#3A4554", "#FFFFFFFF", 4)
        this._PlacePadBtn("左", GetLang("左"), 200, 124, 32, 26, "#3A4554", "#FFFFFFFF", 4)
        this._PlacePadBtn("右", GetLang("右"), 256, 124, 32, 26, "#3A4554", "#FFFFFFFF", 4)
        this._PlacePadBtn("下", GetLang("下"), 228, 152, 32, 26, "#3A4554", "#FFFFFFFF", 4)
        this._PlacePadBtn("无方向", GetLang("无"), 206, 186, 76, 22, "#323A46", "#FFB8C2CE", 6)

        ; 中间系统键
        this._PlacePadBtn("Back", MySoftData.GetJoyDisplayName("JoyBack"), 286, 78, 48, 22, "#3A4554", "#FFFFFFFF", 8)
        this._PlacePadBtn("Home", MySoftData.GetJoyDisplayName("JoyHome"), 342, 74, 36, 30, "#4A5566", "#FFFFFFFF", 16)
        this._PlacePadBtn("Start", MySoftData.GetJoyDisplayName("JoyStart"), 386, 78, 48, 22, "#3A4554", "#FFFFFFFF", 8)
        this._PlacePadBtn("Pad", MySoftData.GetJoyDisplayName("JoyPad"), 338, 198, 44, 22, "#3A4554", "#FFFFFFFF", 8)

        ; 右摇杆 + R3
        this._PlaceStickWell("AxisRS", 368, 128, 70)
        this._PlacePadBtn("RS", MySoftData.GetJoyDisplayName("JoyRS"), 385, 145, 36, 36, "#1A2028", "#FFD0D8E0", 18)

        ; ABXY
        this._PlacePadBtn("Y", MySoftData.GetJoyDisplayName("JoyY"), 508, 78, 36, 36, "#F1C40F", "#FF1A1A1A", 18)
        this._PlacePadBtn("X", MySoftData.GetJoyDisplayName("JoyX"), 472, 114, 36, 36, "#3498DB", "#FFFFFFFF", 18)
        this._PlacePadBtn("B", MySoftData.GetJoyDisplayName("JoyB"), 544, 114, 36, 36, "#E74C3C", "#FFFFFFFF", 18)
        this._PlacePadBtn("A", MySoftData.GetJoyDisplayName("JoyA"), 508, 150, 36, 36, "#2ECC71", "#FF1A1A1A", 18)
    }

    _RegisterPadEvents() {
        for name, id in this._btnKeyMap
            this.ui.OnEvent(name, "Click", ObjBindMethod(this, "OnPadClick").Bind(id))
    }

    _IsAnalogId(id) {
        return id == "AxisLS" || id == "AxisRS" || id == "AxisLT" || id == "AxisRT"
    }

    _DpadSet() {
        return Map("上", true, "下", true, "左", true, "右", true, "无方向", true)
    }

    OnPadClick(id, *) {
        if (this._IsAnalogId(id)) {
            if (this.Mode == "analog" && this._axisGroup == id) {
                this.ClearAll()
                return
            }
            this.Mode := "analog"
            this.CheckedArr := []
            this._axisGroup := id
            this.AxisMap := Map()
            if (id == "AxisLS") {
                this.AxisMap["LX"] := 100
                this.AxisMap["LY"] := 0
            } else if (id == "AxisRS") {
                this.AxisMap["RX"] := 100
                this.AxisMap["RY"] := 0
            } else if (id == "AxisLT") {
                this.AxisMap["LT"] := 100
            } else {
                this.AxisMap["RT"] := 100
            }
            this._SyncAxisControls()
            this._RefreshPadHighlight()
            this.Refresh()
            return
        }

        if (this.Mode == "analog") {
            this.AxisMap := Map()
            this._axisGroup := ""
            this.Mode := "digital"
        }

        found := 0
        for i, v in this.CheckedArr {
            if (v == id) {
                found := i
                break
            }
        }
        dpad := this._DpadSet()
        if (found) {
            this.CheckedArr.RemoveAt(found)
        } else {
            if (dpad.Has(id)) {
                i := this.CheckedArr.Length
                while (i >= 1) {
                    if (dpad.Has(this.CheckedArr[i]))
                        this.CheckedArr.RemoveAt(i)
                    i--
                }
            }
            this.CheckedArr.Push(id)
        }
        this._RefreshPadHighlight()
        this.Refresh()
    }

    _RefreshPadHighlight() {
        selected := Map()
        if (this.Mode == "digital") {
            for v in this.CheckedArr
                selected[v] := true
        } else if (this._axisGroup != "") {
            selected[this._axisGroup] := true
        }
        for name, id in this._btnKeyMap {
            on := selected.Has(id)
            if (id == "AxisLS" || id == "AxisRS") {
                bgName := name "Bg"
                this.ui.Update(bgName, "Fill", on ? this.SelectColor : this._btnDefBg.Get(bgName, "#2B3340"))
                this.ui.Update(bgName, "Stroke", on ? "#C8FFD0" : "#5A6A7C")
            } else {
                this.ui.Update(name, "Background", on ? this.SelectColor : this._btnDefBg.Get(name, "#3A4554"))
            }
        }
    }

    _SyncAxisControls() {
        if (this.Mode != "analog")
            return
        if (this._axisGroup == "AxisLS" || this._axisGroup == "AxisRS") {
            a1 := (this._axisGroup == "AxisLS") ? "LX" : "RX"
            a2 := (this._axisGroup == "AxisLS") ? "LY" : "RY"
            this.ui.Update("AxisTip1", "Text", a1)
            this.ui.Update("AxisTip2", "Text", a2)
            this.ui.Update("AxisSlider1", "Minimum", "-100")
            this.ui.Update("AxisSlider1", "Maximum", "100")
            this.ui.Update("AxisSlider2", "Minimum", "-100")
            this.ui.Update("AxisSlider2", "Maximum", "100")
            v1 := this.AxisMap.Get(a1, 100)
            v2 := this.AxisMap.Get(a2, 0)
            this.ui.Update("AxisSlider1", "Value", String(v1))
            this.ui.Update("AxisSlider2", "Value", String(v2))
            this.ui.Update("AxisVal1", "Text", String(v1))
            this.ui.Update("AxisVal2", "Text", String(v2))
            this.ui.Update("AxisRangeTip", "Text", "-100 ~ 100")
        } else {
            a1 := (this._axisGroup == "AxisLT") ? "LT" : "RT"
            this.ui.Update("AxisTip1", "Text", a1)
            this.ui.Update("AxisSlider1", "Minimum", "0")
            this.ui.Update("AxisSlider1", "Maximum", "100")
            v1 := this.AxisMap.Get(a1, 100)
            this.ui.Update("AxisSlider1", "Value", String(v1))
            this.ui.Update("AxisVal1", "Text", String(v1))
            this.ui.Update("AxisRangeTip", "Text", "0 ~ 100")
        }
    }

    _AxisNames() {
        if (this._axisGroup == "AxisLS")
            return ["LX", "LY"]
        if (this._axisGroup == "AxisRS")
            return ["RX", "RY"]
        if (this._axisGroup == "AxisLT")
            return ["LT"]
        if (this._axisGroup == "AxisRT")
            return ["RT"]
        return []
    }

    _ClampAxis(name, v) {
        if (!IsNumber(v))
            v := (name == "LT" || name == "RT" || name == "LX" || name == "RX") ? 100 : 0
        v := Integer(v)
        if (name == "LT" || name == "RT") {
            if (v < 0)
                return 0
            if (v > 100)
                return 100
            return v
        }
        if (v < -100)
            return -100
        if (v > 100)
            return 100
        return v
    }

    OnAxisSlider(which, *) {
        if (this.Mode != "analog")
            return
        names := this._AxisNames()
        if (which > names.Length)
            return
        raw := this.ui.Query("AxisSlider" which)
        v := this._ClampAxis(names[which], IsNumber(raw) ? Round(Float(raw)) : 0)
        this.AxisMap[names[which]] := v
        this.ui.Update("AxisVal" which, "Text", String(v))
        this.Refresh()
    }

    OnAxisText(which, *) {
        if (this.Mode != "analog")
            return
        names := this._AxisNames()
        if (which > names.Length)
            return
        raw := this.ui.Query("AxisVal" which)
        if (!IsNumber(raw))
            return
        v := this._ClampAxis(names[which], raw)
        this.AxisMap[names[which]] := v
        this.ui.Update("AxisSlider" which, "Value", String(v))
        this.Refresh()
    }

    ClearAll() {
        this.Mode := "digital"
        this.CheckedArr := []
        this.AxisMap := Map()
        this._axisGroup := ""
        this._RefreshPadHighlight()
        this.Refresh()
    }

    Init(cmd) {
        cmd := RMTParseErrHandle(cmd).cmd
        cmd := JoyLegacyKeyToJoyCmd(cmd)
        this.Mode := "digital"
        this.CheckedArr := []
        this.AxisMap := Map()
        this._axisGroup := ""
        this.ui.Update("HoldTimeCon", "Text", "100")
        this.ui.Update("KeyCountCon", "Text", "1")
        this.ui.Update("PerIntervalCon", "Text", "200")
        this._SetKeyType(GetLang("点击"))

        paramArr := cmd != "" ? SplitCommand(cmd) : []
        if (paramArr.Length < 2) {
            this.CheckedArr := ["A"]
            this._RefreshPadHighlight()
            this.Refresh()
            return
        }

        typeWords := Map(GetLang("按下"), true, GetLang("松开"), true, GetLang("点击"), true)
        i := 2
        while (i <= paramArr.Length) {
            p := paramArr[i]
            if (RegExMatch(p, "^(LX|LY|RX|RY|LT|RT):(-?[0-9]+)$", &m)) {
                this.Mode := "analog"
                this.AxisMap[m[1]] := Integer(m[2])
            } else if (typeWords.Has(p)) {
                this._SetKeyType(p)
                if (i + 1 <= paramArr.Length)
                    this.ui.Update("HoldTimeCon", "Text", paramArr[i + 1])
                if (i + 2 <= paramArr.Length)
                    this.ui.Update("KeyCountCon", "Text", paramArr[i + 2])
                if (i + 3 <= paramArr.Length)
                    this.ui.Update("PerIntervalCon", "Text", paramArr[i + 3])
                break
            } else {
                for short in StrSplit(p, "+") {
                    short := Trim(short)
                    if (short != "")
                        this.CheckedArr.Push(JoyInternalToShort(short))
                }
            }
            i++
        }

        if (this.Mode == "analog") {
            this.CheckedArr := []
            if (this.AxisMap.Has("LX") || this.AxisMap.Has("LY"))
                this._axisGroup := "AxisLS"
            else if (this.AxisMap.Has("RX") || this.AxisMap.Has("RY"))
                this._axisGroup := "AxisRS"
            else if (this.AxisMap.Has("LT"))
                this._axisGroup := "AxisLT"
            else if (this.AxisMap.Has("RT"))
                this._axisGroup := "AxisRT"
            this._SyncAxisControls()
        }
        this._RefreshPadHighlight()
        this.Refresh()
    }

    _KeyTypeIndex() {
        v := IsObject(this.ui) ? this.ui.Query("KeyTypeCon>SelectedIndex") : ""
        if (!IsNumber(v) || Integer(v) < 0)
            return 3
        return Integer(v) + 1
    }

    _KeyTypeText() {
        return IsObject(this.ui) ? this.ui.Query("KeyTypeCon") : GetLang("点击")
    }

    _SetKeyType(text) {
        items := GetLangArr(["按下", "松开", "点击"])
        idx := 3
        for i, it in items
            if (it == text)
                idx := i
        this.ui.Update("KeyTypeCon", "SelectedIndex", String(idx - 1))
    }

    _TypeHelpText() {
        str1 := GetLang("按下，松开是不消耗时间的，可以理解为瞬发")
        str2 := GetLang("按下后建议搭配一个松开，如果不松开再次按下，后续按下指令可能无效（卡键）")
        str3 := GetLang("点击时间小于200表现为点击， 大于250表现为长按")
        return Format("{}`n{}`n{}", str1, str2, str3)
    }

    OnChangeEditValue(*) {
        this.Refresh()
    }

    UpdateCommandStr() {
        CommandStr := GetLang("手柄")
        if (this.Mode == "analog" && this.AxisMap.Count > 0) {
            order := ["LX", "LY", "RX", "RY", "LT", "RT"]
            for name in order {
                if (this.AxisMap.Has(name))
                    CommandStr .= "_" name ":" this.AxisMap[name]
            }
        } else {
            keys := ""
            for v in this.CheckedArr
                keys .= (keys == "" ? "" : "+") v
            CommandStr .= "_" keys
            CommandStr .= "_" this._KeyTypeText()
            if (this._KeyTypeIndex() == 3) {
                CommandStr .= "_" this.ui.Query("HoldTimeCon")
                if (this.ui.Query("KeyCountCon") != 1) {
                    CommandStr .= "_" this.ui.Query("KeyCountCon")
                    if (this.ui.Query("PerIntervalCon") != 0)
                        CommandStr .= "_" this.ui.Query("PerIntervalCon")
                }
            }
        }
        this.CommandStr := CommandStr
    }

    Refresh() {
        this.UpdateCommandStr()
        isAnalog := this.Mode == "analog"
        isClick := !isAnalog && this._KeyTypeIndex() == 3
        isCount := isClick
        isInter := isCount && this.ui.Query("KeyCountCon") != 1
        dual := isAnalog && (this._axisGroup == "AxisLS" || this._axisGroup == "AxisRS")

        this.ui.Update("DigitalRow", "Visibility", isAnalog ? "Collapsed" : "Visible")
        this.ui.Update("HoldTimeTipCon", "Visibility", isClick ? "Visible" : "Collapsed")
        this.ui.Update("HoldTimeCon", "Visibility", isClick ? "Visible" : "Collapsed")
        this.ui.Update("KeyCountTipCon", "Visibility", isCount ? "Visible" : "Collapsed")
        this.ui.Update("KeyCountCon", "Visibility", isCount ? "Visible" : "Collapsed")
        this.ui.Update("PerIntervalTipCon", "Visibility", isInter ? "Visible" : "Collapsed")
        this.ui.Update("PerIntervalCon", "Visibility", isInter ? "Visible" : "Collapsed")
        this.ui.Update("AnalogRow", "Visibility", isAnalog ? "Visible" : "Collapsed")
        this.ui.Update("AxisTip2", "Visibility", dual ? "Visible" : "Collapsed")
        this.ui.Update("AxisSlider2", "Visibility", dual ? "Visible" : "Collapsed")
        this.ui.Update("AxisVal2", "Visibility", dual ? "Visible" : "Collapsed")
        this.ui.Update("CommandStrCon", "Text", Format("{}{}", GetLang("当前指令："), this.CommandStr))
    }

    CheckIfValid() {
        if (this.Mode == "analog") {
            if (this.AxisMap.Count == 0) {
                MsgBox(GetLang("请选择摇杆或扳机，并设置轴值！"))
                return false
            }
            return true
        }
        if (this.CheckedArr.Length == 0) {
            MsgBox(GetLang("请选择手柄按键！"))
            return false
        }
        if (!IsInteger(this.ui.Query("KeyCountCon")) || Integer(this.ui.Query("KeyCountCon")) <= 0) {
            MsgBox(GetLang("按键次数必须为大于零的整数！"))
            return false
        }
        if (this._KeyTypeIndex() == 3) {
            if (IsFloat(this.ui.Query("HoldTimeCon")) || this.ui.Query("HoldTimeCon") < 0) {
                MsgBox(GetLang("按键时间请输入大于0的整数"))
                return false
            }
        }
        return true
    }

    OnSureBtnClick(*) {
        this.UpdateCommandStr()
        if (!this.CheckIfValid())
            return
        if (!IsViGEmInstalled()) {
            ShowViGEmInstallTip()
            return
        }
        action := this.SureBtnAction
        action(this.CommandStr)
        this.OnGuiClose()
    }

    TriggerMacro(*) {
        if (!this.CheckIfValid())
            return
        this.UpdateCommandStr()
        OnTriggerSepcialItemMacro(this.CommandStr)
    }

    ToggleFunc(state) {
        if (state)
            Hotkey("F1", this.TriggerAction, "On")
        else
            Hotkey("F1", this.TriggerAction, "Off")
    }

    OnWindowLoad(*) {
        XamlWin.OnLoadTheme(this.ui)
    }

    OnWindowClosing(*) {
        try this.ToggleFunc(false)
        if (this.OwnerHwnd != "" && MainSoftData.IsModalSubGui) {
            try SafeGuiFromHwnd(this.OwnerHwnd).Opt("-Disabled")
        }
        this.ui := ""
        this._closed := true
    }

    OnCancelClick(*) {
        this._CloseWindow()
    }

    _CloseWindow() {
        try this.ToggleFunc(false)
        if (this.OwnerHwnd != "" && MainSoftData.IsModalSubGui) {
            try SafeGuiFromHwnd(this.OwnerHwnd).Opt("-Disabled")
        }
        if (IsObject(this.ui)) {
            try this.ui.Update("Window", "Close", "")
        }
        this.ui := ""
        this._closed := true
    }

    OnGuiClose() {
        this._CloseWindow()
    }
}

JoyShortToInternal(short) {
    static m := ""
    if (!IsObject(m)) {
        m := Map(
            "A", "JoyA", "B", "JoyB", "X", "JoyX", "Y", "JoyY",
            "LB", "JoyLB", "RB", "JoyRB", "LT", "JoyLT", "RT", "JoyRT",
            "LS", "JoyLS", "RS", "JoyRS", "Back", "JoyBack", "Start", "JoyStart",
            "Home", "JoyHome", "Pad", "JoyPad",
            "上", "JoyDpadUp", "下", "JoyDpadDown", "左", "JoyDpadLeft", "右", "JoyDpadRight",
            "无方向", "JoyDpadNone", "无", "JoyDpadNone",
            "LX", "JoyAxisLX", "LY", "JoyAxisLY", "RX", "JoyAxisRX", "RY", "JoyAxisRY")
    }
    return m.Get(short, "")
}

JoyInternalToShort(internal) {
    if (internal == "")
        return ""
    if (RegExMatch(internal, "^(JoyAxisL[XY]|JoyAxisR[XY]|JoyAxisLT|JoyAxisRT):(-?[0-9]+)$", &am))
        return SubStr(am[1], 8) ":" am[2]
    static m := ""
    if (!IsObject(m)) {
        m := Map(
            "JoyA", "A", "JoyB", "B", "JoyX", "X", "JoyY", "Y",
            "JoyLB", "LB", "JoyRB", "RB", "JoyLT", "LT", "JoyRT", "RT",
            "JoyLS", "LS", "JoyRS", "RS", "JoyBack", "Back", "JoyStart", "Start",
            "JoyHome", "Home", "JoyPad", "Pad",
            "JoyDpadUp", "上", "JoyDpadDown", "下", "JoyDpadLeft", "左", "JoyDpadRight", "右",
            "JoyDpadNone", "无方向",
            "JoyAxisLX", "LX", "JoyAxisLY", "LY", "JoyAxisRX", "RX", "JoyAxisRY", "RY",
            "JoyAxisLT", "LT", "JoyAxisRT", "RT")
    }
    return m.Get(internal, internal)
}

IsJoyLegacyKeyCmd(cmd) {
    if (cmd == "")
        return false
    paramArr := SplitCommand(cmd)
    if (paramArr.Length < 1)
        return false
    SplitSerialTextAndNumbers(paramArr[1], &textOnly, &numbersOnly)
    if (GetCmdOnlyText(textOnly) != GetLang("按键"))
        return false
    keyName := ""
    if (numbersOnly != "") {
        try keyName := GetMacroCMDData(paramArr[1]).KeyName
    } else if (paramArr.Length >= 2) {
        keyName := paramArr[2]
    }
    return InStr(keyName, "Joy") || InStr(keyName, "Axis") || InStr(keyName, "Dpad")
}

JoyLegacyKeyToJoyCmd(cmd) {
    if (cmd == "")
        return cmd
    paramArr := SplitCommand(cmd)
    if (paramArr.Length < 1)
        return cmd
    SplitSerialTextAndNumbers(paramArr[1], &textOnly, &numbersOnly)
    if (GetCmdOnlyText(textOnly) == GetLang("手柄"))
        return cmd
    if (GetCmdOnlyText(textOnly) != GetLang("按键"))
        return cmd
    if (!IsJoyLegacyKeyCmd(cmd))
        return cmd

    keyName := ""
    ktype := GetLang("点击")
    hold := 100
    count := 1
    interval := 0
    axisCmd := ""
    if (numbersOnly != "") {
        Data := GetMacroCMDData(paramArr[1])
        keyName := Data.KeyName
        if (IsObject(Data) && Data.IsAxis && InStr(Data.KeyName, "JoyAxis")) {
            axisCmd := JoyInternalToShort(Data.KeyName) ":" (Data.HasOwnProp("AxisValue") ? Data.AxisValue : 0)
        } else {
            ktype := GetLangArr(["按下", "松开", "点击"])[Data.KeyType]
            hold := Data.HoldTime
            count := Data.Count
            interval := Data.IntervalTime
        }
    } else {
        keyName := paramArr[2]
        if (RegExMatch(keyName, "^(JoyAxisL[XY]|JoyAxisR[XY]|JoyAxisLT|JoyAxisRT):(-?[0-9]+)$", &am))
            axisCmd := SubStr(am[1], 8) ":" am[2]
        else {
            if (paramArr.Length >= 3)
                ktype := paramArr[3]
            if (paramArr.Length >= 4)
                hold := paramArr[4]
            if (paramArr.Length >= 5)
                count := paramArr[5]
            if (paramArr.Length >= 6)
                interval := paramArr[6]
        }
    }
    if (axisCmd != "")
        return GetLang("手柄") "_" axisCmd

    shorts := ""
    for part in StrSplit(keyName, "⎖") {
        s := JoyInternalToShort(part)
        shorts .= (shorts == "" ? "" : "+") s
    }
    out := GetLang("手柄") "_" shorts "_" ktype
    if (ktype == GetLang("点击")) {
        out .= "_" hold
        if (count != 1 && count != "1") {
            out .= "_" count
            if (interval != 0 && interval != "0")
                out .= "_" interval
        }
    }
    return out
}

JoyCmdToPressKeyParts(cmd) {
    paramArr := SplitCommand(cmd)
    axes := []
    buttons := []
    ktype := GetLang("点击")
    rest := []
    typeWords := Map(GetLang("按下"), true, GetLang("松开"), true, GetLang("点击"), true)
    i := 2
    while (i <= paramArr.Length) {
        p := paramArr[i]
        if (RegExMatch(p, "^(LX|LY|RX|RY|LT|RT):(-?[0-9]+)$", &m)) {
            axes.Push("JoyAxis" m[1] ":" m[2])
        } else if (typeWords.Has(p)) {
            ktype := p
            j := i + 1
            while (j <= paramArr.Length) {
                rest.Push(paramArr[j])
                j++
            }
            break
        } else {
            for short in StrSplit(p, "+") {
                inn := JoyShortToInternal(Trim(short))
                if (inn != "")
                    buttons.Push(inn)
            }
        }
        i++
    }
    return { axes: axes, buttons: buttons, ktype: ktype, rest: rest }
}
