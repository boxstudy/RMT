#Requires AutoHotkey v2.0

; 倒计时浮层：与 MinTool\CountDown 相同（置顶、无标题、点击穿透）
global CountDownAlive := Map()
global CountDownAliveSeq := 0

OnCountDown(tableItem, cmd, index) {
    paramArr := StrSplit(cmd, "_")
    Data := GetMacroCMDData(paramArr[1])
    if (!IsObject(Data))
        return

    total := CountDownTotal(tableItem, index, Data)
    if (total <= 0)
        return

    posX := CountDownNum(tableItem, index, Data.PosX, 200)
    posY := CountDownNum(tableItem, index, Data.PosY, 200)
    fontSize := CountDownNum(tableItem, index, Data.FontSize, 32)
    if (fontSize < 8)
        fontSize := 8
    alpha := CountDownWinAlpha(CountDownNum(tableItem, index, Data.Alpha, 70))

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

CountDownNum(tableItem, index, raw, def) {
    v := GetReplaceVarText(tableItem, index, raw)
    return IsNumber(v) ? Integer(v) : def
}

CountDownTotal(tableItem, index, Data) {
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

CountDownFormatText(sec, mode) {
    switch mode {
        case "ddhhmmss":
            d := Floor(sec / 86400)
            h := Floor(Mod(sec, 86400) / 3600)
            m := Floor(Mod(sec, 3600) / 60)
            s := Mod(sec, 60)
            return Format("{:02}:{:02}:{:02}:{:02}", d, h, m, s)
        case "hhmmss":
            return Format("{:02}:{:02}:{:02}", Floor(sec / 3600), Floor(Mod(sec, 3600) / 60), Mod(sec, 60))
        case "mmss":
            return Format("{:02}:{:02}", Floor(sec / 60), Mod(sec, 60))
        default:
            return String(sec)
    }
}

class CountDownOverlay {
    __New() {
        this.Running := false
        this.gui := ""
        this.txt := ""
        this.tickFn := ""
        this.aliveId := 0
        this.remaining := 0
        this.displayType := "ss"
    }

    Start(total, posX, posY, fontSize, textColor, bg, alpha) {
        global CountDownAlive, CountDownAliveSeq
        this.remaining := total
        if (total >= 86400) {
            this.displayType := "ddhhmmss"
            width := 260, height := 50
        } else if (total >= 3600) {
            this.displayType := "hhmmss"
            width := 200, height := 50
        } else if (total >= 60) {
            this.displayType := "mmss"
            width := 130, height := 50
        } else {
            this.displayType := "ss"
            width := 70, height := 50
        }

        g := Gui()
        g.Opt("+AlwaysOnTop -Caption +ToolWindow +E0x20")
        g.BackColor := bg
        g.SetFont("s" fontSize " c" textColor, "Consolas")
        this.txt := g.AddText("x0 y0 w" width " h" height " Center", CountDownFormatText(total, this.displayType))
        WinSetTransparent(alpha, g.Hwnd)
        g.Show("x" posX " y" posY " w" width " h" height " NoActivate")
        this.gui := g
        this.Running := true
        this.tickFn := ObjBindMethod(this, "Tick")
        CountDownAliveSeq += 1
        this.aliveId := CountDownAliveSeq
        CountDownAlive[this.aliveId] := this
        SetTimer(this.tickFn, 1000)
    }

    Tick(*) {
        if (!this.Running)
            return
        this.remaining -= 1
        if (this.remaining < 0) {
            this.Close()
            return
        }
        try this.txt.Text := CountDownFormatText(this.remaining, this.displayType)
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
        if (this.aliveId && CountDownAlive.Has(this.aliveId))
            CountDownAlive.Delete(this.aliveId)
    }
}
