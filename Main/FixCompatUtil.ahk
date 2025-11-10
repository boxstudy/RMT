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

        if (Data == "")
            continue

        ; ;如果有了，那就说明是新版本，不需要兼容处理
        ; if (ObjHasOwnProp(Data, "ActionType"))
        ;     break

        Data.ActionType := 1
        saveStr := JSON.stringify(Data, 0)
        IniWrite(saveStr, filePath, IniSection, Data.SerialStr)
    }
}
