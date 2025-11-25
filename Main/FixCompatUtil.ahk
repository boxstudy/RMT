#Requires AutoHotkey v2.0

;1.0.8F4到新版本兼容, 模块中新增菜单模块相关数据
Compat1_0_8F4FlodInfo(FoldInfo) {
    if (FoldInfo == "" || ObjHasOwnProp(FoldInfo, "FrontInfoArr"))
        return

    FoldInfo.FrontInfoArr := []
    FoldInfo.TKTypeArr := []
    FoldInfo.TKArr := []
    FoldInfo.HoldTimeArr := []
    loop FoldInfo.RemarkArr.Length {
        FoldInfo.FrontInfoArr.Push("")
        FoldInfo.TKTypeArr.Push(1)
        FoldInfo.TKArr.Push("")
        FoldInfo.HoldTimeArr.Push(500)
    }
}

;1.0.8F7到新版本兼容, 新增鼠标类型
Compat1_0_8F7MMPro(filePath) {
    if (!FileExist(FilePath))
        return

    Symbol := "MMPro"
    loop read, filePath {
        LineStr := A_LoopReadLine
        if (SubStr(LineStr, 1, StrLen(Symbol)) != Symbol)
            continue

        SerialStr := SubStr(LineStr, 1, StrLen(Symbol) + 7)
        saveStr := IniRead(FilePath, IniSection, SerialStr, "")
        Data := JSON.parse(saveStr, , false)

        if (saveStr == "")
            continue

        ;如果有了，那就说明是新版本，不需要兼容处理
        if (ObjHasOwnProp(Data, "ActionType"))
            continue

        Data.ActionType := 1
        saveStr := JSON.stringify(Data, 0)
        IniWrite(saveStr, filePath, IniSection, Data.SerialStr)
    }
}

;1.0.9F1到新版本兼容 增加配置音选项
Compat1_0_9F1TipSound(tableItem) {
    if (tableItem.ModeArr.Length == tableItem.StartTipSoundArr.Length &&
        tableItem.ModeArr.Length == tableItem.EndTipSoundArr.Length)
        return

    for index, value in tableItem.ModeArr {
        if (tableItem.StartTipSoundArr.Length < index) {
            tableItem.StartTipSoundArr.Push(1)
        }

        if (tableItem.EndTipSoundArr.Length < index) {
            tableItem.EndTipSoundArr.Push(1)
        }
    }
}

;宏插入可以指定次数
Compat1_0_9F1MacroInsert(FilePath) {
    if (!FileExist(FilePath))
        return

    Symbol := "SubMacro"
    loop read, FilePath {
        LineStr := A_LoopReadLine
        if (SubStr(LineStr, 1, StrLen(Symbol)) != Symbol)
            continue

        SerialStr := SubStr(LineStr, 1, StrLen(Symbol) + 7)
        saveStr := IniRead(FilePath, IniSection, SerialStr, "")
        Data := JSON.parse(saveStr, , false)

        if (saveStr == "")
            continue

        ;如果有了，那就说明是新版本，不需要兼容处理
        if (ObjHasOwnProp(Data, "InsertCount"))
            continue

        Data.InsertCount := 1
        saveStr := JSON.stringify(Data, 0)
        IniWrite(saveStr, FilePath, IniSection, Data.SerialStr)
    }
}
