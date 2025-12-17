#Requires AutoHotkey v2.0

class RunGui {
    __new() {
        this.ParentTile := ""
        this.Gui := ""
        this.RemarkCon := ""
        this.SureBtnAction := ""
        this.PathTextCon := ""
        this.MouseProNameCon := ""
        this.BackPlayCon := ""

        this.RefreshAction := () => this.RefreshProcessName()
        this.Data := ""
    }

    ShowGui(cmd) {
        if (this.Gui != "") {
            this.Gui.Show()
        }
        else {
            this.AddGui()
        }

        this.Init(cmd)
        this.ToggleFunc(true)
    }

    AddGui() {
        MyGui := Gui(, this.ParentTile GetLang("运行编辑器"))
        this.Gui := MyGui
        MyGui.SetFont("S10 W550 Q2", MySoftData.FontType)

        PosX := 10
        PosY := 10
        MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 80), GetLang("快捷方式:"))
        PosX += 80
        con := MyGui.Add("Hotkey", Format("x{} y{} w{}", PosX, PosY - 3, 70), "!l")
        con.Enabled := false

        PosX += 90
        btnCon := MyGui.Add("Button", Format("x{} y{} w{}", PosX, PosY - 5, 80), GetLang("执行指令"))
        btnCon.OnEvent("Click", (*) => this.TriggerMacro())

        PosX += 90
        MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 50), GetLang("备注:"))
        PosX += 50
        this.RemarkCon := MyGui.Add("Edit", Format("x{} y{} w{}", PosX, PosY - 5, 150), "")

        PosY += 30
        PosX := 10
        MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 400), GetLang("F1:确定鼠标下进程"))

        PosX := 10
        PosY += 20
        this.MouseProNameCon := MyGui.Add("Text", Format("x{} y{} w{} h{}", PosX, PosY, 380, 20), GetLang(
            "鼠标下进程名:Zone.exe"))

        PosX := 10
        PosY += 30
        MyGui.Add("Text", Format("x{} y{}", PosX, PosY), GetLang("路径："))

        PosX += 40
        this.PathTextCon := MyGui.Add("Edit", Format("x{} y{} w{}", PosX, PosY - 3, 350))

        PosX += 355
        btnCon := MyGui.Add("Button", Format("x{} y{}", PosX, PosY - 5), GetLang("选择文件"))
        btnCon.OnEvent("Click", (*) => this.OnClickFileSelectBtn())

        PosY += 25
        PosX := 10
        MyGui.Add("Text", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("支持类别：进程、网址、文件等等"))

        PosY += 25
        PosX := 10
        MyGui.Add("Text", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("支持文件后缀：进程名、网址、exe、txt、bat、mp4、vbs、mp3等等"))

        PosX := 10
        PosY += 25
        this.BackPlayCon := MyGui.Add("Checkbox", Format("x{} y{} w{}", PosX, PosY, 400), GetLang("后台播放mp3文件"))

        PosY += 45
        PosX := 10
        MyGui.Add("Text", Format("x{} y{} w{} h{}", PosX, PosY, 400, 20), GetLang("路径是进程时：该进程务必属于系统软件，或者有系统变量环境"))

        PosY += 25
        PosX := 200
        btnCon := MyGui.Add("Button", Format("x{} y{} w{} h{}", PosX, PosY, 100, 40), GetLang("确定"))
        btnCon.OnEvent("Click", (*) => this.OnClickSureBtn())

        MyGui.OnEvent("Close", (*) => this.ToggleFunc(false))
        MyGui.Show(Format("w{} h{}", 500, 285))
    }

    Init(cmd) {
        cmdArr := cmd != "" ? StrSplit(cmd, "_") : []
        this.SerialStr := cmdArr.Length >= 2 ? cmdArr[2] : GetSerialStr("Run")
        this.RemarkCon.Value := cmdArr.Length >= 3 ? cmdArr[3] : ""
        this.Data := this.GetRunData(this.SerialStr)

        this.PathTextCon.Value := this.Data.RunPath
        this.BackPlayCon.Value := this.Data.BackPlay
    }

    GetCommandStr() {
        CommandStr := Format("{}_{}", GetLang("运行"), this.Data.SerialStr)
        Remark := CorrectRemark(this.RemarkCon.Value)
        if (Remark != "") {
            CommandStr .= "_" Remark
        }
        return CommandStr
    }

    ToggleFunc(state) {
        MacroAction := (*) => this.TriggerMacro()
        if (state) {
            SetTimer this.RefreshAction, 100
            Hotkey("!l", MacroAction, "On")
            Hotkey("F1", (*) => this.SureProcessName(), "On")
        }
        else {
            SetTimer this.RefreshAction, 0
            Hotkey("!l", MacroAction, "Off")
            Hotkey("F1", (*) => this.SureProcessName(), "Off")
        }
    }

    RefreshProcessName() {
        CoordMode("Mouse", "Screen")
        MouseGetPos &mouseX, &mouseY, &winId
        try {
            processName := WinGetProcessName(winId)
            this.MouseProNameCon.Value := Format(GetLang("当前鼠标下进程名:{}"), processName)
        }
    }

    SureProcessName() {
        CoordMode("Mouse", "Screen")
        MouseGetPos &mouseX, &mouseY, &winId
        try {
            processName := WinGetProcessName(winId)
            this.PathTextCon.Value := processName
        }

    }

    OnClickFileSelectBtn() {
        fileString := FileSelect("S1", "", GetLang("选择要运行的文件"))
        if (fileString == "")
            return

        this.PathTextCon.Value := fileString
    }

    OnClickSureBtn() {
        valid := this.CheckIfValid()
        if (!valid)
            return
        this.SaveRunData()
        this.ToggleFunc(false)
        action := this.SureBtnAction
        action(this.GetCommandStr())
        this.Gui.Hide()
    }

    CheckIfValid() {
        if (this.PathTextCon.Value == "") {
            MsgBox(GetLang("路径不能为空！"))
            return false
        }
        return true
    }

    TriggerMacro() {
        this.SaveRunData()
        OnTriggerSepcialItemMacro(this.GetCommandStr())
    }

    GetRunData(SerialStr) {
        saveStr := IniRead(RunFile, IniSection, SerialStr, "")
        if (!saveStr) {
            data := FileData()
            data.SerialStr := SerialStr
            return data
        }

        data := JSON.parse(saveStr, , false)
        return data
    }

    SaveRunData() {
        this.Data.RunPath := this.PathTextCon.Value
        this.Data.BackPlay := this.BackPlayCon.Value

        saveStr := JSON.stringify(this.Data, 0)
        IniWrite(saveStr, RunFile, IniSection, this.Data.SerialStr)
        if (MySoftData.DataCacheMap.Has(this.Data.SerialStr)) {
            MySoftData.DataCacheMap.Delete(this.Data.SerialStr)
        }
    }
}
