#Requires AutoHotkey v2.0
#Include WinRuleGui.ahk

; =====================================================================
; 移动Pro编辑器 —— XAML 迁移版（独立实现）
; 公开接口保持：ShowGui(cmd) / SureBtnAction / OwnerHwnd / ParentTile
; =====================================================================

class MMProGui {
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
        this.PosAction := () => this.RefreshMousePos()
        this.ConfigDLArr := []
        this._syncing := false   ; 程序初始化/刷新配置时抑制 SelectionChanged/Click 递归
        this.RuleMenu := ""
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
        title := this.ParentTile GetLang("移动Pro编辑器")
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
        body.Rows("34", "30", "24", "32", "34", "34", "32", "32", "24", "*")
        body.Cols("80", "130", "80", "130")

        ; 行0：快捷方式
        row0 := body.Add("StackPanel").Grid_Row(0).Grid_ColumnSpan(4).Orientation("Horizontal").VerticalAlignment("Center")
        row0.Add("TextBlock").Text(GetLang("快捷方式：")).VerticalAlignment("Center")
        row0.Add("TextBox").Width(60).Height(24).MinHeight(24).Margin("4,0,0,0").Text("!l").IsReadOnly("True")
        row0.Add("Button").Name("BtnExecute").Content(GetLang("执行指令")).Height(26).MinHeight(26).Margin("10,0,0,0")
        row0.Add("TextBlock").Text(GetLang("备注：")).VerticalAlignment("Center").Margin("14,0,0,0")
        row0.Add("TextBox").Name("RemarkCon").Width(150).Height(24).MinHeight(24).Margin("4,0,0,0")

        ; 行1：F1 + 定位取色器
        row1 := body.Add("StackPanel").Grid_Row(1).Grid_ColumnSpan(4).Orientation("Horizontal").VerticalAlignment("Center")
        row1.Add("TextBlock").Text(GetLang("F1:选取当前坐标")).VerticalAlignment("Center")
        row1.Add("Button").Name("BtnTargeter").Content(GetLang("定位取色器")).Width(100).Height(26).MinHeight(26).Margin("14,0,0,0")
        row1.Add("Button").Name("BtnTargeterHelp").Content("?").Width(30).Height(26).MinHeight(26).Margin("4,0,0,0")

        ; 行2：鼠标位置
        body.Add("TextBlock").Grid_Row(2).Grid_ColumnSpan(4).Name("MousePosCon").Text(GetLang("当前鼠标位置:0,0")).VerticalAlignment("Center")

        ; 行3：屏幕规格
        row3 := body.Add("StackPanel").Grid_Row(3).Grid_ColumnSpan(4).Orientation("Horizontal").VerticalAlignment("Center")
        row3.Add("TextBlock").Text(GetLang("屏幕规格：")).VerticalAlignment("Center")
        row3.Add("ComboBox").Name("ConfigDLCombo").Width(220).Height(26).MinHeight(26).Margin("4,0,0,0")
        row3.Add("Button").Name("BtnConfigEdit").Content(GetLang("编辑")).Height(26).MinHeight(26).Margin("8,0,0,0")

        ; 行4：坐标位置X/Y
        body.Add("TextBlock").Grid_Row(4).Grid_Column(0).Text(GetLang("坐标位置X:")).VerticalAlignment("Center")
        body.Add("ComboBox").Grid_Row(4).Grid_Column(1).Name("PosVarX").Height(26).MinHeight(26).IsEditable("True")
        body.Add("TextBlock").Grid_Row(4).Grid_Column(2).Text(GetLang("坐标位置Y:")).VerticalAlignment("Center")
        body.Add("ComboBox").Grid_Row(4).Grid_Column(3).Name("PosVarY").Height(26).MinHeight(26).IsEditable("True")

        ; 行5：移动速度 + 鼠标动作
        body.Add("TextBlock").Grid_Row(5).Grid_Column(0).Text(GetLang("移动速度：")).VerticalAlignment("Center")
        body.Add("TextBox").Grid_Row(5).Grid_Column(1).Name("SpeedCon").Height(24).MinHeight(24).VerticalContentAlignment("Center").Text("90")
        body.Add("TextBlock").Grid_Row(5).Grid_Column(2).Text(GetLang("鼠标动作：")).VerticalAlignment("Center")
        act := body.Add("ComboBox").Grid_Row(5).Grid_Column(3).Name("ActionTypeCombo").Height(26).MinHeight(26)
        for a in GetLangArr(["移动", "移动点击1次", "移动点击2次"])
            act.Add("ComboBoxItem").Content(a)

        ; 行6：移动方式 + 拟真轨迹
        row6 := body.Add("StackPanel").Grid_Row(6).Grid_ColumnSpan(4).Orientation("Horizontal").VerticalAlignment("Center")
        row6.Add("TextBlock").Text(GetLang("移动方式：")).VerticalAlignment("Center")
        mm := row6.Add("ComboBox").Name("MouseMoveModeCombo").Width(110).Height(26).MinHeight(26).Margin("4,0,0,0")
        for m in GetLangArr(["绝对移动", "相对移动", "游戏视角"])
            mm.Add("ComboBoxItem").Content(m)
        row6.Add("CheckBox").Name("HumanMouseTog").Content(GetLang("启用拟真轨迹")).VerticalAlignment("Center").Margin("14,0,0,0")

        ; 行7：移动次数 + 每次间隔
        row7 := body.Add("StackPanel").Grid_Row(7).Grid_ColumnSpan(4).Orientation("Horizontal").VerticalAlignment("Center")
        countRow := row7.Add("StackPanel").Name("CountRow").Orientation("Horizontal")
        countRow.Add("TextBlock").Text(GetLang("移动次数:")).VerticalAlignment("Center")
        countRow.Add("TextBox").Name("CountCon").Width(90).Height(24).MinHeight(24).Margin("4,0,0,0").VerticalContentAlignment("Center").Text("1")
        intervalRow := row7.Add("StackPanel").Name("IntervalRow").Orientation("Horizontal").Margin("16,0,0,0")
        intervalRow.Add("TextBlock").Text(GetLang("每次间隔：")).VerticalAlignment("Center")
        intervalRow.Add("TextBox").Name("IntervalCon").Width(90).Height(24).MinHeight(24).Margin("4,0,0,0").VerticalContentAlignment("Center").Text("1000")

        ; 行8：提示
        body.Add("TextBlock").Grid_Row(8).Grid_ColumnSpan(4).Text(GetLang("游戏视角：调整原神等第一人称，第三人称游戏视角")).VerticalAlignment("Center")

        ; 行9：确定
        btnRow := body.Add("StackPanel").Grid_Row(9).Grid_ColumnSpan(4).Orientation("Horizontal").HorizontalAlignment("Center").VerticalAlignment("Center")
        btnRow.Add("Button").Name("BtnOk").Content(GetLang("确定")).Width(100).Height(36).MinHeight(36)

        ; === 创建 XAMLHost ===
        tmp := StrReplace(XAML_TEMPLATE, "%CaptionHeight%", titleHeight)
        this.ui := XAMLHost(StrReplace(tmp, "%app%", main.ToString()), "", this.OwnerHwnd)
        this.ui.xaml := StrReplace(this.ui.xaml, 'Width="940" Height="700"', 'Title="' this._EscapeXml(title) '" Width="500" Height="380" Opacity="0"')
        this.ui.xaml := StrReplace(this.ui.xaml, 'FontFamily="Segoe UI Variable Display, Segoe UI, sans-serif"', 'FontFamily="' MainSoftData.FontType '"')
        this.ui.xaml := StrReplace(this.ui.xaml, '%resources%', '')

        ; === 事件 ===
        this.ui.OnEvent("Window", "Closing", ObjBindMethod(this, "OnWindowClosing"))
        this.ui.OnEvent("Window", "LoadedHwnd", ObjBindMethod(this, "OnWindowLoad"))
        this.ui.OnEvent("BtnClosePanel", "Click", ObjBindMethod(this, "OnCancelClick"))
        this.ui.OnEvent("BtnExecute", "Click", ObjBindMethod(this, "TriggerMacro"))
        this.ui.OnEvent("ConfigDLCombo", "SelectionChanged", ObjBindMethod(this, "OnChangeConfig"))
        this.ui.OnEvent("BtnConfigEdit", "Click", ObjBindMethod(this, "OnClickConfigEditBtn"))
        this.ui.OnEvent("MouseMoveModeCombo", "SelectionChanged", ObjBindMethod(this, "OnTypeChange"))
        this.ui.OnEvent("HumanMouseTog", "Click", ObjBindMethod(this, "OnHumanMouseTogClick"))
        this.ui.OnEvent("BtnTargeter", "Click", ObjBindMethod(this, "OnClickTargeterBtn"))
        this.ui.OnEvent("BtnTargeterHelp", "Click", ObjBindMethod(this, "OnClickTargeterHelpBtn"))
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
        
        try this.ToggleFunc(false)
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
        ; 先关窗（PostMessage WM_CLOSE），再清理——任何清理异常都不阻断关闭
        if (IsObject(this.ui)) {
            try this.ui.Update("Window", "Close", "")
        }
        try this.ToggleFunc(false)
        if (this.OwnerHwnd != "" && MainSoftData.IsModalSubGui) {
            try SafeGuiFromHwnd(this.OwnerHwnd).Opt("-Disabled")
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

    _SelIndex(comboName) {
        v := IsObject(this.ui) ? this.ui.Query(comboName ">SelectedIndex") : ""
        return IsNumber(v) ? Integer(v) : 0
    }

    _TypeValue() => this._SelIndex("ActionTypeCombo") + 1
    _MoveMode() => this._SelIndex("MouseMoveModeCombo")

    Init(cmd) {
        
        cmdArr := cmd != "" ? StrSplit(cmd, "_") : []
        this.SerialStr := cmdArr.Length >= 1 ? cmdArr[1] : GetCMDSerialStr("移动Pro")
        
        this.ui.Update("RemarkCon", "Text", cmdArr.Length >= 2 ? cmdArr[2] : "")
        
        this.Data := GetMacroCMDData(this.SerialStr)
        this.DLVariableArr := GetGuiVarArr()

        
        this.RefreshConfigDLArr()
        
        this._SetCombo("PosVarX", this.DLVariableArr, GetLang(this.Data.PosVarX))
        this._SetCombo("PosVarY", this.DLVariableArr, GetLang(this.Data.PosVarY))
        this.ui.Update("ActionTypeCombo", "SelectedIndex", String(this.Data.ActionType - 1))

        MoveMode := 0
        if (ObjHasOwnProp(this.Data, "MouseMoveMode"))
            MoveMode := this.Data.MouseMoveMode
        this.ui.Update("MouseMoveModeCombo", "SelectedIndex", String(MoveMode))

        this.ui.Update("SpeedCon", "Text", this.Data.Speed)
        this.ui.Update("CountCon", "Text", this.Data.Count)
        this.ui.Update("IntervalCon", "Text", this.Data.Interval)
        this.ui.Update("HumanMouseTog", "IsChecked", (ObjHasOwnProp(this.Data, "IsHumanMouse") ? this.Data.IsHumanMouse : 0) ? "True" : "False")

        this.OnTypeChange()
        this.OnHumanMouseTogClick()
    }

    TriggerMacro(state := "", ctrl := "", event := "") {
        if (!this.CheckIfValid())
            return
        if (!IsNumber(this.ui.Query("PosVarX"))) {
            MsgBox(GetLang("坐标X是变量时，编辑模式下无法执行"))
            return
        }
        if (!IsNumber(this.ui.Query("PosVarY"))) {
            MsgBox(GetLang("坐标Y是变量时，编辑模式下无法执行"))
            return
        }
        this.SaveMMProData()
        OnTriggerSepcialItemMacro(this.GetCommandStr())
    }

    GetCommandStr() {
        textOnly := RegExReplace(this.Data.SerialStr, "\d+")
        numbersOnly := RegExReplace(this.Data.SerialStr, "\D+")
        CommandStr := Format("{}{}", GetLang(textOnly), numbersOnly)
        CommandStr := CorrectRemark(CommandStr, this.ui.Query("RemarkCon"))
        return CommandStr
    }

    RefreshConfigDLArr() {
        Arr := []
        Arr.Push(this.Data.ConfigName)
        loop this.Data.ConfigArr.Length {
            CurConfigData := this.Data.ConfigArr[A_Index]
            if (ObjHasOwnProp(CurConfigData, "ConfigName"))
                Arr.Push(CurConfigData.ConfigName)
        }
        this.ConfigDLArr := Arr
        this._syncing := true
        try this._SetCombo("ConfigDLCombo", Arr, this.Data.ConfigName)
        finally this._syncing := false
    }

    _SaveConfigData(saveStr) {
        IniWrite(saveStr, MMProFile, IniSection, this.Data.SerialStr)
    }

    OnClickConfigEditBtn(state := "", ctrl := "", event := "") {
        ; 打开 编辑 菜单（修改/增加/删除）
        x := y := 0
        CoordMode("Mouse", "Screen")
        MouseGetPos(&x, &y)
        this.OnRuleMenuAt(x, y)
    }

    OnRuleMenuAt(x, y) {
        ; 用 AHK 原生 Menu 弹编辑菜单（简单三选项，无需 XAML ContextMenu 样式）
        if (this.RuleMenu == "") {
            this.RuleMenu := Menu()
            this.RuleMenu.Add(GetLang("修改"), (*) => this.OnRuleMenuHandler(GetLang("修改")))
            this.RuleMenu.Add(GetLang("增加"), (*) => this.OnRuleMenuHandler(GetLang("增加")))
            this.RuleMenu.Add(GetLang("删除"), (*) => this.OnRuleMenuHandler(GetLang("删除")))
        }
        this.RuleMenu.Show(x, y)
    }

    OnRuleMenuHandler(Str) {
        if (Str == GetLang("修改")) {
            if (!ObjHasOwnProp(this, "WinRuleGui")) {
                this.WinRuleGui := WinRuleGui()
            }
            SureAction(width, height, remark) {
                ConfigName := Format("{}*{}", width, height)
                if (remark != "")
                    ConfigName := Format("{}*{}_{}", width, height, remark)
                if (ConfigName == this.Data.ConfigName)
                    return
                loop this.ConfigDLArr.Length {
                    if (this.ConfigDLArr[A_Index] == ConfigName) {
                        MsgBox(Format("{} 配置已存在，修改失败", ConfigName))
                        return
                    }
                }
                this.Data.ConfigName := ConfigName
                this.RefreshConfigDLArr()
                saveStr := JSON.stringify(this.Data, 0)
                this._SaveConfigData(saveStr)
                MsgBox(GetLang("修改成功"))
            }
            this.WinRuleGui.SureAction := SureAction
            this.WinRuleGui.ShowGui()
        }
        else if (Str == GetLang("增加")) {
            this.OnAddConfig()
        }
        else if (Str == GetLang("删除")) {
            this.OnRemoveConfig()
        }
    }

    _SaveCurrentConfigToData() {
        LastConfig := Object()
        LastConfig.ConfigName := this.Data.ConfigName
        LastConfig.PosVarX := GetLangKey(this.ui.Query("PosVarX"))
        LastConfig.PosVarY := GetLangKey(this.ui.Query("PosVarY"))
        LastConfig.ActionType := this._TypeValue()
        LastConfig.MouseMoveMode := this._MoveMode()
        LastConfig.Speed := this.ui.Query("SpeedCon")
        LastConfig.Count := this.ui.Query("CountCon")
        LastConfig.Interval := this.ui.Query("IntervalCon")
        return LastConfig
    }

    OnAddConfig() {
        if (!ObjHasOwnProp(this, "WinRuleGui")) {
            this.WinRuleGui := WinRuleGui()
        }
        SureAction(width, height, remark) {
            ConfigName := Format("{}*{}", width, height)
            if (remark != "")
                ConfigName := Format("{}*{}_{}", width, height, remark)
            loop this.ConfigDLArr.Length {
                if (this.ConfigDLArr[A_Index] == ConfigName) {
                    MsgBox(Format("{} 配置已存在，无法重复添加", ConfigName))
                    return
                }
            }
            LastConfig := this._SaveCurrentConfigToData()
            this.Data.ConfigArr.Push(LastConfig)
            this.Data.ConfigName := ConfigName
            this.RefreshConfigDLArr()
            saveStr := JSON.stringify(this.Data, 0)
            this._SaveConfigData(saveStr)
            MsgBox(Format("{} 配置添加成功", ConfigName))
        }
        this.WinRuleGui.SureAction := SureAction
        this.WinRuleGui.ShowGui()
    }

    OnRemoveConfig() {
        if (this.ConfigDLArr.Length <= 1) {
            MsgBox("最后选项不可删除！！！")
            return
        }
        result := MsgBox(Format(GetLang("是否删除 {} 配置"), this.ui.Query("ConfigDLCombo")), GetLang("提示"), 1)
        if (result == "Cancel")
            return

        ConfigData := this.Data.ConfigArr[1]
        this.Data.ConfigArr.RemoveAt(1)
        this.Data.ConfigName := ConfigData.ConfigName
        this.Data.PosVarX := ConfigData.PosVarX
        this.Data.PosVarY := ConfigData.PosVarY
        this.Data.ActionType := ConfigData.ActionType
        this.Data.MouseMoveMode := ObjHasOwnProp(ConfigData, "MouseMoveMode") ? ConfigData.MouseMoveMode : 0
        this.Data.Speed := ConfigData.Speed
        this.Data.Count := ConfigData.Count
        this.Data.Interval := ConfigData.Interval
        saveStr := JSON.stringify(this.Data, 0)
        this._SaveConfigData(saveStr)
        CMDStr := this.GetCommandStr()
        this.Init(CMDStr)
    }

    OnChangeConfig(state := "", ctrl := "", event := "") {
        if (this._syncing || !IsObject(this.ui) || !this.ConfigDLArr.Length)
            return
        ; 程序化设置（Init/Refresh）触发的 SelectionChanged 是异步到达的，_syncing 已被清。
        ; 此时新值==当前配置名=无实际切换，直接返回，避免 OnChangeConfig → Init 无限递归。
        if (this.ui.Query("ConfigDLCombo") == this.Data.ConfigName)
            return
        LastConfig := this._SaveCurrentConfigToData()
        this.Data.ConfigArr.Push(LastConfig)

        ConfigData := ""
        loop this.ConfigDLArr.Length {
            if (this.ui.Query("ConfigDLCombo") == this.Data.ConfigArr[A_Index].ConfigName) {
                ConfigData := this.Data.ConfigArr.RemoveAt(A_Index)
                break
            }
        }
        if (ConfigData == "")
            return

        this.Data.ConfigName := ConfigData.ConfigName
        this.Data.PosVarX := ConfigData.PosVarX
        this.Data.PosVarY := ConfigData.PosVarY
        this.Data.ActionType := ConfigData.ActionType
        this.Data.MouseMoveMode := ObjHasOwnProp(ConfigData, "MouseMoveMode") ? ConfigData.MouseMoveMode : 0
        this.Data.Speed := ConfigData.Speed
        this.Data.Count := ConfigData.Count
        this.Data.Interval := ConfigData.Interval
        saveStr := JSON.stringify(this.Data, 0)
        this._SaveConfigData(saveStr)
        CMDStr := this.GetCommandStr()
        this.Init(CMDStr)
    }

    CheckIfValid() {
        return true
    }

    RefreshMousePos() {
        
        if (!IsObject(this.ui))
            return
        CoordMode("Mouse", "Screen")
        MouseGetPos &mouseX, &mouseY
        this.ui.Update("MousePosCon", "Text", Format("{}{},{}", GetLang("当前鼠标位置:"), mouseX, mouseY))
        
    }

    ToggleFunc(state) {
        ; 全部 try/catch：任何热键/定时器异常都不能阻断开关流程（否则窗口无法关闭）
        if (state) {
            try SetTimer this.PosAction, 100
            try Hotkey("!l", (*) => this.TriggerMacro(), "On")
            try Hotkey("F1", (*) => this.SureMMPro(), "On")
        }
        else {
            try SetTimer this.PosAction, 0
            try Hotkey("!l", (*) => this.TriggerMacro(), "Off")
            try Hotkey("F1", (*) => this.SureMMPro(), "Off")
        }
    }

    OnTypeChange(state := "", ctrl := "", event := "") {
        if (this._syncing || !IsObject(this.ui))
            return
        MoveMode := this._MoveMode()
        isGameView := MoveMode == 2
        this.ui.Update("ActionTypeCombo", "IsEnabled", isGameView ? "False" : "True")
        this.ui.Update("SpeedCon", "IsEnabled", isGameView ? "False" : "True")
        this.ui.Update("HumanMouseTog", "IsEnabled", isGameView ? "False" : "True")
        this.ui.Update("CountRow", "Visibility", isGameView ? "Visible" : "Collapsed")
        this.ui.Update("IntervalRow", "Visibility", isGameView ? "Visible" : "Collapsed")
        if (isGameView) {
            this.ui.Update("ActionTypeCombo", "SelectedIndex", "0")
            this.ui.Update("SpeedCon", "Text", "100")
        }
    }

    OnSureTarget(PosX, PosY, Color) {
        if (IsObject(this.ui)) {
            this.ui.Update("PosVarX", "Text", PosX)
            this.ui.Update("PosVarY", "Text", PosY)
        }
    }

    OnClickTargeterBtn(state := "", ctrl := "", event := "") {
        MyTargetGui.SureAction := this.OnSureTarget.Bind(this)
        MyTargetGui.ShowGui()
    }

    OnClickTargeterHelpBtn(state := "", ctrl := "", event := "") {
        str := Format("{}`n{}`n{}", GetLang("1.左键拖拽改变位置"), GetLang("2.上下左右方向键微调位置"), GetLang("3.左键双击或回车键关闭取色器，同时确定点位信息"))
        MsgBox(str, GetLang("定位取色器操作说明"))
    }

    OnClickSureBtn(state, ctrl, event) {
        
        if (!this.CheckIfValid())
            return
        this.SaveMMProData()
        CommandStr := this.GetCommandStr()
        action := this.SureBtnAction
        this._CloseWindow()           ; 先关窗，回调即使抛异常也不阻断关闭
        if (action != "")
            action(CommandStr)
    }

    SureMMPro() {
        CoordMode("Mouse", "Screen")
        MouseGetPos &mouseX, &mouseY
        if (IsObject(this.ui)) {
            this.ui.Update("PosVarX", "Text", mouseX)
            this.ui.Update("PosVarY", "Text", mouseY)
        }
    }

    OnHumanMouseTogClick(state := "", ctrl := "", event := "") {
        if (this._syncing || !IsObject(this.ui))
            return
        isEnabled := this.ui.Query("HumanMouseTog") == "True"
        if (isEnabled) {
            if (this._MoveMode() == 2) {
                this.ui.Update("MouseMoveModeCombo", "SelectedIndex", "0")
                this.OnTypeChange()
            }
            if (this._TypeValue() != 1)
                this.ui.Update("ActionTypeCombo", "SelectedIndex", "0")
            this.ui.Update("ActionTypeCombo", "IsEnabled", "False")
            this.ui.Update("MouseMoveModeCombo", "IsEnabled", "False")
        }
        else {
            this.ui.Update("ActionTypeCombo", "IsEnabled", "True")
            this.ui.Update("MouseMoveModeCombo", "IsEnabled", "True")
        }
    }

    SaveMMProData() {
        this.Data.PosVarX := GetLangKey(this.ui.Query("PosVarX"))
        this.Data.PosVarY := GetLangKey(this.ui.Query("PosVarY"))
        this.Data.ActionType := this._TypeValue()
        this.Data.MouseMoveMode := this._MoveMode()
        this.Data.Speed := this.ui.Query("SpeedCon")
        this.Data.Count := this.ui.Query("CountCon")
        this.Data.Interval := this.ui.Query("IntervalCon")
        this.Data.IsHumanMouse := this.ui.Query("HumanMouseTog") == "True" ? 1 : 0
        SaveMacroCMDData(this.Data)
    }
}
