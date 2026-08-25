#Requires AutoHotkey v2.0

class ThemeSettingGui {
    static instances := Map()
    static _opening := false

    __new() {
        this.ui := 0
        this.closed := false
        this._instanceKey := ""
        this._themeKey := AppThemeUtil.DefaultThemeKey
        this._colors := Map()
        this._applyingTheme := false
    }

    static ShowGui() {
        key := "global"
        XamlUiDiag("ShowGui enter _opening=" ThemeSettingGui._opening " hasInst=" ThemeSettingGui.instances.Has(key), "Theme")
        XamlUiDiagDaemon("Theme.pre")
        if (ThemeSettingGui.instances.Has(key)) {
            oldInst := ThemeSettingGui.instances[key]
            hwnd := (IsObject(oldInst.ui) && oldInst.ui.HasProp("wpfHwnd")) ? oldInst.ui.wpfHwnd : 0
            reuse := (!oldInst.closed && XAMLHost.CanReuseWindow(hwnd))
            XamlUiDiag(Format("oldInst closed={} hwnd={} reuse={}", oldInst.closed, hwnd, reuse), "Theme")
            XamlUiDiagWindow(hwnd, "Theme.oldInst", false)
            if (reuse) {
                try WinActivate("ahk_id " hwnd)
                XamlUiDiag("reuse existing window + Activate", "Theme")
                XamlUiDiagWindow(hwnd, "Theme.reuse", true)
                return
            }
            ; 窗口已失效/卡死但实例残留：清理后重建
            try {
                if (!oldInst.closed && IsObject(oldInst.ui))
                    oldInst.Close()
            }
            ThemeSettingGui.instances.Delete(key)
            XamlUiDiag("deleted stale instance", "Theme")
        }

        t0 := A_TickCount
        XAMLHost.EnsureDaemonHealthy()
        XamlUiDiag("EnsureDaemonHealthy cost=" (A_TickCount - t0) "ms", "Theme")
        XamlUiDiagDaemon("Theme.afterHealthy")
        if (ThemeSettingGui._opening) {
            XamlUiDiag("ABORT: _opening=true (reentry)", "Theme")
            return
        }
        ThemeSettingGui._opening := true
        try {
            inst := ThemeSettingGui()
            inst._instanceKey := key
            inst._BuildAndShow()
            ThemeSettingGui.instances[key] := inst
            XamlUiDiag("ShowGui done hwnd=" (IsObject(inst.ui) && inst.ui.HasProp("wpfHwnd") ? inst.ui.wpfHwnd : 0), "Theme")
        } catch as e {
            XamlUiDiag("ShowGui EXCEPTION: " e.Message " @ " e.File ":" e.Line, "Theme")
        } finally {
            ThemeSettingGui._opening := false
        }
    }

    _BuildAndShow() {
        this.closed := false
        title := GetLang("主题选项")
        titleHeight := "36"

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
        panel := scrollViewer.Add("StackPanel").Margin("14, 6, 14, 10")

        ; 颜色值用 Border+TextBlock 显示，避免 WPF TextBox 默认 MinHeight 导致高度调不动
        ; 主题界面字号与设置页签一致（标签 12 / 输入 11 / 色值 13）
        this._colorUi := {
            labelFg: "{DynamicResource TextMain}", labelFs: 12, labelW: 78,
            boxW: 100, boxH: 24, boxFs: 13,
            previewW: 24, previewH: 24
        }

        ; ===== 字体（在主题预设上面，其他内容顺延）=====
        fontGroup := panel.Add("GroupBox").Header(GetLang("字体")).Margin("0,0,0,0")
            .BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1")
            .Foreground("{DynamicResource TextMain}")
        fontInner := fontGroup.Add("StackPanel").Margin("12, 8")

        ; 一行两列：左=软件字体（下拉），右=字体大小（滑动条 0-40，默认 22）
        fontRow := fontInner.Add("Grid").Margin("0,2,0,0")
        fontRow.Cols("*", "*")

        ; 左：软件字体
        familyCol := fontRow.Add("StackPanel").Grid_Column(0).Orientation("Horizontal")
        familyCol.Add("TextBlock").Text(GetLang("软件字体") "：")
            .Foreground(this._colorUi.labelFg).FontSize(this._colorUi.labelFs)
            .VerticalAlignment("Center").Width(this._colorUi.labelW)
        fontCombo := familyCol.Add("ComboBox").Name("FontFamilyCon").Width(130).Height(26).MinHeight(26)
            .VerticalContentAlignment("Center")
            .Foreground("{DynamicResource InputText}").Background("{DynamicResource InputBg}")
            .BorderBrush("{DynamicResource InputStroke}").BorderThickness("1").Margin("4,0,0,0")
        if (IsObject(MainSoftData.FontList)) {
            for font in MainSoftData.FontList
                fontCombo.Add("ComboBoxItem").Content(font)
        }

        ; 右：字体大小（滑动条）
        sizeCol := fontRow.Add("StackPanel").Grid_Column(1).Orientation("Horizontal").Margin("8,0,0,0")
        sizeCol.Add("TextBlock").Text(GetLang("字体大小") "：")
            .Foreground(this._colorUi.labelFg).FontSize(this._colorUi.labelFs)
            .VerticalAlignment("Center").Width(this._colorUi.labelW)
        sizeSlider := sizeCol.Add("Slider").Name("FontSizeCon").Width(150).Height(26).MinHeight(26).Margin("2,0,0,0")
            .Minimum("0").Maximum("40").Value("22").IsMoveToPointEnabled("True")
        sizeVal := sizeCol.Add("TextBlock").Name("FontSizeVal").Text("22")
            .FontSize(11).Width(28).Foreground("{DynamicResource TextMain}")
            .VerticalAlignment("Center").Margin("4,0,0,0")

        ; ===== 顶部：主题下拉 =====
        themeGroup := panel.Add("GroupBox").Header(GetLang("主题预设")).Margin("0,10,0,0")
            .BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1")
            .Foreground("{DynamicResource TextMain}")
        themeInner := themeGroup.Add("StackPanel").Margin("12, 8")
        themeRow := themeInner.Add("StackPanel").Orientation("Horizontal").Margin("0,2,0,0")
        themeRow.Add("TextBlock").Text(GetLang("选择主题") "：")
            .Foreground(this._colorUi.labelFg).FontSize(this._colorUi.labelFs)
            .VerticalAlignment("Center").Width(this._colorUi.labelW)
        themeCombo := themeRow.Add("ComboBox").Name("ThemeCombo").Width(130).Height(26).MinHeight(26)
            .VerticalContentAlignment("Center")
            .Foreground("{DynamicResource InputText}").Background("{DynamicResource InputBg}")
            .BorderBrush("{DynamicResource InputStroke}").BorderThickness("1").Margin("4,0,0,0")
        for item in AppThemeUtil.Presets
            themeCombo.Add("ComboBoxItem").Content(GetLang(item.Name))
        themeCombo.Add("ComboBoxItem").Content(GetLang("自定义"))

        ; ===== 下方：可滚动颜色组（分组与行布局由 ColorDefs 自动生成，便于后续扩展）=====
        groups := AppThemeUtil.GetGroupNames()
        for gi, groupName in groups {
            groupBox := panel.Add("GroupBox").Header(GetLang(groupName)).Margin(gi == 1 ? "0,10,0,0" : "0,8,0,0")
                .BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1")
                .Foreground("{DynamicResource TextMain}")
            inner := groupBox.Add("StackPanel").Margin("12, 6")
            rowKeys := this._GetGroupRowKeys(groupName)
            for ri, keys in rowKeys {
                ; 双列 Grid：第二列与字体行第二列统一左对齐
                row := inner.Add("Grid").Margin(ri == 1 ? "0,4,0,0" : "0,6,0,0")
                row.Cols("*", "*")
                this._AddColorItem(row, this._FindColorDef(keys[1]), 0)
                if (keys.Length >= 2)
                    this._AddColorItem(row, this._FindColorDef(keys[2]), 1)
            }
        }

        PrimaryBtnStyle := '<Style TargetType="Button"><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border x:Name="bd" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="3"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bd" Property="Background" Value="{DynamicResource ActionHoverBg}"/><Setter TargetName="bd" Property="BorderBrush" Value="{DynamicResource ActionHoverStroke}"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>'
        btnRow := panel.Add("StackPanel").Orientation("Horizontal").HorizontalAlignment("Center").Margin("0,18,0,10")
        okBtn := btnRow.Add("Button").Name("BtnConfirm").Content(GetLang("确定")).Background("{DynamicResource ActionBg}").Foreground("{DynamicResource ActionText}").FontWeight("Bold").BorderBrush("{DynamicResource ActionStroke}").BorderThickness("1").FontSize(13).Cursor("Hand").Width(80).Height(32)
        okBtn.InjectResources(PrimaryBtnStyle)

        tmp := StrReplace(XAML_TEMPLATE, "%CaptionHeight%", titleHeight)
        this.ui := XAMLHost(StrReplace(tmp, "%app%", main.ToString()), "", "")
        this.ui.xaml := StrReplace(this.ui.xaml, 'Width="940" Height="700"', 'Title="' title '" ShowInTaskbar="False" Width="600" Height="640" Opacity="0"')
        this.ui.xaml := StrReplace(this.ui.xaml, 'FontFamily="Segoe UI Variable Display, Segoe UI, sans-serif"', 'FontFamily="' MainSoftData.FontType '"')
        this.ui.xaml := StrReplace(this.ui.xaml, 'CornerRadius="{DynamicResource WindowRadius}"', 'CornerRadius="{DynamicResource PanelRadius}"')
        groupBoxStyle := '<Style TargetType="GroupBox"><Setter Property="BorderBrush" Value="{DynamicResource ControlBorder}"/><Setter Property="BorderThickness" Value="1"/><Setter Property="Foreground" Value="{DynamicResource TextMain}"/></Style>'
        this.ui.xaml := StrReplace(this.ui.xaml, '%resources%', '<CornerRadius x:Key="PanelRadius">8</CornerRadius><SolidColorBrush x:Key="GroupStroke" Color="#999999"/>' groupBoxStyle)

        this.ui.OnEvent("Window", "Closing", ObjBindMethod(this, "OnWindowClosing"))
        this.ui.OnEvent("Window", "LoadedHwnd", ObjBindMethod(this, "OnWindowLoad"))
        this.ui.OnEvent("BtnClosePanel", "Click", ObjBindMethod(this, "OnCancelClick"))
        this.ui.Track("ThemeCombo")
        this.ui.Track("FontSizeCon")
        this.ui.OnEvent("FontSizeCon", "ValueChanged", ObjBindMethod(this, "OnFontSizeChanged"))
        this.ui.OnEvent("ThemeCombo", "SelectionChanged", ObjBindMethod(this, "OnThemeSelectionChanged"))
        this.ui.OnEvent("BtnConfirm", "Click", ObjBindMethod(this, "OnConfirmClick"))

        for def in AppThemeUtil.ColorDefs
            this.ui.OnEvent(def.Key "_Preview", "MouseLeftButtonDown", ObjBindMethod(this, "OnPickColor", def.Key, def.Label))

        ; Show 前入队配置，LoadedHwnd 时立即刷入，避免先闪默认值
        this.LoadInitValues()
        this.ApplyValuesToUI()
        XamlUiDiag("before ui.Show() hostId=" this.ui.id, "Theme")
        tShow := A_TickCount
        this.ui.Show()
        XamlUiDiag("ui.Show() returned cost=" (A_TickCount - tShow) "ms", "Theme")

        gotHwnd := false
        loop 40 {
            if (this.ui.HasProp("wpfHwnd") && this.ui.wpfHwnd) {
                gotHwnd := true
                hwnd := this.ui.wpfHwnd
                XamlUiDiag("got wpfHwnd at loop=" A_Index " +" (A_TickCount - tShow) "ms", "Theme")
                ; LoadedHwnd 异步后 Opacity=1 可能尚未执行，这里兜底强制可见
                try this.ui.Update("Window", "Opacity", "1")
                try WinActivate("ahk_id " hwnd)
                XamlUiDiagWindow(hwnd, "Theme.afterShow", true)
                break
            }
            Sleep(50)
        }
        if (!gotHwnd) {
            XamlUiDiag("FAIL: no wpfHwnd after wait (LoadedHwnd missing?)", "Theme")
            XamlUiDiagDaemon("Theme.noHwnd")
        }
    }

    ; 按 ColorDefs 顺序收集该组 Key，两两一行（新增颜色项无需改此处）
    _GetGroupRowKeys(groupName) {
        keys := []
        for def in AppThemeUtil.ColorDefs {
            if (def.Group == groupName)
                keys.Push(def.Key)
        }
        rows := []
        i := 1
        while (i <= keys.Length) {
            if (i + 1 <= keys.Length) {
                rows.Push([keys[i], keys[i + 1]])
                i += 2
            } else {
                rows.Push([keys[i]])
                i += 1
            }
        }
        return rows
    }

    _FindColorDef(key) {
        for def in AppThemeUtil.ColorDefs {
            if (def.Key == key)
                return def
        }
        return {Key: key, Group: "", Label: key}
    }

    _AddColorItem(row, def, col) {
        ui := this._colorUi
        item := row.Add("StackPanel").Orientation("Horizontal").Grid_Column(col)
            .VerticalAlignment("Center")
        item.Add("TextBlock").Text(GetLang(def.Label) "：")
            .Foreground(ui.labelFg).FontSize(ui.labelFs)
            .VerticalAlignment("Center").Width(ui.labelW)
        ; 只读色值展示：Border + TextBlock，高度可控
        box := item.Add("Border").Width(ui.boxW).Height(ui.boxH).CornerRadius("3")
            .Background("{DynamicResource InputBg}")
            .BorderBrush("{DynamicResource InputStroke}").BorderThickness("1")
            .VerticalAlignment("Center")
        box.Add("TextBlock").Name(def.Key "_Text")
            .Text("#FF000000").FontSize(ui.boxFs)
            .Foreground("{DynamicResource InputText}")
            .HorizontalAlignment("Center").VerticalAlignment("Center")
        item.Add("Border").Name(def.Key "_Preview")
            .Width(ui.previewW).Height(ui.previewH).CornerRadius("3").Margin("6,0,0,0")
            .BorderBrush("{DynamicResource InputStroke}").BorderThickness("1")
            .Background("#FF000000").Cursor("Hand").VerticalAlignment("Center")
    }

    LoadInitValues() {
        this._themeKey := MainSoftData.HasProp("AppTheme") ? MainSoftData.AppTheme : AppThemeUtil.DefaultThemeKey
        if (this._themeKey == "" || !AppThemeUtil.IsPresetKey(this._themeKey))
            this._themeKey := AppThemeUtil.DefaultThemeKey
        ; CloneColorMap 会以默认主题补齐缺失 Key，兼容版本升级后的自定义主题
        if (IsObject(MainSoftData.ThemeColors))
            this._colors := AppThemeUtil.CloneColorMap(MainSoftData.ThemeColors)
        else
            this._colors := AppThemeUtil.NewColorMapFromPreset(AppThemeUtil.FindPreset(this._themeKey))
    }

    ApplyValuesToUI() {
        this._applyingTheme := true
        try {
            themeIdx := AppThemeUtil.Presets.Length  ; 自定义
            for i, item in AppThemeUtil.Presets {
                if (item.Key == this._themeKey) {
                    themeIdx := i - 1
                    break
                }
            }
            this.ui.Update("ThemeCombo", "SelectedIndex", String(themeIdx))
            this.RefreshColorRows()
            ; 字体：大小 = 当前 XAML 主题 FontSize；字体 = 全局 FontType
            fsz := MainSoftData.HasProp("FontSize") ? Integer(MainSoftData.FontSize) : 22
            this.ui.Update("FontSizeCon", "Value", String(fsz))
            this.ui.Update("FontSizeVal", "Text", String(fsz))
            fIdx := 0
            if (IsObject(MainSoftData.FontList)) {
                for i, f in MainSoftData.FontList {
                    if (f == MainSoftData.FontType) {
                        fIdx := i - 1
                        break
                    }
                }
            }
            this.ui.Update("FontFamilyCon", "SelectedIndex", String(fIdx))
        } finally {
            this._applyingTheme := false
        }
    }

    RefreshColorRows() {
        for def in AppThemeUtil.ColorDefs {
            color := AppThemeUtil.ResolveColor(this._colors, def.Key)
            this.ui.Update(def.Key "_Preview", "Background", color)
            this.ui.Update(def.Key "_Text", "Text", color)
        }
    }

    OnThemeSelectionChanged(state, ctrl, event) {
        if (this._applyingTheme)
            return
        selText := state.Has("ThemeCombo") ? state["ThemeCombo"] : ""
        if (selText == "" || selText == GetLang("自定义")) {
            this._themeKey := "Custom"
            return
        }
        preset := AppThemeUtil.FindPresetByName(selText)
        if (!IsObject(preset))
            return
        this._themeKey := preset.Key
        this._colors := AppThemeUtil.NewColorMapFromPreset(preset)
        this.RefreshColorRows()
        AppThemeUtil.ApplyWinThemeToXaml(this.ui, this._colors)
    }

    ; 字号滑动条变化：右侧同步显示当前值
    OnFontSizeChanged(state, ctrl, event) {
        v := (IsObject(state) && state.Has("FontSizeCon")) ? state["FontSizeCon"] : ""
        if (v != "")
            try this.ui.Update("FontSizeVal", "Text", String(Integer(v)))
    }

    OnPickColor(colorKey, labelKey, state, ctrl, event) {
        cur := AppThemeUtil.ResolveColor(this._colors, colorKey)
        result := XColorPicker.Show({
            Title: GetLang(labelKey),
            DefaultColor: cur,
            Owner: this.ui.wpfHwnd,
            Modal: true
        })
        if (result.Status != "OK")
            return
        this._colors[colorKey] := result.Color
        this.ui.Update(colorKey "_Preview", "Background", result.Color)
        this.ui.Update(colorKey "_Text", "Text", result.Color)
        if (InStr(colorKey, "Win_") == 1)
            AppThemeUtil.ApplyWinThemeToXaml(this.ui, this._colors)
        this._themeKey := "Custom"
        this._applyingTheme := true
        try this.ui.Update("ThemeCombo", "SelectedIndex", String(AppThemeUtil.Presets.Length))
        finally this._applyingTheme := false
    }

    OnConfirmClick(state, ctrl, event) {
        this.SaveData()
        this.ui.Update("Window", "Close", "")
    }

    OnCancelClick(state, ctrl, event) {
        this.ui.Update("Window", "Close", "")
    }

    SaveData() {
        if (this._themeKey == "" || !AppThemeUtil.IsPresetKey(this._themeKey))
            this._themeKey := AppThemeUtil.DefaultThemeKey
        MainSoftData.AppTheme := this._themeKey
        ; 补齐缺失项后再落盘，保证后续新增 ColorDefs 写入默认主题色
        MainSoftData.ThemeColors := AppThemeUtil.CloneColorMap(this._colors)
        AppThemeUtil.ApplyToRuntime(MainSoftData.ThemeColors)
        AppThemeUtil.SaveToIni()
        ; 字体：软件字体 + 字体大小写入当前 XAML 主题并刷新全局，立即应用到主界面与主题窗口自身
        global XAML_FontSizeDelta, XAML_FontSizeBase, XAML_FontWeight, XAML_TextClarity
        try {
            themeIni := IsSet(ThemesIniPath) ? ThemesIniPath : (A_ScriptDir "\Setting\themes.ini")
            ; 软件字体
            try {
                sel := this.ui.Query("FontFamilyCon")
                if (sel != "" && IsObject(MainSoftData.FontList) && MainSoftData.FontList.Has(sel)) {
                    MainSoftData.FontType := sel
                    IniWrite(sel, IniFile, IniSection, "FontType")
                }
            }
            ; 字体大小（滑动条 0-40，默认 22）
            oldDelta := XAML_FontSizeDelta
            fs := 22
            try fs := Integer(this.ui.Query("FontSizeCon"))
            if (fs < 0)
                fs := 0
            if (fs > 40)
                fs := 40
            IniWrite(fs, themeIni, MainSoftData.Theme, "FontSize")
            MainSoftData.FontSize := fs
            XAML_FontSizeDelta := fs - XAML_FontSizeBase
            ; 立即应用（引擎 Window|ApplyFonts：字体|字号增量变化|粗细|清晰度=1），无需重开窗口
            change := XAML_FontSizeDelta - oldDelta
            MainSoftData.FontClarity := "1"
            XAML_TextClarity := 1
            payload := MainSoftData.FontType "|" change "|" MainSoftData.FontWeight "|1"
            try {
                if (IsSet(MyMainWin) && IsObject(MyMainWin) && IsObject(MyMainWin.ui)
                    && MyMainWin.ui.HasProp("wpfHwnd") && MyMainWin.ui.wpfHwnd)
                    MyMainWin.ui.Update("Window", "ApplyFonts", payload)
            }
            try this.ui.Update("Window", "ApplyFonts", payload)
        }
        ; 浮窗 / 指令显示运行时已打开时刷新业务色
        if (IsSet(MyUIMacroGui) && IsObject(MyUIMacroGui))
            MyUIMacroGui.RefreshPanels()
        if (IsSet(MyCMDTipGui) && IsObject(MyCMDTipGui))
            MyCMDTipGui.ApplyThemeColors()
        ; 已打开的设置窗 / 节点编辑器同步「通用窗口」色
        AppThemeUtil.RefreshOpenSettingWindows()
        try MacroGraphGui.RefreshOpenThemes()
    }

    OnWindowClosing(state, ctrl, event) {
        hwnd := (IsObject(this.ui) && this.ui.HasProp("wpfHwnd")) ? this.ui.wpfHwnd : 0
        XamlUiDiag("OnWindowClosing hwnd=" hwnd, "Theme")
        XamlUiDiagWindow(hwnd, "Theme.closing", false)
        this.closed := true
        ThemeSettingGui._opening := false
        if (this._instanceKey != "" && ThemeSettingGui.instances.Has(this._instanceKey))
            ThemeSettingGui.instances.Delete(this._instanceKey)
        this.ui := ""
        ; 仅清理已退出的句柄；卡死检测放在下次 ShowGui / 发送消息时处理
        try {
            if (!XAMLHost.IsDaemonAlive())
                XAMLHost.ResetDaemon()
        }
        XamlUiDiagDaemon("Theme.afterClose")
    }

    OnWindowLoad(state, ctrl, event) {
        hwnd := (IsObject(this.ui) && this.ui.HasProp("wpfHwnd")) ? this.ui.wpfHwnd : 0
        XamlUiDiag("OnWindowLoad enter hwnd=" hwnd, "Theme")
        try {
            themeName := MainSoftData.HasProp("Theme") ? MainSoftData.Theme : "RMT_Light"
            ApplyXamlTheme(this.ui, themeName)
            this.ApplyValuesToUI()
        } catch as e {
            XamlUiDiag("OnWindowLoad err: " e.Message, "Theme")
        } finally {
            try this.ui.Update("Window", "Opacity", "1")
            XamlUiDiagWindow(hwnd, "Theme.loaded", true)
        }
    }

    Close() {
        this.closed := true
        if IsObject(this.ui) {
            try this.ui.Update("Window", "Close", "")
            this.ui := ""
        }
    }
}
