#Requires AutoHotkey v2.0
; 新增：使用表达式解析器计算（支持括号、数值处理函数）
GetExpressionResult(Expression, tableItem, tableIndex, &Res) {
    if (Expression == "")
        return false

    ; 替换表达式中的变量为实际值
    ProcessedExpr := GetReplaceVarText(tableItem, tableIndex, Expression)
    ; 计算表达式
    try {
        Res := EvaluateExpression(ProcessedExpr)
        return true
    } catch {
        ; 解析失败，回退到简单计算
        return false
    }
}

; 表达式计算器：词法分析 + 递归下降（支持 abs/max/min/round/ceil/floor）
EvaluateExpression(expr) {
    ; 预处理：去除空格（含全角空格）
    expr := RegExReplace(expr, "[\s　]+", "")
    ; 兼容全角括号/逗号
    expr := StrReplace(expr, "（", "(")
    expr := StrReplace(expr, "）", ")")
    expr := StrReplace(expr, "，", ",")

    if (expr == "")
        return 0

    tokens := Tokenize(expr)
    if (tokens.Length == 0)
        return 0

    pos := 1
    result := ParseAddSub(tokens, &pos)
    return TrimZeros(result)
}

Tokenize(expr) {
    tokens := []
    pos := 1
    len := StrLen(expr)

    while (pos <= len) {
        char := SubStr(expr, pos, 1)
        ; 数字
        if (RegExMatch(char, "\d")) {
            numStr := ""
            while (pos <= len && RegExMatch(SubStr(expr, pos, 1), "[\d\.]")) {
                numStr .= SubStr(expr, pos, 1)
                pos++
            }
            tokens.Push(numStr)
            continue
        }

        ; 函数名（英文字母）
        if (RegExMatch(char, "[a-zA-Z_]")) {
            name := ""
            while (pos <= len && RegExMatch(SubStr(expr, pos, 1), "[a-zA-Z_]")) {
                name .= SubStr(expr, pos, 1)
                pos++
            }
            tokens.Push(StrLower(name))
            continue
        }

        ; 运算符、括号、取整括号、逗号
        if (InStr("+-*/%^()⌊⌋,", char)) {
            tokens.Push(char)
            pos++
            continue
        }

        pos++
    }

    return tokens
}

ParseAddSub(tokens, &pos) {
    value := ParseMulDiv(tokens, &pos)

    while (pos <= tokens.Length && InStr("+-", tokens[pos])) {
        op := tokens[pos]
        pos++
        next := ParseMulDiv(tokens, &pos)

        if (op == "+")
            value := Round(value + next, 6)
        else
            value := Round(value - next, 6)
    }

    return value
}

ParseMulDiv(tokens, &pos) {
    value := ParsePower(tokens, &pos)

    while (pos <= tokens.Length && InStr("*/%", tokens[pos])) {
        op := tokens[pos]
        pos++
        next := ParsePower(tokens, &pos)

        if (op == "*")
            value := Round(value * next, 6)
        else if (op == "/")
            value := Round(value / next, 6)
        else if (op == "%")
            value := Round(Mod(value, next), 6)
    }

    return value
}

ParsePower(tokens, &pos) {
    value := ParseAtom(tokens, &pos)

    if (pos <= tokens.Length && tokens[pos] == "^") {
        pos++
        next := ParsePower(tokens, &pos)
        value := Round(value ** next, 6)
    }

    return value
}

ParseAtom(tokens, &pos) {
    if (pos > tokens.Length)
        return 0

    token := tokens[pos]

    ; 数字
    if (RegExMatch(token, "^[\d\.]+$")) {
        pos++
        return token
    }

    ; 数值处理函数
    if (token == "abs" || token == "max" || token == "min" || token == "round" || token == "ceil" || token == "floor") {
        return ParseFuncCall(tokens, &pos, token)
    }

    ; 普通括号
    if (token == "(") {
        pos++
        value := ParseAddSub(tokens, &pos)
        if (pos <= tokens.Length && tokens[pos] == ")")
            pos++
        return value
    }

    ; 兼容旧 ⌊⌋ 取整（按四舍五入）
    if (token == "⌊") {
        pos++
        value := ParseAddSub(tokens, &pos)
        if (pos <= tokens.Length && tokens[pos] == "⌋")
            pos++
        return Round(value)
    }

    ; 一元正负号
    if (token == "+" || token == "-") {
        sign := token == "+" ? 1 : -1
        pos++
        value := ParseAtom(tokens, &pos)
        return sign * value
    }

    pos++
    return 0
}

ParseFuncCall(tokens, &pos, fname) {
    pos++  ; 跳过函数名
    if (pos > tokens.Length || tokens[pos] != "(")
        return 0
    pos++  ; 跳过 '('

    ; 空参：abs() 等 → 0
    if (pos <= tokens.Length && tokens[pos] == ")") {
        pos++
        return 0
    }

    arg1 := ParseAddSub(tokens, &pos)
    arg2 := ""
    hasArg2 := false
    if (pos <= tokens.Length && tokens[pos] == ",") {
        pos++
        arg2 := ParseAddSub(tokens, &pos)
        hasArg2 := true
    }
    if (pos <= tokens.Length && tokens[pos] == ")")
        pos++

    switch fname {
        case "abs":
            return Abs(arg1)
        case "round":
            return Round(arg1)
        case "ceil":
            return Ceil(arg1)
        case "floor":
            return Floor(arg1)
        case "max":
            return hasArg2 ? Max(arg1, arg2) : arg1
        case "min":
            return hasArg2 ? Min(arg1, arg2) : arg1
    }
    return arg1
}

TrimZeros(num_str) {
    if (!InStr(num_str, "."))
        return num_str

    while (SubStr(num_str, -1) = "0")
        num_str := SubStr(num_str, 1, -1)

    if (SubStr(num_str, -1) = ".")
        num_str := SubStr(num_str, 1, -1)

    num_str := num_str == "" ? "0" : num_str

    return num_str
}
