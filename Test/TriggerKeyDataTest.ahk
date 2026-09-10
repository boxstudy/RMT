#Requires AutoHotkey v2.0
#SingleInstance Off
#Warn All, Off

global MainSoftData := {ContinuousTrigger: false, AutoLoosenModifier: false, KeyDownDownType: 1}
global MySoftData := {
    OnlyDownKeyMap: Map(
        "WheelDown", 0, "WheelUp", 0,
        "WheelLeft", 0, "WheelRight", 0,
        "Bright_Down", 0, "Bright_Up", 0,
        "None", 0
    )
}
global MyMouseInfo := {UpdateInfo: (*) => 0}

GetTableBySymbol(*) => ""
GetParamsWinInfoStr(value) => value
LoosenModifyKey(*) {
}
AreKeysPressed(*) => false

#Include ..\Main\TriggerKeyData.ahk

class FakeTriggerInfo {
    __New() {
        this.Count := 0
    }

    GetTriggerType() => 1
    GetFrontStr() => ""
    GetTK() => ""
    Action() => this.Count++
    GetWorkState() => false
}

Assert(value, message) {
    if (!value)
        throw Error(message)
    FileAppend("PASS " message "`n", "*")
}

Exercise(key, expectedAfterTwoDowns, expectedAfterRelease) {
    data := TriggerKeyData(key)
    info := FakeTriggerInfo()
    data.AddData(info)

    data.OnTriggerKeyDown()
    data.OnTriggerKeyDown()
    Assert(info.Count == expectedAfterTwoDowns, key " repeated down count")

    data.OnTriggerKeyUp()
    data.OnTriggerKeyDown()
    Assert(info.Count == expectedAfterRelease, key " count after release")
}

try {
    ; “按下时按下”的三种输出策略都不应改变滚轮触发行为。
    ; 滚轮没有 up 事件：每个脉冲都必须触发，即使关闭了“连续触发”。
    for mode in [1, 2, 3] {
        MainSoftData.KeyDownDownType := mode
        Exercise("wheelup", 2, 3)
    }
    Exercise("wheelleft", 2, 3)
    Exercise("^wheeldown", 2, 3)

    ; 普通键仍维持原语义：未松开时拦截重复按下，松开后恢复。
    Exercise("a", 1, 2)
    ExitApp(0)
} catch as e {
    FileAppend("FAIL " e.Message " @ " e.Line "`n", "*")
    ExitApp(1)
}
