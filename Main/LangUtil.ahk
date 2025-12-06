#Requires AutoHotkey v2.0
LangKeyMap := Map()

;指令相关的key
LangCmdKeyArr := ["截图", "截图提取文本", "自由贴", "开启指令显示", "关闭指令显示", "显示菜单", "关闭菜单", "启用键鼠", "禁用键鼠", "休眠",
    "暂停所有宏", "恢复所有宏", "终止所有宏", "重载", "关闭软件", "间隔", "按键", "搜索", "搜索Pro", "移动", "移动Pro", "输出", "运行", "循环", "宏操作", "变量",
    "变量提取",
    "如果", "如果Pro", "运算", "RMT指令", "后台鼠标", "后台按键", "指令循环次数", "宏循环次数", "当前鼠标坐标X", "当前鼠标坐标Y"]
LangValueMap := Map()   ;部分文本需要反向映射

LangInitSetting() {
    LangMap := Map("中文", 1)   ;确保存在中文
    if (DirExist(LangDir)) {
        loop files, LangDir "\*.txt" {
            SplitPath A_LoopFileName, &OutFileName, &OutDir, &OutExtension, &OutNameNoExt, &OutDrive
            LangMap[OutNameNoExt] := 1
        }
    }

    for Key, Value in LangMap {
        MySoftData.LangArr.Push(Key)
    }

    if (MySoftData.Lang == "无语言") {
        ChineseMap := Map("7804", 1, "0004", 1, "0804", 1, "1004", 1, "7C04", 1, "0C04", 1, "1404", 1, "0404", 1)
        if (ChineseMap.Has(A_Language))
            MySoftData.Lang := "中文"
        else {
            MySoftData.Lang := "English"
        }
    }
}

LangKeysInit() {
    if (MySoftData.Lang == "中文")  ;中文就不用做处理了
        return

    LangFilePath := Format("{}\{}.txt", LangDir, MySoftData.Lang)
    if (!FileExist(LangFilePath))
        return

    try {
        ; 以 UTF-8 编码打开文件
        file := FileOpen(LangFilePath, "r", "UTF-8")

        while !file.AtEOF {
            line := file.ReadLine()
            if (line = "")  ; 跳过空行
                continue

            LineStrArr := StrSplit(line, "=")
            if (LineStrArr.Length == 2) {
                LangKeyMap[Trim(LineStrArr[1])] := Trim(LineStrArr[2])
            }
        }

        file.Close()
    } catch as e {
        MsgBox GetLang("读取文件失败:") e.Message
    }

    for value in LangCmdKeyArr {
        key := GetLang(value)
        if (key != value)
            LangValueMap.Set(key, value)
    }
}

LangRemoveRepeat() {
    LangFilePath := Format("{}\{}.txt", LangDir, "中文")
    NewLangFilePath := Format("{}\{}.txt", LangDir, "New中文")
    file := FileOpen(LangFilePath, "r", "UTF-8")
    ResultArr := []
    KeyMap := Map()
    while !file.AtEOF {
        line := file.ReadLine()
        if (line = "")  ; 跳过空行
            continue
        key := Trim(line)
        if (!KeyMap.Has(key)) {
            KeyMap[key] := 1
            ResultArr.Push(key)
        }
    }
    file.Close()

    ; FileDelete(LangFilePath)
    for value in ResultArr {
        FileAppend(value "`n", NewLangFilePath, "UTF-8")
    }
    MsgBox("中文Key去重成功")
}

GetLang(Key) {
    ;中文或者LangKeyMap不存在时 直接返回key就行
    if (MySoftData.Lang == "中文" || LangKeyMap.Count == 0)
        return key

    if (LangKeyMap.Has(Key))
        return LangKeyMap[Key]

    return Key
}

GetLangArr(KeyArr) {
    ResArr := []
    for Value in KeyArr {
        ResArr.Push(GetLang(Value))
    }
    return ResArr
}

GetLangKey(value) {
    ;中文或者LangKeyMap不存在时 直接返回key就行
    if (MySoftData.Lang == "中文" || LangValueMap.Count == 0)
        return value

    if (LangValueMap.Has(value))
        return LangValueMap[value]

    return value
}

GetLangKeyArr(ValueArr) {
    ResArr := []
    for Value in ValueArr {
        ResArr.Push(GetLangKey(Value))
    }
    return ResArr
}

GetLangMacro(MacroStr, Mode) {
    cmdArr := SplitMacro(MacroStr)
    for cmdStr in cmdArr {
        cmdStr := GetLangCmd(cmdStr, Mode)
        cmdArr[A_Index] := cmdStr
    }
    return GetMacroStrByCmdArr(cmdArr)
}

;mode 1多语言模式  2中文语言模式
GetLangCmd(Cmd, Mode) {
    paramArr := StrSplit(Cmd, "_")
    action := Mode == 1 ? GetLang : GetLangKey
    paramArr[1] := action(paramArr[1])

    if (paramArr[1] == "RMT指令" || paramArr[1] == GetLang("RMT指令")) {
        paramArr[2] := action(paramArr[2])
    }

    if (paramArr[1] == "间隔" || paramArr[1] == GetLang("间隔")) {
        paramArr[2] := action(paramArr[2])
    }

    return GetCmdByParams(paramArr)
}

;mode 1多语言模式  2中文语言模式
GetLangStr(Str, Mode) {
    SpecialKeyArr1 := ["指令循环次数", "宏循环次数", "当前鼠标坐标X", "当前鼠标坐标Y"]
    SpecialKeyArr2 := [GetLang("指令循环次数"), GetLang("宏循环次数"), GetLang("当前鼠标坐标X"), GetLang("当前鼠标坐标Y")]
    KeyArr := Mode == 1 ? SpecialKeyArr1 : SpecialKeyArr2
    action := Mode == 1 ? GetLang : GetLangKey

    for index, value in KeyArr {
        Str := StrReplace(Str, value, action(value))
    }
    return Str
}
