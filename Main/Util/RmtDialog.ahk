#Requires AutoHotkey v2.0

; =============================================================================
; RMT 通用提示/确认弹窗
; 窗口骨架与主题配置、快捷键编辑一致：XAML_TEMPLATE + 标题栏 + BgColor 内容区。
; =============================================================================
class RmtDialog {
    ; 单按钮提示（确定）
    static Info(msg, title := "") {
        RmtDialog._Trace("Info enter msg=" RmtDialog._Clip(msg))
        try {
            RmtDialog._Show(String(msg), title != "" ? title : GetLang("提示"), [GetLang("确定")], Chr(0xE946), "{DynamicResource TextMain}", true)
        } catch as e {
            RmtDialog._Log("Info", e)
        }
    }

    ; 确定/取消，返回是否点了确定
    static Confirm(msg, title := "") {
        RmtDialog._Trace("Confirm enter msg=" RmtDialog._Clip(msg))
        try {
            btn := RmtDialog._Show(String(msg), title != "" ? title : GetLang("提示"), [GetLang("确定"), GetLang("取消")], Chr(0xE814), "{DynamicResource Accent}", false)
            ok := (btn == GetLang("确定"))
            RmtDialog._Trace("Confirm result ok=" ok " btn=" btn)
            return ok
        } catch as e {
            RmtDialog._Log("Confirm", e)
            return false
        }
    }

    static _Show(msg, title, buttons, iconChar, iconColor, offsetMsg := false) {
        owner := 0
        try {
            if (IsSet(MyMainWin) && IsObject(MyMainWin) && IsObject(MyMainWin.ui) && MyMainWin.ui.wpfHwnd)
                owner := MyMainWin.ui.wpfHwnd
        }
        try XAMLHost.EnsureDaemonHealthy()

        titleHeight := "36"
        fs := XAMLHost.FontSize()
        winW := 300   ; 设计宽度（250+50）；Show 时 ApplyDialogVisualScale + Viewbox 与其它弹窗同一套管线
        iconFs := fs * 3
        fontFamily := ""
        try {
            if (IsSet(MainSoftData) && MainSoftData.HasProp("FontType") && MainSoftData.FontType != "")
                fontFamily := MainSoftData.FontType
        }

        main := XAML_Generator("Grid").Background("{DynamicResource BgColor}")
        if (fontFamily != "")
            main.TextElement_FontFamily(fontFamily)
        main.TextElement_FontSize(fs)
        main.Rows(titleHeight, "Auto")

        tb := main.Add("Border").Grid_Row(0).Background("{DynamicResource TitleBarColor}").Name("DragArea")
        tbInner := tb.Add("Grid")
        tbInner.Add("TextBlock").Text(title).Foreground("{DynamicResource TitleBarForeground}")
            .FontSize(XAMLHost.TitleFontSize()).FontWeight("Bold").VerticalAlignment("Center").Margin("15,0,0,0").Padding("0")

        btnGroup := tbInner.Add("StackPanel").Orientation("Horizontal").HorizontalAlignment("Right").VerticalAlignment("Stretch").Height(36)
        ; 关闭钮与各界面统一：TitleBarCloseButton（hover=ControlBorder、按下=BtnPressBg）
        closeBtn := btnGroup.Add("Button").Name("BtnClosePanel").Style("{StaticResource TitleBarCloseButton}")
            .WindowChrome_IsHitTestVisibleInChrome("True").Width(46).Height(36).MinHeight(36).Padding("0")
            .VerticalAlignment("Stretch").Background("Transparent").Foreground("{DynamicResource TitleBarForeground}").BorderThickness(0)
        closeBtn.Add("TextBlock").Text(Chr(0xE8BB)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize(10)
            .VerticalAlignment("Center").HorizontalAlignment("Center")

        body := main.Add("Border").Grid_Row(1).Background("{DynamicResource BgColor}")
        panel := body.Add("StackPanel").Margin("14,18,14,14")

        if (offsetMsg) {
            ; Info（空复制等）：图标靠左，文案整窗居中后再右偏 50，换行块内左对齐，避免压住图标
            msgRow := panel.Add("Grid").Margin("0,4,0,4")
            if (iconChar != "") {
                msgRow.Add("TextBlock").Text(iconChar).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets")
                    .FontSize(iconFs).Foreground(iconColor).VerticalAlignment("Center").HorizontalAlignment("Left")
                    .Margin("2,0,0,0")
            }
            msgTb := msgRow.Add("TextBlock").Text(msg).Foreground("{DynamicResource TextMain}").FontSize(fs)
                .VerticalAlignment("Center").HorizontalAlignment("Center").TextAlignment("Left").TextWrapping("Wrap")
                .Margin("50,0,0,0")
        } else {
            ; Confirm（删除等）：图标+文案作为一组水平居中
            msgRow := panel.Add("StackPanel").Orientation("Horizontal").HorizontalAlignment("Center").VerticalAlignment("Center").Margin("0,4,0,4")
            if (iconChar != "") {
                msgRow.Add("TextBlock").Text(iconChar).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets")
                    .FontSize(iconFs).Foreground(iconColor).VerticalAlignment("Center").Margin("0,0,10,0")
            }
            msgTb := msgRow.Add("TextBlock").Text(msg).Foreground("{DynamicResource TextMain}").FontSize(fs)
                .VerticalAlignment("Center").TextAlignment("Center")
        }
        if (fontFamily != "")
            msgTb.FontFamily(fontFamily)

        PrimaryBtnStyle := '<Style TargetType="Button"><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border x:Name="bd" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="3"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bd" Property="Background" Value="{DynamicResource ActionHoverBg}"/><Setter TargetName="bd" Property="BorderBrush" Value="{DynamicResource ActionHoverStroke}"/></Trigger><Trigger Property="IsPressed" Value="True"><Setter TargetName="bd" Property="Background" Value="{DynamicResource ActionPressBg}"/><Setter TargetName="bd" Property="BorderBrush" Value="{DynamicResource ActionHoverStroke}"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>'
        btnRow := panel.Add("StackPanel").Orientation("Horizontal").HorizontalAlignment("Center").Margin("0,14,0,4")
        okText := GetLang("确定")
        cancelText := GetLang("取消")
        loop buttons.Length {
            idx := A_Index
            btnText := buttons[idx]
            gap := (idx < buttons.Length) ? "0,0,58,0" : "0"
            btnEl := btnRow.Add("Button").Name("Btn" idx).Content(btnText)
                .Background("{DynamicResource ActionBg}").Foreground("{DynamicResource ActionText}")
                .FontWeight("Bold").BorderBrush("{DynamicResource ActionStroke}").BorderThickness("1")
                .FontSize(fs).Cursor("Hand").Width(80).Height(32).Margin(gap)
            if (btnText == okText)
                btnEl.IsDefault("True")
            if (btnText == cancelText)
                btnEl.IsCancel("True")
            btnEl.InjectResources(PrimaryBtnStyle)
        }

        tmp := StrReplace(XAML_TEMPLATE, "%CaptionHeight%", titleHeight)
        ui := XAMLHost(StrReplace(tmp, "%app%", main.ToString()), "", owner)
        ; 走与设置/编辑窗完全一致的管线（字号按 delta 缩放、标题栏补丁统一标题字号与关闭钮、视觉缩放），
        ; 因此不设 skipFontScale：正文声明基准字号→缩放到主题字号，标题由补丁强制为主题字号+2。
        safeTitle := RmtDialog._XmlEsc(title)
        ui.xaml := StrReplace(ui.xaml, 'Width="940" Height="700"', 'Title="' safeTitle '" ShowInTaskbar="False" Width="' winW '" SizeToContent="Height" Topmost="True" Opacity="0"')
        ui.xaml := StrReplace(ui.xaml, 'ResizeMode="CanResize"', 'ResizeMode="NoResize"')
        if (fontFamily != "")
            ui.xaml := StrReplace(ui.xaml, 'FontFamily="Segoe UI Variable Display, Segoe UI, sans-serif"', 'FontFamily="' fontFamily '"')
        ui.xaml := StrReplace(ui.xaml, 'CornerRadius="{DynamicResource WindowRadius}"', 'CornerRadius="{DynamicResource PanelRadius}"')
        ui.xaml := StrReplace(ui.xaml, '%resources%', '<CornerRadius x:Key="PanelRadius">8</CornerRadius>')

        resultObj := { Button: "", Instance: ui }
        ownerDisabled := false

        ui.OnEvent("Window", "Closing", (state, ctrl, event) => RmtDialog._OnClosing(resultObj, owner))
        ui.OnEvent("Window", "LoadedHwnd", (state, ctrl, event) => RmtDialog._OnLoad(ui, owner))
        ui.OnEvent("BtnClosePanel", "Click", (state, ctrl, event) => RmtDialog._OnPick(ui, resultObj, "Closed", owner))
        loop buttons.Length {
            idx := A_Index
            btnText := buttons[idx]
            ui.OnEvent("Btn" idx, "Click", ObjBindMethod(RmtDialog, "_OnPick", ui, resultObj, btnText, owner))
        }

        try {
            themeName := (IsSet(MainSoftData) && MainSoftData.HasProp("Theme") && MainSoftData.Theme != "") ? MainSoftData.Theme : "RMT_Light"
            ApplyXamlTheme(ui, themeName)
        } catch as e {
            RmtDialog._Trace("ApplyXamlTheme err=" e.Message)
        }

        RmtDialog._Trace("Show start owner=" owner " w=" winW " fs=" fs)
        ui.Show()

        waitStart := A_TickCount
        while (resultObj.Button == "" && (ui.wpfHwnd == 0 || WinExist("ahk_id " ui.wpfHwnd))) {
            if (ui.wpfHwnd && owner && !ownerDisabled) {
                try WinSetEnabled(0, "ahk_id " owner)
                ownerDisabled := true
            }
            if (ui.wpfHwnd == 0 && A_TickCount - waitStart > 5000) {
                try {
                    dir := A_ScriptDir "\Log"
                    if !DirExist(dir)
                        DirCreate(dir)
                    FileAppend(ui.xaml, dir "\RmtDialog.last.xaml", "UTF-8")
                }
                throw Error("Dialog window failed to open")
            }
            Sleep(50)
        }
        if (resultObj.Button == "")
            resultObj.Button := "Closed"
        if (owner) {
            try WinSetEnabled(1, "ahk_id " owner)
        }
        RmtDialog._Trace("Show done btn=" resultObj.Button)
        return resultObj.Button
    }

    static _OnLoad(ui, owner, state := "", ctrl := "", event := "") {
        if (owner)
            try ui.Update("Window", "NativeOwner", owner)
        try ui.Update("Window", "Opacity", "1")
    }

    static _OnClosing(resultObj, owner, state := "", ctrl := "", event := "") {
        if (resultObj.Button == "")
            resultObj.Button := "Closed"
        if (owner) {
            try WinSetEnabled(1, "ahk_id " owner)
        }
    }

    static _OnPick(ui, resultObj, btnText, owner, state := "", ctrl := "", event := "") {
        resultObj.Button := btnText
        if (owner) {
            try WinSetEnabled(1, "ahk_id " owner)
        }
        try ui.Update("Window", "Close", "")
    }

    static _XmlEsc(s) {
        s := StrReplace(String(s), "&", "&amp;")
        s := StrReplace(s, "<", "&lt;")
        s := StrReplace(s, ">", "&gt;")
        s := StrReplace(s, '"', "&quot;")
        return s
    }

    static _LogPath() {
        dir := A_ScriptDir "\Log"
        if !DirExist(dir)
            DirCreate(dir)
        return dir "\RmtDialog.log"
    }

    static _Trace(msg) {
        try FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") "." SubStr(A_TickCount, -2) " " msg "`n", RmtDialog._LogPath(), "UTF-8")
    }

    static _Clip(s, n := 80) {
        s := StrReplace(String(s), "`n", " ")
        return StrLen(s) > n ? SubStr(s, 1, n) "..." : s
    }

    static _Log(where, e) {
        try FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") " [" where "] " e.Message "`n" e.Stack "`n`n", RmtDialog._LogPath(), "UTF-8")
    }
}
