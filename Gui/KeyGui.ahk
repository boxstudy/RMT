#Requires AutoHotkey v2.0

class KeyGui {
    __new() {
        this.ParentTile := ""
        this.Gui := ""
        this.SureBtnAction := ""
        this.SaveBtnAction := ""

        this.HotkeyCon := ""
        this.CheckedBox := []
        this.ConMap := Map()
        this.CheckedInfoCon := ""
        this.CheckRuleBtn := ""

        this.KeyStr := ""
        this.CommandStr := ""
        this.HoldTimeCon := ""
        this.KeyTypeCon := ""
        this.PerIntervalCon := ""
        this.KeyCountCon := ""
        this.CommandStrCon := ""

        this.ModifyKeys := ["Shift", "Alt", "Ctrl", "Win", "LShift", "RShift", "LAlt", "RAlt", "LCtrl", "RCtrl", "LWin",
            "RWin"]
        this.JoyAxises := ["JoyXMin", "JoyXMax", "JoyYMin", "JoyYMax", "JoyZMin", "JoyZMax", "JoyRMin", "JoyRMax",
            "JoyUMin", "JoyUMax", "JoyVMin", "JoyVMax", "JoyPOV_0", "JoyPOV_9000", "JoyPOV_18000", "JoyPOV_27000"]

        this.ModifyKeyMap := Map("LAlt", "<!", "RAlt", ">!", "Alt", "!", "LWin", "<#", "RWin", ">#", "Win", "#",
            "LCtrl", "<^", "RCtrl", ">^", "Ctrl", "^", "LShift", "<+", "RShift", ">+", "Shift", "+")
    }

    OnSureHotkey() {
        triggerKey := this.HotkeyCon.Value
        triggerKey := StrReplace(triggerKey, ",", "逗号")
        triggerKey := StrReplace(triggerKey, "Insert", "Ins")
        this.RefreshCheckBox(triggerKey)

        this.Refresh()
    }

    ;选项相关
    OnCheckedKey(key) {
        isSelected := false
        arrayIndex := 0
        con := this.ConMap.Get(key)

        for index, value in this.CheckedBox {
            if (value == key) {
                isSelected := true
                arrayIndex := index
                break
            }
        }

        if (isSelected) {
            con.Opt("-Background")
            this.CheckedBox.RemoveAt(arrayIndex)
        }
        else {
            con.Opt("Background" "0x4cae50")
            this.CheckedBox.Push(key)
        }

        this.Refresh()
    }

    ClearCheckedBox() {
        for index, value in this.CheckedBox {
            if (this.ConMap.Has(value)) {
                con := this.ConMap.Get(value)
                con.Opt("-Background")
                con.Value := 0
            }
        }
        this.CheckedBox := []
        this.Refresh()
    }

    GetTriggerKey() {
        triggerKey := ""
        for index, value in this.CheckedBox {
            triggerKey .= value "⎖"
        }
        triggerKey := RTrim(triggerKey, "⎖")
        return triggerKey
    }

    ;按钮点击回调
    OnSureBtnClick() {
        this.UpdateCommandStr()
        action := this.SureBtnAction
        action(this.CommandStr)
        this.Gui.Hide()
    }

    AddGui() {
        MyGui := Gui(, this.ParentTile GetLang("按键编辑器"))
        this.Gui := MyGui
        MyGui.SetFont("S10 W550 Q2", MySoftData.FontType)

        PosX := 20
        PosY := 10
        con := MyGui.Add("Hotkey", Format("x{} y{} w{}", PosX, PosY - 3, 25), "F1")
        con.Enabled := false

        PosX += 30
        btnCon := MyGui.Add("Button", Format("x{} y{} w{}", PosX, PosY - 5, 80), GetLang("模拟指令"))
        btnCon.OnEvent("Click", (*) => this.TriggerMacro())

        PosX += 350
        MyGui.Add("Text", Format("x{} y{}", PosX, PosY), GetLang("键盘按键检测："))

        PosX += 120
        this.HotkeyCon := MyGui.Add("Hotkey", Format("x{} y{} w140", PosX, PosY - 3))

        PosX += 150
        con := MyGui.Add("Button", Format("x{} y{}", PosX, PosY - 5), GetLang("确定"))
        con.OnEvent("Click", (*) => this.OnSureHotkey())

        PosY += 30
        PosX := 10
        MyGui.Add("GroupBox", Format("x{} y{} w{} h{}", PosX, PosY, 1240, 490), GetLang("请从下面按钮中选择按键："))
        PosX := 20
        PosY += 20
        {

            MyGui.Add("Text", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("键盘"))

            PosX := 20
            PosY += 20
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "Esc")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Esc"))
            this.ConMap.Set("Esc", con)

            PosX += 100
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "F1")
            con.OnEvent("Click", (*) => this.OnCheckedKey("F1"))
            this.ConMap.Set("F1", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "F2")
            con.OnEvent("Click", (*) => this.OnCheckedKey("F2"))
            this.ConMap.Set("F2", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "F3")
            con.OnEvent("Click", (*) => this.OnCheckedKey("F3"))
            this.ConMap.Set("F3", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "F4")
            con.OnEvent("Click", (*) => this.OnCheckedKey("F4"))
            this.ConMap.Set("F4", con)

            PosX += 75
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "F5")
            con.OnEvent("Click", (*) => this.OnCheckedKey("F5"))
            this.ConMap.Set("F5", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "F6")
            con.OnEvent("Click", (*) => this.OnCheckedKey("F6"))
            this.ConMap.Set("F6", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "F7")
            con.OnEvent("Click", (*) => this.OnCheckedKey("F7"))
            this.ConMap.Set("F7", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "F8")
            con.OnEvent("Click", (*) => this.OnCheckedKey("F8"))
            this.ConMap.Set("F8", con)

            PosX += 75
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "F9")
            con.OnEvent("Click", (*) => this.OnCheckedKey("F9"))
            this.ConMap.Set("F9", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "F10")
            con.OnEvent("Click", (*) => this.OnCheckedKey("F10"))
            this.ConMap.Set("F10", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "F11")
            con.OnEvent("Click", (*) => this.OnCheckedKey("F11"))
            this.ConMap.Set("F11", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "F12")
            con.OnEvent("Click", (*) => this.OnCheckedKey("F12"))
            this.ConMap.Set("F12", con)

            PosX += 75
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "PrtScr")
            con.OnEvent("Click", (*) => this.OnCheckedKey("PrintScreen"))
            this.ConMap.Set("PrintScreen", con)

            PosX += 75
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "Scroll")
            con.OnEvent("Click", (*) => this.OnCheckedKey("ScrollLock"))
            this.ConMap.Set("ScrollLock", con)

            PosX += 75
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "Pause")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Pause"))
            this.ConMap.Set("Pause", con)

            PosY += 30
            PosX := 20
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "~")
            con.OnEvent("Click", (*) => this.OnCheckedKey("``"))
            this.ConMap.Set("``", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "1")
            con.OnEvent("Click", (*) => this.OnCheckedKey("1"))
            this.ConMap.Set("1", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "2")
            con.OnEvent("Click", (*) => this.OnCheckedKey("2"))
            this.ConMap.Set("2", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "3")
            con.OnEvent("Click", (*) => this.OnCheckedKey("3"))
            this.ConMap.Set("3", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "4")
            con.OnEvent("Click", (*) => this.OnCheckedKey("4"))
            this.ConMap.Set("4", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "5")
            con.OnEvent("Click", (*) => this.OnCheckedKey("5"))
            this.ConMap.Set("5", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "6")
            con.OnEvent("Click", (*) => this.OnCheckedKey("6"))
            this.ConMap.Set("6", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "7")
            con.OnEvent("Click", (*) => this.OnCheckedKey("7"))
            this.ConMap.Set("7", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "8")
            con.OnEvent("Click", (*) => this.OnCheckedKey("8"))
            this.ConMap.Set("8", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "9")
            con.OnEvent("Click", (*) => this.OnCheckedKey("9"))
            this.ConMap.Set("9", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "0")
            con.OnEvent("Click", (*) => this.OnCheckedKey("0"))
            this.ConMap.Set("0", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "-")
            con.OnEvent("Click", (*) => this.OnCheckedKey("-"))
            this.ConMap.Set("-", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "=")
            con.OnEvent("Click", (*) => this.OnCheckedKey("="))
            this.ConMap.Set("=", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "Backspace")
            con.OnEvent("Click", (*) => this.OnCheckedKey("BS"))
            this.ConMap.Set("BS", con)

            PosX += 125
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "Ins")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Ins"))
            this.ConMap.Set("Ins", con)

            PosX += 75
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "Home")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Home"))
            this.ConMap.Set("Home", con)

            PosX += 75
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "PgUp")
            con.OnEvent("Click", (*) => this.OnCheckedKey("PgUp"))
            this.ConMap.Set("PgUp", con)

            PosX += 100
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "Num")
            con.OnEvent("Click", (*) => this.OnCheckedKey("NumLock"))
            this.ConMap.Set("NumLock", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "/")
            con.OnEvent("Click", (*) => this.OnCheckedKey("NumpadDiv"))
            this.ConMap.Set("NumpadDiv", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "*")
            con.OnEvent("Click", (*) => this.OnCheckedKey("NumpadMult"))
            this.ConMap.Set("NumpadMult", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "-")
            con.OnEvent("Click", (*) => this.OnCheckedKey("NumpadSub"))
            this.ConMap.Set("NumpadSub", con)

            PosY += 30
            PosX := 20
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "Tab")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Tab"))
            this.ConMap.Set("Tab", con)

            PosX += 75
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "q")
            con.OnEvent("Click", (*) => this.OnCheckedKey("q"))
            this.ConMap.Set("q", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "w")
            con.OnEvent("Click", (*) => this.OnCheckedKey("w"))
            this.ConMap.Set("w", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "e")
            con.OnEvent("Click", (*) => this.OnCheckedKey("e"))
            this.ConMap.Set("e", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "r")
            con.OnEvent("Click", (*) => this.OnCheckedKey("r"))
            this.ConMap.Set("r", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "t")
            con.OnEvent("Click", (*) => this.OnCheckedKey("t"))
            this.ConMap.Set("t", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "y")
            con.OnEvent("Click", (*) => this.OnCheckedKey("y"))
            this.ConMap.Set("y", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "u")
            con.OnEvent("Click", (*) => this.OnCheckedKey("u"))
            this.ConMap.Set("u", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "i")
            con.OnEvent("Click", (*) => this.OnCheckedKey("i"))
            this.ConMap.Set("i", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "o")
            con.OnEvent("Click", (*) => this.OnCheckedKey("o"))
            this.ConMap.Set("o", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "p")
            con.OnEvent("Click", (*) => this.OnCheckedKey("p"))
            this.ConMap.Set("p", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "[")
            con.OnEvent("Click", (*) => this.OnCheckedKey("["))
            this.ConMap.Set("[", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "]")
            con.OnEvent("Click", (*) => this.OnCheckedKey("]"))
            this.ConMap.Set("]", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "\")
            con.OnEvent("Click", (*) => this.OnCheckedKey("\"))
            this.ConMap.Set("\", con)

            PosX += 100
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "Del")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Del"))
            this.ConMap.Set("Del", con)

            PosX += 75
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "End")
            con.OnEvent("Click", (*) => this.OnCheckedKey("End"))
            this.ConMap.Set("End", con)

            PosX += 75
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "PgDn")
            con.OnEvent("Click", (*) => this.OnCheckedKey("PgDn"))
            this.ConMap.Set("PgDn", con)

            PosX += 100
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "7")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Numpad7"))
            this.ConMap.Set("Numpad7", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "8")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Numpad8"))
            this.ConMap.Set("Numpad8", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "9")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Numpad9"))
            this.ConMap.Set("Numpad9", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "+")
            con.OnEvent("Click", (*) => this.OnCheckedKey("NumpadAdd"))
            this.ConMap.Set("NumpadAdd", con)

            PosY += 30
            PosX := 20
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "CapsLock")
            con.OnEvent("Click", (*) => this.OnCheckedKey("CapsLock"))
            this.ConMap.Set("CapsLock", con)

            PosX += 90
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "a")
            con.OnEvent("Click", (*) => this.OnCheckedKey("a"))
            this.ConMap.Set("a", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "s")
            con.OnEvent("Click", (*) => this.OnCheckedKey("s"))
            this.ConMap.Set("s", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "d")
            con.OnEvent("Click", (*) => this.OnCheckedKey("d"))
            this.ConMap.Set("d", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "f")
            con.OnEvent("Click", (*) => this.OnCheckedKey("f"))
            this.ConMap.Set("f", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "g")
            con.OnEvent("Click", (*) => this.OnCheckedKey("g"))
            this.ConMap.Set("g", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "h")
            con.OnEvent("Click", (*) => this.OnCheckedKey("h"))
            this.ConMap.Set("h", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "j")
            con.OnEvent("Click", (*) => this.OnCheckedKey("j"))
            this.ConMap.Set("j", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "k")
            con.OnEvent("Click", (*) => this.OnCheckedKey("k"))
            this.ConMap.Set("k", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "l")
            con.OnEvent("Click", (*) => this.OnCheckedKey("l"))
            this.ConMap.Set("l", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), ";")
            con.OnEvent("Click", (*) => this.OnCheckedKey(";"))
            this.ConMap.Set(";", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "'")
            con.OnEvent("Click", (*) => this.OnCheckedKey("'"))
            this.ConMap.Set("'", con)

            PosX += 75
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "Enter")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Enter"))
            this.ConMap.Set("Enter", con)

            PosX += 360
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "4")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Numpad4"))
            this.ConMap.Set("Numpad4", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "5")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Numpad5"))
            this.ConMap.Set("Numpad5", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "6")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Numpad6"))
            this.ConMap.Set("Numpad6", con)

            PosY += 30
            PosX := 20
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "LShift")
            con.OnEvent("Click", (*) => this.OnCheckedKey("LShift"))
            this.ConMap.Set("LShift", con)

            PosX += 110
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "z")
            con.OnEvent("Click", (*) => this.OnCheckedKey("z"))
            this.ConMap.Set("z", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "x")
            con.OnEvent("Click", (*) => this.OnCheckedKey("x"))
            this.ConMap.Set("x", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "c")
            con.OnEvent("Click", (*) => this.OnCheckedKey("c"))
            this.ConMap.Set("c", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "v")
            con.OnEvent("Click", (*) => this.OnCheckedKey("v"))
            this.ConMap.Set("v", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "b")
            con.OnEvent("Click", (*) => this.OnCheckedKey("b"))
            this.ConMap.Set("b", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "n")
            con.OnEvent("Click", (*) => this.OnCheckedKey("n"))
            this.ConMap.Set("n", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "m")
            con.OnEvent("Click", (*) => this.OnCheckedKey("m"))
            this.ConMap.Set("m", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), ",")
            con.OnEvent("Click", (*) => this.OnCheckedKey("逗号"))
            this.ConMap.Set("逗号", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), ".")
            con.OnEvent("Click", (*) => this.OnCheckedKey("."))
            this.ConMap.Set(".", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "/")
            con.OnEvent("Click", (*) => this.OnCheckedKey("/"))
            this.ConMap.Set("/", con)

            PosX += 100
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "RShift")
            con.OnEvent("Click", (*) => this.OnCheckedKey("RShift"))
            this.ConMap.Set("RShift", con)

            PosX += 200
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "↑")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Up"))
            this.ConMap.Set("Up", con)

            PosX += 165
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "1")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Numpad1"))
            this.ConMap.Set("Numpad1", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "2")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Numpad2"))
            this.ConMap.Set("Numpad2", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "3")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Numpad3"))
            this.ConMap.Set("Numpad3", con)

            PosX += 50
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "Enter")
            con.OnEvent("Click", (*) => this.OnCheckedKey("NumpadEnter"))
            this.ConMap.Set("NumpadEnter", con)

            PosY += 30
            PosX := 20
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "LCtrl")
            con.OnEvent("Click", (*) => this.OnCheckedKey("LCtrl"))
            this.ConMap.Set("LCtrl", con)

            PosX += 75
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "LWin")
            con.OnEvent("Click", (*) => this.OnCheckedKey("LWin"))
            this.ConMap.Set("LWin", con)

            PosX += 75
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "LAlt")
            con.OnEvent("Click", (*) => this.OnCheckedKey("LAlt"))
            this.ConMap.Set("LAlt", con)

            PosX += 100
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "Space")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Space"))
            this.ConMap.Set("Space", con)

            PosX += 100
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "RAlt")
            con.OnEvent("Click", (*) => this.OnCheckedKey("RAlt"))
            this.ConMap.Set("RAlt", con)

            PosX += 75
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "RWin")
            con.OnEvent("Click", (*) => this.OnCheckedKey("RWin"))
            this.ConMap.Set("RWin", con)

            PosX += 75
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "AppsKey")
            con.OnEvent("Click", (*) => this.OnCheckedKey("AppsKey"))
            this.ConMap.Set("AppsKey", con)

            PosX += 100
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "RCtrl")
            con.OnEvent("Click", (*) => this.OnCheckedKey("RCtrl"))
            this.ConMap.Set("RCtrl", con)

            PosX += 185
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "←")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Left"))
            this.ConMap.Set("Left", con)

            PosX += 75
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "↓")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Down"))
            this.ConMap.Set("Down", con)

            PosX += 75
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "→")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Right"))
            this.ConMap.Set("Right", con)

            PosX += 90
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "0")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Numpad0"))
            this.ConMap.Set("Numpad0", con)

            PosX += 100
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "Del")
            con.OnEvent("Click", (*) => this.OnCheckedKey("NumpadDot"))
            this.ConMap.Set("NumpadDot", con)

            PosY += 30
            PosX := 20
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "Ctrl")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Ctrl"))
            this.ConMap.Set("Ctrl", con)

            PosX += 75
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "Win")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Win"))
            this.ConMap.Set("Win", con)

            PosX += 75
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "Shift")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Shift"))
            this.ConMap.Set("Shift", con)

            PosX += 75
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "Alt")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Alt"))
            this.ConMap.Set("Alt", con)

            PosY += 30
            PosX := 20
            MyGui.Add("Text", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("多媒体键"))

            PosY += 15
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("后退"))
            con.OnEvent("Click", (*) => this.OnCheckedKey("Browser_Back"))
            this.ConMap.Set("Browser_Back", con)

            PosX += 60
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("前进"))
            con.OnEvent("Click", (*) => this.OnCheckedKey("Browser_Forward"))
            this.ConMap.Set("Browser_Forward", con)

            PosX += 60
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("刷新"))
            con.OnEvent("Click", (*) => this.OnCheckedKey("Browser_Refresh"))
            this.ConMap.Set("Browser_Refresh", con)

            PosX += 60
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("停止"))
            con.OnEvent("Click", (*) => this.OnCheckedKey("Browser_Stop"))
            this.ConMap.Set("Browser_Stop", con)

            PosX += 60
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("搜索"))
            con.OnEvent("Click", (*) => this.OnCheckedKey("Browser_Search"))
            this.ConMap.Set("Browser_Search", con)

            PosX += 60
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("收藏夹"))
            con.OnEvent("Click", (*) => this.OnCheckedKey("Browser_Favorites"))
            this.ConMap.Set("Browser_Favorites", con)

            PosX += 75
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("主页"))
            con.OnEvent("Click", (*) => this.OnCheckedKey("Browser_Home"))
            this.ConMap.Set("Browser_Home", con)

            PosX += 60
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("静音"))
            con.OnEvent("Click", (*) => this.OnCheckedKey("Volume_Mute"))
            this.ConMap.Set("Volume_Mute", con)

            PosX += 60
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("调低音量"))
            con.OnEvent("Click", (*) => this.OnCheckedKey("Volume_Down"))
            this.ConMap.Set("Volume_Down", con)

            PosX += 90
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("增加音量"))
            con.OnEvent("Click", (*) => this.OnCheckedKey("Volume_Up"))
            this.ConMap.Set("Volume_Up", con)

            PosX += 90
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("下一首"))
            con.OnEvent("Click", (*) => this.OnCheckedKey("Media_Next"))
            this.ConMap.Set("Media_Next", con)

            PosX += 75
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("上一首"))
            con.OnEvent("Click", (*) => this.OnCheckedKey("Media_Prev"))
            this.ConMap.Set("Media_Prev", con)

            PosX += 75
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("停止"))
            con.OnEvent("Click", (*) => this.OnCheckedKey("Media_Stop"))
            this.ConMap.Set("Media_Stop", con)

            PosX += 60
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("播放/暂停"))
            con.OnEvent("Click", (*) => this.OnCheckedKey("Media_Play_Pause"))
            this.ConMap.Set("Media_Play_Pause", con)

            PosX += 90
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("此电脑"))
            con.OnEvent("Click", (*) => this.OnCheckedKey("Launch_App1"))
            this.ConMap.Set("Launch_App1", con)

            PosX += 75
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("计算器"))
            con.OnEvent("Click", (*) => this.OnCheckedKey("Launch_App2"))
            this.ConMap.Set("Launch_App2", con)

            PosY += 30
            PosX := 20
            MyGui.Add("Text", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("鼠标"))

            PosY += 15
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("左键"))
            con.OnEvent("Click", (*) => this.OnCheckedKey("LButton"))
            this.ConMap.Set("LButton", con)

            PosX += 60
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("中键"))
            con.OnEvent("Click", (*) => this.OnCheckedKey("MButton"))
            this.ConMap.Set("MButton", con)

            PosX += 60
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("右键"))
            con.OnEvent("Click", (*) => this.OnCheckedKey("RButton"))
            this.ConMap.Set("RButton", con)

            PosX += 60
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("下滚轮"))
            con.OnEvent("Click", (*) => this.OnCheckedKey("WheelDown"))
            this.ConMap.Set("WheelDown", con)

            PosX += 70
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("上滚轮"))
            con.OnEvent("Click", (*) => this.OnCheckedKey("WheelUp"))
            this.ConMap.Set("WheelUp", con)

            PosX += 70
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("滚轮左键"))
            con.OnEvent("Click", (*) => this.OnCheckedKey("WheelLeft"))
            this.ConMap.Set("WheelLeft", con)

            PosX += 85
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("滚轮右键"))
            con.OnEvent("Click", (*) => this.OnCheckedKey("WheelRight"))
            this.ConMap.Set("WheelRight", con)

            PosX += 85
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("侧键1"))
            con.OnEvent("Click", (*) => this.OnCheckedKey("XButton1"))
            this.ConMap.Set("XButton1", con)

            PosX += 70
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("侧键2"))
            con.OnEvent("Click", (*) => this.OnCheckedKey("XButton2"))
            this.ConMap.Set("XButton2", con)

            PosY += 30
            PosX := 20
            MyGui.Add("Text", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("手柄"))

            PosY += 15
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("按钮") "1")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Joy1"))
            this.ConMap.Set("Joy1", con)

            PosX += 70
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("按钮") "2")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Joy2"))
            this.ConMap.Set("Joy2", con)

            PosX += 70
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("按钮") "3")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Joy3"))
            this.ConMap.Set("Joy3", con)

            PosX += 70
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("按钮") "4")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Joy4"))
            this.ConMap.Set("Joy4", con)

            PosX += 70
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("按钮") "5")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Joy5"))
            this.ConMap.Set("Joy5", con)

            PosX += 70
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("按钮") "6")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Joy6"))
            this.ConMap.Set("Joy6", con)

            PosX += 70
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("按钮") "7")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Joy7"))
            this.ConMap.Set("Joy7", con)

            PosX += 70
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("按钮") "8")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Joy8"))
            this.ConMap.Set("Joy8", con)

            PosX += 70
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("按钮") "9")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Joy9"))
            this.ConMap.Set("Joy9", con)

            PosX += 70
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("按钮") "10")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Joy10"))
            this.ConMap.Set("Joy10", con)

            PosX += 70
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("按钮") "11")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Joy11"))
            this.ConMap.Set("Joy11", con)

            PosX += 70
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("按钮") "12")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Joy12"))
            this.ConMap.Set("Joy12", con)

            PosX += 70
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("按钮") "13")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Joy13"))
            this.ConMap.Set("Joy13", con)

            PosX += 70
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("按钮") "14")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Joy14"))
            this.ConMap.Set("Joy14", con)

            PosX += 70
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("按钮") "15")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Joy15"))
            this.ConMap.Set("Joy15", con)

            PosX += 70
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("按钮") "16")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Joy16"))
            this.ConMap.Set("Joy16", con)

            PosY += 30
            PosX := 20
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("按钮") "17")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Joy17"))
            this.ConMap.Set("Joy17", con)

            PosX += 70
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("按钮") "18")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Joy18"))
            this.ConMap.Set("Joy18", con)

            PosX += 70
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("按钮") "19")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Joy19"))
            this.ConMap.Set("Joy19", con)

            PosX += 70
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("按钮") "20")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Joy20"))
            this.ConMap.Set("Joy20", con)

            PosX += 70
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("按钮") "21")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Joy21"))
            this.ConMap.Set("Joy21", con)

            PosX += 70
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("按钮") "22")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Joy22"))
            this.ConMap.Set("Joy22", con)

            PosX += 70
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("按钮") "23")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Joy23"))
            this.ConMap.Set("Joy23", con)

            PosX += 70
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("按钮") "24")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Joy24"))
            this.ConMap.Set("Joy24", con)

            PosX += 70
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("按钮") "25")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Joy25"))
            this.ConMap.Set("Joy25", con)

            PosX += 70
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("按钮") "26")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Joy26"))
            this.ConMap.Set("Joy26", con)

            PosX += 70
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("按钮") "27")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Joy27"))
            this.ConMap.Set("Joy27", con)

            PosX += 70
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("按钮") "28")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Joy28"))
            this.ConMap.Set("Joy28", con)

            PosX += 70
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("按钮") "29")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Joy29"))
            this.ConMap.Set("Joy29", con)

            PosX += 70
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("按钮") "30")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Joy30"))
            this.ConMap.Set("Joy30", con)

            PosX += 70
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("按钮") "31")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Joy31"))
            this.ConMap.Set("Joy31", con)

            PosX += 70
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("按钮") "32")
            con.OnEvent("Click", (*) => this.OnCheckedKey("Joy32"))
            this.ConMap.Set("Joy32", con)

            PosY += 30
            PosX := 20
            MyGui.Add("Text", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("摇杆"))

            PosY += 15
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "轴1Min")
            con.OnEvent("Click", (*) => this.OnCheckedKey("JoyAxis1Min"))
            this.ConMap.Set("JoyAxis1Min", con)

            PosX += 85
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "轴1Max")
            con.OnEvent("Click", (*) => this.OnCheckedKey("JoyAxis1Max"))
            this.ConMap.Set("JoyAxis1Max", con)

            PosX += 85
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "轴2Min")
            con.OnEvent("Click", (*) => this.OnCheckedKey("JoyAxis2Min"))
            this.ConMap.Set("JoyAxis2Min", con)

            PosX += 85
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "轴2Max")
            con.OnEvent("Click", (*) => this.OnCheckedKey("JoyAxis2Max"))
            this.ConMap.Set("JoyAxis2Max", con)

            PosX += 85
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "轴3Min")
            con.OnEvent("Click", (*) => this.OnCheckedKey("JoyAxis3Min"))
            this.ConMap.Set("JoyAxis3Min", con)

            PosX += 85
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "轴3Max")
            con.OnEvent("Click", (*) => this.OnCheckedKey("JoyAxis3Max"))
            this.ConMap.Set("JoyAxis3Max", con)

            PosX += 85
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "轴4Min")
            con.OnEvent("Click", (*) => this.OnCheckedKey("JoyAxis4Min"))
            this.ConMap.Set("JoyAxis4Min", con)

            PosX += 85
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "轴4Max")
            con.OnEvent("Click", (*) => this.OnCheckedKey("JoyAxis4Max"))
            this.ConMap.Set("JoyAxis4Max", con)

            PosX += 85
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "轴5Min")
            con.OnEvent("Click", (*) => this.OnCheckedKey("JoyAxis5Min"))
            this.ConMap.Set("JoyAxis5Min", con)

            PosX += 85
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "轴5Max")
            con.OnEvent("Click", (*) => this.OnCheckedKey("JoyAxis5Max"))
            this.ConMap.Set("JoyAxis5Max", con)

            PosX += 85
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "轴6Min")
            con.OnEvent("Click", (*) => this.OnCheckedKey("JoyAxis6Min"))
            this.ConMap.Set("JoyAxis6Min", con)

            PosX += 85
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "轴6Max")
            con.OnEvent("Click", (*) => this.OnCheckedKey("JoyAxis6Max"))
            this.ConMap.Set("JoyAxis6Max", con)

            PosY += 30
            PosX := 20
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "轴7Min")
            con.OnEvent("Click", (*) => this.OnCheckedKey("JoyAxis7Min"))
            this.ConMap.Set("JoyAxis7Min", con)

            PosX += 85
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "轴7Max")
            con.OnEvent("Click", (*) => this.OnCheckedKey("JoyAxis7Max"))
            this.ConMap.Set("JoyAxis7Max", con)

            PosX += 85
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "轴8Min")
            con.OnEvent("Click", (*) => this.OnCheckedKey("JoyAxis8Min"))
            this.ConMap.Set("JoyAxis8Min", con)

            PosX += 85
            con := MyGui.Add("Checkbox", Format("x{} y{} h{}", PosX, PosY, 20), "轴8Max")
            con.OnEvent("Click", (*) => this.OnCheckedKey("JoyAxis8Max"))
            this.ConMap.Set("JoyAxis8Max", con)

        }

        PosY += 40
        PosX := 100
        MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 50), GetLang("类型:"))
        PosX += 50
        this.KeyTypeCon := MyGui.Add("DropDownList", Format("x{} y{} w{} h{}", PosX, PosY - 3, 80, 100), GetLangArr([
            "按下",
            "松开", "点击"]))
        this.KeyTypeCon.OnEvent("Change", (*) => this.OnChangeEditValue())
        this.KeyTypeCon.Value := 1

        PosX += 130
        MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 90), GetLang("点击时长:"))
        PosX += 70
        this.HoldTimeCon := MyGui.Add("Edit", Format("x{} y{} w{} Center", PosX, PosY - 5, 50), 50)
        this.HoldTimeCon.OnEvent("Change", (*) => this.OnChangeEditValue())

        PosX += 130
        MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 90), GetLang("点击次数:"))
        PosX += 70
        this.KeyCountCon := MyGui.Add("Edit", Format("x{} y{} w{} Center", PosX, PosY - 5, 50), 1)
        this.KeyCountCon.OnEvent("Change", (*) => this.OnChangeEditValue())

        PosX += 130
        MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 90), GetLang("每次间隔:"))
        PosX += 70
        this.PerIntervalCon := MyGui.Add("Edit", Format("x{} y{} w{} Center", PosX, PosY - 5, 50), 100)
        this.PerIntervalCon.OnEvent("Change", (*) => this.OnChangeEditValue())

        PosX += 130
        this.CommandStrCon := MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 300), GetLang("当前指令：无"))

        PosY += 40
        PosX := 300
        btnCon := MyGui.Add("Button", Format("x{} y{} h{} w{} center", PosX, PosY, 40, 100), GetLang("清空"))
        btnCon.OnEvent("Click", (*) => this.ClearCheckedBox())

        PosX += 450
        btnCon := MyGui.Add("Button", Format("x{} y{} h{} w{} center", PosX, PosY, 40, 100), GetLang("确定"))
        btnCon.OnEvent("Click", (*) => this.OnSureBtnClick())

        MyGui.Show(Format("w{} h{}", 1280, 640))
    }

    ShowGui(cmd) {
        if (this.Gui != "") {
            this.Gui.Show()
        }
        else {
            this.AddGui()
        }

        this.Init(cmd)
        this.Refresh()
        this.ToggleFunc(true)
    }

    Init(cmd) {
        cmdArr := cmd != "" ? SplitKeyCommand(cmd) : []
        this.KeyStr := cmdArr.Length >= 2 ? cmdArr[2] : ""
        this.KeyTypeCon.Value := cmdArr.Length >= 3 ? cmdArr[3] : 3
        this.HoldTimeCon.Value := cmdArr.Length >= 4 ? cmdArr[4] : 100
        this.KeyCountCon.Value := cmdArr.Length >= 5 ? cmdArr[5] : 1
        this.PerIntervalCon.Value := cmdArr.Length >= 6 ? cmdArr[6] : 200

        this.RefreshCheckBox(this.KeyStr)
    }

    RefreshCheckBox(KeyArrStr) {
        this.CheckedBox := GetPressKeyArr(KeyArrStr)

        for key, value in this.ConMap {
            value.Opt("-Background")
            value.Value := 0
        }

        for index, value in this.CheckedBox {
            if (this.ConMap.Has(value)) {
                con := this.ConMap.Get(value)
                con.Opt("Background" "0x4cae50")
                con.Value := 1
            }

        }
    }

    ToggleFunc(state) {
        MacroAction := (*) => this.TriggerMacro()
        if (state) {
            Hotkey("F1", MacroAction, "On")
        }
        else {
            Hotkey("F1", MacroAction, "Off")
        }
    }

    TriggerMacro() {
        valid := this.CheckIfValid()
        if (!valid)
            return

        this.UpdateCommandStr()
        tableItem := MySoftData.SpecialTableItem
        tableItem.KilledArr[1] := false
        tableItem.PauseArr[1] := 0
        tableItem.ActionCount[1] := 0
        tableItem.VariableMapArr[1] := Map()
        tableItem.index := 1

        OnPressKey(tableItem, this.CommandStr, 1)
    }

    CheckIfValid() {
        if (this.KeyStr == "") {
            MsgBox(GetLang("请选择按键！"))
            return false
        }

        if (!IsInteger(this.KeyCountCon.Value) || Integer(this.KeyCountCon.Value) <= 0) {
            MsgBox(GetLang("按键次数必须为大于零的整数！"))
            return false
        }

        return true
    }

    UpdateCommandStr() {
        isShowHoldTime := this.KeyTypeCon.Value == 3
        isShowCount := isShowHoldTime && this.KeyCountCon.Value != 1
        isShowInterval := isShowCount && this.PerIntervalCon.Value != 0

        CommandStr := GetLang("按键")
        CommandStr .= "_" this.KeyStr
        CommandStr .= "_" this.KeyTypeCon.Value
        if (isShowHoldTime) {
            CommandStr .= "_" this.HoldTimeCon.Value
        }
        if (isShowCount) {
            CommandStr .= "_" this.KeyCountCon.Value
        }
        if (isShowInterval) {
            CommandStr .= "_" this.PerIntervalCon.Value
        }

        this.CommandStr := CommandStr
    }

    OnChangeEditValue() {
        this.Refresh()
    }

    Refresh() {
        this.KeyStr := this.GetTriggerKey()
        this.UpdateCommandStr()

        isShowHoldTime := this.KeyTypeCon.Value == 3
        isShowCount := isShowHoldTime && this.KeyCountCon.Value != 1
        isShowInterval := isShowCount && this.PerIntervalCon.Value != 0

        this.HoldTimeCon.Enabled := isShowHoldTime
        this.KeyCountCon.Enabled := isShowHoldTime
        this.PerIntervalCon.Enabled := isShowCount
        this.CommandStrCon.Value := Format("{}{}", GetLang("当前指令："), this.CommandStr)
    }
}
