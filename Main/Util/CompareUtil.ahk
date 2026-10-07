#Requires AutoHotkey v2.0

GetAmpersandSequence(str) {
    sequence := Map()
    counter := 1
    needle := "&[xc]"  ; 正则表达式匹配 &x 或 &c

    foundPos := 1
    while (foundPos := RegExMatch(str, needle, &match, foundPos)) {
        sequence[counter] := match[0]  ; 按顺序编号存储
        counter += 1
        foundPos += match.Len  ; 移动到匹配后的位置继续搜索
    }

    return sequence
}

ExtractVariable(Text, Pattern) {
    ; 去除空格
    Text := StrReplace(Text, " ", "")
    Pattern := StrReplace(Pattern, " ", "")
    
    ; 转义Pattern中的特殊字符
    Pattern := RegExReplace(Pattern, "[.*+?()\[\]{}|^$\\]", "\$0")
    ; 将 pattern 中的中英文冒号统一替换为正则通配 [:：]
    Pattern := RegExReplace(Pattern, "[:：]", "[:：]")
    Pattern := RegExReplace(Pattern, "[,，]", "[,，]")
    SymbolMap := GetAmpersandSequence(Pattern)

    ; 优化数字匹配模式，区分千分位和普通数字
    Pattern := RegExReplace(Pattern, "&x", BuildNumberPattern())
    Pattern := RegExReplace(Pattern, "&c", "(.*)")

    if (RegExMatch(Text, Pattern, &Match)) {
        Result := []
        for i, Value in Match {
            if (i == 0)
                continue

            if (SymbolMap[i] == "&x") {
                ; 智能处理千分位和普通数字
                tempValue := ProcessNumberValue(Value)
            } else {
                tempValue := Value
            }
            Result.Push(tempValue)
        }
        return Result
    }
    return ""
}

BuildNumberPattern() {
    ; 千分位模式：必须包含逗号且格式正确
    ThousandFormat := "\d{1,3}(?:[,，]\d{3})+(?:\.\d+)?"
    ; 普通数字模式：不包含逗号或仅含小数点
    NormalFormat := "[+-]?\d+(?:\.\d+)?"
    ; 小数模式：以小数点开头
    DecimalFormat := "[+-]?\.\d+"

    return "(" ThousandFormat "|" NormalFormat "|" DecimalFormat ")"
}

ProcessNumberValue(Value) {
    Cleaned := StrReplace(Value, ",")
    Cleaned := StrReplace(Cleaned, "，", "")
    Cleaned := StrReplace(Cleaned, "＋", "+")
    Cleaned := StrReplace(Cleaned, "－", "-")

    if (IsFloat(Cleaned)) {
        ; 处理整数部分前导零
        Cleaned := RegExReplace(Cleaned, "^([+-])?0+(\d)", "$1$2")

        ; 处理小数部分末尾零
        return RegExReplace(Cleaned, "(\.\d*?[1-9])0+$|(\.)0+$", "$1$2")
    }

    ; 处理整数前导零
    return Integer(RegExReplace(Cleaned, "^0+(\d)", "$1"))
}

; 条件比较：下拉显示顺序（等于后为不等于）
; 存储序号保持兼容：1> 2>= 3== 4<= 5< 6包含 7变量存在 8正则 9!=
GetCompareTypeLangArr() {
    return GetLangArr(["大于", "大于等于", "等于", "不等于", "小于等于", "小于", "字符包含", "变量存在", "正则匹配"])
}

GetCompareTypeName(ct) {
    if (!IsNumber(ct))
        ct := 1
    ct := Integer(ct)
    arr := GetLangArr(["大于", "大于等于", "等于", "小于等于", "小于", "字符包含", "变量存在", "正则匹配", "不等于"])
    if (ct >= 1 && ct <= arr.Length)
        return arr[ct]
    return arr[1]
}

GetCompareTypeStrMap() {
    return Map(
        GetLang("大于"), 1,
        GetLang("大于等于"), 2,
        GetLang("等于"), 3,
        GetLang("不等于"), 9,
        GetLang("小于等于"), 4,
        GetLang("小于"), 5,
        GetLang("字符包含"), 6,
        GetLang("变量存在"), 7,
        GetLang("正则匹配"), 8
    )
}

IsCompareExistVar(ct) {
    return IsNumber(ct) && Integer(ct) == 7
}

ComboIndexToCompareType(idx) {
    if (!IsNumber(idx) || Integer(idx) < 0)
        return 1
    idx := Integer(idx)
    if (idx <= 2)
        return idx + 1
    if (idx == 3)
        return 9
    if (idx <= 8)
        return idx
    return 1
}

CompareTypeToComboIndex(ct) {
    if (!IsNumber(ct) || Integer(ct) < 1)
        return 0
    ct := Integer(ct)
    if (ct <= 3)
        return ct - 1
    if (ct == 9)
        return 3
    if (ct >= 4 && ct <= 8)
        return ct
    return 0
}
