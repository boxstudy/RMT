#Requires AutoHotkey v2.0
#SingleInstance Off
#Warn All, Off
Persistent true
#Include ..\Plugins\AHK-XAML\lib\XAML_Host.ahk
#Include ..\Plugins\AHK-XAML\lib\XAML_Generator.ahk
#Include ..\Main\Util\XamlWin.ahk
#Include ..\Gui\VoiceGui.ahk
#Include ..\Main\VirtualListHost.ahk

SetWorkingDir(A_ScriptDir "\..")

; Exercise the real cross-process window lifecycle without loading user macros.
global XAML_ENGINE_BUILD_LOCATION := "temp"
global XAML_FORCE_DYNAMIC_COMPILE := true
global XAML_ENABLE_DEVTOOLS := false
global XAML_ENABLE_TRACING := false
global MainSoftData := {FontType: "Microsoft YaHei UI", FontSize: 15, Theme: "RMT_Light", MyGui: ""}
global TestTable := {Index: 1, ID: "voice-test", Items: [{VoiceKeywords: "开始,暂停"}]}
global MyVoiceGui := VoiceGui()
global TestHost := ""
global TestMain := ""
global MyMainWin := ""
global MySoftData := {TableInfo: [TestTable]}

GetLang(value) => value
CheckIsItemTable(*) => true
GetTableIndexByID(*) => 1
CheckIsStringMacroTable(*) => false
CheckIsTimingMacroTable(*) => false
CheckIsMenuMacroTable(*) => false
GetTableSymbol(*) => "Voice"
ApplyXamlTheme(*) {
}
HotReloadPublish(*) {
}
OnItemVoiceTriggerSetting(table, index, *) => MyVoiceGui.ShowGui(table, index)
class RmtDialog {
    static _Trace(message) => FileAppend(message "`n", "*")
}
TraceHost(this, message, *) => FileAppend(message "`n", "*")
XAMLHost.DefineProp("Diag", {Call: TraceHost})

try {
    panel := XAML_Generator("StackPanel")
    panel.Add("ListBox").Name("FoldList_1").Height(160)
    TestMain := XamlWin.Create("Voice integration test", panel, 480, 300)
    TestMain.xaml := RegExReplace(TestMain.xaml, '(<ListBox\b[^>]*?)/>', '$1><ListBox.ItemTemplate><DataTemplate><Button Name="VoiceEdit" Tag="TKBtn" Content="Voice editor" /></DataTemplate></ListBox.ItemTemplate></ListBox>')
    TestHost := VirtualListHost(TestMain)
    TestHost.EnsureEvents(1)
    if (!XamlWin.Open(TestMain))
        throw Error("parent window did not open")
    MainSoftData.MyGui := {Hwnd: TestMain.wpfHwnd}
    TestMain.Update("FoldList_1", "VL_INIT", "R1_1" US "Voice test" US "开始,暂停" US "0" US "1" US "0" US "Transparent" US "1.")
    FileAppend("parent hwnd=" TestMain.wpfHwnd " daemon=" XAMLHost.daemonHwnd "`n", "*")
    SetTimer(RunVoiceProbe, -100)
} catch as err {
    FileAppend("FAIL " err.Message " @ " err.Line "`n", "*")
    ExitApp(1)
}

RunVoiceProbe(*) {
    try {
        start := A_TickCount
        TestMain.Update("VoiceEdit", "Invoke", "")
        Sleep(3500)
        if (!MyVoiceGui.hasGui || !IsObject(MyVoiceGui.ui) || !MyVoiceGui.ui.wpfHwnd)
            throw Error("voice window did not open; elapsed=" (A_TickCount - start))
        if (!DllCall("user32\IsWindow", "Ptr", TestMain.wpfHwnd))
            throw Error("parent window was destroyed")
        fontValues := MyVoiceGui.ui.Query("Window>FontSize", "EdKeywords>FontSize")
        if (fontValues.Count != 2 || Abs(Number(fontValues["Window>FontSize"]) - 15) > 0.01 || Abs(Number(fontValues["EdKeywords>FontSize"]) - 15) > 0.01)
            throw Error("voice font does not match theme: " JoinValues(fontValues))
        layoutValues := MyVoiceGui.ui.Query("Window>ActualWidth", "Window>ActualHeight", "RmtDialogRoot>ActualWidth", "RmtDialogRoot>ActualHeight")
        FileAppend("voice layout: " JoinValues(layoutValues) "`n", "*")
        chipValues := MyVoiceGui.ui.Query("KwChipHost>Height", "KwChipHost>Padding")
        if (Number(chipValues["KwChipHost>Height"]) != 124 || chipValues["KwChipHost>Padding"] != "4,2,4,2")
            throw Error("voice chip area size or padding mismatch: " JoinValues(chipValues))
        closeValues := MyVoiceGui.ui.Query("KwChipDel_1>Margin", "KwChip_1>Margin")
        FileAppend("voice chip close: " JoinValues(closeValues) "`n", "*")
        if (closeValues["KwChipDel_1>Margin"] != "0,-4,-8,0" || closeValues["KwChip_1>Margin"] != "6,4,6,4")
            throw Error("voice chip close position or spacing mismatch: " JoinValues(closeValues))
        if (Abs(Number(layoutValues["Window>ActualWidth"]) - Number(layoutValues["RmtDialogRoot>ActualWidth"])) > 1
            || Abs(Number(layoutValues["Window>ActualHeight"]) - Number(layoutValues["RmtDialogRoot>ActualHeight"])) > 1)
            throw Error("voice dialog root does not fill the restored window: " JoinValues(layoutValues))
        chromeValues := MyVoiceGui.ui.Query("DialogTitle>FontSize", "BtnClosePanel>Width", "BtnClosePanel>Height", "KwChipPanel>Uid")
        if (chromeValues.Count != 4 || Abs(Number(chromeValues["DialogTitle>FontSize"]) - 17) > 0.01
            || Abs(Number(chromeValues["BtnClosePanel>Width"]) - 46) > 0.01 || Abs(Number(chromeValues["BtnClosePanel>Height"]) - 30) > 0.01
            || chromeValues["KwChipPanel>Uid"] != "ahk:Voice.Keywords.Chips")
            throw Error("voice chrome or persistent chip panel id mismatch: " JoinValues(chromeValues))
        strokes := MyVoiceGui.ui.Query("KwInputHost>BorderThickness", "BtnSure>BorderThickness")
        if (strokes.Count != 2 || !InStr(strokes["KwInputHost>BorderThickness"], "1") || !InStr(strokes["BtnSure>BorderThickness"], "1"))
            throw Error("voice border thickness mismatch: " JoinValues(strokes))
        FileAppend("PASS voice window opened, parent still alive`n", "*")
        MyVoiceGui.Cancel()
        TestMain.Update("Window", "Close", "")
        ExitApp(0)
    } catch as err {
        FileAppend("FAIL " err.Message " @ " err.Line "`n", "*")
        ExitApp(1)
    }
}

JoinValues(values) {
    text := ""
    for key, value in values
        text .= (text = "" ? "" : " | ") key "=" value
    return text
}
