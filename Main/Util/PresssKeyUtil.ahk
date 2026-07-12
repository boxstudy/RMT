#Requires AutoHotkey v2.0
SendKeyWrapper(KeyArrStr, holdTime, tableItem, index, keyType, Action) {
    static BrightKeyMap := Map("Bright_Up", 0, "Bright_Down", 0)
    static LogicNoKeyMap := Map("Volume_Up", 0, "Volume_Down", 0, "Volume_Mute", 0)
    KeyArrStr := StrReplace(KeyArrStr, "逗号", ",")
    KeyArr := GetPressKeyArr(KeyArrStr)

    GetRealAction(key) {
        return (Action == SendLogicKey && LogicNoKeyMap.Has(key)) ? SendNormalKey : Action
    }

    KeyDown() {
        for key in KeyArr {
            if (BrightKeyMap.Has(key)) {
                SetBrightnessByKey(key)
                continue
            }

            RealAction := GetRealAction(key)

            if (HandleKeyDownDown(key, tableItem, index, RealAction))
                continue

            RealAction(key, 1, tableItem, index)
        }
    }

    KeyUp() {
        Loop KeyArr.Length {
            key := KeyArr[KeyArr.Length - A_Index + 1]

            if (OnlyDownKeyMap.Has(key))
                continue

            GetRealAction(key)(key, 0, tableItem, index)
        }
    }

    if (keyType == 1) {
        KeyDown()
    } else if (keyType == 2) {
        KeyUp()
    } else if (keyType == 3) {
        KeyDown()
        Sleep(holdTime)
        KeyUp()
    }
}

SendNormalKey(Key, state, tableItem, index) {
    Symbol := state == 1 ? "down" : "up"
    keySymbol := "{Blind}{" key " " Symbol "}"
    Send(keySymbol)

    if (MySoftData.OnlyDownKeyMap.Has(Key))
        return
    if (state == 1) {
        tableItem.HoldKeyArr[index][Key] := "Normal"
    }
    else {
        tableItem.HoldKeyArr[index].Delete(Key)
    }
}

SendGameModeKey(Key, state, tableItem, index)
{
    static MouseVK := Map(
        1, 0,     ; LButton
        2, 0,     ; RButton
        4, 0,     ; MButton
        5, 0,     ; XButton1
        6, 0,     ; XButton2
        158, 0,   ; WheelDown
        159, 0    ; WheelUp
    )

    static ExtendedVK := Map(
        0x21, 0,  ; PageUp
        0x22, 0,  ; PageDown
        0x23, 0,  ; End
        0x24, 0,  ; Home
        0x25, 0,  ; Left
        0x26, 0,  ; Up
        0x27, 0,  ; Right
        0x28, 0,  ; Down
        0x2D, 0,  ; Insert
        0x2E, 0   ; Delete
    )

    VK := GetKeyVK(Key)

    if MouseVK.Has(VK) {
        SendGameMouseKey(Key, state, tableItem, index)
        return
    }

    SC := GetKeySC(Key)
    isExtended := ExtendedVK.Has(VK)

    if (state) {
        DllCall("keybd_event", "UChar", VK, "UChar", SC, "UInt", isExtended ? 1 : 0, "UPtr", 0)
        if MySoftData.OnlyDownKeyMap.Has(Key)
            return
        tableItem.HoldKeyArr[index][Key] := "Game"
    }
    else {
        DllCall("keybd_event", "UChar", VK, "UChar", SC, "UInt", isExtended ? 3 : 2, "UPtr", 0)
        tableItem.HoldKeyArr[index].Delete(Key)
    }
}

SendGameMouseKey(key, state, tableItem, index) {
    static MouseMap := Map(
        "LButton",   {Down: 0x0002, Up: 0x0004, Data: 0},
        "RButton",   {Down: 0x0008, Up: 0x0010, Data: 0},
        "MButton",   {Down: 0x0020, Up: 0x0040, Data: 0},
        "WheelUp",   {Down: 0x0800, Up: 0,      Data: 120},
        "WheelDown", {Down: 0x0800, Up: 0,      Data: -120},
        "XButton1",  {Down: 0x0080, Up: 0x0100, Data: 0x0001},
        "XButton2",  {Down: 0x0080, Up: 0x0100, Data: 0x0002}
    )

    info := MouseMap[key]

    if (state) {
        DllCall("mouse_event", "UInt", info.Down, "UInt", 0, "UInt", 0, "UInt", info.Data, "UInt", 0)
        tableItem.HoldKeyArr[index][key] := "GameMouse"
    }
    else {
        if (info.Up) {
            DllCall("mouse_event", "UInt", info.Up, "UInt", 0, "UInt", 0, "UInt", info.Data, "UInt", 0)
        }
        tableItem.HoldKeyArr[index].Delete(key)
    }
}

SendLogicKey(Key, state, tableItem, index) {
    if (!InitLogitechGHubNew())
        return

    Symbol := state == 1 ? "down" : "up"
    keySymbol := "{Blind}{" key " " Symbol "}"
    IbSend(keySymbol)

    if (MySoftData.OnlyDownKeyMap.Has(Key))
        return
    if (state == 1) {
        tableItem.HoldKeyArr[index][Key] := "Logic"
    }
    else {
        tableItem.HoldKeyArr[index].Delete(Key)
    }
}

SendAHIKey(Key, state, tableItem, index) {
    if (!InitAHI())
        return

    AhiSendKey(Key, state)

    if (MySoftData.OnlyDownKeyMap.Has(Key))
        return
    if (state == 1) {
        tableItem.HoldKeyArr[index][Key] := "AHI"
    }
    else {
        tableItem.HoldKeyArr[index].Delete(Key)
    }
}

SendJoyBtnKey(key, state, tableItem, index) {
    JoyBtnName := SubStr(key, 4)
    if (JoyBtnName == "LT" || JoyBtnName == "RT") {
        Value := state == 1 ? 100 : 0
        MyViGJoySetState("Axis", JoyBtnName, Value)
    }
    else {
        MyViGJoySetState("Btn", JoyBtnName, state)
    }

    if (state == 1) {
        tableItem.HoldKeyArr[index][key] := "Joy"
    }
    else {
        tableItem.HoldKeyArr[index].Delete(key)
    }
}

SendJoyAxisKey(key, state, tableItem, index) {
    Value := InStr(key, "Min") ? 0 : 100
    Value := state == 1 ? Value : 50
    JoyAxisName := SubStr(key, 8, 2)
    MyViGJoySetState("Axis", JoyAxisName, Value)

    if (state == 1) {
        tableItem.HoldKeyArr[index][key] := "JoyAxis"
    }
    else {
        tableItem.HoldKeyArr[index].Delete(key)
    }
}

SendJoyDpadKey(key, state, tableItem, index) {
    RealKey := SubStr(key, 8)
    Value := state ? RealKey : "None"
    MyViGJoySetState("Dpad", Value, 0)

    if (state == 1 && Value != "None") {
        tableItem.HoldKeyArr[index][key] := "JoyDpad"
    }
    else {
        DpadArr := ["Up", "Down", "Left", "Right"]
        loop DpadArr.Length {
            tableItem.HoldKeyArr[index].Delete(DpadArr[A_Index])
        }
    }
}

SetBrightnessByKey(key, *) {
    if (key == "Bright_Down")
        ChangeBrightness(false)
    if (key == "Bright_Up")
        ChangeBrightness(true)
}

ChangeBrightness(isAdd) {
    CurrentBrightness := GetBrightness()
    Value := isAdd ? CurrentBrightness + 10 : CurrentBrightness - 10
    Value := Max(0, Min(100, Value)) ; 限制在 0-100
    wmi := ComObjGet("winmgmts:\\.\root\WMI")
    for item in wmi.ExecQuery("SELECT * FROM WmiMonitorBrightnessMethods") {
        item.WmiSetBrightness(1, Value)
    }
}

;处理宏按键：按下时按下
HandleKeyDownDown(key, tableItem, index, Action) {
    isSkip := false
    try {   ;按下前已经按下的话先松开
        state := GetKeyState(key)
        if (state == 1) {
            if (MainSoftData.KeyDownDownType == 1)    ; 1自动松开
                Action(key, 0, tableItem, index)
            else if (MainSoftData.KeyDownDownType == 2)   ;2忽略后续按下
                isSkip := true
            else if (MainSoftData.KeyDownDownType == 3) { ;3允许该行为，不做任何干预
            }
        }
    }
    return isSkip
}