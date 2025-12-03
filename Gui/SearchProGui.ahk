#Requires AutoHotkey v2.0
#Include MacroEditGui.ahk

class SearchProGui {
    __new() {
        this.ParentTile := ""
        this.Gui := ""
        this.SureBtnAction := ""
        this.VariableObjArr := []
        this.RemarkCon := ""
        this.PosAction := () => this.RefreshMouseInfo()
        this.SetAreaAction := (x1, y1, x2, y2) => this.OnSetSearchArea(x1, y1, x2, y2)
        this.CheckClipboardAction := () => this.CheckClipboard()
        this.SelectToggleCon := ""
        this.Data := ""
        this.MousePosCon := ""
        this.MouseColorCon := ""
        this.MouseColorTipCon := ""
        this.StartPosXCon := ""
        this.StartPosYCon := ""
        this.EndPosXCon := ""
        this.EndPosYCon := ""
        this.ImageCon := ""
        this.ImageBtn := ""
        this.SimilarCon := ""
        this.OCRLabelCon := ""
        this.OCRTypeCon := ""
        this.ScreenshotBtn := ""
        this.ImageTipCon := ""
        this.ImageTypeTipCon := ""
        this.ImageTypeCon := ""
        this.ColorTipCon := ""
        this.HexColorCon := ""
        this.HexColorTipCon := ""
        this.TextCon := ""
        this.TextTipCon := ""
        this.SearchCountCon := ""
        this.SearchIntervalCon := ""
        this.FoundCommandStrCon := ""
        this.UnFoundCommandStrCon := ""
        this.SearchTypeCon := ""
        this.MouseActionTypeCon := ""
        this.ClickCountCon := ""
        this.SpeedCon := ""
        this.ResultToggleCon := ""
        this.ResultSaveNameCon := ""
        this.TrueValueCon := ""
        this.FalseValueCon := ""
        this.CoordToogleCon := ""
        this.CoordXNameCon := ""
        this.CoordYNameCon := ""
        this.MacroGui := ""

        this.CountTogArr := []
        this.MouseTogArr := []
        this.ResultTogArr := []
        this.CoordTogArr := []
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
        MyGui := Gui(, this.ParentTile GetLang("搜索Pro编辑器"))
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
        con := MyGui.Add("Edit", Format("x{} y{} w{}", PosX, PosY, 25), "F1")
        con.Enabled := false

        PosX += 30
        this.SelectToggleCon := MyGui.Add("Checkbox", Format("x{} y{} w{} h{} Left", PosX, PosY, 150, 25), GetLang(
            "左键框选搜索范围"))
        this.SelectToggleCon.OnEvent("Click", (*) => this.OnClickSelectToggle())

        PosX += 150
        con := MyGui.Add("Edit", Format("x{} y{} w{}", PosX, PosY, 25), "F2")
        con.Enabled := false
        PosX += 30
        MyGui.Add("Text", Format("x{} y{} h{} Center", PosX, PosY + 3, 25), GetLang("截图"))

        PosX += 80
        con := MyGui.Add("Edit", Format("x{} y{} w{}", PosX, PosY, 25), "F3")
        con.Enabled := false
        PosX += 30
        MyGui.Add("Text", Format("x{} y{} h{} Center", PosX, PosY + 3, 25), GetLang("选取当前颜色"))

        PosX += 120
        Con := MyGui.Add("Button", Format("x{} y{} w100", PosX, PosY - 2), GetLang("定位取色器"))
        Con.OnEvent("Click", this.OnClickTargeterBtn.Bind(this))
        Con := MyGui.Add("Button", Format("x{} y{} w30", PosX + 102, PosY - 2), "?")
        Con.OnEvent("Click", this.OnClickTargeterHelpBtn.Bind(this))

        PosX := 10
        PosY += 30
        this.MousePosCon := MyGui.Add("Text", Format("x{} y{} w{} h{}", PosX, PosY, 230, 20), GetLang("当前鼠标坐标:0,0"))
        PosX += 330
        this.MouseColorCon := MyGui.Add("Text", Format("x{} y{} w{} h{}", PosX, PosY, 150, 20), GetLang("当前鼠标颜色:FFFFFF"
        ))
        PosX += 150
        this.MouseColorTipCon := MyGui.Add("Text", Format("x{} y{} w{} Background{}", PosX, PosY, 20, "FF0000"), "")
        PosX := 10
        PosY += 30
        MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 100), GetLang("搜索范围:"))
        PosX := 150
        MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 75), GetLang("相似度(%):"))
        PosX += 75
        this.SimilarCon := MyGui.Add("Edit", Format("x{} y{} w{} Center", PosX, PosY - 5, 55))

        PosX := 330
        MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 80), GetLang("搜索类型:"))
        PosX += 80
        this.SearchTypeCon := MyGui.Add("DropDownList", Format("x{} y{} w{} h{}", PosX, PosY - 3, 80, 100), GetLangArr([
            "图片", "颜色",
            "文本"]))
        this.SearchTypeCon.OnEvent("Change", (*) => this.OnChangeType())
        this.SearchTypeCon.Value := 1
        PosY += 30
        PosX := 10
        SplitPosY := PosY
        MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 75), GetLang("起始坐标X:"))
        PosX += 75
        this.StartPosXCon := MyGui.Add("Edit", Format("x{} y{} w{} Center", PosX, PosY - 5, 55))
        PosX := 150
        MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 75), GetLang("起始坐标Y:"))
        PosX += 75
        this.StartPosYCon := MyGui.Add("Edit", Format("x{} y{} w{} Center", PosX, PosY - 5, 55))
        PosY += 30
        PosX := 10
        MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 75), GetLang("终止坐标X:"))
        PosX += 75
        this.EndPosXCon := MyGui.Add("Edit", Format("x{} y{} w{} Center", PosX, PosY - 5, 55))
        PosX := 150
        MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 75), GetLang("终止坐标Y:"))
        PosX += 75
        this.EndPosYCon := MyGui.Add("Edit", Format("x{} y{} w{} Center", PosX, PosY - 5, 55))
        PosY += 30
        PosX := 10
        MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 75), GetLang("搜索次数:"))
        PosX += 75
        this.SearchCountCon := MyGui.Add("ComboBox", Format("x{} y{} w{} Center", PosX, PosY - 5, 55))
        this.SearchCountCon.OnEvent("LoseFocus", this.OnChangeType.Bind(this))
        PosX := 150
        con := MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 75), GetLang("每次间隔:"))
        this.CountTogArr.Push(con)
        PosX += 75
        con := this.SearchIntervalCon := MyGui.Add("Edit", Format("x{} y{} w{} Center", PosX, PosY - 5, 55))
        this.CountTogArr.Push(con)
        PosY += 30
        PosX := 10
        MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 75), GetLang("鼠标动作:"))
        PosX += 75
        this.MouseActionTypeCon := MyGui.Add("DropDownList", Format("x{} y{} w{} Center", PosX, PosY - 5, 130),
        GetLangArr(["无动作",
            "移动至目标", "移动至目标点击"]))
        this.MouseActionTypeCon.Value := 1
        this.MouseActionTypeCon.OnEvent("Change", this.OnChangeType.Bind(this))
        PosY += 30
        PosX := 10
        con := MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 120), GetLang("移动速度(0~100):"))
        this.MouseTogArr.Push(con)
        PosX += 120
        con := this.SpeedCon := MyGui.Add("Edit", Format("x{} y{} w{} Center", PosX, PosY - 5, 55), "90")
        this.MouseTogArr.Push(con)
        PosY += 30
        PosX := 10
        con := MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 120), GetLang("鼠标点击次数:"))
        this.MouseTogArr.Push(con)
        PosX += 120
        con := this.ClickCountCon := MyGui.Add("Edit", Format("x{} y{} w{} Center", PosX, PosY - 5, 55), "1")
        this.MouseTogArr.Push(con)

        PosY := SplitPosY
        PosX := 330
        this.ImageTipCon := MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 80), GetLang("搜索图片:"))
        PosY += 25
        this.ImageTypeTipCon := MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 80), GetLang("识别模型:"))
        PosX += 80
        this.ImageTypeCon := MyGui.Add("DropDownList", Format("x{} y{} w{} Center", PosX, PosY - 3, 80), ["OpenCV",
            "RMT识图"])
        PosY += 25
        PosX := 330
        btnCon := MyGui.Add("Button", Format("x{} y{} w{} h{}", PosX, PosY, 70, 25), GetLang("选择图片"))
        btnCon.OnEvent("Click", (*) => this.OnClickSetPicBtn())
        btnCon.Focus()
        this.ImageBtn := btnCon

        PosX += 80
        btnCon := MyGui.Add("Button", Format("x{} y{} w{} h{}", PosX, PosY, 80, 25), GetLang("截图"))
        btnCon.OnEvent("Click", (*) => this.OnScreenShotBtnClick())
        this.ScreenshotBtn := btnCon
        PosY := SplitPosY
        PosX := 500
        this.ImageCon := MyGui.Add("Picture", Format("x{} y{} w{} h{}", PosX, PosY, 80, 80), "")

        PosY += 90
        PosX := 330
        this.ColorTipCon := MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 80), GetLang("搜索颜色:"))
        PosX += 80
        this.HexColorCon := MyGui.Add("Edit", Format("x{} y{} w{} Center", PosX, PosY - 5, 120), "FFFFFF")
        PosX += 130
        this.HexColorTipCon := MyGui.Add("Text", Format("x{} y{} w{} Background{}", PosX, PosY, 20, "FF0000"), "")

        PosY += 30
        PosX := 330
        this.TextTipCon := MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 80), GetLang("搜索文本:"))
        PosX += 80
        this.TextCon := MyGui.Add("ComboBox", Format("x{} y{} w{} Center R5", PosX, PosY - 3, 120), [])
        PosY += 30
        PosX := 330
        this.OCRLabelCon := MyGui.Add("Text", Format("x{} y{} w{}", PosX, PosY, 80), GetLang("识别模型:"))
        PosX += 80
        this.OCRTypeCon := MyGui.Add("DropDownList", Format("x{} y{} w{} Center", PosX, PosY - 3, 80), GetLangArr(["中文",
            "英文"]))

        PosY += 30
        TempPosY := PosY
        PosX := 10
        MyGui.Add("Text", Format("x{} y{} w{} h{}", PosX, PosY, 170, 20), GetLang("找到后的指令:（可选）"))
        PosX += 180
        btnCon := MyGui.Add("Button", Format("x{} y{} w{} h{}", PosX, PosY - 5, 80, 20), GetLang("编辑指令"))
        btnCon.OnEvent("Click", (*) => this.OnEditFoundMacroBtnClick())
        PosY += 20
        PosX := 10
        this.FoundCommandStrCon := MyGui.Add("Edit", Format("x{} y{} w{} h{}", PosX, PosY, 280, 80), "")
        PosY := TempPosY
        PosX := 330
        MyGui.Add("Text", Format("x{} y{} w{} h{}", PosX, PosY, 170, 20), GetLang("未找到后的指令:（可选）"))
        PosX += 180
        btnCon := MyGui.Add("Button", Format("x{} y{} w{} h{}", PosX, PosY - 5, 80, 20), GetLang("编辑指令"))
        btnCon.OnEvent("Click", (*) => this.OnEditUnFoundMacroBtnClick())
        PosY += 20
        PosX := 330
        this.UnFoundCommandStrCon := MyGui.Add("Edit", Format("x{} y{} w{} h{}", PosX, PosY, 280, 80), "")
        TempPosY := PosY
        PosY += 90
        PosX := 10
        MyGui.Add("GroupBox", Format("x{} y{} w{} h{}", PosX, PosY, 310, 75), GetLang("结果保存"))

        PosY += 20
        PosX := 15
        MyGui.Add("Text", Format("x{} y{}", PosX, PosY), GetLang("开关"))
        PosX += 50
        con := MyGui.Add("Text", Format("x{} y{}", PosX, PosY), GetLang("变量名"))
        this.ResultTogArr.Push(con)
        PosX += 110
        con := MyGui.Add("Text", Format("x{} y{}", PosX, PosY), GetLang("真值"))
        this.ResultTogArr.Push(con)
        PosX += 85
        con := MyGui.Add("Text", Format("x{} y{}", PosX, PosY), GetLang("真值"))
        this.ResultTogArr.Push(con)

        PosY += 25
        PosX := 20
        this.ResultToggleCon := MyGui.Add("Checkbox", Format("x{} y{} w{}", PosX, PosY, 30))
        this.ResultToggleCon.OnEvent("Click", this.OnChangeType.Bind(this))
        this.ResultSaveNameCon := MyGui.Add("ComboBox", Format("x{} y{} w{} R5", PosX + 30, PosY - 3, 100), [])
        this.ResultTogArr.Push(this.ResultSaveNameCon)
        this.TrueValueCon := MyGui.Add("Edit", Format("x{} y{} w{} Center", PosX + 135, PosY - 4, 70), 0)
        this.ResultTogArr.Push(this.TrueValueCon)
        this.FalseValueCon := MyGui.Add("Edit", Format("x{} y{} w{} Center", PosX + 220, PosY - 4, 70), 0)
        this.ResultTogArr.Push(this.FalseValueCon)
        PosY := TempPosY
        PosY += 90
        PosX := 330
        MyGui.Add("GroupBox", Format("x{} y{} w{} h{}", PosX, PosY, 290, 75), GetLang("目标点保存"))

        PosY += 20
        PosX := 335
        MyGui.Add("Text", Format("x{} y{}", PosX, PosY), GetLang("开关"))
        PosX += 45
        con := MyGui.Add("Text", Format("x{} y{}", PosX, PosY), GetLang("坐标X变量名"))
        this.CoordTogArr.Push(con)
        PosX += 110
        con := MyGui.Add("Text", Format("x{} y{}", PosX, PosY), GetLang("坐标Y变量名"))
        this.CoordTogArr.Push(con)

        PosY += 25
        PosX := 340
        this.CoordToogleCon := MyGui.Add("Checkbox", Format("x{} y{} w{}", PosX, PosY, 30))
        this.CoordToogleCon.OnEvent("Click", this.OnChangeType.Bind(this))
        this.CoordXNameCon := MyGui.Add("ComboBox", Format("x{} y{} w{} R5", PosX + 35, PosY - 3, 100), [])
        this.CoordTogArr.Push(this.CoordXNameCon)
        this.CoordYNameCon := MyGui.Add("ComboBox", Format("x{} y{} w{} R5", PosX + 150, PosY - 3, 100), [])
        this.CoordTogArr.Push(this.CoordYNameCon)

        PosY += 40
        PosX := 270
        btnCon := MyGui.Add("Button", Format("x{} y{} w{} h{}", PosX, PosY, 100, 40), GetLang("确定"))
        btnCon.OnEvent("Click", (*) => this.OnClickSureBtn())
        MyGui.OnEvent("Close", (*) => this.ToggleFunc(false))
        MyGui.Show(Format("w{} h{}", 640, 550))
    }

    Init(cmd) {
        cmdArr := cmd != "" ? StrSplit(cmd, "_") : []
        this.SerialStr := cmdArr.Length >= 2 ? cmdArr[2] : GetSerialStr("Search")
        this.RemarkCon.Value := cmdArr.Length >= 3 ? cmdArr[3] : ""
        this.Data := this.GetSearchData(this.SerialStr)
        if (!this.CheckIfDataValid())
            return

        this.SearchTypeCon.Value := this.Data.SearchType
        this.SimilarCon.Value := this.Data.Similar
        this.OCRTypeCon.Value := this.Data.OCRType
        this.ImageTypeCon.Value := this.Data.SearchImageType
        this.ImageCon.GetPos(&imagePosX, &imagePosY)
        this.ImageCon.Value := this.Data.SearchImagePath
        this.ImageCon.Move(imagePosX, imagePosY, 80, 80)
        this.HexColorCon.Value := this.Data.SearchColor
        this.TextCon.Delete()
        this.TextCon.Add(this.VariableObjArr)
        this.TextCon.Text := this.Data.SearchText
        this.StartPosXCon.Value := this.Data.StartPosX
        this.StartPosYCon.Value := this.Data.StartPosY
        this.EndPosXCon.Value := this.Data.EndPosX
        this.EndPosYCon.Value := this.Data.EndPosY
        this.SearchCountCon.Delete()
        this.SearchCountCon.Add([GetLang("无限")])
        this.SearchCountCon.Text := this.Data.SearchCount == -1 ? GetLang("无限") : this.Data.SearchCount
        this.SearchIntervalCon.Value := this.Data.SearchInterval
        this.MouseActionTypeCon.Value := this.Data.MouseActionType
        this.SpeedCon.Value := this.Data.Speed
        this.ClickCountCon.Value := this.Data.ClickCount
        this.FoundCommandStrCon.Value := this.Data.TrueMacro
        this.UnFoundCommandStrCon.Value := this.Data.FalseMacro
        this.ResultToggleCon.Value := this.Data.ResultToggle
        this.ResultSaveNameCon.Delete()
        this.ResultSaveNameCon.Add(this.VariableObjArr)
        this.ResultSaveNameCon.Text := this.Data.ResultSaveName
        this.TrueValueCon.Value := this.Data.TrueValue
        this.FalseValueCon.Value := this.Data.FalseValue
        this.CoordToogleCon.Value := this.Data.CoordToogle
        this.CoordXNameCon.Delete()
        this.CoordXNameCon.Add(this.VariableObjArr)
        this.CoordXNameCon.Text := this.Data.CoordXName
        this.CoordYNameCon.Delete()
        this.CoordYNameCon.Add(this.VariableObjArr)
        this.CoordYNameCon.Text := this.Data.CoordYName
        this.OnChangeType()
    }

    GetCommandStr() {
        hasRemark := this.RemarkCon.Value != ""
        CommandStr := "搜索Pro_" this.Data.SerialStr
        if (hasRemark) {
            CommandStr .= "_" this.RemarkCon.Value
        }
        return CommandStr
    }

    GetSearchData(SerialStr) {
        saveStr := IniRead(SearchProFile, IniSection, SerialStr, "")
        if (!saveStr) {
            data := SearchData()
            data.SerialStr := SerialStr
            return data
        }

        data := JSON.parse(saveStr, , false)
        return data
    }

    CheckIfDataValid() {
        if (!ObjHasOwnProp(this.Data, "SearchImagePath")) {
            MsgBox(GetLang("这条指令不完整，请删除"))
            return false
        }

        if (this.Data.SearchImagePath != "" && !FileExist(this.Data.SearchImagePath)) {
            MsgBox(Format(GetLang("{} 图片不存在`n如果是软件位置发生改变，请点击若梦兔-配置管理-配置校准"), this.Data.SearchImagePath))
            return false
        }
        return true
    }

    CheckIfValid() {
        if (!IsNumber(this.StartPosXCon.Value) || !IsNumber(this.StartPosYCon.Value) || !IsNumber(this.EndPosXCon.Value
        ) || !IsNumber(this.EndPosYCon.Value)) {
            MsgBox(GetLang("坐标中请输入数字"))
            return false
        }

        if (Number(this.StartPosXCon.Value) > Number(this.EndPosXCon.Value) || Number(this.StartPosYCon.Value) >
        Number(
            this.EndPosYCon.Value)) {
            MsgBox(GetLang("起始坐标不能大于终止坐标"))
            return false
        }

        if (this.SearchCountCon.Text == GetLang("无限")) {

        }
        else if (!IsNumber(this.SearchCountCon.Text) || Number(this.SearchCountCon.Text) <= 0) {
            MsgBox(GetLang("搜索次数请输入大于0的数字"))
            return false
        }

        if (this.SearchTypeCon.Value == 1 && this.Data.SearchImagePath == "") {
            MsgBox(GetLang("请设置搜索图片"))
            return false
        }

        if (this.SearchTypeCon.Value == 1) {
            searchWidth := this.EndPosXCon.Value - this.StartPosXCon.Value
            searchHeight := this.EndPosYCon.Value - this.StartPosYCon.Value
            size := GetImageSize(this.Data.SearchImagePath)
            if (size[1] > searchWidth || size[2] > searchHeight) {
                MsgBox(GetLang("搜索范围不能小于图片大小"))
                return false
            }
        }

        if (this.SearchTypeCon.Value == 2 && !RegExMatch(this.HexColorCon.Value, "^([0-9A-Fa-f]{6})$")) {
            MsgBox(GetLang("请输入正确的颜色值"))
            return false
        }

        if (this.SearchTypeCon.Value == 3) {
            if (Number(this.StartPosXCon.Value) == Number(this.EndPosXCon.Value) ||
            Number(this.StartPosYCon.Value) == Number(this.EndPosYCon.Value)) {
                MsgBox(GetLang("搜索文本时：搜索范围中起始坐标不能和终止坐标相同"))
                return false
            }
        }

        if (this.ResultToggleCon.Value) {
            if (IsNumber(this.ResultSaveNameCon.Text)) {
                MsgBox(GetLang("结果变量名不规范：变量名不能是纯数字"))
                return false
            }

            if (this.ResultSaveNameCon.Text == "") {
                MsgBox(GetLang("结果变量名不规范：变量名不能为空"))
                return false
            }
        }

        return true
    }

    ToggleFunc(state) {
        MacroAction := (*) => this.TriggerMacro()
        if (state) {
            SetTimer this.PosAction, 100
            Hotkey("!l", MacroAction, "On")
            Hotkey("F1", (*) => this.OnF1(), "On")
            Hotkey("F2", (*) => this.OnScreenShotBtnClick(), "On")
            Hotkey("F3", (*) => this.SureColor(), "On")
        }
        else {
            SetTimer this.PosAction, 0
            Hotkey("!l", MacroAction, "Off")
            Hotkey("F1", (*) => this.OnF1(), "Off")
            Hotkey("F2", (*) => this.OnScreenShotBtnClick(), "Off")
            Hotkey("F3", (*) => this.SureColor(), "Off")
        }
    }

    RefreshMouseInfo() {
        CoordMode("Mouse", "Screen")
        MouseGetPos &mouseX, &mouseY
        this.MousePosCon.Value := Format("{}{},{}", GetLang("当前鼠标坐标:"), mouseX, mouseY)

        CoordMode("Pixel", "Screen")
        Color := PixelGetColor(mouseX, mouseY, "Slow")
        ColorText := StrReplace(Color, "0x", "")
        this.MouseColorCon.Value := Format("{}{}", GetLang("当前鼠标坐标:"), ColorText)
        this.MouseColorTipCon.Opt(Format("+Background0x{}", ColorText))
        this.MouseColorTipCon.Redraw()
    }

    OnSureTarget(PosX, PosY, Color) {
        ColorText := StrReplace(Color, "0x", "")
        this.HexColorCon.Value := ColorText
        this.HexColor := ColorText
        this.HexColorTipCon.Visible := true
        this.HexColorTipCon.Opt(Format("+Background0x{}", this.HexColorCon.Value))
        this.HexColorTipCon.Redraw()
        this.OnSetSearchArea(PosX, PosY, PosX, PosY)
    }

    OnClickTargeterBtn(*) {
        MyTargetGui.SureAction := this.OnSureTarget.Bind(this)
        MyTargetGui.ShowGui()
    }

    OnClickTargeterHelpBtn(*) {
        MsgBox(GetLang("1.左键拖拽改变位置`n2.上下左右方向键微调位置`n3.左键双击或回车键关闭取色器，同时确定点位信息"), GetLang("定位取色器操作说明"))
    }

    OnClickSureBtn() {
        valid := this.CheckIfValid()
        if (!valid)
            return
        this.SaveSearchData()
        action := this.SureBtnAction
        action(this.GetCommandStr())
        this.ToggleFunc(false)
        this.Gui.Hide()
    }

    OnClickSetPicBtn() {
        path := FileSelect(1, , GetLang("选择图片"), "PNG Files (*.png)")
        this.ImageCon.Value := path
        this.Data.SearchImagePath := path
    }

    OnScreenShotBtnClick() {
        if (MySoftData.ScreenShotTypeCtrl.Value == 1) {
            A_Clipboard := ""  ; 清空剪贴板
            Run("ms-screenclip:")
            SetTimer(this.CheckClipboardAction, 500)  ; 每 500 毫秒检查一次剪贴板
            TogGetSelectArea(true, this.OnGetArea.Bind(this))
        }
        else {
            TogSelectArea(true, this.OnScreenShotGetArea.Bind(this))
        }
    }

    CheckClipboard() {
        ; 如果剪贴板中有图像
        if DllCall("IsClipboardFormatAvailable", "uint", 8)  ; 8 是 CF_BITMAP 格式
        {
            ; 获取当前日期和时间，用于生成唯一的文件名
            CurrentDateTime := FormatTime(, "HHmmss")
            filePath := A_WorkingDir "\Setting\" MySoftData.CurSettingName "\Images\ScreenShot\" CurrentDateTime ".png"
            SaveClipToBitmap(filePath)
            this.ImageCon.Value := filePath
            this.Data.SearchImagePath := filePath
            ; 停止监听
            SetTimer(, 0)
        }
    }

    OnGetArea(x1, y1, x2, y2) {
        AreaX1 := Max(0, x1 - 20)
        AreaX2 := Min(A_ScreenWidth, x2 + 20)
        AreaY1 := Max(0, y1 - 20)
        AreaY2 := Min(A_ScreenHeight, y2 + 20)
        this.OnSetSearchArea(AreaX1, AreaY1, AreaX2, AreaY2)
    }

    OnScreenShotGetArea(x1, y1, x2, y2) {
        CurrentDateTime := FormatTime(, "HHmmss")
        filePath := A_WorkingDir "\Setting\" MySoftData.CurSettingName "\Images\ScreenShot\" CurrentDateTime ".png"
        ScreenShot(x1, y1, x2, y2, filePath)
        this.ImageCon.Value := filePath
        this.Data.SearchImagePath := filePath

        this.OnGetArea(x1, y1, x2, y2)
    }

    OnSureFoundMacroBtnClick(CommandStr) {
        this.FoundCommandStr := CommandStr
        this.FoundCommandStrCon.Value := CommandStr
    }

    OnSureUnFoundMacroBtnClick(CommandStr) {
        this.UnFoundCommandStr := CommandStr
        this.UnFoundCommandStrCon.Value := CommandStr
    }

    OnEditFoundMacroBtnClick() {
        if (this.MacroGui == "") {
            this.MacroGui := MacroEditGui()
            this.MacroGui.VariableObjArr := this.VariableObjArr
            this.MacroGui.SureFocusCon := this.MousePosCon

            ParentTile := StrReplace(this.Gui.Title, GetLang("编辑器"), "")
            this.MacroGui.ParentTile := ParentTile "-"
        }

        this.MacroGui.SureBtnAction := (command) => this.OnSureFoundMacroBtnClick(command)
        this.MacroGui.ShowGui(this.FoundCommandStrCon.Value, false)
    }

    OnEditUnFoundMacroBtnClick() {
        if (this.MacroGui == "") {
            this.MacroGui := MacroEditGui()
            this.MacroGui.VariableObjArr := this.VariableObjArr
            this.MacroGui.SureFocusCon := this.MousePosCon

            ParentTile := StrReplace(this.Gui.Title, GetLang("编辑器"), "")
            this.MacroGui.ParentTile := ParentTile "-"
        }
        this.MacroGui.SureBtnAction := (command) => this.OnSureUnFoundMacroBtnClick(command)
        this.MacroGui.ShowGui(this.UnFoundCommandStrCon.Value, false)
    }

    OnChangeType(*) {
        isImage := this.SearchTypeCon.Value == 1
        isColor := this.SearchTypeCon.Value == 2
        isText := this.SearchTypeCon.Value == 3

        showImageTip := isImage && this.Data.SearchImagePath == ""
        showColorTip := isColor && RegExMatch(this.HexColorCon.Value, "^([0-9A-Fa-f]{6})$")

        this.ImageBtn.Enabled := isImage
        this.ScreenshotBtn.Enabled := isImage
        this.ImageTypeCon.Enabled := isImage && A_PtrSize == 8
        this.ImageTipCon.Enabled := isImage
        this.ImageTypeTipCon.Enabled := isImage
        this.ImageCon.Enabled := isImage
        if (A_PtrSize != 8)
            this.ImageTypeCon.Value := 2

        this.HexColorCon.Enabled := isColor
        this.ColorTipCon.Enabled := isColor
        this.HexColorTipCon.Visible := showColorTip
        if (showColorTip) {
            this.HexColorTipCon.Opt(Format("+Background0x{}", this.HexColorCon.Value))
            this.HexColorTipCon.Redraw()
        }

        this.TextCon.Enabled := isText
        this.OCRLabelCon.Enabled := isText
        this.OCRTypeCon.Enabled := isText
        this.TextTipCon.Enabled := isText
        this.MousePosCon.Focus()

        CountValue := this.SearchCountCon.Text == GetLang("无限") ? -1 : this.SearchCountCon.Text
        isCount := IsNumber(CountValue) && (CountValue == -1 || CountValue > 1)
        this.SetConArrState(this.CountTogArr, isCount)

        isMouseAction := this.MouseActionTypeCon.Value != 1
        this.SetConArrState(this.MouseTogArr, isMouseAction)

        isSaveResult := this.ResultToggleCon.Value
        this.SetConArrState(this.ResultTogArr, isSaveResult)

        isCoord := this.CoordToogleCon.Value
        this.SetConArrState(this.CoordTogArr, isCoord)
    }

    SetConArrState(ConArr, state) {
        for Value in ConArr {
            Value.Enabled := state
        }
    }

    TriggerMacro() {
        valid := this.CheckIfValid()
        if (!valid)
            return
        this.SaveSearchData()
        tableItem := MySoftData.SpecialTableItem
        tableItem.KilledArr[1] := false
        tableItem.PauseArr[1] := 0
        tableItem.ActionCount[1] := 0
        tableItem.VariableMapArr[1] := Map()
        tableItem.index := 1

        OnSearch(tableItem, this.GetCommandStr(), 1)
    }

    OnClickSelectToggle() {
        state := this.SelectToggleCon.Value
        if (state == 1)
            TogSelectArea(true, this.SetAreaAction)
        else
            TogSelectArea(false)
    }

    OnF1() {
        this.SelectToggleCon.Value := 1
        TogSelectArea(true, this.SetAreaAction)
    }

    OnSetSearchArea(x1, y1, x2, y2) {
        this.SelectToggleCon.Value := 0
        this.StartPosXCon.Value := x1
        this.StartPosYCon.Value := y1
        this.EndPosXCon.Value := x2
        this.EndPosYCon.Value := y2
    }

    SureColor() {
        CoordMode("Mouse", "Screen")
        MouseGetPos &mouseX, &mouseY

        CoordMode("Pixel", "Screen")
        Color := PixelGetColor(mouseX, mouseY, "Slow")
        ColorText := StrReplace(Color, "0x", "")
        this.HexColorCon.Value := ColorText
        this.HexColor := ColorText
        this.HexColorTipCon.Visible := true
        this.HexColorTipCon.Opt(Format("+Background0x{}", this.HexColorCon.Value))
        this.HexColorTipCon.Redraw()
        this.OnSetSearchArea(mouseX, mouseY, mouseX, mouseY)
    }

    SaveSearchData() {
        data := this.Data
        data.Similar := this.SimilarCon.Value
        data.OCRType := this.OCRTypeCon.Value
        data.SearchImageType := this.ImageTypeCon.Value
        data.SearchType := this.SearchTypeCon.Value
        data.SearchColor := this.HexColorCon.Value
        data.SearchText := this.TextCon.Text
        data.StartPosX := this.StartPosXCon.Value
        data.StartPosY := this.StartPosYCon.Value
        data.EndPosX := this.EndPosXCon.Value
        data.EndPosY := this.EndPosYCon.Value
        data.SearchCount := this.SearchCountCon.Text == GetLang("无限") ? -1 : this.SearchCountCon.Text
        data.SearchInterval := this.SearchIntervalCon.Value
        data.MouseActionType := this.MouseActionTypeCon.Value
        data.ClickCount := this.ClickCountCon.Value
        data.Speed := this.SpeedCon.Value
        data.TrueMacro := this.FoundCommandStrCon.Value
        data.FalseMacro := this.UnFoundCommandStrCon.Value
        data.ResultToggle := this.ResultToggleCon.Value
        data.ResultSaveName := this.ResultSaveNameCon.Text
        data.TrueValue := this.TrueValueCon.Value
        data.FalseValue := this.FalseValueCon.Value
        data.CoordToogle := this.CoordToogleCon.Value
        data.CoordXName := this.CoordXNameCon.Text
        data.CoordYName := this.CoordYNameCon.Text

        if (data.ResultToggle)
            MySoftData.GlobalVariMap[data.ResultSaveName] := true

        if (data.CoordToogle) {
            MySoftData.GlobalVariMap[data.CoordXName] := true
            MySoftData.GlobalVariMap[data.CoordYName] := true
        }

        saveStr := JSON.stringify(data, 0)
        IniWrite(saveStr, SearchProFile, IniSection, data.SerialStr)
        if (MySoftData.DataCacheMap.Has(this.Data.SerialStr)) {
            MySoftData.DataCacheMap.Delete(this.Data.SerialStr)
        }
    }
}
