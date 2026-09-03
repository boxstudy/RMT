#Requires AutoHotkey v2.0

; =============================================================================
; RMT 通用 XAML 提示/确认弹窗
; 基于 AHK-XAML 的 XDialog，套主界面主题字体、字号与按钮高度。
; =============================================================================
class RmtDialog {
    ; 单按钮提示（确定）
    static Info(msg, title := "") {
        RmtDialog._Trace("Info enter msg=" RmtDialog._Clip(msg))
        opts := RmtDialog._BaseOpts()
        opts.Title := title != "" ? title : GetLang("提示")
        opts.Message := String(msg)
        opts.Icon := Chr(0xE946)
        opts.Buttons := [GetLang("确定")]
        try {
            res := XDialog.Show(opts)
            RmtDialog._Trace("Info Show returned button=" (IsObject(res) && res.HasProp("Button") ? res.Button : "n/a")
                " hwnd=" (IsObject(res) && IsObject(res.Instance) ? res.Instance.wpfHwnd : 0))
        } catch as e {
            RmtDialog._Log("Info", e)
            try {
                if (opts.Owner)
                    WinSetEnabled(1, "ahk_id " opts.Owner)
            }
        }
    }

    ; 确定/取消，返回是否点了确定
    static Confirm(msg, title := "") {
        RmtDialog._Trace("Confirm enter msg=" RmtDialog._Clip(msg))
        opts := RmtDialog._BaseOpts()
        opts.Title := title != "" ? title : GetLang("提示")
        opts.Message := String(msg)
        opts.Icon := Chr(0xE814)
        opts.IconColor := "{DynamicResource Accent}"
        opts.Buttons := [GetLang("确定"), GetLang("取消")]
        try {
            res := XDialog.Show(opts)
            ok := IsObject(res) && res.Button == GetLang("确定")
            RmtDialog._Trace("Confirm Show returned button=" (IsObject(res) ? res.Button : "n/a") " ok=" ok)
            return ok
        } catch as e {
            RmtDialog._Log("Confirm", e)
            try {
                if (opts.Owner)
                    WinSetEnabled(1, "ahk_id " opts.Owner)
            }
            return false
        }
    }

    static _BaseOpts() {
        opts := { Modal: true, Owner: 0, Width: 380, AlwaysOnTop: true, ButtonHeight: 32, ButtonWidth: 80 }
        opts.TitleFontSize := 12
        opts.ContentFontSize := XAMLHost.GetDesignFontSize()
        opts.IconFontSize := 36
        opts.IconColWidth := 72
        opts.UniformButtons := true
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
        RmtDialog._Trace("opts owner=" opts.Owner " theme=" (opts.HasOwnProp("Theme") ? opts.Theme : "")
            " font=" (opts.HasOwnProp("FontFamily") ? opts.FontFamily : "")
            " daemon=" (IsSet(XAMLHost) ? XAMLHost.daemonHwnd : 0))
        return opts
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

    static _DialogStyles() {
        close := '<Style x:Key="TitleBarCloseButton" TargetType="Button">'
            . '<Setter Property="Width" Value="46"/><Setter Property="Height" Value="36"/>'
            . '<Setter Property="MinWidth" Value="46"/><Setter Property="MinHeight" Value="36"/>'
            . '<Setter Property="Padding" Value="0"/><Setter Property="Margin" Value="0"/>'
            . '<Setter Property="VerticalAlignment" Value="Stretch"/>'
            . '<Setter Property="Background" Value="Transparent"/>'
            . '<Setter Property="BorderThickness" Value="0"/>'
            . '<Setter Property="Cursor" Value="Hand"/>'
            . '<Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button">'
            . '<Border x:Name="border" Background="{TemplateBinding Background}" CornerRadius="{DynamicResource CloseBtnRadius}" HorizontalAlignment="Stretch" VerticalAlignment="Stretch" SnapsToDevicePixels="True">'
            . '<ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>'
            . '</Border>'
            . '<ControlTemplate.Triggers>'
            . '<Trigger Property="IsMouseOver" Value="True"><Setter TargetName="border" Property="Background" Value="#E0FF3333"/><Setter Property="Foreground" Value="White"/></Trigger>'
            . '</ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>'
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
            . '<Border x:Name="Bd" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="3" SnapsToDevicePixels="True">'
            . '<ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>'
            . '</Border>'
            . '<ControlTemplate.Triggers>'
            . '<Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Background" Value="{DynamicResource ActionHoverBg}"/><Setter TargetName="Bd" Property="BorderBrush" Value="{DynamicResource ActionHoverStroke}"/></Trigger>'
            . '<Trigger Property="IsPressed" Value="True"><Setter TargetName="Bd" Property="Background" Value="{DynamicResource ActionPressBg}"/><Setter TargetName="Bd" Property="BorderBrush" Value="{DynamicResource ActionHoverStroke}"/></Trigger>'
            . '</ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>'
        return close . btn . StrReplace(btn, 'x:Key="DialogBtn"', 'x:Key="DialogPrimaryBtn"')
    }
}
