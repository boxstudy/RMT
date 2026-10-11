#Requires AutoHotkey v2.0

; 倒计时浮层：与 MinTool\CountDown 相同（置顶、无标题、点击穿透）
global CountDownAlive := Map()

OnCountDown(tableItem, cmd, index) {
    paramArr := StrSplit(cmd, "_")
    Data := GetMacroCMDData(paramArr[1])
    if (!IsObject(Data))
        return
    TimeExecCountDown(tableItem, index, Data)
}

TimeExecCountDown(tableItem, index, Data) {
    total := CountDownTotal(tableItem, index, Data)
    if (total <= 0)
        return

    posX := CountDownNum(tableItem, index, Data.PosX, 200)
    posY := CountDownNum(tableItem, index, Data.PosY, 200)
    fontSize := CountDownStyleFontSize()
    alpha := CountDownWinAlpha(CountDownStyleAlpha())

    CountDownReplaceAt(posX, posY)
    ov := CountDownOverlay()
    ov.Start(total, posX, posY, fontSize, CountDownThemeRgb("text"), CountDownThemeRgb("bg"), alpha)

    if (GetLangKey(Data.WaitEnd) == "不等待")
        return

    while (ov.Running) {
        item := tableItem.Items[index]
        if (item.Killed) {
            ov.Close()
            return
        }
        WaitIfPaused(tableItem, index)
        if (item.Killed) {
            ov.Close()
            return
        }
        Sleep(50)
    }
}

CountDownPosKey(posX, posY) {
    return Integer(posX) ":" Integer(posY)
}

CountDownWinTitle(key) {
    return "RMTCountDown:" key
}

CountDownReplaceAt(posX, posY) {
    global CountDownAlive
    key := CountDownPosKey(posX, posY)
    if (CountDownAlive.Has(key)) {
        old := CountDownAlive[key]
        CountDownAlive.Delete(key)
        try old.Close()
    }
    title := CountDownWinTitle(key)
    prev := A_DetectHiddenWindows
    DetectHiddenWindows(true)
    try {
        loop 8 {
            hwnd := WinExist(title)
            if (!hwnd)
                break
            try WinClose("ahk_id " hwnd)
            Sleep(10)
        }
    } finally {
        DetectHiddenWindows(prev)
    }
}

CountDownNum(tableItem, index, raw, def) {
    v := GetReplaceVarText(tableItem, index, raw)
    return IsNumber(v) ? Integer(v) : def
}

CountDownKind(Data) {
    if (!IsObject(Data) || !ObjHasOwnProp(Data, "Param2") || Trim(String(Data.Param2)) == "")
        return "时长"
    return TimeNormWaitType(Data.Param2)
}

CountDownTotal(tableItem, index, Data) {
    kind := CountDownKind(Data)
    if (kind == "时刻") {
        raw := (ObjHasOwnProp(Data, "Param1") && Data.Param1 != "") ? Data.Param1 : (Data.Hour ":" Data.Min ":" Data.Sec)
        target := TimeParseDateTime(TimeResolveClock(tableItem, index, raw))
        if (target == "")
            return 0
        d := DateDiff(target, A_Now, "Seconds")
        return d > 0 ? d : 0
    }
    if (kind == "时间戳") {
        val := GetReplaceVarText(tableItem, index, ObjHasOwnProp(Data, "Param1") ? Data.Param1 : "")
        target := TimeParseDateTime(val)
        if (target == "")
            return 0
        d := DateDiff(target, A_Now, "Seconds")
        return d > 0 ? d : 0
    }
    if (ObjHasOwnProp(Data, "Hour") || ObjHasOwnProp(Data, "Min") || ObjHasOwnProp(Data, "Sec")) {
        h := CountDownNum(tableItem, index, ObjHasOwnProp(Data, "Hour") ? Data.Hour : 0, 0)
        m := CountDownNum(tableItem, index, ObjHasOwnProp(Data, "Min") ? Data.Min : 0, 0)
        s := CountDownNum(tableItem, index, ObjHasOwnProp(Data, "Sec") ? Data.Sec : 0, 0)
        total := h * 3600 + m * 60 + s
        if (total > 0)
            return total
    }
    return CountDownNum(tableItem, index, Data.Seconds, 0)
}

CountDownWinAlpha(pct) {
    if (pct > 100)
        pct := Round(pct * 100 / 255)
    if (pct < 0)
        pct := 0
    if (pct > 100)
        pct := 100
    return Round(pct * 255 / 100)
}

CountDownUiAlpha(raw) {
    al := IsNumber(raw) ? Integer(raw) : 70
    if (al > 100)
        al := Round(al * 100 / 255)
    if (al < 0)
        al := 0
    if (al > 100)
        al := 100
    return al
}

CountDownStyleFontSize() {
    global MainSoftData
    v := 15
    try {
        if (IsSet(MainSoftData) && MainSoftData.HasProp("CountDownFontSize") && IsNumber(MainSoftData.CountDownFontSize))
            v := Integer(MainSoftData.CountDownFontSize)
    }
    if (v < 8)
        v := 8
    if (v > 72)
        v := 72
    return v
}

CountDownStyleAlpha() {
    global MainSoftData
    v := 70
    try {
        if (IsSet(MainSoftData) && MainSoftData.HasProp("CountDownAlpha"))
            v := CountDownUiAlpha(MainSoftData.CountDownAlpha)
    }
    return v
}

CountDownEnsureTheme() {
    static ready := false
    if (ready)
        return
    try {
        if (IsSet(MainSoftData) && IsObject(MainSoftData.ThemeColors) && MainSoftData.ThemeColors.Count > 0) {
            AppThemeUtil.ApplyToRuntime(MainSoftData.ThemeColors)
            ready := true
            return
        }
        AppThemeUtil.LoadFromToml()
        ready := true
    }
}

CountDownThemeRgb(kind) {
    CountDownEnsureTheme()
    def := (kind == "text") ? "1A1A1A" : "F0F0F0"
    try {
        v := (kind == "text") ? MainSoftData.CMDFontColor : MainSoftData.CMDBGColor
        v := StrUpper(StrReplace(Trim(String(v)), "#", ""))
        if (StrLen(v) == 8)
            v := SubStr(v, 3)
        if (RegExMatch(v, "^[0-9A-F]{6}$"))
            return v
    }
    return def
}

CountDownHex(val, def) {
    s := StrUpper(Trim(String(val)))
    s := StrReplace(s, "#", "")
    if (!RegExMatch(s, "^[0-9A-F]{6}$"))
        return def
    return s
}

CountDownStyleKind() {
    global MainSoftData
    v := 2
    try {
        if (IsSet(MainSoftData) && MainSoftData.HasProp("CountDownStyle") && IsNumber(MainSoftData.CountDownStyle))
            v := Integer(MainSoftData.CountDownStyle)
    }
    if (v < 1 || v > 3)
        v := 2
    return v
}

CountDownPadEnabled() {
    global MainSoftData
    try {
        if (IsSet(MainSoftData) && MainSoftData.HasProp("CountDownPadZero"))
            return !!MainSoftData.CountDownPadZero
    }
    return true
}

CountDownPart(n, pad) {
    n := Integer(n)
    return pad ? Format("{:02}", n) : String(n)
}

CountDownFormatMode(sec) {
    sec := Integer(sec)
    if (sec < 0)
        sec := 0
    switch CountDownStyleKind() {
        case 1:
            return "hhmmss"
        case 3:
            return "ss"
        default:
            if (sec >= 3600)
                return "hhmmss"
            if (sec >= 60)
                return "mmss"
            return "ss"
    }
}

CountDownFormatText(sec, mode := "") {
    sec := Integer(sec)
    if (sec < 0)
        sec := 0
    if (mode == "")
        mode := CountDownFormatMode(sec)
    if (mode == "ss")
        return String(sec)
    pad := CountDownPadEnabled()
    if (mode == "ddhhmmss") {
        d := Floor(sec / 86400)
        h := Floor(Mod(sec, 86400) / 3600)
        m := Floor(Mod(sec, 3600) / 60)
        s := Mod(sec, 60)
        return CountDownPart(d, pad) ":" CountDownPart(h, pad) ":" CountDownPart(m, pad) ":" CountDownPart(s, pad)
    }
    if (mode == "hhmmss")
        return CountDownPart(Floor(sec / 3600), pad) ":" CountDownPart(Floor(Mod(sec, 3600) / 60), pad) ":" CountDownPart(Mod(sec, 60), pad)
    if (mode == "mmss")
        return CountDownPart(Floor(sec / 60), pad) ":" CountDownPart(Mod(sec, 60), pad)
    return String(sec)
}

CountDownOverlaySize(mode) {
    switch mode {
        case "ddhhmmss":
            return [260, 50]
        case "hhmmss":
            return [200, 50]
        case "mmss":
            return [130, 50]
        default:
            return [70, 50]
    }
}

class CountDownOverlay {
    __New() {
        this.Running := false
        this.gui := ""
        this.txt := ""
        this.tickFn := ""
        this.aliveId := 0
        this.posKey := ""
        this.remaining := 0
        this.displayType := "ss"
    }

    Start(total, posX, posY, fontSize, textColor, bg, alpha) {
        global CountDownAlive
        this.remaining := total
        this.posKey := CountDownPosKey(posX, posY)
        this.displayType := CountDownFormatMode(total)
        sz := CountDownOverlaySize(this.displayType)
        width := sz[1], height := sz[2]

        g := Gui()
        g.Title := CountDownWinTitle(this.posKey)
        g.Opt("+AlwaysOnTop -Caption +ToolWindow +E0x20")
        g.BackColor := bg
        g.SetFont("s" fontSize " c" textColor, "Consolas")
        this.txt := g.AddText("x0 y0 w" width " h" height " Center", CountDownFormatText(total))
        WinSetTransparent(alpha, g.Hwnd)
        g.Show("x" posX " y" posY " w" width " h" height " NoActivate")
        this.gui := g
        this.Running := true
        this.tickFn := ObjBindMethod(this, "Tick")
        this.aliveId := this.posKey
        CountDownAlive[this.posKey] := this
        SetTimer(this.tickFn, 1000)
    }

    Tick(*) {
        if (!this.Running)
            return
        try {
            if (!IsObject(this.gui) || !WinExist("ahk_id " this.gui.Hwnd)) {
                this.Close()
                return
            }
        }
        this.remaining -= 1
        if (this.remaining < 0) {
            this.Close()
            return
        }
        this.displayType := CountDownFormatMode(this.remaining)
        try this.txt.Text := CountDownFormatText(this.remaining)
    }

    Close(*) {
        global CountDownAlive
        if (!this.Running)
            return
        this.Running := false
        if (this.tickFn != "")
            SetTimer(this.tickFn, 0)
        try this.gui.Destroy()
        catch {
        }
        this.gui := ""
        this.txt := ""
        if (this.posKey != "" && CountDownAlive.Has(this.posKey) && CountDownAlive[this.posKey] == this)
            CountDownAlive.Delete(this.posKey)
    }
}
