#Requires AutoHotkey v2.0

class FrontInfoGui {
    __new() {
        this.Gui := ""
        this.InfoAction := () => this.RefreshMouseInfo()
        this.SureAction := ""
        this.frontInfoCon := ""
        this.InfoTogCon := ""
        this.TopTogCon := ""
        this.WinInfoCon := ""
        this.InfoTogArrCon := []
        this.InfoTextArrCon := []
    }

    ShowGui(frontInfoCon) {
        if (this.Gui != "") {
            this.Gui.Show()
        }
        else {
            this.AddGui()
        }
        this.Init(frontInfoCon)
        this.ToggleFunc(true)
    }

    Init(frontInfoCon) {
        this.frontInfoCon := frontInfoCon
        this.TopTogCon.Value := true
        infoStr := frontInfoCon.Value
        if (infoStr != "")
            infoArr := StrSplit(infoStr, "⎖")
        if (infoStr == "" || infoArr.Length != 3)
            infoArr := ["", "", ""]

        loop 3 {
            this.InfoTogArrCon[A_Index].Value := infoArr[A_Index] != ""
            this.InfoTextArrCon[A_Index].Value := infoArr[A_Index]
        }

        this.OnTogClick()
    }

    AddGui() {
        MyGui := Gui(, GetLang("前台信息编辑器"))
        this.Gui := MyGui
        MyGui.SetFont("S11 W550 Q2", MySoftData.FontType)
        PosX := 10
        PosY := 10

        PosX := 10
        con := MyGui.Add("Checkbox", Format("x{} y{}", PosX, PosY), GetLang("窗口置顶"))
        con.OnEvent("Click", this.OnTogClick.Bind(this))
        this.TopTogCon := con

        PosX := 160
        con := MyGui.Add("Edit", Format("x{} y{}", PosX, PosY - 5), "F1")
        con.Enabled := false
        PosX += 30
        MyGui.Add("Text", Format("x{} y{}", PosX, PosY), GetLang("确定信息"))

        PosY += 30
        PosX := 10
        MyGui.Add("Text", Format("x{} y{}", PosX, PosY), GetLang("当前鼠标下窗口信息："))

        PosY += 25
        PosX := 10
        this.WinInfoCon := MyGui.Add("Text", Format("x{} y{} w500 h90", PosX, PosY))

        PosY += 95
        PosX := 20
        con := MyGui.Add("Checkbox", Format("x{} y{}", PosX, PosY), GetLang("标题"))
        con.OnEvent("Click", this.OnTogClick.Bind(this))
        this.InfoTogArrCon.Push(con)
        PosX := 95
        con := MyGui.Add("Edit", Format("x{} y{} w320", PosX, PosY - 3), "")
        this.InfoTextArrCon.Push(con)

        PosY += 35
        PosX := 20
        con := MyGui.Add("Checkbox", Format("x{} y{}", PosX, PosY), GetLang("窗口类"))
        con.OnEvent("Click", this.OnTogClick.Bind(this))
        this.InfoTogArrCon.Push(con)
        PosX := 95
        con := MyGui.Add("Edit", Format("x{} y{} w320", PosX, PosY - 3), "")
        this.InfoTextArrCon.Push(con)

        PosY += 35
        PosX := 20
        con := MyGui.Add("Checkbox", Format("x{} y{}", PosX, PosY), GetLang("进程名"))
        con.OnEvent("Click", this.OnTogClick.Bind(this))
        this.InfoTogArrCon.Push(con)
        PosX := 95
        con := MyGui.Add("Edit", Format("x{} y{} w320", PosX, PosY - 3), "")
        this.InfoTextArrCon.Push(con)

        PosY += 30
        PosX := 20
        MyGui.Add("Text", Format("x{} y{}", PosX, PosY), GetLang("提示：宏仅当鼠标悬停窗口符合上述条件时触发"))

        PosX := 200
        PosY += 40
        con := MyGui.Add("Button", Format("x{} y{} w100 h40", PosX, PosY), GetLang("确定"))
        con.OnEvent("Click", (*) => this.OnSureBtnClick())
        MyGui.OnEvent("Close", (*) => this.ToggleFunc(false))
        MyGui.Show(Format("w{} h{}", 500, 360))
    }

    RefreshMouseInfo() {
        CoordMode("Mouse", "Screen")
        MouseGetPos &mouseX, &mouseY, &winId
        try {
            title := WinGetTitle(winId)
            className := WinGetClass(winId)
            process := WinGetProcessName(winId)
            tipStr := Format("{}{}`n{}{}`n{}{}", GetLang("标题："), title, GetLang("窗口类："), className, GetLang("进程名："),
            process)
            this.WinInfoCon.Value := tipStr
        }
    }

    ToggleFunc(state) {
        if (state) {
            SetTimer this.InfoAction, 100
            Hotkey("F1", (*) => this.OnF1(), "On")
        }
        else {
            SetTimer this.InfoAction, 0
            Hotkey("F1", (*) => this.OnF1(), "Off")
        }
    }

    CheckIfValid() {
        if (this.InfoTextArrCon[1].Value && this.InfoTextArrCon[1].Value == "") {
            MsgBox(GetLang("勾选标题后，标题内容不能为空"))
            return false
        }

        if (this.InfoTextArrCon[1].Value && this.InfoTextArrCon[1].Value == "") {
            MsgBox(GetLang("勾选窗口类后，窗口类内容不能为空"))
            return false
        }

        if (this.InfoTextArrCon[1].Value && this.InfoTextArrCon[1].Value == "") {
            MsgBox(GetLang("勾选进程名后，进程名内容不能为空"))
            return false
        }
        return true
    }

    GetInfoStr() {
        Str := ""
        loop 3 {
            if (this.InfoTogArrCon[A_Index].Value) {
                Str .= this.InfoTextArrCon[A_Index].Value
            }
            if (A_Index != 3)
                Str .= "⎖"
        }
        if (Str == "⎖⎖")
            return ""
        return Str
    }

    OnSureBtnClick() {
        isValid := this.CheckIfValid()
        if (!isValid)
            return

        this.frontInfoCon.Value := this.GetInfoStr()
        this.ToggleFunc(false)
        this.Gui.Hide()
        if (this.SureAction != "") {
            action := this.SureAction
            action()
            this.SureAction := ""
        }
    }

    OnTogClick(*) {
        if (this.TopTogCon.Value) {
            this.Gui.Opt("+AlwaysOnTop")
        }
        else {
            this.Gui.Opt("-AlwaysOnTop")
        }

        loop 3 {
            Enable := this.InfoTogArrCon[A_Index].Value
            this.InfoTextArrCon[A_Index].Enabled := Enable
        }
    }

    OnF1() {
        CoordMode("Mouse", "Screen")
        MouseGetPos &mouseX, &mouseY, &winId
        try {
            title := WinGetTitle(winId)
            className := WinGetClass(winId)
            process := WinGetProcessName(winId)
            this.InfoTextArrCon[1].Value := title
            this.InfoTextArrCon[2].Value := className
            this.InfoTextArrCon[3].Value := process
            loop 3 {
                this.InfoTogArrCon[A_Index].Value := true
            }
            this.OnTogClick()
        }
    }
}
