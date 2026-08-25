#Requires AutoHotkey v2.0

class SettingMgrGui {
    static instances := Map()
    static _opening := false

    __new() {
        this.ui := 0
        this.closed := false
        this._instanceKey := ""
        this.SettingList := []
        this._selectedSetting := ""
        this._applyingUI := false
        this._btnStyle := ""
        this._themeReady := false
        this._contentReady := false
        this._revealed := false
        this._openTick := 0
    }

    ; 兼容旧入口 MySettingMgrGui.ShowGui()
    ShowGui() {
        SettingMgrGui.ShowGui()
    }

    static ShowGui() {
        key := "global"
        XamlUiDiag("ShowGui enter hasInst=" SettingMgrGui.instances.Has(key) " opening=" SettingMgrGui._opening, "SettingMgr")
        if (SettingMgrGui.instances.Has(key)) {
            oldInst := SettingMgrGui.instances[key]
            hwnd := (IsObject(oldInst.ui) && oldInst.ui.HasProp("wpfHwnd")) ? oldInst.ui.wpfHwnd : 0
            reuse := !oldInst.closed && XAMLHost.CanReuseWindow(hwnd)
            XamlUiDiag("oldInst closed=" oldInst.closed " hwnd=" hwnd " reuse=" reuse, "SettingMgr")
            if (reuse) {
                try WinActivate("ahk_id " hwnd)
                oldInst.Refresh()
                XamlUiDiagWindow(hwnd, "SettingMgr.reuse", true)
                return
            }
            try {
                if (!oldInst.closed && IsObject(oldInst.ui))
                    oldInst.Close()
            }
            SettingMgrGui.instances.Delete(key)
        }

        XAMLHost.EnsureDaemonHealthy()
        if (SettingMgrGui._opening) {
            XamlUiDiag("ABORT: _opening=true", "SettingMgr")
            return
        }
        SettingMgrGui._opening := true
        try {
            inst := SettingMgrGui()
            inst._instanceKey := key
            ; ===== 临时诊断S1：构建前 =====
            DiagOpenStep("SettingMgr", "S1-构建前", "窗口尚未创建，屏幕上不应出现任何新窗口。")
            inst._BuildAndShow()
            ; ===== 临时诊断S3：构建完成（窗口应已显示）=====
            hwnd3 := (IsObject(inst.ui) && inst.ui.HasProp("wpfHwnd")) ? inst.ui.wpfHwnd : 0
            DiagOpenStep("SettingMgr", "S3-构建完成", "窗口应已【回到原位并完整显示】：标题「配置管理」+ 所有配置列表 + 按钮区（迁入/重命名/配置校准等），主题色背景。"
                "`n若打开过程中有白屏/闪烁，请描述你看到的顺序（先白后内容？）。", hwnd3)
            SettingMgrGui.instances[key] := inst
            XamlUiDiag("ShowGui done hwnd=" (IsObject(inst.ui) && inst.ui.HasProp("wpfHwnd") ? inst.ui.wpfHwnd : 0), "SettingMgr")
        } catch as e {
            XamlUiDiag("ShowGui EXCEPTION: " e.Message " @ " e.File ":" e.Line, "SettingMgr")
        } finally {
            SettingMgrGui._opening := false
        }
    }

    _BuildAndShow() {
        this.closed := false
        title := GetLang("配置管理")
        titleHeight := "36"
        this._btnStyle := '<Style TargetType="Button"><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border x:Name="bd" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="3"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bd" Property="Background" Value="{DynamicResource EditHoverBg}"/><Setter TargetName="bd" Property="BorderBrush" Value="{DynamicResource EditHoverStroke}"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>'

        main := XAML_Generator("Grid").Background("{DynamicResource BgColor}")
        main.Rows(titleHeight, "*")

        tb := main.Add("Border").Grid_Row(0).Background("{DynamicResource TitleBarColor}").Name("DragArea")
        tbInner := tb.Add("Grid")
        tbInner.Add("TextBlock").Text(title).Foreground("{DynamicResource TitleBarForeground}").FontSize(12).FontWeight("SemiBold").VerticalAlignment("Center").Margin("15,0,0,0")

        BtnGroup := tbInner.Add("StackPanel").Orientation("Horizontal").HorizontalAlignment("Right")
        CloseBtnTemplate := '<Style TargetType="Button"><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border x:Name="border" Background="{TemplateBinding Background}" CornerRadius="{DynamicResource CloseBtnRadius}"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="border" Property="Background" Value="#E0FF3333"/><Setter Property="Foreground" Value="White"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>'
        closeBtn := BtnGroup.Add("Button").Name("BtnClosePanel").WindowChrome_IsHitTestVisibleInChrome("True").Width(40).Background("Transparent").Foreground("{DynamicResource TitleBarForeground}").BorderThickness(0)
        closeBtn.InjectResources(CloseBtnTemplate)
        closeBtn.Add("TextBlock").Text(Chr(0xE8BB)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize(10).VerticalAlignment("Center").HorizontalAlignment("Center")

        body := main.Add("Border").Grid_Row(1).Background("{DynamicResource BgColor}")
        scrollViewer := body.Add("ScrollViewer").VerticalScrollBarVisibility("Auto").HorizontalScrollBarVisibility("Disabled")
        panel := scrollViewer.Add("StackPanel").Margin("16, 8, 16, 12")

        ; 顶部右侧按钮区：迁入宽 = 重命名 + 间距 + 配置校准，左右分别对齐
        renameW := 80
        repairW := 80
        topBtnGap := 8
        replaceW := renameW + topBtnGap + repairW

        ; 组内操作行：与「配置选项 + 下拉」同宽，左右按钮分别贴齐两端
        optLabelW := 78
        comboW := 200
        comboMargin := 8
        operRowW := optLabelW + comboMargin + comboW
        operBtnW := 100

        ; 所有配置 + 迁入
        rowAll := panel.Add("Grid").Margin("0,2,0,0")
        rowAll.Cols("*", "Auto")
        rowAll.Add("TextBlock").Text(GetLang("所有配置："))
            .Foreground("{DynamicResource TextMain}").FontSize(13).FontWeight("SemiBold")
            .VerticalAlignment("Center").Grid_Column(0)
        this._AddBtn(rowAll, "BtnReplace", GetLang("迁入配置文件夹"), replaceW)
            .Grid_Column(1).HorizontalAlignment("Right")

        ; 当前配置 + 重命名 / 校准
        rowCur := panel.Add("Grid").Margin("0,10,0,0")
        rowCur.Cols("*", "Auto")
        curLeft := rowCur.Add("StackPanel").Orientation("Horizontal").Grid_Column(0).VerticalAlignment("Center")
        curLeft.Add("TextBlock").Text(GetLang("当前配置："))
            .Foreground("{DynamicResource TextMain}").FontSize(13)
            .VerticalAlignment("Center")
        curLeft.Add("TextBlock").Name("CurSettingCon").Text("")
            .Foreground("{DynamicResource TextSub}").FontSize(13)
            .VerticalAlignment("Center").Margin("4,0,0,0")
        curRight := rowCur.Add("StackPanel").Orientation("Horizontal").Grid_Column(1)
            .HorizontalAlignment("Right").VerticalAlignment("Center").Width(replaceW)
        this._AddBtn(curRight, "BtnRename", GetLang("重命名"), renameW).Margin("0,0," topBtnGap ",0")
        this._AddBtn(curRight, "BtnRepair", GetLang("配置校准"), repairW)

        ; 新增与导入
        addGroup := panel.Add("GroupBox").Header(GetLang("新增与导入")).Margin("0,12,0,0")
            .BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1")
            .Foreground("{DynamicResource TextMain}")
        addInner := addGroup.Add("StackPanel").Orientation("Horizontal").Margin("12, 10, 12, 10").HorizontalAlignment("Center")
        this._AddBtn(addInner, "BtnAdd", GetLang("新增配置"), 100).Margin("0,0,10,0")
        this._AddBtn(addInner, "BtnUnpack", GetLang("导入配置"), 100).Margin("0,0,10,0")
        this._AddBtn(addInner, "BtnMerge", GetLang("合并导入"), 100)

        ; 配置操作
        operGroup := panel.Add("GroupBox").Header(GetLang("配置操作")).Margin("0,10,0,0")
            .BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1")
            .Foreground("{DynamicResource TextMain}")
        operInner := operGroup.Add("StackPanel").Margin("12, 8, 12, 10")

        rowOpt := operInner.Add("StackPanel").Orientation("Horizontal").Margin("0,2,0,0")
            .HorizontalAlignment("Center").Width(operRowW)
        rowOpt.Add("TextBlock").Text(GetLang("配置选项："))
            .Foreground("{DynamicResource TextMain}").FontSize(13)
            .VerticalAlignment("Center").Width(optLabelW)
        rowOpt.Add("ComboBox").Name("OperSettingCon").Width(comboW).Height(26).MinHeight(26)
            .Margin(comboMargin ",0,0,0")

        this._AddPairBtnRow(operInner, "BtnLoad", GetLang("加载配置"), "BtnDel", GetLang("删除配置"),
            operRowW, operBtnW, "0,12,0,0")
        this._AddPairBtnRow(operInner, "BtnCourse", GetLang("使用说明"), "BtnPack", GetLang("导出配置"),
            operRowW, operBtnW, "0,10,0,0")

        ; 仓库配置（与配置操作行同宽对齐）
        repoGroup := panel.Add("GroupBox").Header(GetLang("仓库配置")).Margin("0,10,0,0")
            .BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1")
            .Foreground("{DynamicResource TextMain}")
        repoInner := repoGroup.Add("StackPanel").Margin("12, 10, 12, 10")
        this._AddPairBtnRow(repoInner, "BtnOpenRepo", GetLang("打开仓库"), "BtnUpload", GetLang("共享上传"),
            operRowW, operBtnW, "0,0,0,0")

        tmp := StrReplace(XAML_TEMPLATE, "%CaptionHeight%", titleHeight)
        this.ui := XAMLHost(StrReplace(tmp, "%app%", main.ToString()), "", "")
        this.ui.xaml := StrReplace(this.ui.xaml, 'Width="940" Height="700"', 'Title="' title '" ShowInTaskbar="False" Width="440" Height="460" Opacity="0"')
        this.ui.xaml := StrReplace(this.ui.xaml, 'CornerRadius="{DynamicResource WindowRadius}"', 'CornerRadius="{DynamicResource PanelRadius}"')
        this.ui.xaml := StrReplace(this.ui.xaml, 'FontFamily="Segoe UI Variable Display, Segoe UI, sans-serif"', 'FontFamily="' MainSoftData.FontType '"')
        groupBoxStyle := '<Style TargetType="GroupBox"><Setter Property="BorderBrush" Value="{DynamicResource ControlBorder}"/><Setter Property="BorderThickness" Value="1"/><Setter Property="Foreground" Value="{DynamicResource TextMain}"/></Style>'
        this.ui.xaml := StrReplace(this.ui.xaml, '%resources%', '<CornerRadius x:Key="PanelRadius">8</CornerRadius>' groupBoxStyle)

        this.ui.OnEvent("Window", "Closing", ObjBindMethod(this, "OnWindowClosing"))
        this.ui.OnEvent("Window", "LoadedHwnd", ObjBindMethod(this, "OnWindowLoad"))
        this.ui.OnEvent("BtnClosePanel", "Click", ObjBindMethod(this, "OnCancelClick"))
        this.ui.Track("OperSettingCon")
        this.ui.OnEvent("OperSettingCon", "SelectionChanged", ObjBindMethod(this, "OnOperSettingChanged"))

        this.ui.OnEvent("BtnReplace", "Click", ObjBindMethod(this, "OnReplaceBtnClick"))
        this.ui.OnEvent("BtnRename", "Click", ObjBindMethod(this, "OnReNameBtnClick"))
        this.ui.OnEvent("BtnRepair", "Click", ObjBindMethod(this, "OnRepairBtnClick"))
        this.ui.OnEvent("BtnAdd", "Click", ObjBindMethod(this, "OnAddBtnClick"))
        this.ui.OnEvent("BtnUnpack", "Click", ObjBindMethod(this, "OnUnpackBtnClick"))
        this.ui.OnEvent("BtnMerge", "Click", ObjBindMethod(this, "OnMergeBtnClick"))
        this.ui.OnEvent("BtnLoad", "Click", ObjBindMethod(this, "OnLoadBtnClick"))
        this.ui.OnEvent("BtnDel", "Click", ObjBindMethod(this, "OnDelBtnClick"))
        this.ui.OnEvent("BtnCourse", "Click", ObjBindMethod(this, "OnCourseBtnClick"))
        this.ui.OnEvent("BtnPack", "Click", ObjBindMethod(this, "OnPackBtnClick"))
        this.ui.OnEvent("BtnOpenRepo", "Click", ObjBindMethod(this, "OnOpenRMTSettingBtnClick"))
        this.ui.OnEvent("BtnUpload", "Click", ObjBindMethod(this, "OnRMTUploadBtnClick"))

        this._openTick := A_TickCount
        this._themeReady := false
        this._contentReady := false
        this._revealed := false
        ; Show 前入队配置：LoadedHwnd 时引擎先 flush _updateQueue 再调 OnWindowLoad，首帧已有文案
        this.Refresh()
        this._contentReady := true
        XamlUiDiag("content queued +" (A_TickCount - this._openTick) "ms", "SettingMgr")
        XamlUiDiag("before ui.Show() hostId=" (this.ui.HasProp("id") ? this.ui.id : "?")
            " opacity0=" (InStr(this.ui.xaml, 'Opacity="0"') ? 1 : 0), "SettingMgr")
        ; ===== 临时诊断S2：窗口即将创建 =====
        DiagOpenStep("SettingMgr", "S2-窗口即将创建", "窗口尚未出现在屏幕上（马上创建，创建后会被移到屏幕外隐藏）。"
            "`n若此时屏幕上有异常窗口，请描述。")
        tShow := A_TickCount
        this.ui.Show()
        XamlUiDiag("ui.Show() returned cost=" (A_TickCount - tShow) "ms", "SettingMgr")
        gotHwnd := false
        loop 40 {
            if (this.ui.HasProp("wpfHwnd") && this.ui.wpfHwnd) {
                gotHwnd := true
                ; 仅等 HWND；Opacity=1 只在 OnWindowLoad 主题套完后 _TryReveal（引擎 LWA_ALPHA 在 Show 前已挂）
                XamlUiDiag("got wpfHwnd at loop=" A_Index " +" (A_TickCount - tShow) "ms", "SettingMgr")
                XamlUiDiagWindow(this.ui.wpfHwnd, "SettingMgr.afterShow", false)
                break
            }
            Sleep(50)
        }
        if (!gotHwnd) {
            XamlUiDiag("FAIL: no wpfHwnd after wait", "SettingMgr")
            XamlUiDiagDaemon("SettingMgr.noHwnd")
        }
        ; LoadedHwnd 若丢失则兜底（正常路径 OnWindowLoad 已 reveal）
        SetTimer(ObjBindMethod(this, "_RevealFallback"), -800)
    }

    _AddBtn(parent, name, content, width) {
        btn := parent.Add("Button").Name(name).Content(content)
            .Background("{DynamicResource EditBg}").Foreground("{DynamicResource EditText}")
            .BorderBrush("{DynamicResource EditStroke}").BorderThickness("1")
            .FontSize(12).Cursor("Hand").Width(width).Height(28)
        btn.InjectResources(this._btnStyle)
        return btn
    }

    ; 左右两端贴齐：左按钮对齐行起点，右按钮对齐行终点（与配置选项行同宽）
    _AddPairBtnRow(parent, leftName, leftText, rightName, rightText, rowW, btnW, margin) {
        row := parent.Add("Grid").Margin(margin).HorizontalAlignment("Center").Width(rowW)
        row.Cols("*", "*")
        this._AddBtn(row, leftName, leftText, btnW)
            .Grid_Column(0).HorizontalAlignment("Left")
        this._AddBtn(row, rightName, rightText, btnW)
            .Grid_Column(1).HorizontalAlignment("Right")
        return row
    }

    OnWindowClosing(state, ctrl, event) {
        hwnd := (IsObject(this.ui) && this.ui.HasProp("wpfHwnd")) ? this.ui.wpfHwnd : 0
        XamlUiDiag("OnWindowClosing hwnd=" hwnd, "SettingMgr")
        this.closed := true
        this._revealed := true   ; 关闭中不再 fallback reveal
        SettingMgrGui._opening := false
        if (this._instanceKey != "" && SettingMgrGui.instances.Has(this._instanceKey))
            SettingMgrGui.instances.Delete(this._instanceKey)
        this.ui := ""
        try {
            if (!XAMLHost.IsDaemonAlive())
                XAMLHost.ResetDaemon()
        }
        XamlUiDiagDaemon("SettingMgr.afterClose")
    }

    OnWindowLoad(state, ctrl, event) {
        hwnd := (IsObject(this.ui) && this.ui.HasProp("wpfHwnd")) ? this.ui.wpfHwnd : 0
        XamlUiDiag("OnWindowLoad enter hwnd=" hwnd " +" (A_TickCount - this._openTick) "ms", "SettingMgr")
        try {
            themeName := MainSoftData.HasProp("Theme") ? MainSoftData.Theme : "RMT_Light"
            ApplyXamlTheme(this.ui, themeName)
            this.Refresh()
            this._themeReady := true
            this._contentReady := true
            XamlUiDiag("theme+content ready theme=" themeName, "SettingMgr")
        } catch as e {
            this._themeReady := true
            this._contentReady := true
            XamlUiDiag("OnWindowLoad err: " e.Message, "SettingMgr")
        }
        this._TryReveal("theme")
    }

    ; 主题 + 内容就绪后才可见，避免空白/默认主题先闪一帧
    _TryReveal(from := "") {
        if (this._revealed || this.closed)
            return
        XamlUiDiag("TryReveal from=" from " theme=" this._themeReady " content=" this._contentReady
            " +" (A_TickCount - this._openTick) "ms", "SettingMgr")
        if (!this._themeReady || !this._contentReady)
            return
        if (!IsObject(this.ui) || !this.ui.HasProp("wpfHwnd") || !this.ui.wpfHwnd) {
            XamlUiDiag("TryReveal abort: no hwnd", "SettingMgr")
            return
        }
        this._revealed := true
        try this.ui.Update("Window", "Opacity", "1")
        try WinActivate("ahk_id " this.ui.wpfHwnd)
        XamlUiDiag("revealed Opacity=1 +" (A_TickCount - this._openTick) "ms", "SettingMgr")
        XamlUiDiagWindow(this.ui.wpfHwnd, "SettingMgr.revealed", false)
    }

    _RevealFallback(*) {
        if (this._revealed || this.closed)
            return
        XamlUiDiag("RevealFallback force themeWas=" this._themeReady " contentWas=" this._contentReady, "SettingMgr")
        this._themeReady := true
        this._contentReady := true
        this._TryReveal("fallback")
    }

    OnCancelClick(state, ctrl, event) {
        this.ui.Update("Window", "Close", "")
    }

    Close() {
        this.closed := true
        if IsObject(this.ui) {
            try this.ui.Update("Window", "Close", "")
            this.ui := ""
        }
    }

    Refresh() {
        this.SettingList := StrSplit(MainSoftData.SettingArrStr, "π")
        this._selectedSetting := MySoftData.CurSettingName
        if (!IsObject(this.ui))
            return

        this._applyingUI := true
        try {
            this.ui.Update("CurSettingCon", "Text", MySoftData.CurSettingName)
            this.ui.Update("OperSettingCon", "ClearItems", "")
            selIdx := 0
            ns := 'xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"'
            for i, name in this.SettingList {
                this.ui.Update("OperSettingCon", "AddXamlItem",
                    '<ComboBoxItem ' ns ' Content="' this._XmlEsc(name) '"/>')
                if (name == MySoftData.CurSettingName)
                    selIdx := i - 1
            }
            if (this.SettingList.Length > 0)
                this.ui.Update("OperSettingCon", "SelectedIndex", String(selIdx))
        } finally {
            this._applyingUI := false
        }
    }

    _XmlEsc(s) {
        s := StrReplace(s, "&", "&amp;")
        s := StrReplace(s, "<", "&lt;")
        s := StrReplace(s, ">", "&gt;")
        s := StrReplace(s, '"', "&quot;")
        return s
    }

    OnOperSettingChanged(state, ctrl, event) {
        if (this._applyingUI)
            return
        this._selectedSetting := this._GetSelectedSetting(state)
    }

    _GetSelectedSetting(state := unset) {
        if (IsSet(state) && IsObject(state) && state.Has("OperSettingCon") && state["OperSettingCon"] != "")
            return state["OperSettingCon"]
        if (this._selectedSetting != "")
            return this._selectedSetting
        return MySoftData.CurSettingName
    }

    OnMergeBtnClick(state, ctrl, event) {
        ConfigMergeGui.ShowGui()
    }

    OnReNameBtnClick(state, ctrl, event) {
        newFileName := InputBox(GetLang("请输入新的配置名："), GetLang("重命名"), "w300 h100")
        if newFileName.Result = "Cancel" || newFileName.Value = ""
            return

        isVaild := this.CheckIfExistAndValid(newFileName.Value)
        if (!isVaild)
            return false

        NewSettingArrStr := ""
        for index, settingName in this.SettingList {
            value := MySoftData.CurSettingName == settingName ? newFileName.Value : settingName
            NewSettingArrStr .= value "π"
        }

        oldDir := A_WorkingDir "\Setting\" MySoftData.CurSettingName
        newDir := A_WorkingDir "\Setting\" newFileName.Value
        DirMove(oldDir, newDir)
        NewSettingArrStr := RTrim(NewSettingArrStr, "π")
        IniWrite(NewSettingArrStr, IniFile, IniSection, "SettingArrStr")

        MySoftData.CurSettingName := newFileName.Value
        IniWrite(MySoftData.CurSettingName, IniFile, IniSection, "CurSettingName")

        SettingDir := A_WorkingDir "\Setting\" MySoftData.CurSettingName
        this.OnRepairSetting(SettingDir)
        MsgBox(GetLang("重命名成功"))
        SafeReload()
    }

    OnReplaceBtnClick(state, ctrl, event) {
        tipStr := Format("{}`n{}", GetLang("将清空当前软件的所有配置，并把所选文件中的配置迁移导入本软件。"), GetLang(
            "为了避免数据丢失，自动备份当前所有配置保存到软件下SettingOld中。"))
        MsgBox(tipStr)
        SelectedFolder := DirSelect(, 0, GetLang("请选择若梦兔软件下Setting配置文件。"))
        if SelectedFolder == ""
            return
        SplitPath SelectedFolder, &name, &dir, &ext, &name_no_ext, &drive
        if (!InStr(name, "Setting") || name == "SettingOld") {
            MsgBox(GetLang("需要选择若梦兔软件下的Setting文件"))
            return
        }
        CurSettingDir := A_WorkingDir "\Setting"
        OldSettingDir := A_WorkingDir "\SettingOld\Setting" FormatTime(, "MM月dd日HH-mm-ss")
        if (DirExist(OldSettingDir))
            DirDelete(OldSettingDir, true)
        DirCopy(CurSettingDir, OldSettingDir, 1)
        if (DirExist(CurSettingDir))
            DirDelete(CurSettingDir, true)
        DirCopy(SelectedFolder, CurSettingDir, 1)
        try {
            loop files, CurSettingDir "\*", "D" {
                this.OnRepairSetting(A_LoopFilePath)
            }
        } catch as e {
            MsgBox(GetLang("迁移失败: ") e.Message, GetLang("错误"), 0x10)
            return
        }
        MySoftData.MacroTotalCount := IniRead(IniFile, "UserSettings", "MacroTotalCount", 0)
        IniWrite(true, IniFile, IniSection, "IsReload")
        MsgBox(GetLang("配置迁移成功"))
        SafeReload()
    }

    OnRepairBtnClick(state, ctrl, event) {
        SettingDir := A_WorkingDir "\Setting\" MySoftData.CurSettingName
        hasWork := this.OnRepairSetting(SettingDir)
        if (hasWork) {
            MsgBox("已校对")
            IniWrite(true, IniFile, IniSection, "IsReload")
            SafeReload()
        }
        else {
            tipStr := (
                Format("{}`n{}`n{}`n{}", GetLang("未发现需要修复的内容"), GetLang("重要须知："), GetLang("- 针对覆盖配置文件后，搜索图片的配置路径矫正"),
                GetLang("- 低版本配置到高版本时，进行兼容适配升级"))
            )
            MsgBox(tipStr)
        }
    }

    OnOpenRMTSettingBtnClick(state, ctrl, event) {
        Run("https://zclucas.github.io/RMT-Setting/")
    }

    OnRMTUploadBtnClick(state, ctrl, event) {
        global RMT_Http, RMT_HasDotNet, RMT_IsForbidUpdate
        if (!RMT_HasDotNet || RMT_Http == "") {
            MsgBox(GetLang("缺少.NET环境，无法使用共享上传功能"))
            return
        }
        if (RMT_IsForbidUpdate) {
            MsgBox(Format("{}`n{}`n{}", GetLang("因为以下原因配置无法上传："), GetLang("服务器没有启动"), GetLang("今日上传次数太多")))
            return
        }
        selectedFile := FileSelect(1, , GetLang("选择要共享上传的 RMT 文件"), "RMT Files (*.rmt)")
        if selectedFile == ""
            return

        SplitPath selectedFile, &fileName, , &fileExt, &fileNameNoExt
        if fileExt != "rmt" {
            MsgBox(GetLang("请选择 .rmt 文件！"), GetLang("错误"), 0x10)
            return
        }

        if (fileNameNoExt == GetLang("RMT默认配置")) {
            MsgBox(GetLang("请重命名配置文件后再上传（配置名需要与功能相关）"))
            return
        }

        isVaild := this.IsValidFolderName(fileNameNoExt)
        if (!isVaild) {
            MsgBox(GetLang("配置名不符合文件目录命名规则，请修改"))
            return
        }

        FolderPackager.UploadFile(selectedFile)
    }

    OnPackBtnClick(state, ctrl, event) {
        settingName := this._GetSelectedSetting(state)
        folderPath := A_WorkingDir "\Setting\" settingName
        outputFile := A_Desktop "\" settingName ".rmt"
        FolderPackager.PackFolder(folderPath, outputFile)
        MsgBox(GetLang("打包完成:") outputFile)
    }

    OnUnpackBtnClick(state, ctrl, event) {
        selectedFile := FileSelect(1, , GetLang("选择要导入的 RMT 文件"), "RMT Files (*.rmt)")
        if selectedFile == ""
            return

        SplitPath selectedFile, &fileName, , &fileExt, &fileNameNoExt
        if fileExt != "rmt" {
            MsgBox(GetLang("请选择 .rmt 文件！"), GetLang("错误"), 0x10)
            return
        }

        isVaild := this.IsValidFolderName(fileNameNoExt)
        if (!isVaild) {
            MsgBox(GetLang("配置名不符合文件目录命名规则，请修改"))
            return false
        }

        LoadType := 1
        for settingName in this.SettingList {
            if (fileNameNoExt == settingName) {
                SelectType := CustomMsgBox(GetLang("配置已存在，请选择导入方式："), GetLang("配置导入选项"), GetLang("覆盖导入|自增导入|取消导入"))
                if (SelectType == 0 || SelectType == 3)
                    return

                LoadType := SelectType + 1
                break
            }
        }

        if (LoadType == 3)
            fileNameNoExt := IncrementText(this.SettingList, fileNameNoExt)

        outputFolder := A_WorkingDir "\Setting\" fileNameNoExt

        try {
            FolderPackager.UnpackFile(selectedFile, outputFolder)
            this.OnRepairSetting(outputFolder)
            if (LoadType != 2) {
                MainSoftData.SettingArrStr .= "π" fileNameNoExt
                IniWrite(MainSoftData.SettingArrStr, IniFile, IniSection, "SettingArrStr")
            }

            MySoftData.CurSettingName := fileNameNoExt
            IniWrite(MySoftData.CurSettingName, IniFile, IniSection, "CurSettingName")
            IniWrite(true, IniFile, IniSection, "IsReload")
            MsgBox(fileNameNoExt GetLang("配置导入成功"))
            SafeReload()
        } catch as e {
            MsgBox(GetLang("解包失败: ") e.Message, GetLang("错误"), 0x10)
        }
    }

    OnLoadBtnClick(state, ctrl, event) {
        MySoftData.CurSettingName := this._GetSelectedSetting(state)
        IniWrite(MySoftData.CurSettingName, IniFile, IniSection, "CurSettingName")
        IniWrite(true, IniFile, IniSection, "IsReload")
        SafeReload()
    }

    OnCourseBtnClick(state, ctrl, event) {
        folderPath := A_WorkingDir "\Setting\" this._GetSelectedSetting(state)
        MyUseExplainGui.Mode := 1
        MyUseExplainGui.ShowGui(folderPath)
    }

    OnDelBtnClick(state, ctrl, event) {
        settingName := this._GetSelectedSetting(state)
        if (settingName == MySoftData.CurSettingName) {
            MsgBox(GetLang("不可删除当前配置"))
            return
        }

        result := MsgBox(Format(GetLang("是否删除{}配置"), settingName), GetLang("提示"), 1)
        if (result == "Cancel")
            return

        if (DirExist(A_WorkingDir "\Setting\" settingName))
            DirDelete(A_WorkingDir "\Setting\" settingName, true)

        SettingArrStr := ""
        for name in this.SettingList {
            if (settingName == name)
                continue
            SettingArrStr .= name "π"
        }
        SettingArrStr := RTrim(SettingArrStr, "π")
        MainSoftData.SettingArrStr := SettingArrStr
        IniWrite(MainSoftData.SettingArrStr, IniFile, IniSection, "SettingArrStr")
        MsgBox(GetLang("删除配置: ") settingName)
        this.Refresh()
    }

    OnAddBtnClick(state, ctrl, event) {
        newFileName := InputBox(GetLang("请输入新的配置名："), GetLang("新增配置"), "w300 h100")
        if newFileName.Result = "Cancel" || newFileName.Value = ""
            return

        isVaild := this.CheckIfExistAndValid(newFileName.Value)
        if (!isVaild)
            return false

        MySoftData.CurSettingName := newFileName.Value
        IniWrite(MySoftData.CurSettingName, IniFile, IniSection, "CurSettingName")

        MainSoftData.SettingArrStr .= "π" newFileName.Value
        IniWrite(MainSoftData.SettingArrStr, IniFile, IniSection, "SettingArrStr")
        MsgBox(GetLang("成功新增配置：") newFileName.Value)
        SafeReload()
    }

    OnCopyBtnClick(state := unset, ctrl := unset, event := unset) {
        newFileName := InputBox(GetLang("请输入新的配置名："), GetLang("复制配置"), "w300 h100")
        if newFileName.Result = "Cancel" || newFileName.Value = ""
            return

        isVaild := this.CheckIfExistAndValid(newFileName.Value)
        if (!isVaild)
            return false

        MainSoftData.SettingArrStr .= "π" newFileName.Value
        IniWrite(MainSoftData.SettingArrStr, IniFile, IniSection, "SettingArrStr")
        SourcePath := A_WorkingDir "\Setting\" MySoftData.CurSettingName
        DestPath := A_WorkingDir "\Setting\" newFileName.Value
        DirCopy(SourcePath, DestPath, 1)
        this.OnRepairSetting(DestPath)
        MsgBox(Format(GetLang("成功复制<{}>配置到<{}>中"), MySoftData.CurSettingName, newFileName.Value))

        MySoftData.CurSettingName := newFileName.Value
        IniWrite(MySoftData.CurSettingName, IniFile, IniSection, "CurSettingName")
        SafeReload()
    }

    OnRepairSetting(SettringDir) {
        SplitPath SettringDir, &fileName, , &fileExt, &fileNameNoExt
        hasWork := false
        hasWork := CompatCMD(SettringDir "\MacroFile.ini") || hasWork
        hasWork := CompatSearch(SettringDir "\SearchFile.ini") || hasWork
        hasWork := CompatSearchPro(SettringDir "\SearchProFile.ini") || hasWork
        hasWork := CompatMMPro(SettringDir "\MMProFile.ini") || hasWork
        hasWork := CompatOutput(SettringDir "\OutputFile.ini") || hasWork
        hasWork := CompatRun(SettringDir "\RunFile.ini") || hasWork
        hasWork := CompatLoop(SettringDir "\LoopFile.ini") || hasWork
        hasWork := CompatSubMacro(SettringDir "\SubMacroFile.ini") || hasWork
        hasWork := CompatVariable(SettringDir "\VariableFile.ini") || hasWork
        hasWork := CompatExVariable(SettringDir "\ExVariableFile.ini") || hasWork
        hasWork := CompatCompare(SettringDir "\CompareFile.ini") || hasWork
        hasWork := CompatComparePro(SettringDir "\CompareProFile.ini") || hasWork
        hasWork := CompatOperation(SettringDir "\OperationFile.ini") || hasWork
        hasWork := CompatBGMouse(SettringDir "\BGMouseFile.ini") || hasWork
        hasWork := CompatBGKey(SettringDir "\BGKeyFile.ini") || hasWork
        hasWork := CompatTiming(SettringDir "\TimingFile.ini") || hasWork
        return hasWork
    }

    CheckIfExistAndValid(FileName) {
        isVaild := this.IsValidFolderName(FileName)
        if (!isVaild) {
            MsgBox(GetLang("配置名不符合文件目录命名规则，请修改"))
            return false
        }

        for settingName in this.SettingList {
            if (FileName == settingName) {
                MsgBox(GetLang("配置名已存在"))
                return false
            }
        }
        return true
    }

    IsValidFolderName(folderName) {
        if (folderName == "")
            return false

        reservedNames := Map(
            "CON", 1, "PRN", 1, "AUX", 1, "NUL", 1,
            "COM1", 1, "COM2", 1, "COM3", 1, "COM4", 1, "COM5", 1, "COM6", 1, "COM7", 1, "COM8", 1, "COM9", 1,
            "LPT1", 1, "LPT2", 1, "LPT3", 1, "LPT4", 1, "LPT5", 1, "LPT6", 1, "LPT7", 1, "LPT8", 1, "LPT9", 1
        )

        if (reservedNames.Has(folderName))
            return false

        illegalChars := ["\", "/", ":", "*", "?", " ", "<", ">", "|"]
        for char in illegalChars {
            if (InStr(folderName, char))
                return false
        }

        if (RegExMatch(folderName, "[ .]$"))
            return false

        if (StrLen(folderName) > 255)
            return false

        return true
    }
}
