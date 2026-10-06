#Requires AutoHotkey v2.0

; =====================================================================
; 增量移动编辑器 —— §20 原「移动Pro-游戏视角」拆出（mouse_event 相对位移）
; 公开接口保持：ShowGui(cmd) / SureBtnAction / OwnerHwnd / ParentTile
; =====================================================================

class DeltaMoveGui {
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
        title := this.ParentTile GetLang("增量移动编辑器")
        this._title := title
        titleHeight := "30"

        main := XAML_Generator("Grid").Background("{DynamicResource BgColor}").TextElement_FontSize(XAMLHost.FontSize())
        main.Rows(titleHeight, "*")

        ; === 标题栏 ===
        chrome := XAMLHost.AddCmdTitleBar(main, title, titleHeight)

        ; === 内容 ===
        body := main.Add("Grid").Grid_Row(1).Margin("15,14,15,14")
        body.Rows("40", "40", "34", "30", "*")
        body.Cols("110", "*")

        ; 备注
        body.Add("TextBlock").Grid_Row(0).Grid_Column(0).Text(GetLang("备注：")).VerticalAlignment("Center").Foreground("{DynamicResource TextMain}").FontSize("12")
        body.Add("TextBox").Grid_Row(0).Grid_Column(1).Name("RemarkCon").Width(220).Height(26).MinHeight(26).HorizontalAlignment("Left")
            .VerticalContentAlignment("Center").FontSize("11").Padding("4,0")
            .Foreground("{DynamicResource InputText}").Background("{DynamicResource InputBg}")
            .BorderBrush("{DynamicResource InputStroke}").BorderThickness("1")

        ; X 偏移
        body.Add("TextBlock").Grid_Row(1).Grid_Column(0).Text(GetLang("X偏移：")).VerticalAlignment("Center").Foreground("{DynamicResource TextMain}").FontSize("12")
        body.Add("TextBox").Grid_Row(1).Grid_Column(1).Name("DeltaXCon").Width(160).Height(26).MinHeight(26).HorizontalAlignment("Left").Text("0")
            .VerticalContentAlignment("Center").FontSize("11").Padding("4,0")
            .Foreground("{DynamicResource InputText}").Background("{DynamicResource InputBg}")
            .BorderBrush("{DynamicResource InputStroke}").BorderThickness("1")

        ; Y 偏移
        body.Add("TextBlock").Grid_Row(2).Grid_Column(0).Text(GetLang("Y偏移：")).VerticalAlignment("Center").Foreground("{DynamicResource TextMain}").FontSize("12")
        body.Add("TextBox").Grid_Row(2).Grid_Column(1).Name("DeltaYCon").Width(160).Height(26).MinHeight(26).HorizontalAlignment("Left").Text("0")
            .VerticalContentAlignment("Center").FontSize("11").Padding("4,0")
            .Foreground("{DynamicResource InputText}").Background("{DynamicResource InputBg}")
            .BorderBrush("{DynamicResource InputStroke}").BorderThickness("1")

        ; 提示
        body.Add("TextBlock").Grid_Row(3).Grid_ColumnSpan(2).Text(GetLang("相对位移（鼠标增量移动），固定走 mouse_event，与按键类型无关；支持 {变量}。")).VerticalAlignment("Center").Foreground("{DynamicResource TextSub}").FontSize("11")

        ; 确定按钮
        btnRow := body.Add("StackPanel").Grid_Row(4).Grid_ColumnSpan(2).Orientation("Horizontal").HorizontalAlignment("Center").VerticalAlignment("Center")
        AddCmdOkBtn(btnRow)

        ; === 创建 XAMLHost ===
        tmp := StrReplace(XAML_TEMPLATE, "%CaptionHeight%", titleHeight)
        this.ui := XAMLHost(StrReplace(tmp, "%app%", main.ToString()), "", this.OwnerHwnd)
        this.ui.xaml := StrReplace(this.ui.xaml, 'Width="940" Height="700"', 'Title="' this._EscapeXml(title) '" Width="380" SizeToContent="Height" Opacity="0"')
        this.ui.xaml := StrReplace(this.ui.xaml, 'FontFamily="Segoe UI Variable Display, Segoe UI, sans-serif"', 'FontFamily="' MainSoftData.FontType '"')
        this.ui.xaml := StrReplace(this.ui.xaml, '%resources%', '')

        ; === 事件 ===
        this.ui.OnEvent("Window", "Closing", ObjBindMethod(this, "OnWindowClosing"))
        this.ui.OnEvent("Window", "LoadedHwnd", ObjBindMethod(this, "OnWindowLoad"))
        this.ui.OnEvent("BtnClosePanel", "Click", ObjBindMethod(this, "OnCancelClick"))
        BindCmdEditorChrome(this.ui, "#指令手册/6-移动Pro")
        this.ui.OnEvent("BtnOk", "Click", ObjBindMethod(this, "OnSureBtnClick"))

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

    Init(cmd) {
        cmd := RMTParseErrHandle(cmd).cmd
        cmdArr := cmd != "" ? StrSplit(cmd, "_") : []
        this.Data := DeltaMoveData()
        this.ui.Update("RemarkCon", "Text", cmdArr.Length >= 2 ? cmdArr[2] : "")
        SplitSerialTextAndNumbers(cmdArr.Length >= 1 ? cmdArr[1] : "", &textOnly, &numbersOnly)
        if (numbersOnly != "") {
            this.Data := GetMacroCMDData(cmdArr[1])
            dX := this.Data.DeltaX
            dY := this.Data.DeltaY
        } else {
            dX := cmdArr.Length >= 2 ? cmdArr[2] : 0
            dY := cmdArr.Length >= 3 ? cmdArr[3] : 0
        }
        this.ui.Update("DeltaXCon", "Text", dX)
        this.ui.Update("DeltaYCon", "Text", dY)
    }

    CheckIfValid() {
        return true
    }

    OnSureBtnClick(state, ctrl, event) {
        if (!this.CheckIfValid())
            return
        CommandStr := this.GetCmdStr()
        action := this.SureBtnAction
        this._CloseWindow()
        if (action != "")
            action(CommandStr)
    }

    ; 阶段5：指令配置化——组装 Data 保存到配置文件，返回 增量移动<serial>_备注
    GetCmdStr() {
        this.Data.DeltaX := this.ui.Query("DeltaXCon")
        this.Data.DeltaY := this.ui.Query("DeltaYCon")

        if (this.Data.SerialStr == "")
            this.Data.SerialStr := GetCMDSerialStr(GetLang("增量移动"))
        SaveMacroCMDData(this.Data)
        remark := Trim(this.ui.Query("RemarkCon"))
        if (remark == "")
            remark := this.Data.DeltaX " " this.Data.DeltaY
        return CorrectRemark(this.Data.SerialStr, remark)
    }
}
