#Requires AutoHotkey v2.0
#Include CompareProEditItemGui.ahk

class CompareProGui {
    __new() {
        this.ParentTile := ""
        this.Gui := ""
        this.SureBtnAction := ""
        this.RemarkCon := ""
        this.MacroGui := ""
        this.VariableObjArr := []
        this.FocusCon := ""
        this.ItemEditGui := ""
        this.ContextMenu := ""

        this.CompareTypeStrArr := GetLangArr(["大于", "大于等于", "等于", "小于等于",
            "小于", "字符包含", "变量存在"])

        this.CompareTypeStrMap := Map(GetLang("大于"), 1, GetLang("大于等于"), 2, GetLang("等于"), 3, GetLang("小于等于"),
        4, GetLang("小于"), 5, GetLang("字符包含"), 6, GetLang("变量存在"), 7)

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
        MyGui := Gui(, this.ParentTile GetLang("如果Pro编辑器"))
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

        PosX := 10
        PosY += 30
        this.LVCon := MyGui.Add("ListView", Format("x{} y{} w480 h280 -LV0x10 NoSort", PosX, PosY), GetLangArr(["条件",
            "关系", "指令"]))
        this.LVCon.OnEvent("ContextMenu", this.ShowContextMenu.Bind(this))
        this.LVCon.OnEvent("DoubleClick", this.OnDoubleClick.Bind(this))
        ; 设置列宽（单位：px）
        this.LVCon.ModifyCol(1, 260) ; 第一列宽度
        this.LVCon.ModifyCol(2, 50) ; 自动填充剩余宽度
        this.LVCon.ModifyCol(3, 150) ; 自动填充剩余宽度

        PosY += 290
        PosX := 190
        btnCon := MyGui.Add("Button", Format("x{} y{} w{} h{}", PosX, PosY, 100, 40), GetLang("确定"))
        btnCon.OnEvent("Click", (*) => this.OnClickSureBtn())
        this.FocusCon := btnCon

        MyGui.OnEvent("Close", (*) => this.ToggleFunc(false))
        MyGui.Show(Format("w{} h{}", 500, 380))
    }

    Init(cmd) {
        cmdArr := cmd != "" ? StrSplit(cmd, "_") : []
        this.SerialStr := cmdArr.Length >= 2 ? cmdArr[2] : GetSerialStr("ComparePro")
        this.RemarkCon.Value := cmdArr.Length >= 3 ? cmdArr[3] : ""
        this.Data := this.GetCompareProData(this.SerialStr)

        this.LVCon.Delete()
        loop this.Data.MacroArr.Length {
            condiStr := ""
            ItemIndex := A_Index
            loop this.Data.VariNameArr[ItemIndex].Length {
                condiStr .= GetLang(this.Data.VariNameArr[ItemIndex][A_Index]) " " this.CompareTypeStrArr[this.Data.CompareTypeArr[
                    ItemIndex][A_Index]] " " GetLang(this.Data.VariableArr[ItemIndex][A_Index])
                condiStr .= "⎖"
            }
            condiStr := Trim(condiStr, "⎖")
            logicStr := this.Data.LogicTypeArr[A_Index] == 1 ? GetLang("且") : GetLang("或")
            macro := GetLangMacro(this.Data.MacroArr[A_Index], 1)

            this.LVCon.Add(, condiStr, logicStr, macro)
        }
        this.LVCon.Add(, GetLang("以上都不是"), "", GetLangMacro(this.Data.DefaultMacro, 1))
        this.LVCon.Focus()  ; 🔥 强制获得焦点，解决第一次双击无效问题
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

    ShowContextMenu(ctrl, item, isRightClick, x, y) {
        if (item == 0)
            return

        if (this.ContextMenu == "") {
            this.ContextMenu := Menu()
            this.ContextMenu.Add(GetLang("编辑"), (*) => this.MenuHandler(GetLang("编辑")))
            this.ContextMenu.Add()  ; 分隔线
            this.ContextMenu.Add(GetLang("向上插入分支"), (*) => this.MenuHandler(GetLang("向上插入分支")))
            this.ContextMenu.Add(GetLang("向下插入分支"), (*) => this.MenuHandler(GetLang("向下插入分支")))
            this.ContextMenu.Add()  ; 分隔线
            this.ContextMenu.Add(GetLang("向上移动"), (*) => this.MenuHandler(GetLang("向上移动")))
            this.ContextMenu.Add(GetLang("向下移动"), (*) => this.MenuHandler(GetLang("向下移动")))
            this.ContextMenu.Add()  ; 分隔线
            this.ContextMenu.Add(GetLang("删除"), (*) => this.MenuHandler(GetLang("删除")))
        }
        this.CurItme := item
        this.ContextMenu.Show(x, y)
    }

    OnDoubleClick(ctrl, item) {
        if (item == 0)
            return
        this.OnEditItem(item)
    }

    MenuHandler(cmdStr) {
        isFinally := this.LVCon.GetText(this.CurItme, 1) == GetLang("以上都不是")
        switch cmdStr {
            case GetLang("编辑"):
            {
                this.OnEditItem(this.CurItme)
            }
            case GetLang("向上插入分支"):
            {
                this.LVCon.Insert(this.CurItme, , GetLang("Num1 大于 Num1"), GetLang("且"), "")
            }
            case GetLang("向下插入分支"):
            {
                if (isFinally) {
                    MsgBox(GetLang("不可向最后的分支插入"))
                    return
                }
                this.LVCon.Insert(this.CurItme + 1, , GetLang("Num1 大于 Num1"), GetLang("且"), "")
            }
            case GetLang("向上移动"):
            {
                if (isFinally) {
                    MsgBox(GetLang("最后的分支不能变更顺序"))
                    return
                }
                if (this.CurItme == 1) {
                    MsgBox(GetLang("第一个分支不能上移"))
                    return
                }
                this.LVCon.Insert(this.CurItme - 1, , this.LVCon.GetText(this.CurItme, 1), this.LVCon.GetText(this.CurItme,
                    2), this.LVCon.GetText(this.CurItme, 3))
                this.LVCon.Delete(this.CurItme + 1)
            }
            case GetLang("向下移动"):
            {
                if (isFinally || this.LVCon.GetCount() == this.CurItme + 1) {
                    MsgBox(GetLang("最后的分支不能变更顺序"))
                    return
                }

                this.LVCon.Insert(this.CurItme + 2, , this.LVCon.GetText(this.CurItme, 1), this.LVCon.GetText(this.CurItme,
                    2), this.LVCon.GetText(this.CurItme, 3))
                this.LVCon.Delete(this.CurItme)
            }
            case GetLang("删除"):
            {
                if (isFinally) {
                    MsgBox(GetLang("最后的分支不能删除，若无需该分支请清空分支指令"))
                    return
                }
                this.LVCon.Delete(this.CurItme)
            }
        }
    }

    OnEditItem(item) {
        if (this.ItemEditGui == "") {
            this.ItemEditGui := CompareProEditItemGui()
            this.ItemEditGui.SureFocusCon := this.FocusCon
        }
        ParentTile := StrReplace(this.Gui.Title, GetLang("编辑器"), "")
        this.ItemEditGui.ParentTile := ParentTile "-"

        this.ItemEditGui.VariableObjArr := this.VariableObjArr
        EditType := this.LVCon.GetText(item, 1) == GetLang("以上都不是") ? 2 : 1
        DataArr := this.GetCondiStrDataArr(this.LVCon.GetText(item, 1))
        logicStr := this.LVCon.GetText(item, 2)
        macro := this.LVCon.GetText(item, 3)
        this.ItemEditGui.ShowGui(EditType, DataArr, logicStr, macro)
        this.ItemEditGui.SureBtnAction := this.OnSureEditItem.Bind(this, item)
    }

    OnSureEditItem(item, condiStr, logicStr, macro) {
        this.LVCon.Modify(item, , condiStr, logicStr, macro)
    }

    OnClickSureBtn() {
        valid := this.CheckIfValid()
        if (!valid)
            return
        this.SaveCompareProData()
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
        this.SaveCompareProData()
        OnTriggerSepcialItemMacro(this.GetCommandStr())
    }

    GetCommandStr() {
        CommandStr := Format("{}_{}", GetLang("如果Pro"), this.Data.SerialStr)
        Remark := CorrectRemark(this.RemarkCon.Value)
        if (Remark != "") {
            CommandStr .= "_" Remark
        }

        return CommandStr
    }

    GetCompareProData(SerialStr) {
        saveStr := IniRead(CompareProFile, IniSection, SerialStr, "")
        if (!saveStr) {
            data := CompareProData()
            data.SerialStr := SerialStr
            return data
        }

        data := JSON.parse(saveStr, , false)
        return data
    }

    GetCondiStrDataArr(condiStr) {
        condiStrArr := StrSplit(condiStr, "⎖")
        VariNameArr := []
        CompareTypeArr := []
        VariableArr := []
        if (condiStr != GetLang("以上都不是")) {
            loop condiStrArr.Length {
                itemCondiArr := StrSplit(condiStrArr[A_Index], " ")
                Variable := itemCondiArr.Length >= 3 ? itemCondiArr[3] : ""
                VariNameArr.Push(itemCondiArr[1])
                CompareTypeArr.Push(this.CompareTypeStrMap[itemCondiArr[2]])
                VariableArr.Push(Variable)
            }
        }

        return [VariNameArr, CompareTypeArr, VariableArr]
    }

    SaveCompareProData() {
        this.Data.VariNameArr := []
        this.Data.CompareTypeArr := []
        this.Data.VariableArr := []
        this.Data.LogicTypeArr := []
        this.Data.MacroArr := []
        loop this.LVCon.GetCount() {
            if (A_Index == this.LVCon.GetCount()) {
                this.Data.DefaultMacro := GetLangMacro(this.LVCon.GetText(A_Index, 3), 2)
                break
            }
            CondiDataArr := this.GetCondiStrDataArr(this.LVCon.GetText(A_Index, 1))
            LogicType := this.LVCon.GetText(A_Index, 2) == GetLang("且") ? 1 : 2
            this.Data.VariNameArr.Push(GetLangKey(CondiDataArr[1]))
            this.Data.CompareTypeArr.Push(CondiDataArr[2])
            this.Data.VariableArr.Push(GetLangKey(CondiDataArr[3]))
            this.Data.LogicTypeArr.Push(LogicType)
            this.Data.MacroArr.Push(GetLangMacro(this.LVCon.GetText(A_Index, 3), 2))
        }

        saveStr := JSON.stringify(this.Data, 0)
        IniWrite(saveStr, CompareProFile, IniSection, this.Data.SerialStr)
        if (MySoftData.DataCacheMap.Has(this.Data.SerialStr)) {
            MySoftData.DataCacheMap.Delete(this.Data.SerialStr)
        }
    }
}
