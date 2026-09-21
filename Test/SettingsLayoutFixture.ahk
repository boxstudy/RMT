#Requires AutoHotkey v2.0
#SingleInstance Off
#Warn All, Off
global MainSoftData := {}
global MySoftData := {CMDTip: false}
; @FIELDS@
MainSoftData.LangArr := 1
MainSoftData.Lang := 1
MainSoftData.PreferredMacroEditor := 1
MainSoftData.IsModalSubGui := 1
MainSoftData.ScreenShotType := 1
MainSoftData.MutiThreadNum := 1
MainSoftData.MacroStopType := 1
MainSoftData.CheckForeground := 1
MainSoftData.AutoLoosenModifier := 1
MainSoftData.ContinuousTrigger := 1
MainSoftData.TriggerJoyType := 1
MainSoftData.JoyType := 1
MainSoftData.HoldFloat := 1
MainSoftData.PreIntervalFloat := 1
MainSoftData.IntervalFloat := 1
MainSoftData.CoordXFloat := 1
MainSoftData.CoordYFloat := 1
MainSoftData.KeyDownDownType := 1
MainSoftData.RemarkAutoType := 1
MainSoftData.NoVariableTip := 1
MainSoftData.RecordShowBorder := 1
MainSoftData.RecordHoldMuti := 1
MainSoftData.RecordAutoLoosen := 1
MainSoftData.RecordKeyboard := 1
MainSoftData.RecordMouse := 1
MainSoftData.RecordMouseTrail := 1
MainSoftData.RecordMouseTrailSpeed := 1
MainSoftData.RecordJoy := 1
MainSoftData.RecordJoyInterval := 1
MainSoftData.CMDPosX := 1
MainSoftData.CMDPosY := 1
MainSoftData.CMDWidth := 1
MainSoftData.CMDHeight := 1
MainSoftData.CMDFontSize := 1
MainSoftData.CMDTransparency := 1
MainSoftData.CMDLogToFile := 1
MainSoftData.CMDLogFilePath := 1
MainSoftData.CMDLogAutoClear := 1
MainSoftData.SysLogMinLevel := 1
MainSoftData.LogWarnBubble := 1
MainSoftData.LogErrorBadge := 1
MainSoftData.BusinessLog := 1
MainSoftData.FixedMenuWheel := 1
MainSoftData.MenuWheelShowTooltip := 1
MainSoftData.MenuWheelSelectMode := 1
MainSoftData.MenuWheelScale := 1
MainSoftData.UIPanelBtnWidth := 1
MainSoftData.UIPanelBtnHeight := 1
MainSoftData.UIPanelFontSize := 1
MainSoftData.UIPanelCols := 1
MainSoftData.NetworkPort := 1
MainSoftData.UIPanelShowOnActive := 1
MainSoftData.UIPanelDefaultPos := 1
MainSoftData.UIPanelOffsetX := 1
MainSoftData.UIPanelOffsetY := 1
MainSoftData.ThemeColors := 1
MainSoftData.AppTheme := 1
MainSoftData.AiProvider := 1
MainSoftData.AiApiBaseUrl := 1
MainSoftData.AiApiKey := 1
MainSoftData.AiModel := 1
MainSoftData.AiAccessMode := 1
MainSoftData.AiApprovalMode := 1
MainSoftData.LangArr := ["简体中文"]
MainSoftData.FontList := ["Microsoft YaHei UI"]
MainSoftData.FontType := "Microsoft YaHei UI"
MainSoftData.ThemeColors := Map()
MainSoftData.SoftBGColor := "#FFFFFFFF"
MainSoftData.BackImagePath := ""
MainSoftData.AiApiKey := ""
class AppThemeUtil {
    static Presets := [{Key: "warm", Name: "暖阳"}]
    static ColorDefs := []
}
class AiAssist {
    static Providers := [Map("name", "OpenAI")]
    static AccessLabels := ["只读", "工作区", "完全访问"]
    static ApprovalLabels := ["询问", "允许"]
    static ModelListArr() => ["test"]
    static ProviderIndex(*) => 1
}
GetLang(x) => x
GetLangArr(x) => x
GetTableIndexByID(*) => 1
FormatHotkeyDisplay(x) => x
class MockUI {
    Update(n, p, x) {
        if (p == "AddXamlItem")
            FileAppend(x, A_Args[1], "UTF-8")
    }
}
class Builder {
    ui := MockUI()
    _XmlEsc(x) => StrReplace(StrReplace(StrReplace(StrReplace(String(x), "&", "&amp;"), "<", "&lt;"), ">", "&gt;"), '"', "&quot;")
    _ShareLoginStateText() => "未登录"
    _TabVisibleVal(*) => true
    _UIPanelPosIndex(*) => 0
; @BUILD@

}
try {
    loop 14 {
        AppThemeUtil.ColorDefs.Push({Key: "Theme_Color" Format("{:02}", A_Index)})
        MainSoftData.ThemeColors["Theme_Color" Format("{:02}", A_Index)] := "#FFFF8C00"
    }
    MainSoftData.CMDWidth := 360
    MainSoftData.CMDHeight := 180
    MainSoftData.CMDFontSize := 15
    MainSoftData.FontSize := 15
    MainSoftData.MenuWheelScale := 100
    Builder().BuildSettingTab()
    ExitApp(0)
} catch as e {
    FileAppend(e.Message " at " e.Line, "*")
    ExitApp(1)
}

