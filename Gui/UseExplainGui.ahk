#Requires AutoHotkey v2.0

class UseExplainGui {
    __new() {
        this.Gui := ""
        this.ContextMenu := ""
        this.AuthorCon := ""
        this.EffectCon := ""
        this.OperCon := ""
        this.LVCon := ""
        this.AllImagePathMap := Map()
        this.ImagePathArr := []
        this.CheckClipboardAction := () => this.CheckClipboard()
        this.SettingPath := ""
        this.Mode := 1  ;1查看模式  2上传确认模式
        this.HasChange := false
        this.ModeAction := ""
    }

    ShowGui(SettingPath) {
        if (this.Gui != "") {
            this.Gui.Show()
        }
        else {
            this.AddGui()
        }
        this.Init(SettingPath)
        this.LVCon.Focus()  ; 🔥 强制获得焦点，解决第一次双击无效问题
    }

    AddGui() {
        MyGui := Gui(, GetLang("使用说明"))
        this.Gui := MyGui
        MyGui.SetFont("S11 W550 Q2", MySoftData.FontType)

        PosX := 10
        PosY := 10
        MyGui.Add("Text", Format("x{} y{}", PosX, PosY), GetLang("配置名称："))

        PosX := 100
        MyGui.Add("Text", Format("x{} y{}", PosX, PosY), MySoftData.CurSettingName)

        PosX := 10
        PosY += 30
        MyGui.Add("Text", Format("x{} y{}", PosX, PosY), GetLang("作者："))
        PosX := 100
        this.AuthorCon := MyGui.Add("Edit", Format("x{} y{} w{}", PosX, PosY - 2, 480))
        this.AuthorCon.OnEvent("Change", this.OnValueChange.Bind(this))

        PosX := 10
        PosY += 40
        MyGui.Add("Text", Format("x{} y{}", PosX, PosY), GetLang("配置作用："))
        PosX := 100
        this.EffectCon := MyGui.Add("Edit", Format("x{} y{} w{} h{}", PosX, PosY - 2, 480, 60))
        this.EffectCon.OnEvent("Change", this.OnValueChange.Bind(this))

        PosX := 10
        PosY += 70
        MyGui.Add("Text", Format("x{} y{}", PosX, PosY), GetLang("操作说明："))
        PosX := 100
        this.OperCon := MyGui.Add("Edit", Format("x{} y{} w{} h{}", PosX, PosY - 2, 480, 200))
        this.OperCon.OnEvent("Change", this.OnValueChange.Bind(this))

        PosX := 10
        PosY += 210
        MyGui.Add("Text", Format("x{} y{}", PosX, PosY), GetLang("图片备注："))
        PosX := 100
        this.LVCon := MyGui.AddListView(Format("x{} y{} w{} h{} Icon", PosX, PosY - 2, 480, 100))
        this.LVCon.OnEvent("DoubleClick", this.OnLVDoubleClick.Bind(this))
        this.LVCon.OnEvent("ContextMenu", this.OnLVRightClick.Bind(this))

        PosX := 10
        PosY += 25
        con := MyGui.Add("Button", Format("x{} y{} w{}", PosX, PosY, 80), GetLang("选择图片"))
        con.OnEvent("Click", (*) => this.OnSelectImage())

        PosX := 10
        PosY += 35
        con := MyGui.Add("Button", Format("x{} y{} w{}", PosX, PosY, 80), GetLang("截图"))
        con.OnEvent("Click", (*) => this.OnScreenShot())

        PosY += 50
        PosX := 250
        btnCon := MyGui.Add("Button", Format("x{} y{} w{} h{}", PosX, PosY, 100, 40), GetLang("确定"))
        btnCon.OnEvent("Click", (*) => this.OnClickSureBtn())
        MyGui.OnEvent("Close", (*) => this.OnTriggerModeAction(false, false))
        MyGui.Show(Format("w{} h{}", 600, 520))
    }

    Init(SettingPath) {
        this.SettingPath := SettingPath
        this.IL := IL_Create(10, 5, true)   ; 5 = 色深，true = large icon
        this.LVCon.SetImageList(this.IL)
        this.ImagePathArr := []
        this.HasChange := false
        if (this.Mode == 2)
            this.Gui.Title := "请完善使用说明"
        OperFilePath := SettingPath "\使用说明&署名.txt"
        IniSection := "Instructions for Use & Attribution"
        AuthorText := IniRead(OperFilePath, IniSection, "Author", "")
        EffectText := IniRead(OperFilePath, IniSection, "Effect", "")
        OperText := IniRead(OperFilePath, IniSection, "Operation", "")
        AuthorText := StrReplace(AuthorText, "⫶", "`n")
        EffectText := StrReplace(EffectText, "⫶", "`n")
        OperText := StrReplace(OperText, "⫶", "`n")
        this.AuthorCon.Value := AuthorText
        this.EffectCon.Value := EffectText
        this.OperCon.Value := OperText

        this.LVCon.Delete()
        ImagesfolderPath := SettingPath "\Images\UseExplain"
        loop files ImagesfolderPath "\*.png" {
            this.AllImagePathMap.Set(A_LoopFileFullPath, true)
            this.ImagePathArr.Push(A_LoopFileFullPath)
            IL_Add(this.IL, this.ImagePathArr[A_Index])
            this.LVCon.Add("Icon" . A_Index)
        }
    }

    OnLVDoubleClick(LV, RowNumber, *) {
        if (RowNumber == 0)
            return
        this.OnValueChange()
        path := this.ImagePathArr[RowNumber]
        run path
    }

    OnLVRightClick(LV, RowNumber, isRightClick, x, y) {
        if (RowNumber == 0)
            return
        this.OnValueChange()
        this.RowNumber := RowNumber
        if (this.ContextMenu == "") {
            this.ContextMenu := Menu()
            this.ContextMenu.Add(GetLang("删除"), (*) => this.MenuHandler(GetLang("删除")))
        }
        this.ContextMenu.Show(x, y)
    }

    OnSelectImage() {
        path := FileSelect(1, , GetLang("选择图片"), "PNG Files (*.png)")
        if (path == "")
            return

        this.OnValueChange()
        SplitPath path, &name, &dir, &ext, &name_no_ext, &drive
        newPath := this.SettingPath "\Images\UseExplain\" name
        if (FileExist(newPath)) {
            MsgBox(GetLang("该图片已添加，请勿重复添加！！！"))
            return
        }

        FileCopy(path, newPath)
        this.AllImagePathMap.Push(newPath, true)
        this.ImagePathArr.Push(newPath)
        IL_Add(this.IL, newPath)
        this.LVCon.Add("Icon" . this.AllImagePathMap.Count)
    }

    OnScreenShot() {
        this.OnValueChange()
        if (MySoftData.ScreenShotTypeCtrl.Value == 1) {
            A_Clipboard := ""  ; 清空剪贴板
            Run("ms-screenclip:")
            SetTimer(this.CheckClipboardAction, 500)  ; 每 500 毫秒检查一次剪贴板
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
            filePath := this.SettingPath "\Images\UseExplain\" CurrentDateTime ".png"
            SaveClipToBitmap(filePath)

            this.AllImagePathMap.Set(filePath, true)
            this.ImagePathArr.Push(filePath)
            IL_Add(this.IL, filePath)
            this.LVCon.Add("Icon" . this.AllImagePathMap.Count)
            SetTimer(, 0)
        }
    }

    OnScreenShotGetArea(x1, y1, x2, y2) {
        CurrentDateTime := FormatTime(, "HHmmss")
        filePath := this.SettingPath "\Images\UseExplain\" CurrentDateTime ".png"
        ScreenShot(x1, y1, x2, y2, filePath)

        this.AllImagePathMap.Set(filePath, true)
        this.ImagePathArr.Push(filePath)
        IL_Add(this.IL, filePath)
        this.LVCon.Add("Icon" . this.AllImagePathMap.Count)
    }

    CheckIfValid() {
        if (this.Mode == 1)
            return true

        if (Trim(this.AuthorCon.Value) == "") {
            MsgBox(GetLang("请完善作者信息，若不想留名请输入匿名"))
            return false
        }

        if (Trim(this.EffectCon.Value) == "") {
            MsgBox(GetLang("请完善配置作用信息，简要的介绍配置的作用"))
            return false
        }

        if (Trim(this.OperCon.Value) == "") {
            MsgBox(GetLang("请完善操作说明信息，详细说明配置对应的操作"))
            return false
        }

        return true
    }

    OnValueChange(*) {
        this.HasChange := true
    }

    OnTriggerModeAction(isSure, isChange) {
        if (this.ModeAction == "")
            return
        action := this.ModeAction
        action(isSure, isChange)
        this.ModeAction := ""
    }

    OnClickSureBtn() {
        isValid := this.CheckIfValid()
        if (!isValid)
            return

        OperFilePath := this.SettingPath "\使用说明&署名.txt"
        IniSection := "Instructions for Use & Attribution"
        AuthorText := StrReplace(this.AuthorCon.Value, "`n", "⫶")
        EffectText := StrReplace(this.EffectCon.Value, "`n", "⫶")
        OperText := StrReplace(this.OperCon.Value, "`n", "⫶")
        IniWrite(AuthorText, OperFilePath, IniSection, "Author")
        IniWrite(EffectText, OperFilePath, IniSection, "Effect")
        IniWrite(OperText, OperFilePath, IniSection, "Operation")
        this.Gui.Hide()
    
        this.OnTriggerModeAction(true, this.HasChange)
    }

    MenuHandler(cmdStr, *) {
        switch cmdStr {
            case GetLang("删除"):
            {
                imagePath := this.ImagePathArr[this.RowNumber]
                this.LVCon.Delete(this.RowNumber)
                this.ImagePathArr.RemoveAt(this.RowNumber)
                if (FileExist(imagePath))
                    FileDelete(imagePath)
            }
        }

    }
}
