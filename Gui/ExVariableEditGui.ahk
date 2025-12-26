#Requires AutoHotkey v2.0

class ExVariableEditGui {
    __new() {
        this.Gui := ""
        this.SureAction := ""

        this.OriTextCon := ""
        this.VarTextConArr := []
    }

    ShowGui() {
        if (this.Gui != "") {
            this.Gui.Show()
        }
        else {
            this.AddGui()
        }
        this.Init()
    }

    Init() {
        this.OriTextCon.Value := ""
        for index, value in this.VarTextConArr {
            value.Value := ""
        }
    }

    AddGui() {
        MyGui := Gui(, GetLang("提取文本编辑器"))
        this.Gui := MyGui
        MyGui.SetFont("S11 W550 Q2", MySoftData.FontType)

        PosX := 15
        PosY := 10
        MyGui.Add("Text", Format("x{} y{}", PosX, PosY), GetLang("源文本内容："))
        PosY += 25
        this.OriTextCon := MyGui.Add("Edit", Format("x{} y{} w{} h{}", PosX, PosY, 410, 50), "")

        PosY += 60
        PosX := 15
        MyGui.Add("Text", Format("x{} y{}", PosX, PosY + 2), Format("{}1:", GetLang("提取内容")))
        con := MyGui.Add("Edit", Format("x{} y{} w{}", PosX + 85, PosY, 100), "")
        this.VarTextConArr.Push(con)

        PosX += 225
        MyGui.Add("Text", Format("x{} y{}", PosX, PosY + 2), Format("{}2:", GetLang("提取内容")))
        con := MyGui.Add("Edit", Format("x{} y{} w{}", PosX + 85, PosY, 100), "")
        this.VarTextConArr.Push(con)

        PosY += 35
        PosX := 15
        MyGui.Add("Text", Format("x{} y{}", PosX, PosY + 2), Format("{}3:", GetLang("提取内容")))
        con := MyGui.Add("Edit", Format("x{} y{} w{}", PosX + 85, PosY, 100), "")
        this.VarTextConArr.Push(con)

        PosX += 225
        MyGui.Add("Text", Format("x{} y{}", PosX, PosY + 2), Format("{}4:", GetLang("提取内容")))
        con := MyGui.Add("Edit", Format("x{} y{} w{}", PosX + 85, PosY, 100), "")
        this.VarTextConArr.Push(con)

        PosY += 35
        PosX := 15
        MyGui.Add("Text", Format("x{} y{}", PosX, PosY + 2), Format("{}5:", GetLang("提取内容")))
        con := MyGui.Add("Edit", Format("x{} y{} w{}", PosX + 85, PosY, 100), "")
        this.VarTextConArr.Push(con)

        PosX += 225
        MyGui.Add("Text", Format("x{} y{}", PosX, PosY + 2), Format("{}6:", GetLang("提取内容")))
        con := MyGui.Add("Edit", Format("x{} y{} w{}", PosX + 85, PosY, 100), "")
        this.VarTextConArr.Push(con)

        PosX := 170
        PosY += 40
        con := MyGui.Add("Button", Format("x{} y{} w100 h40", PosX, PosY), GetLang("确定"))
        con.OnEvent("Click", (*) => this.OnSureBtnClick())
        MyGui.Show(Format("w{} h{}", 440, 260))
    }

    CheckIfValid() {
        ExtractStr := this.OriTextCon.Value
        for index, con in this.VarTextConArr {
            if (con.Value == "")
                break

            isContain := InStr(ExtractStr, con.Value)
            ExtractStr := StrReplace(ExtractStr, con.Value, "", true, &OutputVarCount, 1)
            if (!isContain) {
                tipStr := Format("{}{}:{}", GetLang("提取内容"), index, GetLang("未在源文本内容中出现，请修改"))
                MsgBox(tipStr)
                return false
            }
        }
        return true
    }

    GetExtractStr() {
        ExtractStr := this.OriTextCon.Value
        if (this.VarTextConArr[1].Value == "")
            return ""

        for index, con in this.VarTextConArr {
            text := con.Value
            text := StrReplace(text, ",", "")
            text := StrReplace(text, "，", "")
            isNum := IsNumber(text)
            replaceStr := isNum ? "&x" : "&c"

            ExtractStr := StrReplace(ExtractStr, con.Value, replaceStr, true, &OutputVarCount, 1)
        }
        return ExtractStr
    }

    GetVariNum() {
        if (this.VarTextConArr[1].Value == "")
            return 1
        Count := 0
        for index, con in this.VarTextConArr {
            if (con.Value != "") {
                Count++
                continue
            }
            break
        }
        return Count
    }

    OnSureBtnClick() {
        isValid := this.CheckIfValid()
        if (!isValid)
            return

        Action := this.SureAction
        ExtractStr := this.GetExtractStr()
        VariableNum := this.GetVariNum()
        Action(ExtractStr, VariableNum)
        this.Gui.Hide()
    }
}
