#Requires AutoHotkey v2.0
#Include IntervalGui.ahk
#Include KeyGui.ahk
#Include MouseMoveGui.ahk
#Include SearchGui.ahk
#Include SearchProGui.ahk
#Include RunGui.ahk
#Include CompareGui.ahk
#Include MMProGui.ahk
#Include OutputGui.ahk
#Include VariableGui.ahk
#Include SubMacroGui.ahk
#Include OperationGui.ahk
#Include BGMouseGui.ahk
#Include ExVariableGui.ahk
#Include RMTCMDGui.ahk
#Include BGKeyGui.ahk
#Include LoopGui.ahk
#Include CompareProGui.ahk

class MacroEditGui {
    __new() {
        this.Gui := ""
        this.ShowSaveBtn := false
        this.SureFocusCon := ""
        this.VariableObjArr := []
        this.isContextEdit := false
        this.RecordToggleCon := ""
        this.EditModeCon := ""
        this.SubMacroEditGui := ""

        this.SureBtnAction := ""
        this.SaveBtnAction := ""
        this.SaveBtnCtrl := {}
        this.CmdBtnConMap := map()
        this.SubGuiMap := map()
        this.MacroTreeViewCon := ""
        this.MacroEditTextCon := ""
        this.CmdEditType := 1  ;1添加指令 2修改当前指令 3向上插入指令 4 向下插入指令
        this.CurItemID := ""  ;当前操作itemID
        this.LastItemID := "" ;最后的itemID
        this.ContextMenu := ""
        this.BranchContextMenu := ""
        this.RecordMacroCon := ""
        this.DefaultFocusCon := ""
        this.SubMacroLastIndex := 0

        this.CMDStrArr := ["间隔", "按键", "搜索", "搜索Pro", "移动", "移动Pro", "输出", "运行", "变量", "变量提取", "运算", "如果", "宏操作",
            "RMT指令", "后台鼠标", "后台按键"]
        this.IconMap := Map("间隔", "Icon1", "按键", "Icon2", "搜索", "Icon3", "搜索Pro", "Icon4", "移动", "Icon5", "移动Pro",
            "Icon6", "输出", "Icon7",
            "运行", "Icon8", "变量", "Icon9", "变量提取", "Icon10", "运算", "Icon11", "如果", "Icon12", "RMT指令", "Icon13", "宏操作",
            "Icon14", "后台鼠标", "Icon15", "真", "Icon16", "假", "Icon17", "后台按键", "Icon2")

        this.InitSubGui()
    }

    InitSubGui() {
        this.IntervalGui := IntervalGui()
        this.IntervalGui.SureBtnAction := (CommandStr) => this.OnSubGuiSureBtnClick(CommandStr)
        this.SubGuiMap.Set("间隔", this.IntervalGui)

        this.KeyGui := KeyGui()
        this.KeyGui.SureBtnAction := (CommandStr) => this.OnSubGuiSureBtnClick(CommandStr)
        this.SubGuiMap.Set("按键", this.KeyGui)

        this.MoveMoveGui := MouseMoveGui()
        this.MoveMoveGui.SureBtnAction := (CommandStr) => this.OnSubGuiSureBtnClick(CommandStr)
        this.SubGuiMap.Set("移动", this.MoveMoveGui)

        this.SearchGui := SearchGui()
        this.SearchGui.SureBtnAction := (CommandStr) => this.OnSubGuiSureBtnClick(CommandStr)
        this.SubGuiMap.Set("搜索", this.SearchGui)

        this.SearchProGui := SearchProGui()
        this.SearchProGui.SureBtnAction := (CommandStr) => this.OnSubGuiSureBtnClick(CommandStr)
        this.SubGuiMap.Set("搜索Pro", this.SearchProGui)

        this.RunGui := RunGui()
        this.RunGui.SureBtnAction := (CommandStr) => this.OnSubGuiSureBtnClick(CommandStr)
        this.SubGuiMap.Set("运行", this.RunGui)

        this.CompareGui := CompareGui()
        this.CompareGui.SureBtnAction := (CommandStr) => this.OnSubGuiSureBtnClick(CommandStr)
        this.SubGuiMap.Set("如果", this.CompareGui)

        this.CompareProGui := CompareProGui()
        this.CompareProGui.SureBtnAction := (CommandStr) => this.OnSubGuiSureBtnClick(CommandStr)
        this.SubGuiMap.Set("如果Pro", this.CompareProGui)

        this.MMProGui := MMProGui()
        this.MMProGui.SureBtnAction := (CommandStr) => this.OnSubGuiSureBtnClick(CommandStr)
        this.SubGuiMap.Set("移动Pro", this.MMProGui)

        this.OutputGui := OutputGui()
        this.OutputGui.SureBtnAction := (CommandStr) => this.OnSubGuiSureBtnClick(CommandStr)
        this.SubGuiMap.Set("输出", this.OutputGui)

        this.VariableGui := VariableGui()
        this.VariableGui.SureBtnAction := (CommandStr) => this.OnSubGuiSureBtnClick(CommandStr)
        this.SubGuiMap.Set("变量", this.VariableGui)

        this.ExVariableGui := ExVariableGui()
        this.ExVariableGui.SureBtnAction := (CommandStr) => this.OnSubGuiSureBtnClick(CommandStr)
        this.SubGuiMap.Set("变量提取", this.ExVariableGui)

        this.SubMacroGui := SubMacroGui()
        this.SubMacroGui.SureBtnAction := (CommandStr) => this.OnSubGuiSureBtnClick(CommandStr)
        this.SubGuiMap.Set("宏操作", this.SubMacroGui)

        this.LoopGui := LoopGui()
        this.LoopGui.SureBtnAction := (CommandStr) => this.OnSubGuiSureBtnClick(CommandStr)
        this.SubGuiMap.Set("循环", this.LoopGui)

        this.OperationGui := OperationGui()
        this.OperationGui.SureBtnAction := (CommandStr) => this.OnSubGuiSureBtnClick(CommandStr)
        this.SubGuiMap.Set("运算", this.OperationGui)

        this.BGMouseGui := BGMouseGui()
        this.BGMouseGui.SureBtnAction := (CommandStr) => this.OnSubGuiSureBtnClick(CommandStr)
        this.SubGuiMap.Set("后台鼠标", this.BGMouseGui)

        this.BGKeyGui := BGKeyGui()
        this.BGKeyGui.SureBtnAction := (CommandStr) => this.OnSubGuiSureBtnClick(CommandStr)
        this.SubGuiMap.Set("后台按键", this.BGKeyGui)

        this.RMTCMDGui := RMTCMDGui()
        this.RMTCMDGui.SureBtnAction := (CommandStr) => this.OnSubGuiSureBtnClick(CommandStr)
        this.SubGuiMap.Set("RMT指令", this.RMTCMDGui)
    }

    ShowGui(CommandStr, ShowSaveBtn) {
        global MySoftData
        if (this.Gui != "") {
            this.Gui.Show()
        }
        else {
            this.AddGui()
            ImageListID := IL_Create(15)
            this.MacroTreeViewCon.SetImageList(ImageListID)
            IL_Add(ImageListID, "Images\Soft\Interval.png")
            IL_Add(ImageListID, "Images\Soft\Key.png")
            IL_Add(ImageListID, "Images\Soft\Search.png")
            IL_Add(ImageListID, "Images\Soft\SearchPro.png")
            IL_Add(ImageListID, "Images\Soft\Move.png")
            IL_Add(ImageListID, "Images\Soft\MovePro.png")
            IL_Add(ImageListID, "Images\Soft\Output.png")
            IL_Add(ImageListID, "Images\Soft\Run.png")
            IL_Add(ImageListID, "Images\Soft\Var.png")
            IL_Add(ImageListID, "Images\Soft\Extract.png")
            IL_Add(ImageListID, "Images\Soft\Operation.png")
            IL_Add(ImageListID, "Images\Soft\If.png")
            IL_Add(ImageListID, "Images\Soft\rabit.png")
            IL_Add(ImageListID, "Images\Soft\Sub.png")
            IL_Add(ImageListID, "Images\Soft\Mouse.png")
            IL_Add(ImageListID, "Images\Soft\True.png")
            IL_Add(ImageListID, "Images\Soft\False.png")
        }

        MySoftData.RecordToggleCon := this.RecordMacroCon
        MySoftData.MacroEditGui := this
        this.Init(CommandStr, ShowSaveBtn)
    }

    AddGui() {
        MyGui := Gui(, "指令编辑器")
        this.Gui := MyGui
        MyGui.SetFont("S10 W550 Q2", MySoftData.FontType)

        PosY := 10
        PosX := 10
        MyGui.Add("GroupBox", Format("x{} y{} w{} h{}", PosX, PosY, 170, 530), "指令选项")

        PosY += 20
        PosX := 15
        btnCon := MyGui.Add("Button", Format("x{} y{} h{} w{} center", PosX, PosY, 30, 75), "间隔")
        btnCon.SetFont((Format("S{} W{} Q{}", 11, 400, 5)))
        btnCon.OnEvent("Click", (*) => this.OnOpenSubGui(this.IntervalGui))
        this.CmdBtnConMap.Set("间隔", btnCon)

        PosX += 85
        btnCon := MyGui.Add("Button", Format("x{} y{} h{} w{} center", PosX, PosY, 30, 75), "按键")
        btnCon.SetFont((Format("S{} W{} Q{}", 11, 400, 5)))
        btnCon.OnEvent("Click", (*) => this.OnOpenSubGui(this.KeyGui))
        this.CmdBtnConMap.Set("按键", btnCon)

        PosX := 15
        PosY += 40
        btnCon := MyGui.Add("Button", Format("x{} y{} h{} w{} center", PosX, PosY, 30, 75), "搜索")
        btnCon.SetFont((Format("S{} W{} Q{}", 11, 400, 5)))
        btnCon.OnEvent("Click", (*) => this.OnOpenSubGui(this.SearchGui))
        this.CmdBtnConMap.Set("搜索", btnCon)

        PosX += 85
        btnCon := MyGui.Add("Button", Format("x{} y{} h{} w{} center", PosX, PosY, 30, 75), "搜索Pro")
        btnCon.SetFont((Format("S{} W{} Q{}", 11, 400, 5)))
        btnCon.OnEvent("Click", (*) => this.OnOpenSubGui(this.SearchProGui))
        this.CmdBtnConMap.Set("搜索Pro", btnCon)

        PosX := 15
        PosY += 40
        btnCon := MyGui.Add("Button", Format("x{} y{} h{} w{} center", PosX, PosY, 30, 75), "移动")
        btnCon.SetFont((Format("S{} W{} Q{}", 11, 400, 5)))
        btnCon.OnEvent("Click", (*) => this.OnOpenSubGui(this.MoveMoveGui))
        this.CmdBtnConMap.Set("移动", btnCon)

        PosX += 85
        btnCon := MyGui.Add("Button", Format("x{} y{} h{} w{} center", PosX, PosY, 30, 75), "移动Pro")
        btnCon.SetFont((Format("S{} W{} Q{}", 11, 400, 5)))
        btnCon.OnEvent("Click", (*) => this.OnOpenSubGui(this.MMProGui))
        this.CmdBtnConMap.Set("移动Pro", btnCon)

        PosX := 15
        PosY += 40
        btnCon := MyGui.Add("Button", Format("x{} y{} h{} w{} center", PosX, PosY, 30, 75), "输出")
        btnCon.SetFont((Format("S{} W{} Q{}", 11, 400, 5)))
        btnCon.OnEvent("Click", (*) => this.OnOpenSubGui(this.OutputGui))
        this.CmdBtnConMap.Set("输出", btnCon)

        PosX += 85
        btnCon := MyGui.Add("Button", Format("x{} y{} h{} w{} center", PosX, PosY, 30, 75), "运行")
        btnCon.SetFont((Format("S{} W{} Q{}", 11, 400, 5)))
        btnCon.OnEvent("Click", (*) => this.OnOpenSubGui(this.RunGui))
        this.CmdBtnConMap.Set("运行", btnCon)

        PosX := 15
        PosY += 40
        btnCon := MyGui.Add("Button", Format("x{} y{} h{} w{} center", PosX, PosY, 30, 75), "循环")
        btnCon.SetFont((Format("S{} W{} Q{}", 11, 400, 5)))
        btnCon.OnEvent("Click", (*) => this.OnOpenSubGui(this.LoopGui))
        this.CmdBtnConMap.Set("循环", btnCon)

        PosX += 85
        btnCon := MyGui.Add("Button", Format("x{} y{} h{} w{} center", PosX, PosY, 30, 75), "宏操作")
        btnCon.SetFont((Format("S{} W{} Q{}", 11, 400, 5)))
        btnCon.OnEvent("Click", (*) => this.OnOpenSubGui(this.SubMacroGui))
        this.CmdBtnConMap.Set("宏操作", btnCon)

        PosX := 15
        PosY += 40
        btnCon := MyGui.Add("Button", Format("x{} y{} h{} w{} center", PosX, PosY, 30, 75), "变量")
        btnCon.SetFont((Format("S{} W{} Q{}", 11, 400, 5)))
        btnCon.OnEvent("Click", (*) => this.OnOpenSubGui(this.VariableGui))
        this.CmdBtnConMap.Set("变量", btnCon)

        PosX += 85
        btnCon := MyGui.Add("Button", Format("x{} y{} h{} w{} center", PosX, PosY, 30, 75), "变量提取")
        btnCon.SetFont((Format("S{} W{} Q{}", 11, 400, 5)))
        btnCon.OnEvent("Click", (*) => this.OnOpenSubGui(this.ExVariableGui))
        this.CmdBtnConMap.Set("变量提取", btnCon)

        PosX := 15
        PosY += 40
        btnCon := MyGui.Add("Button", Format("x{} y{} h{} w{} center", PosX, PosY, 30, 75), "如果")
        btnCon.SetFont((Format("S{} W{} Q{}", 11, 400, 5)))
        btnCon.OnEvent("Click", (*) => this.OnOpenSubGui(this.CompareGui))
        this.CmdBtnConMap.Set("如果", btnCon)

        PosX += 85
        btnCon := MyGui.Add("Button", Format("x{} y{} h{} w{} center", PosX, PosY, 30, 75), "如果Pro")
        btnCon.SetFont((Format("S{} W{} Q{}", 11, 400, 5)))
        btnCon.OnEvent("Click", (*) => this.OnOpenSubGui(this.CompareProGui))
        this.CmdBtnConMap.Set("如果Pro", btnCon)

        PosX := 15
        PosY += 40
        btnCon := MyGui.Add("Button", Format("x{} y{} h{} w{} center", PosX, PosY, 30, 75), "运算")
        btnCon.SetFont((Format("S{} W{} Q{}", 11, 400, 5)))
        btnCon.OnEvent("Click", (*) => this.OnOpenSubGui(this.OperationGui))
        this.CmdBtnConMap.Set("运算", btnCon)

        PosX += 85
        btnCon := MyGui.Add("Button", Format("x{} y{} h{} w{} center", PosX, PosY, 30, 75), "RMT指令")
        btnCon.SetFont((Format("S{} W{} Q{}", 11, 400, 5)))
        btnCon.OnEvent("Click", (*) => this.OnOpenSubGui(this.RMTCMDGui))
        this.CmdBtnConMap.Set("RMT指令", btnCon)

        PosX := 15
        PosY += 40
        btnCon := MyGui.Add("Button", Format("x{} y{} h{} w{} center", PosX, PosY, 30, 75), "后台鼠标")
        btnCon.SetFont((Format("S{} W{} Q{}", 11, 400, 5)))
        btnCon.OnEvent("Click", (*) => this.OnOpenSubGui(this.BGMouseGui))
        this.CmdBtnConMap.Set("后台鼠标", btnCon)

        PosX += 85
        btnCon := MyGui.Add("Button", Format("x{} y{} h{} w{} center", PosX, PosY, 30, 75), "后台按键")
        btnCon.SetFont((Format("S{} W{} Q{}", 11, 400, 5)))
        btnCon.OnEvent("Click", (*) => this.OnOpenSubGui(this.BGKeyGui))
        this.CmdBtnConMap.Set("后台按键", btnCon)

        PosX := 200
        PosY := 10
        MyGui.Add("Text", Format("x{} y{}", PosX, PosY), "编辑模式：")
        PosX += 70
        this.EditModeCon := MyGui.Add("DropDownList", Format("x{} y{} w80", PosX, PosY - 3), ["逻辑树", "文本"])
        this.EditModeCon.Value := 1
        this.EditModeCon.OnEvent("Change", this.OnChangeEditMode.Bind(this))

        PosX := 400
        this.RecordMacroCon := MyGui.Add("Checkbox", Format("x{} y{}", PosX, PosY), "指令录制")
        this.RecordMacroCon.Value := false
        this.RecordMacroCon.OnEvent("Click", this.OnClickRecordTog.Bind(this))
        PosX += 85
        isHotKey := CheckIsNormalHotKey(ToolCheckInfo.ToolRecordMacroHotKey)
        CtrlType := isHotKey ? "Hotkey" : "Text"
        con := MyGui.Add(CtrlType, Format("x{} y{} w{}", posX, posY - 3, 130), ToolCheckInfo.ToolRecordMacroHotKey
        )
        con.Enabled := false

        PosX := 190
        PosY += 25
        MyGui.Add("GroupBox", Format("x{} y{} w{} h{}", PosX, PosY, 720, 460), "当前宏指令")
        PosY += 20
        this.MacroTreeViewCon := MyGui.Add("TreeView", Format("x{} y{} w{} h{}", PosX + 5, PosY, 705, 435),
        "")
        this.MacroTreeViewCon.OnEvent("ContextMenu", this.ShowContextMenu.Bind(this))  ; 右键菜单事件
        this.MacroTreeViewCon.OnEvent("DoubleClick", this.OnDoubleClick.Bind(this))  ; 双击编辑指令

        this.MacroEditTextCon := MyGui.Add("Edit", Format("x{} y{} w{} h{}", PosX + 5, PosY, 705, 435), "")
        this.MacroEditTextCon.Visible := false

        PosX := 190
        PosY := 500
        btnCon := MyGui.Add("Button", Format("x{} y{} h{} w{} center", PosX, PosY, 40, 100), "退格")
        btnCon.OnEvent("Click", (*) => this.Backspace())

        PosX += 150
        btnCon := MyGui.Add("Button", Format("x{} y{} h{} w{} center", PosX, PosY, 40, 100), "清空指令")
        btnCon.OnEvent("Click", (*) => this.ClearStr())

        PosX += 150
        btnCon := MyGui.Add("Button", Format("x{} y{} h{} w{} center", PosX, PosY, 40, 100), "确定")
        btnCon.OnEvent("Click", (*) => this.OnSureBtnClick())

        PosX += 150
        this.SaveBtnCtrl := MyGui.Add("Button", Format("x{} y{} h{} w{} center", PosX, PosY, 40, 100), "应用并保存")
        this.SaveBtnCtrl.OnEvent("Click", (*) => this.OnSaveBtnClick())

        MyGui.Show(Format("w{} h{}", 920, 550))
    }

    Init(MacroStr, ShowSaveBtn) {
        this.ShowSaveBtn := ShowSaveBtn
        this.SubMacroLastIndex := 0
        this.SaveBtnCtrl.Visible := this.ShowSaveBtn
        this.InitTreeView(MacroStr)
        this.InitMacroText(MacroStr)
    }

    Backspace() {
        if (this.EditModeCon.Value == 1) {
            if (this.MacroTreeViewCon.GetCount() == 0)
                return
            preItemID := this.MacroTreeViewCon.GetPrev(this.LastItemID)
            this.MacroTreeViewCon.Delete(this.LastItemID)
            this.LastItemID := preItemID
        }
        else {
            MacroStr := this.GetMacroStr()
            cmdArr := SplitMacro(MacroStr)
            if (cmdArr.Length > 0)
                cmdArr.Pop()
            MacroStr := GetMacroStrByCmdArr(cmdArr)

            ; 回到替换前的滑动值
            firstVisible := SendMessage(0xCE, 0, 0, this.MacroEditTextCon) ; EM_GETFIRSTVISIBLELINE = 0xCE
            this.InitMacroText(MacroStr)
            SendMessage(0xB6, 0, firstVisible, this.MacroEditTextCon) ; EM_LINESCROLL = 0xB6
        }
    }

    ClearStr() {
        this.MacroTreeViewCon.Delete()
        this.MacroEditTextCon.Value := ""
    }

    OnChangeEditMode(*) {
        MacroStr := this.GetMacroStr()
        this.MacroTreeViewCon.Visible := this.EditModeCon.Value == 1
        this.MacroEditTextCon.Visible := this.EditModeCon.Value == 2

        if (this.EditModeCon.Value == 1) {
            this.InitTreeView(MacroStr)
        }
        else if (this.EditModeCon.Value == 2) {
            this.InitMacroText(MacroStr)
        }
    }

    OnClickRecordTog(*) {
        MySoftData.RecordToggleCon := this.RecordMacroCon
        MySoftData.MacroEditGui := this
        OnHotToolRecordMacro(true)
    }

    OnSaveBtnClick() {
        macroStr := this.GetMacroStr()
        action := this.SureBtnAction
        action(macroStr)

        this.SureBtnAction := ""
        this.Gui.Hide()

        action := this.SaveBtnAction
        action()
        this.SureFocusCon.Focus()
    }

    OnSureBtnClick() {
        macroStr := this.GetMacroStr()
        action := this.SureBtnAction
        action(macroStr)

        this.SureBtnAction := ""
        this.Gui.Hide()
        this.SureFocusCon.Focus()
    }

    GetMacroStr() {
        MacroStr := ""
        if (this.MacroTreeViewCon.Visible) {
            MacroStr := this.GetTreeMacroStr(0)
        }
        else if (this.MacroEditTextCon.Visible) {
            MacroStr := this.MacroEditTextCon.Value
        }
        return MacroStr
    }

    InitMacroText(MacroStr) {
        this.MacroEditTextCon.Visible := this.EditModeCon.Value == 2

        content := RegExReplace(MacroStr, "[,，⫶]", "`n")
        this.MacroEditTextCon.Value := content
    }

    ShowContextMenu(ctrl, item, isRightClick, x, y) {
        if (item == 0)
            return

        if (this.ContextMenu == "") {
            this.ContextMenu := Menu()
            this.ContextMenu.Add("编辑", (*) => this.MenuHandler("编辑"))

            this.ContextMenu.Add()  ; 分隔线
            subMenu := Menu()
            for value in this.CMDStrArr {
                subMenu.Add(value, this.MenuHandler.Bind(this, "Pre_" value))
            }
            this.ContextMenu.Add("上方插入", subMenu)  ; 将子菜单添加到主菜单
            subMenu := Menu()
            for value in this.CMDStrArr {
                subMenu.Add(value, this.MenuHandler.Bind(this, "Next_" value))
            }
            this.ContextMenu.Add("下方插入", subMenu)  ; 将子菜单添加到主菜单

            this.ContextMenu.Add()  ; 分隔线
            this.ContextMenu.Add("共享复制", (*) => this.MenuHandler("共享复制"))
            this.ContextMenu.Add("完全复制", (*) => this.MenuHandler("完全复制"))
            this.ContextMenu.Add("上方粘贴", (*) => this.MenuHandler("上方粘贴"))
            this.ContextMenu.Add("下方粘贴", (*) => this.MenuHandler("下方粘贴"))

            this.ContextMenu.Add()  ; 分隔线
            this.ContextMenu.Add("删除", (*) => this.MenuHandler("删除"))
        }

        if (this.BranchContextMenu == "") {
            this.BranchContextMenu := Menu()

            subMenu := Menu()
            for value in this.CMDStrArr {
                subMenu.Add(value, this.MenuHandler.Bind(this, "Add_" value))
            }
            this.BranchContextMenu.Add("添加指令", subMenu)  ; 将子菜单添加到主菜单

            this.BranchContextMenu.Add()  ; 分隔线
            this.BranchContextMenu.Add("删除", (*) => this.MenuHandler("删除"))
        }

        this.CurItemID := item
        this.MacroTreeViewCon.Modify(this.CurItemID, "Select")
        itemText := this.MacroTreeViewCon.GetText(this.CurItemID)
        if (itemText == "" || SubStr(itemText, 1, 1) == "⎖")
            return
        else if (itemText == "真" || itemText == "假" || itemText == "循环体") {
            this.BranchContextMenu.Show(x, y)
        }
        else {
            this.ContextMenu.Show(x, y)
        }
    }

    OnDoubleClick(ctrl, item) {
        if (item == 0)
            return

        itemText := this.MacroTreeViewCon.GetText(item)
        if (itemText == "" || SubStr(itemText, 1, 1) == "⎖")
            return

        this.CurItemID := item
        if (itemText == "真" || itemText == "假" || itemText == "循环体") {
            if (this.SubMacroEditGui == "")
                this.SubMacroEditGui := MacroEditGui()

            macroStr := this.GetTreeMacroStr(this.CurItemID)
            this.SubMacroEditGui.SureBtnAction := this.OnSubNodeEdit.Bind(this, this.CurItemID)
            this.SubMacroEditGui.SureFocusCon := this.MacroTreeViewCon
            this.SubMacroEditGui.ShowGui(macroStr, false)
            return
        }

        paramsArr := StrSplit(itemText, "_")
        subGui := this.SubGuiMap[paramsArr[1]]
        this.OnOpenSubGui(subGui, 2)
    }

    MenuHandler(cmdStr, *) {
        itemText := this.MacroTreeViewCon.GetText(this.CurItemID)
        paramsArr := StrSplit(cmdStr, "_")
        if (paramsArr.Length == 2) {
            modeType := paramsArr[1] == "Pre" ? 3 : paramsArr[1] == "Next" ? 4 : 5
            this.CmdEditType := modeType
            subGui := this.SubGuiMap[paramsArr[2]]
            this.OnOpenSubGui(subGui, modeType)
            return
        }

        switch cmdStr {
            case "编辑":
            {
                paramsArr := StrSplit(itemText, "_")
                subGui := this.SubGuiMap[paramsArr[1]]
                this.OnOpenSubGui(subGui, 2)
            }
            case "共享复制":
            {
                A_Clipboard := itemText
            }
            case "完全复制":
            {
                A_Clipboard := FullCopyCmd(itemText)
            }
            case "上方粘贴":
            {
                this.OnPreInsertCmd(A_Clipboard)
            }
            case "下方粘贴":
            {
                this.OnNextInsertCmd(A_Clipboard)
            }
            case "删除":
            {
                this.OnDeleteCmd()
            }

        }
    }

    InitTreeView(MacroStr) {
        this.MacroTreeViewCon.Visible := this.EditModeCon.Value == 1
        cmdArr := SplitMacro(MacroStr)
        this.MacroTreeViewCon.Opt("-Redraw")
        this.MacroTreeViewCon.Delete()
        this.LastItemID := 0
        for cmdStr in cmdArr {
            iconStr := this.GetCmdIconStr(cmdStr)
            root := this.MacroTreeViewCon.Add(cmdStr, 0, iconStr)
            this.LastItemID := root
            this.TreeAddBranch(root, cmdStr)
        }
        this.MacroTreeViewCon.Opt("+Redraw")
    }

    RefreshTree(itemID) {
        CommandStr := this.MacroTreeViewCon.GetText(itemID)
        paramsArr := StrSplit(CommandStr, "_")

        subItem := this.MacroTreeViewCon.GetChild(this.CurItemID)
        while (subItem) {
            this.MacroTreeViewCon.Delete(subItem)
            subItem := this.MacroTreeViewCon.GetChild(this.CurItemID)
        }
        this.TreeAddBranch(this.CurItemID, CommandStr)
        this.TreeExpand(this.CurItemID, 2)
    }

    TreeAddBranch(root, cmdStr) {
        paramArr := StrSplit(cmdStr, "_")
        IsSearch := StrCompare(paramArr[1], "搜索", false) == 0
        IsSearchPro := StrCompare(paramArr[1], "搜索Pro", false) == 0
        IsIf := StrCompare(paramArr[1], "如果", false) == 0
        IsIfPro := StrCompare(paramArr[1], "如果Pro", false) == 0
        IsLoop := StrCompare(paramArr[1], "循环", false) == 0
        if (!IsSearch && !IsSearchPro && !IsIf && !IsLoop && !IsIfPro)
            return

        ParentID := this.MacroTreeViewCon.GetParent(root)
        while (ParentID != 0) {
            itemText := this.MacroTreeViewCon.GetText(ParentID)
            itemParamArr := StrSplit(itemText, "_")
            ParentID := this.MacroTreeViewCon.GetParent(ParentID)
            if (itemParamArr.Length == 1)
                continue

            if (itemParamArr[2] == paramArr[2])
                return
        }

        TrueMacro := ""
        FalseMacro := ""
        if (IsIf) {
            saveStr := IniRead(CompareFile, IniSection, paramArr[2], "")
            Data := JSON.parse(saveStr, , false)

            TrueMacro := Data.TrueMacro
            FalseMacro := Data.FalseMacro
        }
        else if (IsSearch) {
            saveStr := IniRead(SearchFile, IniSection, paramArr[2], "")
            Data := JSON.parse(saveStr, , false)

            TrueMacro := Data.TrueMacro
            FalseMacro := Data.FalseMacro
        }
        else if (IsSearchPro) {
            saveStr := IniRead(SearchProFile, IniSection, paramArr[2], "")
            Data := JSON.parse(saveStr, , false)

            TrueMacro := Data.TrueMacro
            FalseMacro := Data.FalseMacro
        }

        if (IsIf || IsSearch || IsSearchPro) {
            iconStr := this.GetCmdIconStr("真")
            trueRoot := this.MacroTreeViewCon.Add("真", root, iconStr)
            this.TreeAddSubTree(trueRoot, TrueMacro)

            iconStr := this.GetCmdIconStr("假")
            falseRoot := this.MacroTreeViewCon.Add("假", root, iconStr)
            this.TreeAddSubTree(falseRoot, FalseMacro)
        }
        else if (IsLoop) {
            saveStr := IniRead(LoopFile, IniSection, paramArr[2], "")
            Data := JSON.parse(saveStr, , false)

            iconStr := this.GetCmdIconStr("循环次数")
            CountRoot := this.MacroTreeViewCon.Add(Format("⎖循环次数:{}", Data.LoopCount), root, iconStr)

            if (Data.CondiType != 1) {
                iconStr := this.GetCmdIconStr("循环条件")
                CondiStr := Data.CondiType == 2 ? "⎖继续条件：" : "⎖退出条件："
                ItemStr := CondiStr . LoopData.GetCondiStr(Data)
                CondiRoot := this.MacroTreeViewCon.Add(ItemStr, root, iconStr)
            }

            iconStr := this.GetCmdIconStr("循环体")
            BodyRoot := this.MacroTreeViewCon.Add("循环体", root, iconStr)
            this.TreeAddSubTree(BodyRoot, Data.LoopBody)
        }
        else if (IsIfPro) {
            saveStr := IniRead(CompareProFile, IniSection, paramArr[2], "")
            Data := JSON.parse(saveStr, , false)

            iconStr := this.GetCmdIconStr("条件")
            loop Data.VariNameArr.Length {
                CondiStr := "条件：" CompareProData.GetCondiStr(Data, A_Index)
                CondiRoot := this.MacroTreeViewCon.Add(CondiStr, root, iconStr)
                this.TreeAddSubTree(CondiRoot, Data.MacroArr[A_Index])
            }

            CondiStr := "条件：以上都不是"
            CondiRoot := this.MacroTreeViewCon.Add(CondiStr, root, iconStr)
            this.TreeAddSubTree(CondiRoot, Data.DefaultMacro)
        }
    }

    TreeAddSubTree(root, CommandStr) {
        if (CommandStr == "")
            return

        cmdArr := SplitMacro(CommandStr)
        for cmdStr in cmdArr {
            iconStr := this.GetCmdIconStr(cmdStr)
            subRoot := this.MacroTreeViewCon.Add(cmdStr, root, iconStr)
            this.TreeAddBranch(subRoot, cmdStr)
        }
    }

    ;打开子指令编辑器 modeType 1:默认行尾追加 2:编辑修改 3:上方插入 4:下方插入 5:真假节点添加
    OnOpenSubGui(subGui, modeType := 1) {
        this.CmdEditType := modeType
        if ObjHasOwnProp(subGui, "VariableObjArr") {
            macroStr := this.GetTreeMacroStr(0)
            VariableObjArr := GetGuiVariableObjArr(macroStr, this.VariableObjArr)
            subGui.VariableObjArr := VariableObjArr
        }

        if (modeType == 2) {
            CommandStr := this.MacroTreeViewCon.GetText(this.CurItemID)
            subGui.ShowGui(CommandStr)
            return
        }
        subGui.ShowGui("")
    }

    ;确定子指令编辑器
    OnSubGuiSureBtnClick(CommandStr) {
        if (this.CmdEditType == 1) {
            this.OnAddCmd(CommandStr)
        }
        else if (this.CmdEditType == 2) {
            this.OnModifyCmd(CommandStr)
        }
        else if (this.CmdEditType == 3) {
            this.OnPreInsertCmd(CommandStr)
        }
        else if (this.CmdEditType == 4) {
            this.OnNextInsertCmd(CommandStr)
        }
        else if (this.CmdEditType == 5) {
            this.OnSubNodeAddCmd(CommandStr)
        }
        MySoftData.RecordToggleCon := this.RecordMacroCon
        MySoftData.MacroEditGui := this
    }

    ;添加指令
    OnAddCmd(CommandStr) {
        iconStr := this.GetCmdIconStr(CommandStr)
        root := this.MacroTreeViewCon.Add(CommandStr, 0, iconStr)
        this.TreeAddBranch(root, CommandStr)
        this.LastItemID := root
    }

    ;修改指令
    OnModifyCmd(CommandStr) {
        this.MacroTreeViewCon.Modify(this.CurItemID, , CommandStr)
        paramsArr := StrSplit(CommandStr, "_")
        ParentID := this.MacroTreeViewCon.GetParent(this.CurItemID)
        if (ParentID == 0) {
            this.RefreshTree(this.CurItemID)
            return
        }

        macroStr := this.GetTreeMacroStr(ParentID)
        isTrueMacro := this.MacroTreeViewCon.GetText(ParentID) == "真"
        RealItemID := this.MacroTreeViewCon.GetParent(ParentID)
        RealCommandStr := this.MacroTreeViewCon.GetText(RealItemID)
        this.CurItemID := RealItemID

        this.SaveCommandData(RealCommandStr, macroStr, isTrueMacro, false)
        this.RefreshTree(this.CurItemID)
    }

    OnDeleteCmd() {
        ParentID := this.MacroTreeViewCon.GetParent(this.CurItemID)
        if (ParentID == 0) {
            this.MacroTreeViewCon.Delete(this.CurItemID)
            return
        }

        itemText := this.MacroTreeViewCon.GetText(this.CurItemID)
        isClear := false
        if (itemText == "真" || itemText == "假" || itemText == "循环体") {
            isTrueMacro := itemText == "真"
            isClear := true
            RealItemID := ParentID
            RealCommandStr := this.MacroTreeViewCon.GetText(ParentID)
            this.CurItemID := ParentID
            macroStr := ""
        }
        else {
            this.MacroTreeViewCon.Delete(this.CurItemID)
            macroStr := this.GetTreeMacroStr(ParentID)
            isTrueMacro := this.MacroTreeViewCon.GetText(ParentID) == "真"
            RealItemID := this.MacroTreeViewCon.GetParent(ParentID)
            RealCommandStr := this.MacroTreeViewCon.GetText(RealItemID)
            this.CurItemID := RealItemID
        }

        this.SaveCommandData(RealCommandStr, macroStr, isTrueMacro, isClear)
        this.RefreshTree(this.CurItemID)
    }

    ;插入指令
    OnPreInsertCmd(CommandStr) {
        ParentID := this.MacroTreeViewCon.GetParent(this.CurItemID)
        PreItemID := this.MacroTreeViewCon.GetPrev(this.CurItemID)
        Seq := PreItemID == 0 ? "First" : PreItemID
        iconStr := this.GetCmdIconStr(CommandStr)
        newItemID := this.MacroTreeViewCon.Add(CommandStr, ParentID, Seq " " iconStr)
        if (ParentID == 0) {
            this.TreeAddBranch(newItemID, CommandStr)
            return
        }

        macroStr := this.GetTreeMacroStr(ParentID)
        isTrueMacro := this.MacroTreeViewCon.GetText(ParentID) == "真"
        this.CurItemID := this.MacroTreeViewCon.GetParent(ParentID)
        RealCommandStr := this.MacroTreeViewCon.GetText(this.CurItemID)
        this.SaveCommandData(RealCommandStr, macroStr, isTrueMacro, false)
        this.RefreshTree(this.CurItemID)
    }

    ;插入指令
    OnNextInsertCmd(CommandStr) {
        ParentID := this.MacroTreeViewCon.GetParent(this.CurItemID)
        iconStr := this.GetCmdIconStr(CommandStr)
        newItemID := this.MacroTreeViewCon.Add(CommandStr, ParentID, this.CurItemID " " iconStr)
        if (this.CurItemID == this.LastItemID)
            this.LastItemID := newItemID

        if (ParentID == 0) {
            this.TreeAddBranch(newItemID, CommandStr)
            return
        }

        macroStr := this.GetTreeMacroStr(ParentID)
        isTrueMacro := this.MacroTreeViewCon.GetText(ParentID) == "真"
        this.CurItemID := this.MacroTreeViewCon.GetParent(ParentID)
        RealCommandStr := this.MacroTreeViewCon.GetText(this.CurItemID)
        this.SaveCommandData(RealCommandStr, macroStr, isTrueMacro, false)
        this.RefreshTree(this.CurItemID)
    }

    OnSubNodeAddCmd(CommandStr) {
        iconStr := this.GetCmdIconStr(CommandStr)
        newItemID := this.MacroTreeViewCon.Add(CommandStr, this.CurItemID, iconStr)
        macroStr := this.GetTreeMacroStr(this.CurItemID)
        isTrueMacro := this.MacroTreeViewCon.GetText(this.CurItemID) == "真"

        this.CurItemID := this.MacroTreeViewCon.GetParent(this.CurItemID)
        RealCommandStr := this.MacroTreeViewCon.GetText(this.CurItemID)
        this.SaveCommandData(RealCommandStr, macroStr, isTrueMacro, false)
        this.RefreshTree(this.CurItemID)
    }

    OnSubNodeEdit(nodeId, macroStr) {
        isTrueMacro := this.MacroTreeViewCon.GetText(nodeId) == "真"
        RealItemID := this.MacroTreeViewCon.GetParent(nodeId)
        RealCommandStr := this.MacroTreeViewCon.GetText(RealItemID)
        this.CurItemID := RealItemID

        this.SaveCommandData(RealCommandStr, macroStr, isTrueMacro, false)
        this.RefreshTree(this.CurItemID)
    }

    TreeExpand(ItemID, Num) {
        if (Num == 0)
            return

        rootItemID := this.MacroTreeViewCon.GetChild(ItemID)
        while (rootItemID) {
            this.MacroTreeViewCon.Modify(rootItemID, "Expand")
            this.TreeExpand(rootItemID, Num - 1)
            rootItemID := this.MacroTreeViewCon.GetNext(rootItemID)
        }
    }

    GetTreeMacroStr(ItemID) {
        macroStr := ""
        rootItemID := this.MacroTreeViewCon.GetChild(ItemID)
        while (rootItemID) {
            cmdStr := this.MacroTreeViewCon.GetText(rootItemID)
            macroStr .= cmdStr ","
            rootItemID := this.MacroTreeViewCon.GetNext(rootItemID)
        }
        macroStr := Trim(macroStr, ",")
        return macroStr
    }

    GetCmdIconStr(cmdStr) {
        paramArr := StrSplit(cmdStr, "_")
        if (this.IconMap.Has(paramArr[1])) {
            return this.IconMap.Get(paramArr[1])
        }
        return ""
    }

    ;todo 减少参数
    SaveCommandData(RealCommandStr, macroStr, isTrue, isClear) {
        paramArr := StrSplit(RealCommandStr, "_")
        IsSearch := StrCompare(paramArr[1], "搜索", false) == 0
        IsSearchPro := StrCompare(paramArr[1], "搜索Pro", false) == 0
        IsIf := StrCompare(paramArr[1], "如果", false) == 0
        IsLoop := StrCompare(paramArr[1], "循环", false) == 0
        IsIfPro := StrCompare(paramArr[1], "如果Pro", false) == 0
        FileName := ""
        if (IsIf) {
            FileName := CompareFile
        }
        else if (IsIfPro) {
            FileName := CompareProFile
        }
        else if (IsSearch) {
            FileName := SearchFile
        }
        else if (IsSearchPro) {
            FileName := SearchProFile
        }
        else if (IsLoop) {
            FileName := LoopFile
        }
        if (FileName == "")
            return
        saveStr := IniRead(FileName, IniSection, paramArr[2], "")
        Data := JSON.parse(saveStr, , false)
        if (IsLoop) {
            if (isClear)
                Data.LoopBody := ""
            else
                Data.LoopBody := macroStr
        }
        else if (IsIfPro) {

        }
        else if (isTrue && isClear)
            Data.TrueMacro := ""
        else if (isTrue && !isClear)
            Data.TrueMacro := macroStr
        else if (!isTrue && isClear)
            Data.FalseMacro := ""
        else {
            Data.FalseMacro := macroStr
        }
        saveStr := JSON.stringify(Data, 0)
        IniWrite(saveStr, FileName, IniSection, Data.SerialStr)
        if (MySoftData.DataCacheMap.Has(Data.SerialStr)) {
            MySoftData.DataCacheMap.Delete(Data.SerialStr)
        }
    }
}
