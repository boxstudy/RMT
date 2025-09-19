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

class MacroEditGui {
    __new() {
        this.Gui := ""
        this.ShowSaveBtn := false
        this.SureFocusCon := ""
        this.VariableObjArr := []
        this.isContextEdit := false
        this.RecordToggleCon := ""

        this.SureBtnAction := ""
        this.SaveBtnAction := ""
        this.SaveBtnCtrl := {}
        this.CmdBtnConMap := map()
        this.SubGuiMap := map()
        this.NeedCommandInterval := false
        this.MacroTreeViewCon := ""
        this.EditModeType := 1  ;1添加指令 2修改当前指令 3向上插入指令 4 向下插入指令
        this.CurItemID := ""  ;当前操作itemID
        this.LastItemID := "" ;最后的itemID
        this.ContextMenu := ""
        this.BranchContextMenu := ""
        this.RecordMacroCon := ""
        this.DefaultFocusCon := ""
        this.SubMacroLastIndex := 0

        this.CMDStrArr := ["间隔", "按键", "搜索", "搜索Pro", "移动", "移动Pro", "输出", "运行", "变量", "变量提取", "运算", "如果", "宏操作",
            "RMT指令",
            "后台鼠标"]

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

        this.OperationGui := OperationGui()
        this.OperationGui.SureBtnAction := (CommandStr) => this.OnSubGuiSureBtnClick(CommandStr)
        this.SubGuiMap.Set("运算", this.OperationGui)

        this.BGMouseGui := BGMouseGui()
        this.BGMouseGui.SureBtnAction := (CommandStr) => this.OnSubGuiSureBtnClick(CommandStr)
        this.SubGuiMap.Set("后台鼠标", this.BGMouseGui)

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
        MyGui.Add("GroupBox", Format("x{} y{} w{} h{}", PosX, PosY, 170, 430), "指令选项")

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
        btnCon := MyGui.Add("Button", Format("x{} y{} h{} w{} center", PosX, PosY, 30, 75), "运算")
        btnCon.SetFont((Format("S{} W{} Q{}", 11, 400, 5)))
        btnCon.OnEvent("Click", (*) => this.OnOpenSubGui(this.OperationGui))
        this.CmdBtnConMap.Set("运算", btnCon)

        PosX += 85
        btnCon := MyGui.Add("Button", Format("x{} y{} h{} w{} center", PosX, PosY, 30, 75), "如果")
        btnCon.SetFont((Format("S{} W{} Q{}", 11, 400, 5)))
        btnCon.OnEvent("Click", (*) => this.OnOpenSubGui(this.CompareGui))
        this.CmdBtnConMap.Set("如果", btnCon)

        PosX := 15
        PosY += 40
        btnCon := MyGui.Add("Button", Format("x{} y{} h{} w{} center", PosX, PosY, 30, 75), "RMT指令")
        btnCon.SetFont((Format("S{} W{} Q{}", 11, 400, 5)))
        btnCon.OnEvent("Click", (*) => this.OnOpenSubGui(this.RMTCMDGui))
        this.CmdBtnConMap.Set("RMT指令", btnCon)

        PosX += 85
        btnCon := MyGui.Add("Button", Format("x{} y{} h{} w{} center", PosX, PosY, 30, 75), "宏操作")
        btnCon.SetFont((Format("S{} W{} Q{}", 11, 400, 5)))
        btnCon.OnEvent("Click", (*) => this.OnOpenSubGui(this.SubMacroGui))
        this.CmdBtnConMap.Set("宏操作", btnCon)

        PosX := 15
        PosY += 40
        btnCon := MyGui.Add("Button", Format("x{} y{} h{} w{} center", PosX, PosY, 30, 75), "后台鼠标")
        btnCon.SetFont((Format("S{} W{} Q{}", 11, 400, 5)))
        btnCon.OnEvent("Click", (*) => this.OnOpenSubGui(this.BGMouseGui))
        this.CmdBtnConMap.Set("后台鼠标", btnCon)

        PosX := 200
        PosY := 10
        this.RecordMacroCon := MyGui.Add("Checkbox", Format("x{} y{}", PosX, PosY), "指令录制")
        this.RecordMacroCon.Value := false
        this.RecordMacroCon.OnEvent("Click", this.OnClickRecordTog.Bind(this))
        PosX += 95
        isHotKey := CheckIsHotKey(ToolCheckInfo.ToolRecordMacroHotKey)
        CtrlType := isHotKey ? "Hotkey" : "Text"
        con := MyGui.Add(CtrlType, Format("x{} y{} w{}", posX, posY - 3, 130), ToolCheckInfo.ToolRecordMacroHotKey
        )
        con.Enabled := false

        PosX := 190
        PosY += 25
        MyGui.Add("GroupBox", Format("x{} y{} w{} h{}", PosX, PosY, 620, 360), "当前宏指令")
        PosY += 20
        this.MacroTreeViewCon := MyGui.Add("TreeView", Format("x{} y{} w{} h{}", PosX + 5, PosY, 605, 335), "")
        this.MacroTreeViewCon.OnEvent("ContextMenu", this.ShowContextMenu.Bind(this))  ; 右键菜单事件
        this.MacroTreeViewCon.OnEvent("DoubleClick", this.OnDoubleClick.Bind(this))  ; 双击编辑指令

        PosX := 190
        PosY := 400
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

        MyGui.Show(Format("w{} h{}", 820, 450))
    }

    Init(CommandStr, ShowSaveBtn) {
        this.ShowSaveBtn := ShowSaveBtn
        this.SubMacroLastIndex := 0
        this.SaveBtnCtrl.Visible := this.ShowSaveBtn
        this.InitTreeView(CommandStr)
    }

    Backspace() {
        if (this.MacroTreeViewCon.GetCount() == 0)
            return
        preItemID := this.MacroTreeViewCon.GetPrev(this.LastItemID)
        this.MacroTreeViewCon.Delete(this.LastItemID)
        this.LastItemID := preItemID
    }

    ClearStr() {
        this.MacroTreeViewCon.Delete()
    }

    OnClickRecordTog(*) {
        MySoftData.RecordToggleCon := this.RecordMacroCon
        MySoftData.MacroEditGui := this
        OnHotToolRecordMacro(true)
    }

    OnSaveBtnClick() {
        macroStr := this.GetMacroStr(0)
        action := this.SureBtnAction
        action(macroStr)

        this.SureBtnAction := ""
        this.Gui.Hide()

        action := this.SaveBtnAction
        action()
        this.SureFocusCon.Focus()
    }

    OnSureBtnClick() {
        macroStr := this.GetMacroStr(0)
        action := this.SureBtnAction
        action(macroStr)

        this.SureBtnAction := ""
        this.Gui.Hide()
        this.SureFocusCon.Focus()
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
            this.BranchContextMenu.Add("删除", (*) => this.MenuHandler("删除"))
        }

        this.CurItemID := item
        this.MacroTreeViewCon.Modify(this.CurItemID, "Select")
        itemText := this.MacroTreeViewCon.GetText(this.CurItemID)
        if (itemText == "真" || itemText == "假") {
            this.BranchContextMenu.Show(x, y)
        }
        else {
            this.ContextMenu.Show(x, y)
        }
    }

    OnDoubleClick(ctrl, info) {
        if (info == 0)
            return

        itemText := this.MacroTreeViewCon.GetText(info)
        if (itemText == "真" || itemText == "假")
            return

        this.CurItemID := info
        paramsArr := StrSplit(itemText, "_")
        subGui := this.SubGuiMap[paramsArr[1]]
        this.OnOpenSubGui(subGui, 2)
    }

    MenuHandler(cmdStr, *) {
        itemText := this.MacroTreeViewCon.GetText(this.CurItemID)
        paramsArr := StrSplit(cmdStr, "_")
        if (paramsArr.Length == 2) {
            modeType := paramsArr[1] == "Pre" ? 3 : 4
            this.EditModeType := modeType
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

    InitTreeView(CommandStr) {
        cmdArr := SplitMacro(CommandStr)
        this.MacroTreeViewCon.Delete()
        this.LastItemID := 0
        for cmdStr in cmdArr {
            root := this.MacroTreeViewCon.Add(cmdStr)
            this.LastItemID := root
            this.TreeAddBranch(root, cmdStr)
        }
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

        if (TrueMacro != "") {
            trueRoot := this.MacroTreeViewCon.Add("真", root)
            this.TreeAddSubTree(trueRoot, TrueMacro)
        }

        if (FalseMacro != "") {
            falseRoot := this.MacroTreeViewCon.Add("假", root)
            this.TreeAddSubTree(falseRoot, FalseMacro)
        }
    }

    TreeAddSubTree(root, CommandStr) {
        cmdArr := SplitMacro(CommandStr)
        for cmdStr in cmdArr {
            subRoot := this.MacroTreeViewCon.Add(cmdStr, root)
            this.TreeAddBranch(subRoot, cmdStr)
        }
    }

    ;打开子指令编辑器
    OnOpenSubGui(subGui, modeType := 1) {
        this.EditModeType := modeType
        if ObjHasOwnProp(subGui, "VariableObjArr") {
            macroStr := this.GetMacroStr(0)
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
        if (this.EditModeType == 1) {
            this.OnAddCmd(CommandStr)
        }
        else if (this.EditModeType == 2) {
            this.OnModifyCmd(CommandStr)
        }
        else if (this.EditModeType == 3) {
            this.OnPreInsertCmd(CommandStr)
        }
        else if (this.EditModeType == 4) {
            this.OnNextInsertCmd(CommandStr)
        }
        MySoftData.RecordToggleCon := this.RecordMacroCon
        MySoftData.MacroEditGui := this
    }

    ;添加指令
    OnAddCmd(CommandStr) {
        root := this.MacroTreeViewCon.Add(CommandStr)
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

        macroStr := this.GetMacroStr(ParentID)
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
        if (itemText == "真" || itemText == "假") {
            isTrueMacro := itemText == "真"
            isClear := true
            RealItemID := ParentID
            RealCommandStr := this.MacroTreeViewCon.GetText(ParentID)
            this.CurItemID := ParentID
            macroStr := ""
        }
        else {
            this.MacroTreeViewCon.Delete(this.CurItemID)
            macroStr := this.GetMacroStr(ParentID)
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
        newItemID := this.MacroTreeViewCon.Add(CommandStr, ParentID, Seq)
        if (ParentID == 0) {
            this.TreeAddBranch(newItemID, CommandStr)
            return
        }

        macroStr := this.GetMacroStr(ParentID)
        isTrueMacro := this.MacroTreeViewCon.GetText(ParentID) == "真"
        this.CurItemID := this.MacroTreeViewCon.GetParent(ParentID)
        RealCommandStr := this.MacroTreeViewCon.GetText(this.CurItemID)
        this.SaveCommandData(RealCommandStr, macroStr, isTrueMacro, false)
        this.TreeAddBranch(this.CurItemID, CommandStr)
    }

    ;插入指令
    OnNextInsertCmd(CommandStr) {
        ParentID := this.MacroTreeViewCon.GetParent(this.CurItemID)
        newItemID := this.MacroTreeViewCon.Add(CommandStr, ParentID, this.CurItemID)
        if (this.CurItemID == this.LastItemID)
            this.LastItemID := newItemID

        if (ParentID == 0) {
            this.TreeAddBranch(newItemID, CommandStr)
            return
        }

        macroStr := this.GetMacroStr(ParentID)
        isTrueMacro := this.MacroTreeViewCon.GetText(ParentID) == "真"
        this.CurItemID := this.MacroTreeViewCon.GetParent(ParentID)
        RealCommandStr := this.MacroTreeViewCon.GetText(this.CurItemID)
        this.SaveCommandData(RealCommandStr, macroStr, isTrueMacro, false)
        this.TreeAddBranch(this.CurItemID, CommandStr)
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

    GetMacroStr(ItemID) {
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

    SaveCommandData(RealCommandStr, macroStr, isTrue, isClear) {
        paramArr := StrSplit(RealCommandStr, "_")
        IsSearch := StrCompare(paramArr[1], "搜索", false) == 0
        IsSearchPro := StrCompare(paramArr[1], "搜索Pro", false) == 0
        IsIf := StrCompare(paramArr[1], "如果", false) == 0
        FileName := ""
        if (IsIf) {
            FileName := CompareFile
        } else if (IsSearch) {
            FileName := SearchFile
        } else if (IsSearchPro) {
            FileName := SearchProFile
        }
        if (FileName == "")
            return
        saveStr := IniRead(FileName, IniSection, paramArr[2], "")
        Data := JSON.parse(saveStr, , false)
        if (isTrue && isClear)
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
