#Requires AutoHotkey v2.0

SetGlobalVar() {
    VariableMap := Map()
    visitMap := Map()
    loop MySoftData.TabNameArr.Length {
        tableItem := MySoftData.TableInfo[A_Index]
        tableIndex := A_Index
        for index, value in tableItem.ModeArr {
            if (tableItem.MacroArr.Length < index || tableItem.MacroArr[index] == "")
                continue

            macroStr := tableItem.MacroArr[index]
            GetMacroStrGlobalVar(macroStr, VariableMap, visitMap)
        }
    }
    MySoftData.GlobalVariMap := VariableMap
}

GetMacroStrGlobalVar(macroStr, VariableMap, visitMap) {
    if (macroStr == "") 
        return
    cmdArr := SplitMacro(macroStr)
    loop cmdArr.Length {
        paramArr := StrSplit(cmdArr[A_Index], "_")
        if (paramArr.Length >= 2 && visitMap.Has(paramArr[2]))
            continue

        IsVariable := StrCompare(paramArr[1], GetLang("变量"), false) == 0
        IsExVariable := StrCompare(paramArr[1], GetLang("变量提取"), false) == 0
        IsIf := StrCompare(paramArr[1], GetLang("如果"), false) == 0
        IsOpera := StrCompare(paramArr[1], GetLang("运算"), false) == 0
        IsSearch := StrCompare(paramArr[1], GetLang("搜索"), false) == 0
        IsSearchPro := StrCompare(paramArr[1], GetLang("搜索Pro"), false) == 0
        IsLoop := StrCompare(paramArr[1], GetLang("循环"), false) == 0
        IsIfPro := StrCompare(paramArr[1], GetLang("如果Pro"), false) == 0
        IsVarRelate := IsVariable || IsExVariable || IsIf || IsOpera || IsSearch || IsSearchPro
            || IsLoop || IsIfPro
        if (!IsVarRelate)
            continue
        visitMap[paramArr[2]] := true

        if (IsVariable) {
            saveStr := IniRead(VariableFile, IniSection, paramArr[2], "")
            Data := JSON.parse(saveStr, , false)

            loop 4 {
                if (Data.ToggleArr[A_Index])
                    VariableMap[Data.VariableArr[A_Index]] := true
            }
        }
        else if (IsExVariable) {
            saveStr := IniRead(ExVariableFile, IniSection, paramArr[2], "")
            Data := JSON.parse(saveStr, , false)

            loop 4 {
                if (Data.ToggleArr[A_Index])
                    VariableMap[Data.VariableArr[A_Index]] := true
            }
        }
        else if (IsIf) {
            saveStr := IniRead(CompareFile, IniSection, paramArr[2], "")
            Data := JSON.parse(saveStr, , false)

            if (Data.SaveToggle) {
                VariableMap[Data.SaveName] := true
            }
        }
        else if (IsOpera) {
            saveStr := IniRead(OperationFile, IniSection, paramArr[2], "")
            Data := JSON.parse(saveStr, , false)

            loop 4 {
                if (Data.ToggleArr[A_Index])
                    VariableMap[Data.UpdateNameArr[A_Index]] := true
            }
        }
        else if (IsSearch || IsSearchPro) {
            FileName := IsSearch ? SearchFile : SearchProFile
            saveStr := IniRead(FileName, IniSection, paramArr[2], "")
            Data := JSON.parse(saveStr, , false)
            if (Data.ResultToggle) {
                VariableMap[Data.ResultSaveName] := true
            }

            if (Data.CoordToogle) {
                VariableMap[Data.CoordXName] := true
                VariableMap[Data.CoordYName] := true
            }
        }
        else if (IsLoop) {
            VariableMap[GetLang("指令循环次数")] := true
        }

        if (IsIf || IsSearch || IsSearchPro) {
            FileMap := Map(GetLang("如果"), CompareFile, GetLang("搜索"), SearchFile, GetLang("搜索Pro"), SearchProFile)
            filePath := FileMap[paramArr[1]]
            saveStr := IniRead(filePath, IniSection, paramArr[2], "")
            Data := JSON.parse(saveStr, , false)
    
            GetMacroStrGlobalVar(Data.TrueMacro, VariableMap, visitMap)
            GetMacroStrGlobalVar(Data.FalseMacro, VariableMap, visitMap)
        }
        else if (IsLoop) {
            saveStr := IniRead(LoopFile, IniSection, paramArr[2], "")
            Data := JSON.parse(saveStr, , false)
            GetMacroStrGlobalVar(Data.LoopBody, VariableMap, visitMap)
        }
        else if (IsIfPro) {
            saveStr := IniRead(CompareProFile, IniSection, paramArr[2], "")
            Data := JSON.parse(saveStr, , false)
            for index, value in Data.MacroArr {
                GetMacroStrGlobalVar(value, VariableMap, visitMap)
            }
            GetMacroStrGlobalVar(Data.DefaultMacro, VariableMap, visitMap)
        }
    }
}

GetLocalVar(macroStr) {
    VariableMap := Map()
    visitMap := Map()
    GetMacroStrGlobalVar(macroStr, VariableMap, visitMap)
    return VariableMap
}

GetGuiVariableObjArr(curMacroStr, VariableObjArr) {
    ResultArr := []
    ResultMap := GetLocalVar(curMacroStr)
    HasLoopCount := false   ;含有指令循环次数变量
    SpecialKeyArr := [GetLang("指令循环次数"), GetLang("宏循环次数"), GetLang("当前鼠标坐标X"), GetLang("当前鼠标坐标Y")]

    ; 将VariableObjArr中的变量添加到映射中
    for Value in VariableObjArr {
        ResultMap[Value] := true
    }

    ; 添加全局变量（如果不存在）
    for Key in MySoftData.GlobalVariMap {
        if !ResultMap.Has(Key) {
            ResultMap[Key] := true
        }
    }

    ;为了让特殊变量出现在末尾，先删除
    for curKey in SpecialKeyArr {
        if ResultMap.Has(curKey) {
            if (curKey == GetLang("指令循环次数"))
                HasLoopCount := true
            ResultMap.Delete(curKey)
        }
    }

    ; 将映射的键收集到数组中
    for Key in ResultMap {
        ResultArr.Push(Key)
    }

    if (HasLoopCount)
        ResultArr.Push(GetLang("指令循环次数"))
    ResultArr.Push(SpecialKeyArr*)
    return ResultArr
}

;mode 1:移除所有  2：移除坐标变量
RemoveInVariable(VarArr, Mode := 1) {
    SpecialKeyArr1 := [GetLang("指令循环次数"), GetLang("宏循环次数"), GetLang("当前鼠标坐标X"), GetLang("当前鼠标坐标Y")]
    SpecialKeyArr2 := [GetLang("当前鼠标坐标X"), GetLang("当前鼠标坐标Y")]
    SpecialMap := Map(1, SpecialKeyArr1, 2, SpecialKeyArr2)
    SpecialKeyArr := SpecialMap[Mode]

    ; 创建一个新数组来存储结果
    result := []

    ; 第一个循环：遍历原始数组的每个值
    for value in VarArr {
        found := false

        ; 第二个循环：检查这个值是否在特殊值数组中
        for specialValue in SpecialKeyArr {
            if value = specialValue {
                found := true
                break  ; 找到匹配项，跳出内层循环
            }
        }

        ; 如果没有找到匹配项，则添加到结果数组
        if (!found) {
            result.Push(value)
        }
    }

    return result
}
