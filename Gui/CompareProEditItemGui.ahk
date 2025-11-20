#Requires AutoHotkey v2.0
#Include MacroEditGui.ahk

class CompareProEditItemGui {
    __new() {
        this.Gui := ""
        this.SureBtnAction := ""
        this.VariableObjArr := []
        this.RemarkCon := ""
        this.FocusCon := ""
        this.MacroGui := ""

        this.EditType := 1  ;1正常分支 2兜底分支
        this.ToggleConArr := []
        this.NameConArr := []
        this.CompareTypeConArr := []
        this.VariableConArr := []
        this.LogicalTypeCon := ""
        this.MacroCon := ""
    }

    ShowGui(EditType, DataArr, logicStr, macro) {
        if (this.Gui != "") {
            this.Gui.Show()
        }
        else {
            this.AddGui()
        }

        this.Init(EditType, DataArr, logicStr, macro)
        this.OnRefresh()
    }

    AddGui() {
        MyGui := Gui(, "如果Pro分支编辑")
        this.Gui := MyGui
        MyGui.SetFont("S10 W550 Q2", MySoftData.FontType)

        PosX := 10
        PosY := 10
        MyGui.Add("Text", Format("x{} y{} w{} h{}", PosX, PosY, 80, 30), "逻辑关系：")
        this.LogicalTypeCon := MyGui.Add("DropDownList", Format("x{} y{} w{}", PosX + 85, PosY - 3, 60), ["且", "或"])

        PosY += 30
        PosX := 10
        MyGui.Add("Text", Format("x{} y{}", PosX, PosY), "开关")
        PosX += 50
        MyGui.Add("Text", Format("x{} y{}", PosX, PosY), "选择/输入")
        PosX += 230
        MyGui.Add("Text", Format("x{} y{}", PosX, PosY), "选择/输入")

        PosY += 25
        PosX := 15
        con := MyGui.Add("Checkbox", Format("x{} y{} w{}", PosX, PosY, 30))
        this.ToggleConArr.Push(con)
        con.Value := 1

        con := MyGui.Add("ComboBox", Format("x{} y{} w{} R5", PosX + 35, PosY - 3, 120), [])
        this.NameConArr.Push(con)

        con := MyGui.Add("DropDownList", Format("x{} y{} w{}", PosX + 160, PosY - 3, 80), ["大于", "大于等于", "等于", "小于等于",
            "小于", "字符包含", "变量存在"])
        con.Value := 1
        con.OnEvent("Change", (*) => this.OnRefresh())
        this.CompareTypeConArr.Push(con)

        con := MyGui.Add("ComboBox", Format("x{} y{} w{} R5", PosX + 245, PosY - 3, 120), [])
        this.VariableConArr.Push(con)

        PosY += 35
        PosX := 15
        con := MyGui.Add("Checkbox", Format("x{} y{} w{}", PosX, PosY, 30))
        this.ToggleConArr.Push(con)
        con.Value := 1

        con := MyGui.Add("ComboBox", Format("x{} y{} w{} R5", PosX + 35, PosY - 3, 120), [])
        this.NameConArr.Push(con)

        con := MyGui.Add("DropDownList", Format("x{} y{} w{}", PosX + 160, PosY - 3, 80), ["大于", "大于等于", "等于", "小于等于",
            "小于", "字符包含", "变量存在"])
        con.Value := 1
        con.OnEvent("Change", (*) => this.OnRefresh())
        this.CompareTypeConArr.Push(con)

        con := MyGui.Add("ComboBox", Format("x{} y{} w{} R5", PosX + 245, PosY - 3, 120), [])
        this.VariableConArr.Push(con)

        PosY += 35
        PosX := 15
        con := MyGui.Add("Checkbox", Format("x{} y{} w{}", PosX, PosY, 30))
        this.ToggleConArr.Push(con)
        con.Value := 1

        con := MyGui.Add("ComboBox", Format("x{} y{} w{} R5", PosX + 35, PosY - 3, 120), [])
        this.NameConArr.Push(con)

        con := MyGui.Add("DropDownList", Format("x{} y{} w{}", PosX + 160, PosY - 3, 80), ["大于", "大于等于", "等于", "小于等于",
            "小于", "字符包含", "变量存在"])
        con.Value := 1
        con.OnEvent("Change", (*) => this.OnRefresh())
        this.CompareTypeConArr.Push(con)

        con := MyGui.Add("ComboBox", Format("x{} y{} w{} R5", PosX + 245, PosY - 3, 120), [])
        this.VariableConArr.Push(con)

        PosY += 35
        PosX := 15
        con := MyGui.Add("Checkbox", Format("x{} y{} w{}", PosX, PosY, 30))
        this.ToggleConArr.Push(con)
        con.Value := 1

        con := MyGui.Add("ComboBox", Format("x{} y{} w{} R5", PosX + 35, PosY - 3, 120), [])
        this.NameConArr.Push(con)

        con := MyGui.Add("DropDownList", Format("x{} y{} w{}", PosX + 160, PosY - 3, 80), ["大于", "大于等于", "等于", "小于等于",
            "小于", "字符包含", "变量存在"])
        con.Value := 1
        con.OnEvent("Change", (*) => this.OnRefresh())
        this.CompareTypeConArr.Push(con)

        con := MyGui.Add("ComboBox", Format("x{} y{} w{} R5", PosX + 245, PosY - 3, 120), [])
        this.VariableConArr.Push(con)

        PosY += 40
        PosX := 10
        SplitPosY := PosY
        MyGui.Add("Text", Format("x{} y{} w{} h{}", PosX, PosY, 160, 20), "分支指令:")

        PosX += 80
        btnCon := MyGui.Add("Button", Format("x{} y{} w{} h{}", PosX, PosY - 5, 60, 25), "编辑")
        btnCon.OnEvent("Click", (*) => this.OnEditMacroBtnClick())

        PosY += 20
        PosX := 10
        this.MacroCon := MyGui.Add("Edit", Format("x{} y{} w{} h{}", PosX, PosY, 370, 80), "")

        PosY += 90
        PosX := 170
        btnCon := MyGui.Add("Button", Format("x{} y{} w{} h{}", PosX, PosY, 100, 40), "确定")
        btnCon.OnEvent("Click", (*) => this.OnClickSureBtn())
        MyGui.Show(Format("w{} h{}", 420, 370))
    }

    Init(EditType, DataArr, logicStr, macro) {
        this.EditType := EditType
        this.LogicalTypeCon.Text := logicStr == "" ? "且" : logicStr
        this.MacroCon.Value := macro

        VariNameArr := DataArr[1]
        CompareTypeArr := DataArr[2]
        VariableArr := DataArr[3]
        loop 4 {
            this.ToggleConArr[A_Index].Value := VariNameArr.Length >= A_Index
            this.NameConArr[A_Index].Delete()
            this.NameConArr[A_Index].Add(this.VariableObjArr)
            this.NameConArr[A_Index].Text := VariNameArr.Length >= A_Index ? VariNameArr[A_Index] : "Num" A_Index
            this.CompareTypeConArr[A_Index].Value := CompareTypeArr.Length >= A_Index ? CompareTypeArr[A_Index] : 1
            this.VariableConArr[A_Index].Delete()
            this.VariableConArr[A_Index].Add(this.VariableObjArr)
            this.VariableConArr[A_Index].Text := VariableArr.Length >= A_Index ? VariableArr[A_Index] : "Num" A_Index
        }

        isEnabled := EditType == 1
        this.LogicalTypeCon.Enabled := isEnabled
        loop 4 {
            this.ToggleConArr[A_Index].Enabled := isEnabled
            this.NameConArr[A_Index].Enabled := isEnabled
            this.CompareTypeConArr[A_Index].Enabled := isEnabled
            this.VariableConArr[A_Index].Enabled := isEnabled
        }
    }

    OnRefresh() {
        loop 4 {
            OperaTypeValue := this.CompareTypeConArr[A_Index].Value
            EnableVari := OperaTypeValue != 7 && this.EditType == 1
            this.VariableConArr[A_Index].Enabled := EnableVari
        }
    }

    OnClickSureBtn() {
        action := this.SureBtnAction
        if (this.EditType == 1) {
            condiStr := ""
            loop 4 {
                if (this.ToggleConArr[A_Index].Value) {
                    if (this.CompareTypeConArr[A_Index].Text != "变量存在") {
                        condiStr .= this.NameConArr[A_Index].Text " " this.CompareTypeConArr[A_Index].Text " " this.VariableConArr[
                            A_Index].Text
                    }
                    else {
                        condiStr .= this.NameConArr[A_Index].Text " " this.CompareTypeConArr[A_Index].Text
                    }

                    condiStr .= "⎖"
                }
            }
            condiStr := Trim(condiStr, "⎖")
            logicStr := this.LogicalTypeCon.Text
            macro := this.MacroCon.Value
            action(condiStr, logicStr, macro)
        }
        else {
            action("以上都不是", "", this.MacroCon.Value)
        }

        this.SureBtnAction := ""
        this.Gui.Hide()
    }

    OnMacroBtnClick(CommandStr) {
        this.MacroCon.Value := CommandStr
    }

    OnEditMacroBtnClick() {
        if (this.MacroGui == "") {
            this.MacroGui := MacroEditGui()
            this.MacroGui.VariableObjArr := this.VariableObjArr
            this.MacroGui.SureFocusCon := this.LogicalTypeCon
        }

        this.MacroGui.SureBtnAction := (command) => this.OnMacroBtnClick(command)
        this.MacroGui.ShowGui(this.MacroCon.Value, false)
    }
}
