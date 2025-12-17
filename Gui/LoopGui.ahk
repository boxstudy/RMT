#Requires AutoHotkey v2.0
#Include MacroEditGui.ahk

class LoopGui {
    __new() {
        this.ParentTile := ""
        this.Gui := ""
        this.SureBtnAction := ""
        this.RemarkCon := ""
        this.MacroGui := ""
        this.VariableObjArr := []
        this.FocusCon := ""

        this.Data := ""
        this.CountCon := ""
        this.CondiCon := ""
        this.LogicCon := ""
        this.ToggleConArr := []
        this.NameConArr := []
        this.CompareTypeConArr := []
        this.VariableConArr := []
        this.LoopBodyCon := ""
    }

    ShowGui(cmd) {
        if (this.Gui != "") {
            this.Gui.Show()
        }
        else {
            this.AddGui()
        }

        this.Init(cmd)
        this.OnRefresh()
        this.ToggleFunc(true)
    }

    AddGui() {
        MyGui := Gui(, this.ParentTile GetLang("循环编辑器"))
        this.Gui := MyGui
        MyGui.SetFont("S10 W550 Q2", MySoftData.FontType)

        PosX := 10
        PosY := 10
        MyGui.Add("Text", Format("x{} y{}", PosX, PosY), GetLang("快捷方式:"))
        PosX += 70
        con := MyGui.Add("Hotkey", Format("x{} y{} w{}", PosX, PosY - 3, 70), "!l")
        con.Enabled := false

        PosX += 90
        btnCon := MyGui.Add("Button", Format("x{} y{} w{}", PosX, PosY - 5, 80), GetLang("执行指令"))
        btnCon.OnEvent("Click", (*) => this.TriggerMacro())

        PosX += 90
        MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 50), GetLang("备注:"))
        PosX += 50
        this.RemarkCon := MyGui.Add("Edit", Format("x{} y{} w{}", PosX, PosY - 5, 150), "")

        PosX := 20
        PosY += 40
        MyGui.Add("Text", Format("x{} y{} w{} h{}", PosX, PosY - 2, 80, 20), GetLang("循环次数:"))

        PosX += 80
        this.CountCon := MyGui.Add("ComboBox", Format("x{} y{} w{}", PosX, PosY - 5, 120), [])

        PosX := 10
        PosY += 30
        MyGui.Add("GroupBox", Format("x{} y{} w{} h{}", PosX, PosY, 420, 200), GetLang("循环条件:"))

        PosX := 20
        PosY += 25
        MyGui.Add("Text", Format("x{} y{} h{}", PosX, PosY, 20), GetLang("类型:"))

        PosX += 45
        this.CondiCon := MyGui.Add("DropDownList", Format("x{} y{} w{}", PosX, PosY - 5, 120), GetLangArr(["无", "继续条件",
            "退出条件"]))
        this.CondiCon.OnEvent("Change", (*) => this.OnRefresh())

        PosX += 180
        MyGui.Add("Text", Format("x{} y{} w{} h{}", PosX, PosY, 100, 20), GetLang("条件逻辑关系:"))
        PosX += 100
        this.LogicCon := MyGui.Add("DropDownList", Format("x{} y{} w{}", PosX, PosY - 5, 50), GetLangArr(["且", "或"]))

        PosY += 30
        PosX := 30
        con := MyGui.Add("Checkbox", Format("x{} y{} w{}", PosX, PosY, 30))
        this.ToggleConArr.Push(con)
        con.Value := 1

        con := MyGui.Add("ComboBox", Format("x{} y{} w{} R5", PosX + 35, PosY - 3, 120), [])
        this.NameConArr.Push(con)

        con := MyGui.Add("DropDownList", Format("x{} y{} w{}", PosX + 160, PosY - 3, 80), GetLangArr(["大于", "大于等于",
            "等于", "小于等于",
            "小于", "字符包含", "变量存在"]))
        con.Value := 1
        con.OnEvent("Change", (*) => this.OnRefresh())
        this.CompareTypeConArr.Push(con)

        con := MyGui.Add("ComboBox", Format("x{} y{} w{} R5", PosX + 245, PosY - 3, 120), [])
        this.VariableConArr.Push(con)

        PosY += 35
        PosX := 30
        con := MyGui.Add("Checkbox", Format("x{} y{} w{}", PosX, PosY, 30))
        this.ToggleConArr.Push(con)
        con.Value := 1

        con := MyGui.Add("ComboBox", Format("x{} y{} w{} R5", PosX + 35, PosY - 3, 120), [])
        this.NameConArr.Push(con)

        con := MyGui.Add("DropDownList", Format("x{} y{} w{}", PosX + 160, PosY - 3, 80), GetLangArr(["大于", "大于等于",
            "等于", "小于等于",
            "小于", "字符包含", "变量存在"]))
        con.Value := 1
        con.OnEvent("Change", (*) => this.OnRefresh())
        this.CompareTypeConArr.Push(con)

        con := MyGui.Add("ComboBox", Format("x{} y{} w{} R5", PosX + 245, PosY - 3, 120), [])
        this.VariableConArr.Push(con)

        PosY += 35
        PosX := 30
        con := MyGui.Add("Checkbox", Format("x{} y{} w{}", PosX, PosY, 30))
        this.ToggleConArr.Push(con)
        con.Value := 1

        con := MyGui.Add("ComboBox", Format("x{} y{} w{} R5", PosX + 35, PosY - 3, 120), [])
        this.NameConArr.Push(con)

        con := MyGui.Add("DropDownList", Format("x{} y{} w{}", PosX + 160, PosY - 3, 80), GetLangArr(["大于", "大于等于",
            "等于", "小于等于",
            "小于", "字符包含", "变量存在"]))
        con.Value := 1
        con.OnEvent("Change", (*) => this.OnRefresh())
        this.CompareTypeConArr.Push(con)

        con := MyGui.Add("ComboBox", Format("x{} y{} w{} R5", PosX + 245, PosY - 3, 120), [])
        this.VariableConArr.Push(con)

        PosY += 35
        PosX := 30
        con := MyGui.Add("Checkbox", Format("x{} y{} w{}", PosX, PosY, 30))
        this.ToggleConArr.Push(con)
        con.Value := 1

        con := MyGui.Add("ComboBox", Format("x{} y{} w{} R5", PosX + 35, PosY - 3, 120), [])
        this.NameConArr.Push(con)

        con := MyGui.Add("DropDownList", Format("x{} y{} w{}", PosX + 160, PosY - 3, 80), GetLangArr(["大于", "大于等于",
            "等于", "小于等于",
            "小于", "字符包含", "变量存在"]))
        con.Value := 1
        con.OnEvent("Change", (*) => this.OnRefresh())
        this.CompareTypeConArr.Push(con)

        con := MyGui.Add("ComboBox", Format("x{} y{} w{} R5", PosX + 245, PosY - 3, 120), [])
        this.VariableConArr.Push(con)

        PosY += 45
        PosX := 20
        MyGui.Add("Text", Format("x{} y{}", PosX, PosY + 2), GetLang("循环体:"))
        PosX += 60
        con := MyGui.Add("Button", Format("x{} y{} w{} h{}", PosX, PosY, 80, 25), GetLang("编辑"))
        con.OnEvent("Click", this.OnEditMacroBtnClick.Bind(this))
        PosY += 30
        PosX := 10
        this.LoopBodyCon := MyGui.Add("Edit", Format("x{} y{} w{} h{}", PosX, PosY, 450, 100), "")

        PosY += 110
        PosX := 190
        btnCon := MyGui.Add("Button", Format("x{} y{} w{} h{}", PosX, PosY, 100, 40), GetLang("确定"))
        btnCon.OnEvent("Click", (*) => this.OnClickSureBtn())
        this.FocusCon := btnCon

        MyGui.OnEvent("Close", (*) => this.ToggleFunc(false))
        MyGui.Show(Format("w{} h{}", 470, 470))
    }

    Init(cmd) {
        cmdArr := cmd != "" ? StrSplit(cmd, "_") : []
        this.SerialStr := cmdArr.Length >= 2 ? cmdArr[2] : GetSerialStr("Loop")
        this.RemarkCon.Value := cmdArr.Length >= 3 ? cmdArr[3] : ""
        this.Data := this.GetLoopData(this.SerialStr)

        CountVariableArr := this.VariableObjArr.Clone()
        CountVariableArr.Push(GetLang("无限"))
        this.CountCon.Delete()
        this.CountCon.Add(CountVariableArr)
        this.CountCon.Text := this.Data.LoopCount == -1 ? GetLang("无限") : this.Data.LoopCount

        this.CondiCon.Value := this.Data.CondiType
        this.LogicCon.Value := this.Data.LogicType
        this.LoopBodyCon.Value := this.Data.LoopBody

        VariableArr := this.GetDLVariableArr()
        loop 4 {
            this.ToggleConArr[A_Index].Value := this.Data.ToggleArr[A_Index]
            this.NameConArr[A_Index].Delete()
            this.NameConArr[A_Index].Add(VariableArr)
            this.NameConArr[A_Index].Text := GetLang(this.Data.NameArr[A_Index])
            this.CompareTypeConArr[A_Index].Value := this.Data.CompareTypeArr[A_Index]
            this.VariableConArr[A_Index].Delete()
            this.VariableConArr[A_Index].Add(VariableArr)
            this.VariableConArr[A_Index].Text := GetLang(this.Data.VariableArr[A_Index])
        }
    }

    ToggleFunc(state) {
        MacroAction := (*) => this.TriggerMacro()
        if (state) {
            Hotkey("!l", MacroAction, "On")
        }
        else {
            Hotkey("!l", MacroAction, "Off")
        }
    }

    OnRefresh() {
        showCondi := this.CondiCon.Value != 1
        this.LogicCon.Enabled := showCondi

        loop 4 {
            OperaTypeValue := this.CompareTypeConArr[A_Index].Value
            EnableVari := OperaTypeValue != 7

            this.ToggleConArr[A_Index].Enabled := showCondi
            this.NameConArr[A_Index].Enabled := showCondi
            this.CompareTypeConArr[A_Index].Enabled := showCondi
            this.VariableConArr[A_Index].Enabled := EnableVari && showCondi
        }
    }

    OnEditMacroBtnClick(*) {
        if (this.MacroGui == "") {
            this.MacroGui := MacroEditGui()
            this.MacroGui.VariableObjArr := this.GetDLVariableArr()
            this.MacroGui.SureFocusCon := this.FocusCon

            ParentTile := StrReplace(this.Gui.Title, GetLang("编辑器"), "")
            this.MacroGui.ParentTile := ParentTile "-"
        }

        this.MacroGui.SureBtnAction := (command) => this.LoopBodyCon.Value := command
        this.MacroGui.ShowGui(this.LoopBodyCon.Value, false)
    }

    OnClickSureBtn() {
        valid := this.CheckIfValid()
        if (!valid)
            return
        this.SaveLoopData()
        this.ToggleFunc(false)
        CommandStr := this.GetCommandStr()
        action := this.SureBtnAction
        action(CommandStr)
        this.Gui.Hide()
    }

    CheckIfValid() {

        return true
    }

    TriggerMacro() {
        this.SaveLoopData()
        OnTriggerSepcialItemMacro(this.GetCommandStr())
    }

    GetDLVariableArr() {
        VariableArr := this.VariableObjArr.Clone()
        TargetIndex := 1
        loop VariableArr.Length {
            if (VariableArr[A_Index] == GetLang("宏循环次数")) {
                TargetIndex := A_Index
                break
            }
        }

        VariableArr.InsertAt(TargetIndex, GetLang("指令循环次数"))
        return VariableArr
    }

    GetCommandStr() {
        CommandStr := Format("{}_{}", GetLang("循环"), this.Data.SerialStr)
        Remark := CorrectRemark(this.RemarkCon.Value)
        if (Remark != "") {
            CommandStr .= "_" Remark
        }

        return CommandStr
    }

    GetLoopData(SerialStr) {
        saveStr := IniRead(LoopFile, IniSection, SerialStr, "")
        if (!saveStr) {
            data := LoopData()
            data.SerialStr := SerialStr
            return data
        }

        data := JSON.parse(saveStr, , false)
        return data
    }

    SaveLoopData() {
        this.Data.LoopCount := this.CountCon.Text == GetLang("无限") ? -1 : this.CountCon.Text
        this.Data.CondiType := this.CondiCon.Value
        this.Data.LogicType := this.LogicCon.Value
        this.Data.LoopBody := this.LoopBodyCon.Value

        loop 4 {
            this.Data.ToggleArr[A_Index] := this.ToggleConArr[A_Index].Value
            this.Data.NameArr[A_Index] := GetLangKey(this.NameConArr[A_Index].Text)
            this.Data.CompareTypeArr[A_Index] := this.CompareTypeConArr[A_Index].Value
            this.Data.VariableArr[A_Index] := GetLangKey(this.VariableConArr[A_Index].Text)
        }
        saveStr := JSON.stringify(this.Data, 0)
        IniWrite(saveStr, LoopFile, IniSection, this.Data.SerialStr)
        if (MySoftData.DataCacheMap.Has(this.Data.SerialStr)) {
            MySoftData.DataCacheMap.Delete(this.Data.SerialStr)
        }
    }
}
