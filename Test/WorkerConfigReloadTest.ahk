#Requires AutoHotkey v2.0
#SingleInstance Off
#Warn All, Off

global Calls := []
global MySoftData := {CurSettingName: "Before"}

LoadMainSetting() {
    Calls.Push("main")
    MySoftData.CurSettingName := "After"
}
TomlUtil_Invalidate() => Calls.Push("toml")
LoadCurMacroSetting() => Calls.Push("macro")
InitData() => Calls.Push("data")
GraphPoolLog(*) {
}

#Include ..\Thread\WorkUtil.ahk

Assert(value, message) {
    if (!value)
        throw Error(message)
    FileAppend("PASS " message "`n", "*")
}

try {
    SetWorkingDir(A_ScriptDir "\..\Thread")
    ReloadWorkerConfig()
    Assert(Calls.Length == 4, "worker reload executed all refresh stages")
    Assert(Calls[1] == "main" && Calls[2] == "toml" && Calls[3] == "macro" && Calls[4] == "data"
        , "global settings reload before macro data")
    Assert(InStr(MacroFile, "\Setting\After\MacroFile.toml") > 0
        , "worker paths use refreshed setting profile")
    ExitApp(0)
} catch as e {
    FileAppend("FAIL " e.Message " @ " e.Line "`n", "*")
    ExitApp(1)
}
