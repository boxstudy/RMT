#Requires AutoHotkey v2.0
#SingleInstance Off
#Warn All, Off
#Include ..\Plugins\AHK-XAML\lib\XAML_Host.ahk
#Include ..\Plugins\AHK-XAML\lib\XAML_Generator.ahk
#Include ..\Main\Util\XamlWin.ahk
#Include ..\Gui\VoiceGui.ahk
#Include ..\Main\VirtualListHost.ahk

SetWorkingDir(A_ScriptDir "\..")

; Exercise the real cross-process window lifecycle without loading user macros.
global XAML_ENGINE_BUILD_LOCATION := "lib/dep"
global XAML_FORCE_DYNAMIC_COMPILE := false
global XAML_ENABLE_DEVTOOLS := false
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
        FileAppend("PASS voice window opened, parent still alive`n", "*")
        MyVoiceGui.Cancel()
        TestMain.Update("Window", "Close", "")
        ExitApp(0)
    } catch as err {
        FileAppend("FAIL " err.Message " @ " err.Line "`n", "*")
        ExitApp(1)
    }
}
