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
    hasFix := false
    if (!FileExist(FilePath))
        return hasFix

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
        hasFix := true
        saveStr := JSON.stringify(Data, 0)
        IniWrite(saveStr, filePath, IniSection, Data.SerialStr)
    }
    return hasFix
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
    hasFix := false
    if (!FileExist(FilePath))
        return hasFix

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

        hasFix := true
        Data.InsertCount := 1
        saveStr := JSON.stringify(Data, 0)
        IniWrite(saveStr, FilePath, IniSection, Data.SerialStr)
    }
    return hasFix
}

;1.0.9F3 间隔指令调整 统一使用两个参数
Compat1_0_9F3Interval(tableItem) {
    for index, MacroStr in tableItem.MacroArr {
        cmdArr := SplitMacro(MacroStr)
        for cmdStr in cmdArr {
            paramArr := StrSplit(cmdStr, "_")
            if (paramArr[1] == "间隔" && paramArr.Length == 3) {
                paramArr[2] := paramArr[3]
                paramArr.RemoveAt(3)
                cmdArr[A_Index] := GetCmdByParams(paramArr)
            }
        }
        tableItem.MacroArr[index] := GetMacroStrByCmdArr(cmdArr)
        return
    }
}
