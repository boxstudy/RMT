#Requires AutoHotkey v2.0

class MMProGui {
    __new() {
        this.Gui := ""
        this.SureBtnAction := ""
        this.VariableObjArr := []
        this.FocusCon := ""
        this.RemarkCon := ""
        this.Data := ""
        this.PosAction := () => this.RefreshMousePos()

        this.PosVarXCon := ""
        this.PosVarYCon := ""
        this.IsRelativeCon := ""
        this.isGameViewCon := ""
        this.SpeedCon := ""
        this.CountCon := ""
        this.IntervalCon := ""
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
        MyGui := Gui(, "移动Pro指令编辑")
        this.Gui := MyGui
        MyGui.SetFont("S10 W550 Q2", MySoftData.FontType)

        PosX := 10
        PosY := 10
        this.FocusCon := MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 80), "快捷方式:")
        PosX += 80
        con := MyGui.Add("Hotkey", Format("x{} y{} w{}", PosX, PosY - 3, 70), "!l")
        con.Enabled := false

        PosX += 90
        btnCon := MyGui.Add("Button", Format("x{} y{} w{}", PosX, PosY - 5, 80), "执行指令")
        btnCon.OnEvent("Click", (*) => this.TriggerMacro())

        PosX += 90
        MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 50), "备注:")
        PosX += 50
        this.RemarkCon := MyGui.Add("Edit", Format("x{} y{} w{}", PosX, PosY - 5, 150), "")

        PosY += 30
        PosX := 10
        MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 400), "F1:选取当前坐标")

        PosX := 10
        PosY += 20
        this.MousePosCon := MyGui.Add("Text", Format("x{} y{} w{} h{}", PosX, PosY, 380, 20), "当前鼠标位置:0,0")

        PosY += 20
        PosX := 10
        MyGui.Add("Text", Format("x{} y{}", PosX, PosY), "游戏视角：调整原神等游戏视角、此模式下相对位移，速度100")

        PosY += 30
        MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 80), "坐标位置X:")
        PosX += 80
        this.PosVarXCon := MyGui.Add("ComboBox", Format("x{} y{} w{} R5 Center", PosX, PosY - 5, 100), [])

        PosY += 30
        PosX := 10
        MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 80), "坐标位置Y:")
        PosX += 80
        this.PosVarYCon := MyGui.Add("ComboBox", Format("x{} y{} w{} R5 Center", PosX, PosY - 5, 100), [])

        PosX := 10
        PosY += 30
        MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 80), "移动次数:")
        PosX += 80
        this.CountCon := MyGui.Add("Edit", Format("x{} y{} w{} Center", PosX, PosY - 5, 50), 1)

        PosX += 150
        MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 80), "每次间隔:")
        PosX += 80
        this.IntervalCon := MyGui.Add("Edit", Format("x{} y{} w{} Center", PosX, PosY - 5, 50), 1000)

        PosY += 30
        PosX := 10
        MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 80), "移动速度:")
        PosX += 80
        this.SpeedCon := MyGui.Add("Edit", Format("x{} y{} w{} Center", PosX, PosY - 5, 50), "90")

        PosX += 150
        this.IsRelativeCon := MyGui.Add("Checkbox", Format("x{} y{} w{} h{}", PosX, PosY, 100, 20), "相对位移")

        PosX += 100
        this.IsGameViewCon := MyGui.Add("Checkbox", Format("x{} y{} w{} h{}", PosX, PosY, 150, 20), "游戏视角")

        PosY += 35
        PosX := 175
        btnCon := MyGui.Add("Button", Format("x{} y{} w{} h{}", PosX, PosY, 100, 40), "确定")
        btnCon.OnEvent("Click", (*) => this.OnClickSureBtn())

        MyGui.OnEvent("Close", (*) => this.ToggleFunc(false))
        MyGui.Show(Format("w{} h{}", 480, 290))
    }

    Init(cmd) {
        cmdArr := cmd != "" ? StrSplit(cmd, "_") : []
        this.SerialStr := cmdArr.Length >= 2 ? cmdArr[2] : GetSerialStr("MMPro")
        this.Data := this.GetMMProData(this.SerialStr)
        this.RemarkCon.Value := cmdArr.Length >= 3 ? cmdArr[3] : ""

        this.PosVarXCon.Delete()
        this.PosVarXCon.Add(this.VariableObjArr)
        this.PosVarXCon.Text := this.Data.PosVarX
        this.PosVarYCon.Delete()
        this.PosVarYCon.Add(this.VariableObjArr)
        this.PosVarYCon.Text := this.Data.PosVarY
        this.IsRelativeCon.Value := this.Data.IsRelative
        this.isGameViewCon.Value := this.Data.IsGameView
        this.SpeedCon.Value := this.Data.Speed
        this.CountCon.Value := this.Data.Count
        this.IntervalCon.Value := this.Data.Interval
    }

    TriggerMacro() {
        valid := this.CheckIfValid()
        if (!valid)
            return

        if (!IsNumber(this.PosVarXCon.Text)) {
            MsgBox("坐标X是变量时，编辑模式下无法执行")
            return
        }

        if (!IsNumber(this.PosVarYCon.Text)) {
            MsgBox("坐标Y是变量时，编辑模式下无法执行")
            return
        }

        this.SaveMMProData()
        tableItem := MySoftData.SpecialTableItem

        tableItem.KilledArr[1] := false
        tableItem.PauseArr[1] := 0
        tableItem.ActionCount[1] := 0
        tableItem.VariableMapArr[1] := Map()
        tableItem.index := 1
    
        OnMMPro(tableItem, this.GetCommandStr(), 1)
    }

    GetCommandStr() {
        hasRemark := this.RemarkCon.Value != ""
        CommandStr := "移动Pro_" this.Data.SerialStr
        if (hasRemark) {
            CommandStr .= "_" this.RemarkCon.Value
        }
        return CommandStr
    }

    CheckIfValid() {
        return true
    }

    RefreshMousePos() {
        CoordMode("Mouse", "Screen")
        MouseGetPos &mouseX, &mouseY
        this.MousePosCon.Value := "当前鼠标位置:" mouseX "," mouseY
    }

    ToggleFunc(state) {
        if (state) {
            SetTimer this.PosAction, 100
            Hotkey("F1", (*) => this.SureMMPro(), "On")
        }
        else {
            SetTimer this.PosAction, 0
            Hotkey("F1", (*) => this.SureMMPro(), "Off")
        }
    }

    OnClickSureBtn() {
        valid := this.CheckIfValid()
        if (!valid)
            return

        this.SaveMMProData()
        action := this.SureBtnAction
        action(this.GetCommandStr())
        this.ToggleFunc(false)
        this.Gui.Hide()
    }

    SureMMPro() {
        CoordMode("Mouse", "Screen")
        MouseGetPos &mouseX, &mouseY
        this.PosVarXCon.Text := mouseX
        this.PosVarYCon.Text := mouseY
    }

    GetMMProData(SerialStr) {
        saveStr := IniRead(MMPROFile, IniSection, SerialStr, "")
        if (!saveStr) {
            data := MMProData()
            data.SerialStr := SerialStr
            return data
        }

        data := JSON.parse(saveStr, , false)
        return data
    }

    SaveMMProData() {
        this.Data.PosVarX := this.PosVarXCon.Text
        this.Data.PosVarY := this.PosVarYCon.Text
        this.Data.IsRelative := this.IsRelativeCon.Value
        this.Data.IsGameView := this.isGameViewCon.Value
        this.Data.Speed := this.SpeedCon.Value
        this.Data.Count := this.CountCon.Value
        this.Data.Interval := this.IntervalCon.Value

        saveStr := JSON.stringify(this.Data, 0)
        IniWrite(saveStr, MMPROFile, IniSection, this.Data.SerialStr)
        if (MySoftData.DataCacheMap.Has(this.Data.SerialStr)) {
            MySoftData.DataCacheMap.Delete(this.Data.SerialStr)
        }
    }
}
