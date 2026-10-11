#Requires AutoHotkey v2.0

; =====================================================================
; 时间指令执行端 —— 5 种子模式 (纯英文参数)
;   1. 指定时刻等待 (Param1=目标时间/时长, Param2=Seconds/Minutes/Hours/Days/SpecificTime/TimeVariable)
;   2. 时间区间判断 (Param1=开始时间, Param2=结束时间, Param3=允许星期, Param4=Skip/Wait/Stop)
;   3. 获取时间变量 (Param1=目标变量名, Param2=来源时间变量/可选)
;   4. 获取时间字符串 (Param1=目标变量名, Param2=来源时间变量/可选, Param3=格式模板)
;   5. 时间计算     (Param1=时间变量1, Param2=时间变量2/偏移, Param3=Diff/Add/Sub, Param4=目标变量, Param5=Seconds/Milliseconds/Minutes/Hours/Days/HH:mm:ss)
; =====================================================================

OnTimeData(tableItem, cmd, index) {
    paramArr := StrSplit(cmd, "_")
    Data := GetMacroCMDData(paramArr[1])
    if (!IsObject(Data))
        return

    subMode := Integer(Data.SubMode)
    switch subMode {
        case 1: ; 指定时刻等待
            TimeExecWaitUntil(tableItem, index, Data)
        case 2: ; 时间区间判断
            TimeExecWindowCheck(tableItem, index, Data)
        case 3: ; 获取时间变量
            TimeExecGetTimeVar(tableItem, index, Data)
        case 4: ; 获取时间字符串
            TimeExecGetTimeStr(tableItem, index, Data)
        case 5: ; 时间计算
            TimeExecTimeMath(tableItem, index, Data)
    }
}

; ---------- 模式1：指定时刻等待 / 相对等待 ----------

TimeExecWaitUntil(tableItem, index, Data) {
    targetTime := TimeCalcTargetDateTime(tableItem, index, Data)
    if (targetTime == "")
        return

    checkInterval := Integer(Data.CheckInterval > 0 ? Data.CheckInterval : 500)
    timeoutMs := Integer(Data.Timeout > 0 ? Data.Timeout : 0)
    startTick := A_TickCount

    Loop {
        WaitIfPaused(tableItem, index)
        item := tableItem.Items[index]
        if (item.Killed)
            return

        ; 到达目标时间
        if (A_Now >= targetTime)
            return

        ; 超时检查
        if (timeoutMs > 0 && (A_TickCount - startTick >= timeoutMs))
            return

        floatInterval := GetFloatTime(checkInterval, MainSoftData.PreIntervalFloat)
        InterruptibleSleep(tableItem, index, floatInterval)
    }
}

TimeNormWaitType(unit) {
    u := Trim(String(unit))
    if (u == "")
        return "指定时刻"
    u := GetLangKey(u)
    switch u {
        case "SpecificTime", "指定时刻":
            return "指定时刻"
        case "TimeVariable", "时间变量":
            return "时间变量"
        default:
            return "时长"
    }
}

TimeNormMismatch(action) {
    a := GetLangKey(Trim(String(action)))
    switch a {
        case "Wait", "等待":
            return "等待"
        case "Stop", "终止":
            return "终止"
        default:
            return "跳过"
    }
}

TimeNormMathOp(op) {
    o := GetLangKey(Trim(String(op)))
    switch o {
        case "Add", "增加":
            return "增加"
        case "Sub", "减少":
            return "减少"
        default:
            return "差值"
    }
}

TimeNormMathUnit(unit) {
    u := GetLangKey(Trim(String(unit)))
    switch u {
        case "Milliseconds", "毫秒":
            return "毫秒"
        case "Minutes", "分钟":
            return "分钟"
        case "Hours", "小时":
            return "小时"
        case "Days", "天":
            return "天"
        case "HH:mm:ss", "时:分:秒":
            return "时:分:秒"
        default:
            return "秒"
    }
}

TimeParseDurationSecs(val, unit) {
    raw := Trim(String(val))
    u := GetLangKey(Trim(String(unit)))
    if (RegExMatch(raw, "^(-?\d+):(-?\d+):(-?\d+)$", &mt))
        return Integer(mt[1]) * 3600 + Integer(mt[2]) * 60 + Integer(mt[3])
    n := IsNumber(raw) ? Integer(raw) : 0
    switch u {
        case "Minutes", "分钟":
            return n * 60
        case "Hours", "小时":
            return n * 3600
        case "Days", "天":
            return n * 86400
        default:
            return n
    }
}

TimeCalcTargetDateTime(tableItem, index, Data) {
    param1Val := GetReplaceVarText(tableItem, index, Data.Param1)
    waitType := TimeNormWaitType(Data.Param2)

    switch waitType {
        case "时长":
            raw := Trim(String(Data.Param1))
            arr := StrSplit(raw, ":")
            if (arr.Length == 3) {
                h := GetReplaceVarText(tableItem, index, arr[1])
                m := GetReplaceVarText(tableItem, index, arr[2])
                s := GetReplaceVarText(tableItem, index, arr[3])
                param1Val := h ":" m ":" s
            }
            secs := TimeParseDurationSecs(param1Val, Data.Param2)
            return DateAdd(A_Now, secs, "Seconds")
        case "指定时刻":
            return TimeParseDateTime(TimeResolveClock(tableItem, index, Data.Param1))
        case "时间变量":
            valStr := String(param1Val)
            if (valStr == "") {
                rawVarName := GetVarName(Data.Param1)
                v := ""
                if (TryGetTabVarValue(&v, tableItem, index, rawVarName))
                    valStr := String(v)
            }
            if (valStr != "") {
                if (IsNumber(valStr)) {
                    if (StrLen(valStr) <= 10)
                        return DateAdd("19700101000000", Integer(valStr), "Seconds")
                    else if (StrLen(valStr) == 13)
                        return DateAdd("19700101000000", Integer(SubStr(valStr, 1, 10)), "Seconds")
                }
                return TimeParseDateTime(valStr)
            }
            return ""
        default:
            return TimeParseDateTime(param1Val)
    }
}

TimeParseDateTime(s) {
    s := Trim(s)
    if (s == "")
        return ""

    ; 1. 纯数字处理 (14位YYYYMMDDHHMISS / 8位YYYYMMDD / 10位Unix秒 / 13位Unix毫秒)
    if (RegExMatch(s, "^\d+$")) {
        len := StrLen(s)
        if (len == 14)
            return s
        if (len == 8)
            return s "000000"
        if (len <= 10)
            return DateAdd("19700101000000", Integer(s), "Seconds")
        if (len == 13)
            return DateAdd("19700101000000", Integer(SubStr(s, 1, 10)), "Seconds")
    }

    ; 2. 纯时刻格式：14:30:00, 14:30
    if (RegExMatch(s, "^(\d{1,2}):(\d{1,2})(?::(\d{1,2}))?", &mt)) {
        h := Format("{:02}", mt[1])
        mi := Format("{:02}", mt[2])
        se := (mt.Count >= 3 && mt[3] != "") ? Format("{:02}", mt[3]) : "00"
        todayTime := SubStr(A_Now, 1, 8) h mi se
        ; 如果当天目标时间已过，自动顺延至明天同一时间
        if (A_Now > todayTime)
            return DateAdd(todayTime, 1, "Days")
        return todayTime
    }

    ; 3. 年月日 + 时分秒：2026-09-19 14:30:00 / 2026/09/19 14:30
    if (RegExMatch(s, "(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})", &m)) {
        y := m[1]
        mo := Format("{:02}", m[2])
        d := Format("{:02}", m[3])
        h := "00", mi := "00", se := "00"
        if (RegExMatch(s, "(\d{1,2}):(\d{1,2})(?::(\d{1,2}))?", &mt)) {
            h := Format("{:02}", mt[1])
            mi := Format("{:02}", mt[2])
            se := (mt.Count >= 3 && mt[3] != "") ? Format("{:02}", mt[3]) : "00"
        }
        return y mo d h mi se
    }

    ; 4. ISO 8601 标准格式 (2026-09-19T14:30:00Z / 2026-09-19T14:30:00+08:00)
    if (RegExMatch(s, "(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})", &m)) {
        return m[1] m[2] m[3] m[4] m[5] m[6]
    }

    return ""
}

TimeFormatResult(stamp, formatType) {
    if (stamp == "")
        return ""
    switch formatType {
        case "UnixTimestamp":
            return DateDiff(stamp, "19700101000000", "Seconds")
        case "E":
            w := FormatTime(stamp, "WDay")
            return w == 1 ? 7 : w - 1
        case "EEEE":
            return FormatTime(stamp, "dddd")
        case "EEE":
            return FormatTime(stamp, "ddd")
        case "", "Raw":
            return FormatTime(stamp, "yyyy-MM-dd HH:mm:ss")
        default:
            try {
                return FormatTime(stamp, formatType)
            } catch {
                return FormatTime(stamp, "yyyy-MM-dd HH:mm:ss")
            }
    }
}

TimeToAhkStamp(s) {
    s := Trim(s)
    if (s == "")
        return ""
    return TimeParseDateTime(s)
}

; ---------- 模式2：时间区间判断 ----------

TimeResolveClock(tableItem, index, raw) {
    raw := Trim(String(raw))
    arr := StrSplit(raw, ":")
    if (arr.Length == 3) {
        h := GetReplaceVarText(tableItem, index, arr[1])
        m := GetReplaceVarText(tableItem, index, arr[2])
        s := GetReplaceVarText(tableItem, index, arr[3])
        return Trim(h) ":" Trim(m) ":" Trim(s)
    }
    return GetReplaceVarText(tableItem, index, raw)
}

TimeParseClockOfDay(s) {
    s := Trim(s)
    if (RegExMatch(s, "^(\d{1,2}):(\d{1,2})(?::(\d{1,2}))?", &mt)) {
        h := Format("{:02}", Integer(mt[1]))
        mi := Format("{:02}", Integer(mt[2]))
        se := (mt.Count >= 3 && mt[3] != "") ? Format("{:02}", Integer(mt[3])) : "00"
        return SubStr(A_Now, 1, 8) h mi se
    }
    stamp := TimeParseDateTime(s)
    if (stamp == "")
        return ""
    return SubStr(A_Now, 1, 8) SubStr(stamp, 9)
}

TimeNowInClockWindow(startStamp, endStamp) {
    nt := SubStr(A_Now, 9)
    st := SubStr(startStamp, 9)
    et := SubStr(endStamp, 9)
    if (st <= et)
        return nt >= st && nt <= et
    return nt >= st || nt <= et
}

TimeExecWindowCheck(tableItem, index, Data) {
    startTime := TimeResolveClock(tableItem, index, Data.Param1)
    endTime := TimeResolveClock(tableItem, index, Data.Param2)
    allowDays := Data.Param3 != "" ? Data.Param3 : "1,2,3,4,5,6,7"
    mismatchAction := TimeNormMismatch(Data.Param4 != "" ? Data.Param4 : "跳过")

    startStamp := TimeParseClockOfDay(startTime)
    endStamp := TimeParseClockOfDay(endTime)
    if (startStamp == "" || endStamp == "")
        return

    nowDayOfWeek := A_WDay == 1 ? 7 : (A_WDay - 1)  ; AHK: 1=Sun → convert to 1=Mon
    dayOk := InStr("," allowDays ",", "," nowDayOfWeek ",")
    inWindow := dayOk && TimeNowInClockWindow(startStamp, endStamp)

    if (inWindow)
        return

    switch mismatchAction {
        case "跳过":
            return
        case "终止":
            KillTableItemMacro(tableItem, index)
        case "等待":
            Loop {
                WaitIfPaused(tableItem, index)
                item := tableItem.Items[index]
                if (item.Killed)
                    return
                nowDayOfWeek2 := A_WDay == 1 ? 7 : (A_WDay - 1)
                dayOk2 := InStr("," allowDays ",", "," nowDayOfWeek2 ",")
                if (dayOk2 && TimeNowInClockWindow(startStamp, endStamp))
                    return
                InterruptibleSleep(tableItem, index, 1000)
            }
    }
}

; ---------- 模式3：获取时间变量 ----------
; Param1 = 目标变量名
; Param2 = 来源时间（可为变量名、时间字符串、空=当前时间）

TimeExecGetTimeVar(tableItem, index, Data) {
    varName := GetVarName(Trim(Data.Param1))
    if (varName == "")
        return

    srcParam := Trim(Data.Param2)
    if (srcParam != "") {
        srcVal := GetReplaceVarText(tableItem, index, srcParam)
        stamp := TimeToAhkStamp(srcVal)
    } else {
        stamp := ""
    }
    if (stamp == "")
        stamp := A_Now

    ; 时间变量存储为标准格式字符串 "yyyy-MM-dd HH:mm:ss"
    outVal := FormatTime(stamp, "yyyy-MM-dd HH:mm:ss")
    try MySoftData.TimeVarMap[varName] := true
    MySetGlobalVariable([varName], [outVal], false)
}

; ---------- 模式4：获取时间字符串 ----------
; Param1 = 目标变量名
; Param2 = 来源时间（可为变量名、时间字符串、空=当前时间）
; Param3 = 格式化模板

TimeExecGetTimeStr(tableItem, index, Data) {
    varName := GetVarName(Trim(Data.Param1))
    if (varName == "")
        return

    srcParam := Trim(Data.Param2)
    if (srcParam != "") {
        srcVal := GetReplaceVarText(tableItem, index, srcParam)
        stamp := TimeToAhkStamp(srcVal)
    } else {
        stamp := ""
    }
    if (stamp == "")
        stamp := A_Now

    formatTemplate := Data.Param3 != "" ? Data.Param3 : "yyyy-MM-dd HH:mm:ss"
    outStr := TimeFormatResult(stamp, formatTemplate)
    MySetGlobalVariable([varName], [outStr], false)
}

; ---------- 模式5：时间计算 ----------
; Param1 = 时间变量1（或时间字符串）
; Param2 = 时间变量2 / 数值偏移
; Param3 = 操作 (Diff / Add / Sub)
; Param4 = 保存变量名
; Param5 = 单位/格式 (Seconds / Milliseconds / Minutes / Hours / Days / HH:mm:ss)

TimeExecTimeMath(tableItem, index, Data) {
    src1 := GetReplaceVarText(tableItem, index, Data.Param1)
    src2 := GetReplaceVarText(tableItem, index, Data.Param2)
    opType := TimeNormMathOp(Data.Param3 != "" ? Data.Param3 : "差值")
    targetVar := GetVarName(Trim(Data.Param4))
    unit := TimeNormMathUnit(Data.Param5 != "" ? Data.Param5 : "秒")

    if (targetVar == "")
        return

    result := ""

    if (opType == "差值") {
        ; 计算两个时间之差 (src1 - src2)
        t1 := TimeToAhkStamp(src1)
        t2 := TimeToAhkStamp(src2)
        if (t1 != "" && t2 != "") {
            diffSec := DateDiff(t1, t2, "Seconds")
            switch unit {
                case "毫秒":
                    result := diffSec * 1000
                case "分钟":
                    result := Round(diffSec / 60, 2)
                case "小时":
                    result := Round(diffSec / 3600, 2)
                case "天":
                    result := Round(diffSec / 86400, 2)
                case "时:分:秒":
                    absSec := Abs(diffSec)
                    h := Format("{:02}", Floor(absSec / 3600))
                    mi := Format("{:02}", Floor(Mod(absSec, 3600) / 60))
                    se := Format("{:02}", Mod(absSec, 60))
                    result := (diffSec < 0 ? "-" : "") h ":" mi ":" se
                default:
                    result := diffSec
            }
        }
    } else if (opType == "增加" || opType == "减少") {
        ; 时间增加或减少偏移
        baseTime := TimeToAhkStamp(src1)
        if (baseTime == "")
            baseTime := A_Now

        offsetVal := IsNumber(src2) ? Integer(src2) : 0
        if (opType == "减少")
            offsetVal := -offsetVal

        ahkUnit := "Seconds"
        switch unit {
            case "分钟":
                ahkUnit := "Minutes"
            case "小时":
                ahkUnit := "Hours"
            case "天":
                ahkUnit := "Days"
            default:
                ahkUnit := "Seconds"
        }

        resStamp := DateAdd(baseTime, offsetVal, ahkUnit)
        result := FormatTime(resStamp, "yyyy-MM-dd HH:mm:ss")
    }

    if (result != "") {
        MySetGlobalVariable([targetVar], [result], false)
    }
}