#Requires AutoHotkey v2.0

; =============================================================================
; RMT 通用 XAML 提示/确认弹窗
; 基于 AHK-XAML 的 XDialog，套主界面主题字体、字号与按钮高度。
; =============================================================================
class RmtDialog {
    ; 单按钮提示（确定）
    static Info(msg, title := "") {
        opts := RmtDialog._BaseOpts()
        opts.Title := title != "" ? title : GetLang("提示")
        opts.Message := String(msg)
        opts.Icon := Chr(0xE946)
        opts.Buttons := [GetLang("确定")]
        try {
            XDialog.Show(opts)
        } catch {
            try {
                if (opts.Owner)
                    WinSetEnabled(1, "ahk_id " opts.Owner)
            }
            MsgBox(String(msg), opts.Title)
        }
    }

    ; 确定/取消，返回是否点了确定
    static Confirm(msg, title := "") {
        opts := RmtDialog._BaseOpts()
        opts.Title := title != "" ? title : GetLang("提示")
        opts.Message := String(msg)
        opts.Icon := Chr(0xE814)
        opts.IconColor := "{DynamicResource Accent}"
        opts.Buttons := [GetLang("确定"), GetLang("取消")]
        try {
            res := XDialog.Show(opts)
            return IsObject(res) && res.Button == GetLang("确定")
        } catch {
            try {
                if (opts.Owner)
                    WinSetEnabled(1, "ahk_id " opts.Owner)
            }
            return MsgBox(String(msg), opts.Title, "OKCancel") == "OK"
        }
    }

    static _BaseOpts() {
        opts := { Modal: true, Owner: 0, Width: 380, AlwaysOnTop: true, ButtonHeight: 32, ButtonWidth: 80 }
        opts.TitleFontSize := 12
        opts.ContentFontSize := XAMLHost.GetDesignFontSize()
        opts.IconFontSize := 36
        opts.IconColWidth := 72
        opts.UniformButtons := true
        opts.CloseBtnStyle := "{StaticResource TitleBarCloseButton}"
        opts.Resources := RmtDialog._DialogStyles()
        try {
            if (IsSet(MyMainWin) && IsObject(MyMainWin) && IsObject(MyMainWin.ui) && MyMainWin.ui.wpfHwnd)
                opts.Owner := MyMainWin.ui.wpfHwnd
        }
        try {
            if (IsSet(MainSoftData) && MainSoftData.HasProp("Theme") && MainSoftData.Theme != "")
                opts.Theme := MainSoftData.Theme
            if (IsSet(MainSoftData) && MainSoftData.HasProp("FontType") && MainSoftData.FontType != "")
                opts.FontFamily := MainSoftData.FontType
        }
        return opts
    }

    static _DialogStyles() {
        snap := ' SnapsToDevicePixels="True" UseLayoutRounding="False" RenderOptions.EdgeMode="Aliased"'
        ; 与主题选项「确定」相同：Action 底/描边，悬停 ActionHover；确定/取消共用，不区分主次色
        btn := '<Style x:Key="DialogBtn" TargetType="Button">'
            . '<Setter Property="Height" Value="32"/><Setter Property="MinHeight" Value="32"/>'
            . '<Setter Property="Width" Value="80"/>'
            . '<Setter Property="Padding" Value="10,0"/>'
            . '<Setter Property="FontSize" Value="13"/><Setter Property="FontWeight" Value="Bold"/>'
            . '<Setter Property="Cursor" Value="Hand"/>'
            . '<Setter Property="Foreground" Value="{DynamicResource ActionText}"/>'
            . '<Setter Property="Background" Value="{DynamicResource ActionBg}"/>'
            . '<Setter Property="BorderBrush" Value="{DynamicResource ActionStroke}"/>'
            . '<Setter Property="BorderThickness" Value="1"/>'
            . '<Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button">'
            . '<Border x:Name="Bd" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="3"' snap '>'
            . '<ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>'
            . '</Border>'
            . '<ControlTemplate.Triggers>'
            . '<Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Background" Value="{DynamicResource ActionHoverBg}"/><Setter TargetName="Bd" Property="BorderBrush" Value="{DynamicResource ActionHoverStroke}"/></Trigger>'
            . '<Trigger Property="IsPressed" Value="True"><Setter TargetName="Bd" Property="Background" Value="{DynamicResource ActionPressBg}"/><Setter TargetName="Bd" Property="BorderBrush" Value="{DynamicResource ActionHoverStroke}"/></Trigger>'
            . '</ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>'
        primary := StrReplace(btn, 'x:Key="DialogBtn"', 'x:Key="DialogPrimaryBtn"')
        closeBtn := '<Style x:Key="TitleBarCloseButton" TargetType="Button">'
            . '<Setter Property="Width" Value="46"/><Setter Property="Height" Value="36"/><Setter Property="MinHeight" Value="36"/>'
            . '<Setter Property="Padding" Value="0"/><Setter Property="Margin" Value="0"/>'
            . '<Setter Property="Cursor" Value="Hand"/>'
            . '<Setter Property="Background" Value="Transparent"/>'
            . '<Setter Property="BorderThickness" Value="0"/>'
            . '<Setter Property="Foreground" Value="{DynamicResource TextMain}"/>'
            . '<Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button">'
            . '<Border x:Name="Bd" Background="{TemplateBinding Background}" CornerRadius="0,8,0,0" HorizontalAlignment="Stretch" VerticalAlignment="Stretch"' snap '>'
            . '<ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>'
            . '</Border>'
            . '<ControlTemplate.Triggers>'
            . '<Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Background" Value="{DynamicResource ControlBorder}"/><Setter Property="Foreground" Value="{DynamicResource TextMain}"/></Trigger>'
            . '<Trigger Property="IsPressed" Value="True"><Setter TargetName="Bd" Property="Background" Value="{DynamicResource BtnPressBg}"/><Setter Property="Foreground" Value="{DynamicResource TextMain}"/></Trigger>'
            . '</ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>'
        return btn . primary . closeBtn
    }
}
