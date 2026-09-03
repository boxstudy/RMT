#Requires AutoHotkey v2.0

; =====================================================================
; 前台信息编辑器 —— XAML 迁移版（独立实现）
; 公开接口保持：ShowGui(winInfoCon, isFront) / OwnerHwnd / HideAction / SureAction
; winInfoCon 用 XamlValueBridge（含 .Value 读写），F1 取窗 + 鼠标信息定时器沿用原生
; =====================================================================

class FrontInfoGui {
    __new() {
        this.Gui := ""
        this.ui := ""
        this.OwnerHwnd := ""
        this.InfoAction := () => this.RefreshMouseInfo()
        this.HideAction := ""
        this.SureAction := ""
        this.winInfoCon := ""
        this.isFront := false
        this._closed := true

        ; 控件名数组（索引 1..5 对应 运行时鼠标下窗口/句柄ID/标题/窗口类/进程名）
        this.InfoTogArrCon := ["Tog1", "Tog2", "Tog3", "Tog4", "Tog5"]
        this.InfoTextArrCon := ["InfoText1", "InfoText2", "InfoText3", "InfoText4", "InfoText5"]
        this.VarConArr := ["VariTipCon", "VariCon", "BtnAddVar"]
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

    ShowGui(winInfoCon, isFront := false) {
        global MySoftData
        if (IsObject(this.ui) && !this._closed)
            this._CloseWindow()
        this._BuildAndShow()
        if (this.OwnerHwnd != "" && MainSoftData.IsModalSubGui) {
            try SafeGuiFromHwnd(this.OwnerHwnd).Opt("+Disabled")
        }
        this.isFront := isFront
        this.Init(winInfoCon)
        this.ToggleFunc(true)
    }

    _BuildAndShow() {
        global MySoftData
        this._closed := false
        title := GetLang("前台信息编辑器")
        this._title := title
        titleHeight := "30"

        main := XAML_Generator("Grid").Background("{DynamicResource BgColor}").TextElement_FontSize(XAMLHost.FontSize())
        main.Rows(titleHeight, "30", "*", "44")

        ; === 标题栏 ===
        tb := main.Add("Border").Grid_Row(0).Background("{DynamicResource TitleBarColor}").Name("DragArea")
        tbInner := tb.Add("Grid")
        tbInner.Add("TextBlock").Text(title).Foreground("{DynamicResource TitleBarForeground}").FontSize(XAMLHost.TitleFontSize()).FontWeight("Bold").VerticalAlignment("Center").Margin("12,0,0,0")
        BtnGroup := tbInner.Add("StackPanel").Orientation("Horizontal").HorizontalAlignment("Right")
        closeBtn := BtnGroup.Add("Button").Name("BtnClosePanel").WindowChrome_IsHitTestVisibleInChrome("True").Width(40).Background("Transparent").Foreground("{DynamicResource TitleBarForeground}").BorderThickness(0)
        closeBtn.Add("TextBlock").Text(Chr(0xE8BB)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize(10).VerticalAlignment("Center").HorizontalAlignment("Center")

        ; === 顶部行 ===
        top := main.Add("StackPanel").Grid_Row(1).Orientation("Horizontal").Margin("10,4")
        top.Add("CheckBox").Name("TopTogCon").Content(GetLang("窗口置顶")).VerticalAlignment("Center")
        top.Add("TextBlock").Text("F1").VerticalAlignment("Center").Margin("60,0,0,0").Opacity("0.6")
        top.Add("TextBlock").Text(GetLang("确定信息")).VerticalAlignment("Center").Margin("4,0,0,0")
        top.Add("Button").Name("BtnHelp").Content("?").Width(30).Height(26).MinHeight(26).Margin("20,0,0,0").Cursor("Hand")
            .Background("{DynamicResource EditBg}").Foreground("{DynamicResource EditText}")
            .BorderBrush("{DynamicResource EditStroke}").BorderThickness("1").Padding("0")

        ; === 主体 ===
        body := main.Add("StackPanel").Grid_Row(2).Orientation("Vertical").Margin("10,2")
        body.Add("TextBlock").Text(GetLang("当前鼠标下窗口信息：")).VerticalAlignment("Center")
        body.Add("TextBox").Name("CurWinInfoCon").Height(70).Margin("0,2,0,0").IsReadOnly("True")
            .Background("{DynamicResource InputBg}").Foreground("{DynamicResource InputText}")
            .BorderBrush("{DynamicResource InputStroke}").BorderThickness("1").VerticalContentAlignment("Top").Padding("4,2").FontSize(11)

        ; 5 行 checkbox + edit
        this._AddInfoRow(body, 1, GetLang("运行时鼠标下窗口"), true)
        this._AddInfoRow(body, 2, GetLang("句柄ID"), false)
        ; 变量行
        varRow := body.Add("StackPanel").Orientation("Horizontal").Margin("95,2,0,0")
        varRow.Add("TextBlock").Name("VariTipCon").Text(GetLang("变量:")).VerticalAlignment("Center")
        varRow.Add("ComboBox").Name("VariCon").Width(130).Height(26).MinHeight(26).Margin("4,0,0,0").IsEditable("True")
        varRow.Add("Button").Name("BtnAddVar").Content(GetLang("追加变量值")).Height(26).MinHeight(26).Margin("6,0,0,0").Cursor("Hand")
        this._AddInfoRow(body, 3, GetLang("标题"), false)
        this._AddInfoRow(body, 4, GetLang("窗口类"), false)
        this._AddInfoRow(body, 5, GetLang("进程名"), false)

        ; === 底部按钮 ===
        btnRow := main.Add("StackPanel").Grid_Row(3).Orientation("Horizontal").HorizontalAlignment("Center").VerticalAlignment("Center")
        btnRow.Add("Button").Name("BtnSure").Content(GetLang("确定")).Width(100).Height(32).MinHeight(32).Margin("4,0").Cursor("Hand")

        ; === 创建 XAMLHost ===
        tmp := StrReplace(XAML_TEMPLATE, "%CaptionHeight%", titleHeight)
        this.ui := XAMLHost(StrReplace(tmp, "%app%", main.ToString()), "", this.OwnerHwnd)
        this.ui.xaml := StrReplace(this.ui.xaml, 'Width="940" Height="700"', 'Title="' this._EscapeXml(title) '" Width="560" Height="500" Opacity="0"')
        this.ui.xaml := StrReplace(this.ui.xaml, 'FontFamily="Segoe UI Variable Display, Segoe UI, sans-serif"', 'FontFamily="' MainSoftData.FontType '"')
        this.ui.xaml := StrReplace(this.ui.xaml, '%resources%', '')

        ; === 事件 ===
        this.ui.OnEvent("Window", "Closing", ObjBindMethod(this, "OnWindowClosing"))
        this.ui.OnEvent("Window", "LoadedHwnd", ObjBindMethod(this, "OnWindowLoad"))
        this.ui.OnEvent("BtnClosePanel", "Click", ObjBindMethod(this, "OnCancelClick"))
        this.ui.OnEvent("TopTogCon", "Click", ObjBindMethod(this, "OnTopTogClick"))
        this.ui.OnEvent("BtnHelp", "Click", ObjBindMethod(this, "OnClickTypeHelpBtn"))
        this.ui.OnEvent("BtnAddVar", "Click", ObjBindMethod(this, "OnClickAddVarValueBtn"))
        this.ui.OnEvent("BtnSure", "Click", ObjBindMethod(this, "OnSureBtnClick"))
        for i in [1, 2, 3, 4, 5] {
            name := "Tog" i
            this.ui.OnEvent(name, "Click", ObjBindMethod(this, "OnTogClick").Bind(i))
        }

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

    _AddInfoRow(parent, idx, label, hideText) {
        row := parent.Add("StackPanel").Orientation("Horizontal").Margin("0,2,0,0")
        row.Add("CheckBox").Name("Tog" idx).Content(label).Width(150).VerticalAlignment("Center")
        vis := hideText ? "Collapsed" : "Visible"
        row.Add("TextBox").Name("InfoText" idx).Width(360).Height(26).MinHeight(26).Margin("8,0,0,0").Visibility(vis)
            .Background("{DynamicResource InputBg}").Foreground("{DynamicResource InputText}")
            .BorderBrush("{DynamicResource InputStroke}").BorderThickness("1").VerticalContentAlignment("Center").Padding("4,0")
    }

    Init(winInfoCon) {
        this.winInfoCon := winInfoCon
        this.ui.Update("TopTogCon", "IsChecked", "True")
        infoStr := winInfoCon.Value
        if (InStr(infoStr, "❖")) {
            idStr := StrReplace(infoStr, "❖", "")
            infoArr := ["", idStr, "", "", ""]
        }
        else {
            infoArr := ["", "", ""]
            if (infoStr != "") {
                tmp := StrSplit(infoStr, "⎖")
                if (tmp.Length == 3)
                    infoArr := tmp
            }
            infoArr.InsertAt(1, "")
            infoArr.InsertAt(1, "")
        }

        loop 5 {
            this.ui.Update(this.InfoTogArrCon[A_Index], "IsChecked", infoArr[A_Index] != "" ? "True" : "False")
            this.ui.Update(this.InfoTextArrCon[A_Index], "Text", infoArr[A_Index])
        }

        DLVariableArr := GetGuiVarArr(4)
        this.ui.Update("VariCon", "ClearItems", "")
        for it in DLVariableArr {
            if (it == "")
                continue
            this.ui.Update("VariCon", "AddItem", it)
        }
        this.ui.Update("VariCon", "SelectedIndex", "0")

        loop 5 {
            if (this.ui.Query(this.InfoTogArrCon[A_Index]) == "True") {
                this.OnTogClick(A_Index)
                break
            }
        }
    }

    RefreshMouseInfo() {
        static labels := ""
        if (labels == "") {
            labels := {
                hwnd: GetLang("句柄ID："),
                title: GetLang("标题："),
                class: GetLang("窗口类："),
                process: GetLang("进程名：")
            }
        }

        CoordMode("Mouse", "Screen")
        MouseGetPos &mouseX, &mouseY, &winId
        try {
            title := WinGetTitle(winId)
            className := WinGetClass(winId)
            try {
                WinPID := WinGetPID("ahk_id " winId)
                process := ProcessGetName(WinPID)
            }
            catch {
                process := ""
            }

            tipStr := labels.hwnd winId "`n" labels.title title "`n" labels.class className "`n" labels.process process
            this.ui.Update("CurWinInfoCon", "Text", tipStr)
        }
    }

    ToggleFunc(state) {
        if (state) {
            SetTimer this.InfoAction, 100
            Hotkey("F1", (*) => this.OnF1(), "On")
        }
        else {
            SetTimer this.InfoAction, 0
            Hotkey("F1", (*) => this.OnF1(), "Off")
        }
    }

    CheckIfValid() {
        if (this.ui.Query("Tog2") == "True" && this.ui.Query("InfoText2") == "") {
            MsgBox(GetLang("勾选句柄ID后，句柄ID内容不能为空"), "", "Owner" this.Hwnd())
            return false
        }

        if (this.ui.Query("Tog3") == "True" && this.ui.Query("InfoText3") == "") {
            MsgBox(GetLang("勾选标题后，标题内容不能为空"), "", "Owner" this.Hwnd())
            return false
        }

        if (this.ui.Query("Tog4") == "True" && this.ui.Query("InfoText4") == "") {
            MsgBox(GetLang("勾选窗口类后，窗口类内容不能为空"), "", "Owner" this.Hwnd())
            return false
        }

        if (this.ui.Query("Tog5") == "True" && this.ui.Query("InfoText5") == "") {
            MsgBox(GetLang("勾选进程名后，进程名内容不能为空"), "", "Owner" this.Hwnd())
            return false
        }

        if (this.isFront && this.ui.Query("Tog2") == "True") {
            if (InStr(this.ui.Query("InfoText2"), "{")) {
                MsgBox(GetLang("前台窗口信息句柄ID不能使用变量"), "", "Owner" this.Hwnd())
                return false
            }
        }

        return true
    }

    GetInfoStr() {
        if (this.ui.Query("Tog2") == "True")
            return "❖" this.ui.Query("InfoText2")

        Str := ""
        loop 5 {
            if (A_Index == 1 || A_Index == 2)
                continue
            if (this.ui.Query("Tog" A_Index) == "True") {
                Str .= this.ui.Query("InfoText" A_Index)
            }
            if (A_Index != 5)
                Str .= "⎖"
        }
        if (Str == "⎖⎖")
            return ""
        return Str
    }

    OnSureBtnClick(state, ctrl, event) {
        isValid := this.CheckIfValid()
        if (!isValid)
            return

        this.winInfoCon.Value := this.GetInfoStr()
        this._CloseWindow()
        if (this.HideAction != "") {
            action := this.HideAction
            action()
            this.HideAction := ""
        }
        if (this.SureAction != "") {
            action := this.SureAction
            action()
            this.SureAction := ""
        }
    }

    OnTopTogClick(state, ctrl, event) {
        topmost := this.ui.Query("TopTogCon") == "True"
        WinSetAlwaysOnTop(topmost ? "On" : "Off", "ahk_id " this.Hwnd())
    }

    OnTogClick(index, *) {
        isOn := this.ui.Query("Tog" index) == "True"
        if (!isOn)
            return

        switch (index) {
            case 1:
            {
                loop 5 {
                    this.ui.Update("Tog" A_Index, "IsChecked", "False")
                }
                this.ui.Update("Tog1", "IsChecked", "True")
                this.ui.Update("Tog2", "IsChecked", "True")
                this.ui.Update("InfoText2", "Text", "{" GetLang("句柄ID") "}")
                this.ui.Update("InfoText2", "IsEnabled", "False")
                for name in this.VarConArr
                    this.ui.Update(name, "IsEnabled", "False")
                this.ui.Update("InfoText3", "IsEnabled", "False")
                this.ui.Update("InfoText4", "IsEnabled", "False")
                this.ui.Update("InfoText5", "IsEnabled", "False")
            }
            case 2:
            {
                loop 5 {
                    this.ui.Update("Tog" A_Index, "IsChecked", "False")
                }
                this.ui.Update("Tog2", "IsChecked", "True")
                this.ui.Update("InfoText2", "IsEnabled", "True")
                for name in this.VarConArr
                    this.ui.Update(name, "IsEnabled", "True")
                this.ui.Update("InfoText3", "IsEnabled", "False")
                this.ui.Update("InfoText4", "IsEnabled", "False")
                this.ui.Update("InfoText5", "IsEnabled", "False")
            }
            default:
            {
                this.ui.Update("Tog1", "IsChecked", "False")
                this.ui.Update("Tog2", "IsChecked", "False")
                this.ui.Update("InfoText2", "IsEnabled", "False")
                for name in this.VarConArr
                    this.ui.Update(name, "IsEnabled", "False")
                this.ui.Update("InfoText3", "IsEnabled", "True")
                this.ui.Update("InfoText4", "IsEnabled", "True")
                this.ui.Update("InfoText5", "IsEnabled", "True")
            }
        }
    }

    OnF1() {
        CoordMode("Mouse", "Screen")
        MouseGetPos &mouseX, &mouseY, &winId
        try {
            title := WinGetTitle(winId)
            className := WinGetClass(winId)
            try {
                WinPID := WinGetPID("ahk_id " winId)
                process := ProcessGetName(WinPID)
            }
            catch {
                process := ""
            }

            this.ui.Update("Tog3", "IsChecked", "True")
            this.ui.Update("Tog4", "IsChecked", "True")
            this.ui.Update("Tog5", "IsChecked", "True")
            this.ui.Update("Tog2", "IsChecked", "False")
            this.ui.Update("InfoText2", "IsEnabled", "False")
            for name in this.VarConArr
                this.ui.Update(name, "IsEnabled", "False")

            this.ui.Update("InfoText2", "Text", winId)
            this.ui.Update("InfoText3", "Text", title)
            this.ui.Update("InfoText4", "Text", className)
            this.ui.Update("InfoText5", "Text", process)
            this.OnTogClick(3)
        }
    }

    OnClickTypeHelpBtn(*) {
        str1 := GetLang("优先级：句柄ID > 标题 + 窗口类 + 进程名")
        str2 := GetLang("句柄ID支持多ID任意适配")
        str := Format("{}`n{}", str1, str2)
        MsgBox(str, GetLang("窗口信息说明"), "Owner" this.Hwnd())
    }

    OnClickAddVarValueBtn(state, ctrl, event) {
        cur := this.ui.Query("InfoText2")
        Symbol := cur == "" ? "" : "|"
        VarStr := "{" this.ui.Query("VariCon") "}"
        if (this.ui.Query("VariCon") == "") {
            MsgBox("请勿添加空字符变量", "", "Owner" this.Hwnd())
            return
        }
        if (InStr(cur, VarStr)) {
            MsgBox("请勿重复添加变量", "", "Owner" this.Hwnd())
            return
        }

        this.ui.Update("InfoText2", "Text", cur Symbol VarStr)
    }

    OnClose(*) {
        this.ToggleFunc(false)
        if (this.OwnerHwnd != "" && MainSoftData.IsModalSubGui) {
            try SafeGuiFromHwnd(this.OwnerHwnd).Opt("-Disabled")
        }
        if (this.HideAction != "") {
            action := this.HideAction
            action()
            this.HideAction := ""
        }
    }

    OnWindowLoad(state, ctrl, event) {
        try {
            themeName := MainSoftData.HasProp("Theme") ? MainSoftData.Theme : "RMT_Light"
            ApplyXamlTheme(this.ui, themeName)
        } catch {
        }
    }

    OnWindowClosing(state, ctrl, event) {
        this.ToggleFunc(false)
        if (this.OwnerHwnd != "" && MainSoftData.IsModalSubGui) {
            try SafeGuiFromHwnd(this.OwnerHwnd).Opt("-Disabled")
        }
        if (this.HideAction != "") {
            action := this.HideAction
            action()
            this.HideAction := ""
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
}
