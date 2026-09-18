#Requires AutoHotkey v2.0
#SingleInstance Off
#Warn All, Off
#Include ..\Plugins\AHK-XAML\lib\XAML_Host.ahk
#Include ..\Plugins\AHK-XAML\lib\XAML_Generator.ahk
#Include ..\Main\Util\XamlWin.ahk
#Include ..\Main\Util\SttUtil.ahk
#Include ..\Gui\SttGui.ahk

SetWorkingDir(A_ScriptDir "\..")
GetLang(text) => text
ApplyXamlTheme(*) {
}
class Toast {
    static Warning(*) {
    }
    static Progress(*) {
    }
    static Success(*) {
    }
    static Error(*) {
    }
}
class RmtDialog {
    static Confirm(*) => false
}
class InstallProbe extends SttGui {
    _RefreshUi() {
    }
    _MissingModels() => [this.dlSpec]
    _StartNextDownload() {
        this.downloadState := "dl"
        return true
    }
}
Check(ok, message) {
    if (!ok)
        throw Error(message)
    FileAppend("PASS " message "`n", "*")
}

try {
    probe := InstallProbe()
    probe.hasGui := true
    probe.ui := {}
    probe.dlPid := 0
    probe.dlSpec := Map("minBytes", 1, "pkg", "fixture", "files", ["encoder.onnx", "tokens.txt"])
    probe.dlTar := A_Temp "\rmt-stt-missing-" A_TickCount ".tar.bz2"
    probe.downloadState := "dl"
    probe.OnTimer()
    Check(probe.downloadState == "err", "missing download becomes a handled error")
    probe.OnTimer()
    probe.OnDownloadClick()
    Check(probe.downloadState == "dl", "failed download can be retried")

    root := A_Temp "\rmt-stt-test-" DllCall("GetCurrentProcessId") "-" A_TickCount
    DirCreate(root "\fixture")
    FileAppend("model", root "\fixture\encoder.onnx")
    archive := root "\fixture.tar.bz2"
    exitCode := RunWait(Format('tar.exe -cjf "{}" -C "{}" fixture', archive, root), A_Temp, "Hide")
    Check(exitCode == 0, "fixture archive created")
    probe.dlTar := archive
    probe.dlSpec["dir"] := root "\installed"
    Check(probe._StartExtract() && DirExist(probe.dlDir), "fresh extraction directory exists before tar runs")
    Check(!ProcessWaitClose(probe.dlPid, 30), "extraction completes")
    probe.downloadState := "ex"
    probe.OnTimer()
    Check(probe.downloadState == "err" && !DirExist(root "\installed"), "incomplete model is rejected before deployment")
    FileAppend("tokens", probe.dlDir "\fixture\tokens.txt")
    Check(probe._FinishExtract(), "complete model installs successfully")
    Check(FileRead(root "\installed\encoder.onnx") == "model" && FileRead(root "\installed\tokens.txt") == "tokens", "installed model contents are intact")

    if (A_Args.Length && A_Args[1] == "/recover") {
        installer := SttGui()
        models := installer._MissingModels()
        Check(models.Length == 1, "recognition model needs recovery")
        installer.dlSpec := models[1]
        installer.dlTar := A_Temp "\rmt-stt-model.tar.bz2"
        Check(installer._StartExtract(), "cached recognition archive starts extracting")
        Check(!ProcessWaitClose(installer.dlPid, 60), "recognition archive extraction completes")
        Check(installer._FinishExtract(), "cached recognition model installed")
        engine := InitSttEngine()
        Check(engine.IsStreamModelReady(), "recognition model files are ready")
        Check(engine.StreamEnsureInit(), "recognition engine loads the installed model")
        engine.Close()
    }
    ExitApp(0)
} catch as err {
    FileAppend("FAIL " err.Message " @ " err.Line "`n", "*")
    ExitApp(1)
}
