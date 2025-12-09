; IbInputSimulator
; Description: Enable AHK to send keystrokes by drivers.
; Authors: Chaoses-Ib, Pennywise007
; Version: 0.4.1
; Homepage: https://github.com/Chaoses-Ib/IbInputSimulator

#Requires AutoHotkey v2.0 64-bit

#DllLoad "*i IbInputSimulator.dll"  ;DllCall("LoadLibrary") cannot locate DLL correctly

IbSendInit(send_type := "AnyDriver", mode := 1, args*) {
    workding_dir := A_WorkingDir
    SetWorkingDir(A_ScriptDir)

    static hModule := DllCall("GetModuleHandle", "Str", "IbInputSimulator.dll", "Ptr")
    if (hModule == 0) {
        if (A_PtrSize == 4)
            throw "SendLibLoadFailed: Please use AutoHotkey x64"
        else
            throw "SendLibLoadFailed: " A_LastError
    }

    if (send_type == "AnyDriver")
        result := DllCall("IbInputSimulator\IbSendInit", "Int", 0, "Int", 0, "Ptr", 0, "Int")
    else if (send_type == "SendInput")
        result := DllCall("IbInputSimulator\IbSendInit", "Int", 1, "Int", 0, "Ptr", 0, "Int")
    else if (send_type == "Logitech")
        result := DllCall("IbInputSimulator\IbSendInit", "Int", 2, "Int", 0, "Ptr", 0, "Int")
    else if (send_type == "LogitechGHubNew") {
        if (!IsProcessRunning("lghub.exe") && !IsProcessRunning("lghub_agent.exe")) {
            StartLogitechGHub()
        }

        result := DllCall("IbInputSimulator\IbSendInit", "Int", 6, "Int", 0, "Ptr", 0, "Int")
    }
    else if (send_type == "Razer")
        result := DllCall("IbInputSimulator\IbSendInit", "Int", 3, "Int", 0, "Ptr", 0, "Int")
    else if (send_type == "DD") {
        if (args.Length == 1)
            result := DllCall("IbInputSimulator\IbSendInit", "Int", 4, "Int", 0, "WStr", args[1], "Int")
        else
            result := DllCall("IbInputSimulator\IbSendInit", "Int", 4, "Int", 0, "Ptr", 0, "Int")
    } else if (send_type == "MouClassInputInjection") {
        if (args.Length != 1)
            throw "MouClassInputInjection: Please specify the process ID of the target process"
        result := DllCall("IbInputSimulator\IbSendInit", "Int", 5, "Int", 0, "UInt64", args[1], "Int")
    } else
        throw "Invalid send type"

    SetWorkingDir(workding_dir)

    ; if (result !== 0){
    ;     error_text := [
    ;         "InvalidArgument",
    ;         "LibraryNotFound",
    ;         "LibraryLoadFailed",
    ;         "LibraryError",
    ;         "DeviceCreateFailed",
    ;         "DeviceNotFound",
    ;         "DeviceOpenFailed"
    ;     ]
    ;     throw error_text[result]
    ; }
    if (result != 0 && send_type == "LogitechGHubNew") {
        MsgBox("使用罗技按键类型，需要下载安装G HUB")
        Run("https://www.logitechg.com/en-my/innovation/g-hub.html")
        return false
    }

    if (mode !== 0) {
        IbSendMode(mode)
    }
    return true
}

IbSendMode(mode) {
    static ahk_mode := ""
    if (mode == 1) {
        DllCall("IbInputSimulator\IbSendInputHook", "Int", 1)
        ahk_mode := A_SendMode
        SendMode("Input")
    } else if (mode == 0) {
        SendMode(ahk_mode)
        DllCall("IbInputSimulator\IbSendInputHook", "Int", 0)
    } else {
        throw "Invalid send mode"
    }
}

IbSendDestroy() {
    DllCall("IbInputSimulator\IbSendDestroy")
    ;DllCall("FreeLibrary", "Ptr", hModule)
}

IbSyncKeyStates() {
    DllCall("IbInputSimulator\IbSendSyncKeyStates")
}

IbSend(keys) {
    DllCall("IbInputSimulator\IbSendInputHook", "Int", 1)  ;or IbSendMode(1)
    SendInput(keys)
    DllCall("IbInputSimulator\IbSendInputHook", "Int", 0)  ;or IbSendMode(0)
}

IbClick(args*) {
    IbSendMode(1)
    Click(args*)
    IbSendMode(0)
}

IbMouseMove(args*) {
    IbSendMode(1)
    MouseMove(args*)
    IbSendMode(0)
}

IbMouseClick(args*) {
    IbSendMode(1)
    MouseClick(args*)
    IbSendMode(0)
}

IbMouseClickDrag(args*) {
    IbSendMode(1)
    MouseClickDrag(args*)
    IbSendMode(0)
}

IsProcessRunning(processName) {
    try {
        ProcessExist(processName)
        return true
    }
    catch {
        return false
    }
}

; 启动 Logitech G Hub
StartLogitechGHub() {
    ; 尝试在默认安装路径启动
    paths := [
        A_ProgramFiles . "\LGHUB\lghub.exe",
        A_ProgramFiles . "\Logitech Gaming Software\lghub.exe",
        A_AppData . "\Microsoft\Windows\Start Menu\Programs\Logitech G\G HUB.lnk"
    ]

    for path in paths {
        if (FileExist(path)) {
            try {
                Run(path)
                return true
            }
        }
    }

    ; 如果找不到，尝试通过注册表查找
    try {
        file := RegRead(
            "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{521c89be-637f-4274-a840-baaf7460c2b2}",
            "DisplayIcon")
        if (FileExist(file)) {
            Run(file)
            return true
        }
    }

    ; 最后尝试通过系统搜索
    try {
        Run("explorer.exe shell:AppsFolder\LogitechG.LogitechG_hypejqnwv7yhy!App")
        return true
    }

    return false
}
