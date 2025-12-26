class TableItem {
    __New() {
        this.SerialArr := []    ;每个item的序列码
        this.TKArr := []        ;触发键
        this.MacroArr := []     ;宏内容
        this.HoldTimeArr := []  ;按住时间
        this.ForbidArr := []    ;禁止
        this.LoopCountArr := [] ;循环次数
        this.RemarkArr := []    ;备注
        this.TriggerTypeArr := []   ;触发类型
        this.TimingSerialArr := []  ;定时配置序列码
        this.ModeArr := []      ;按键模式   1.send 2.拟真
        this.StartTipSoundArr := [] ;开始提示音 1.无   2.触发提示  3.循环首次提示
        this.EndTipSoundArr := [] ;结束提示音 1.无   2.结束提示  3.循环结束提示

        this.ColorStateArr := []
        this.ColorConArr := []
        this.IndexConArr := []
        this.RemarkConArr := []
        this.TKConArr := []
        this.TriggerTypeConArr := []
        this.LoopCountConArr := []
        this.ForbidConArr := []

        this.HoldKeyArr := []       ;记录当前按下的按键，以便结束时松开
        this.KilledArr := []        ;标记结束状态
        this.PauseArr := []         ;暂停
        this.ActionCount := []      ; 记录执行次数，用于循环次数判断
        this.ToggleStateArr := []   ; 触发键开关状态
        this.ToggleActionArr := []   ; 触发键开关Action
        this.VariableMapArr := []    ;  每条宏对应的变量映射
        this.UnderPosY := 0         ; table的最大PosY
        this.Index := 0             ;   table的Index
        this.SliderValue := 0       ;   滑动值
        this.OffSetPosY := 0        ;   偏移值
        this.AllConArr := []        ;   table中所有的con
        this.AllGroup := []         ; table中所有的group
        this.IsWorkIndexArr := []        ;work正在执行中

        this.FoldInfo := ""          ; 折叠筐保存信息
        this.FoldOffsetArr := []    ;和初始状态的高度偏移值
        this.FoldBtnArr := []       ;折叠筐按钮
        this.ConIndexMap := Map()
    }
}

class ItemFoldInfo {
    __New() {
        this.RemarkArr := []        ;折叠框备注
        this.FrontInfoArr := []     ;折叠框前台信息
        this.IndexSpanArr := []     ;范围索引
        this.ForbidStateArr := []   ;禁用状态
        this.FoldStateArr := []    ;折叠状态

        ;菜单栏功能
        this.TKTypeArr := []    ;触发类型
        this.TKArr := []        ;触发按键，菜单栏功能
        this.HoldTimeArr := []  ;长按时间
    }
}

class MacroItemInfo {
    __New(index, itemConInfo) {
        this.index := index
        this.itemConInfo := ItemConInfo
    }
}

class ItemConInfo {
    __New(Con, tableItem, FoldIndex) {
        this.Con := Con
        this.tableItem := tableItem
        this.FoldOffsetArr := tableItem.FoldOffsetArr
        this.FoldInfo := tableItem.FoldInfo
        this.FoldIndex := FoldIndex
        this.IsTitle := false
        this.IsDel := false
        this.Con.GetPos(&PosX, &PosY)
        this.OriPosX := PosX
        this.OriPosY := PosY
        this.SelfOffsetY := 0
    }

    UpdatePos(offsetPosY) {
        try {
            if (this.IsDel) {
                this.Con.Move(this.OriPosX, -10000)
                return
            }

            isFold := this.FoldInfo.FoldStateArr[this.FoldIndex]
            if ((isFold && !this.IsTitle)) {
                this.Con.Move(this.OriPosX, -10000)
                return
            }
            PosY := 0
            for index, value in this.FoldOffsetArr {
                if (index >= this.FoldIndex)
                    break
                PosY += value
            }

            PosY := PosY + this.OriPosY + this.SelfOffsetY - offsetPosY
            this.Con.Move(this.OriPosX, PosY)
        }
    }

    DelAfterOffset(offsetY) {
        this.SelfOffsetY -= offsetY
    }

    Hide() {
        this.IsDel := true
    }
}

class Timer {
    __New(callback, period) {
        this.binding := callback
        this.period := period
        this.priority := 0
    }

    __Delete() {
        this.Off()
    }

    On() {
        funcObj := this.binding
        SetTimer funcObj, this.period, this.priority
    }

    Off() {
        funcObj := this.binding
        SetTimer funcObj, 0
    }
}

class ToolCheck {
    __New() {
        this.AlwaysOnTopCtrl := ""
        this.ToolCheckCtrl := ""
        this.ToolCheckHotKeyCtrl := ""
        this.ToolMousePosCtrl := ""
        this.ToolMouseWinPosCtrl := ""
        this.ToolProcessNameCtrl := ""
        this.ToolProcessTileCtrl := ""
        this.ToolProcessPidCtrl := ""
        this.ToolProcessClassCtrl := ""
        this.ToolProcessIdCtrl := ""
        this.ToolColorCtrl := ""
        this.ToolTextFilterHotKeyCtrl := ""
        this.ToolTextCtrl := ""
        this.ToolRecordMacroHotKeyCtrl := ""
        this.ToolCheckRecordMacroCtrl := ""
        this.ScreenShotHotKeyCtrl := ""
        this.FreePasteHotKeyCtrl := ""

        this.ScreenShotHotKey := ""
        this.FreePasteHotKey := ""
        this.ToolRecordMacroHotKey := ""
        this.IsToolRecord := false
        this.ToolTextFilterHotKey := ""
        this.IsToolCheck := false
        this.ToolCheckHotKey := ""
        this.PosStr := ""
        this.WinPosStr := ""
        this.ProcessName := ""
        this.ProcessTile := ""
        this.ProcessPid := ""
        this.ProcessClass := ""
        this.ProcessId := ""
        this.Color := ""
        this.MouseInfoTimer := ""

        this.MacroGui := ""

        this.RecordLastMousePos := []
        this.RecordLastTime := ""
        this.RecordMacroStr := ""
        this.RecordHoldKeyMap := Map()
        this.RecordSpecialKeyMap := Map(33, 0, 34, 0, 35, 0, 36, 0, 37, 0, 38, 0, 39, 0, 40, 0, 45, 0, 46, 0)
        this.RecordHoldMuti := ""
        this.RecordAutoLoosen := ""
        this.RecordKeyboard := ""
        this.RecordMouse := ""
        this.RecordMouseRelative := ""
        this.RecordMouseTrail := ""
        this.RecordMouseTrailLen := ""
        this.RecordMouseTrailSpeed := ""
        this.RecordMouseTrailInterval := ""
        this.RecordJoy := ""
        this.RecordJoyInterval := ""
        this.OCRTypeCtrl := ""
        this.OCRTypeValue := 1
    }
}

class SoftData {
    __New() {
        this.isWork := false            ;子线程标识
        this.IsLogitechInit := false    ;罗技按键初始化
        this.ToolTipText := ""          ;临时提示文本
        this.ToolTipEndTime := ""       ;临时提示结束时间
        this.AgreeAgreement := false    ;同意协议
        this.IsBootStart := false       ;开机自启
        this.ShowSplitLine := false     ;显示分割线
        this.FixedMenuWheel := false    ;固定菜单轮
        this.NoVariableTip := false     ;无变量提醒
        this.ScreenShotType := 1        ;截图类型
        this.MutiThreadNum := 3         ;多线程数
        this.IsSuspend := false         ;休眠
        this.SuspendHotkey := ""        ;休眠快捷键
        this.IsPause := false           ;暂停
        this.PauseHotkey := ""          ;暂停快捷键
        this.KillMacroHotkey := ""      ;终止所有宏快捷键
        this.HoldFloat := 0             ;按住时间浮动数值
        this.PreIntervalFloat := 0      ;每次间隔浮动数值
        this.IntervalFloat := 0         ;间隔指令浮动数值
        this.CoordXFloat := 0           ;坐标X浮动数值
        this.CoordYFloat := 0           ;坐标Y浮动数值
        this.SoftBGColor := ""          ;软件背景颜色
        this.IsReload := false          ;软件是否重载
        this.TableIndex := 1            ;当前显示的table索引
        this.HasSaved := false          ;是否保存
        this.MacroEditGui := ""         ;当前宏编辑器
        this.FontType := "微软雅黑"     ;当前字体
        this.FontList := []             ;所有字体类型
        this.Lang := "中文"             ;当前语言
        this.LangArr := []              ;所有语言

        this.MyGui := {}                ;软件主界面GUI
        this.CurSettingName := ""       ;当前配置名称
        this.SettingArrStr := ""        ;所有配置字串
        this.CurMenuWheelIndex := -1    ;当先显示的菜单轮盘

        this.TabCtrl := {}              ;Tab组件
        this.TabPosX := 0               ;Tab位置X
        this.TabPosY := 0               ;Tab位置Y
        this.TableInfo := []            ;TableItem所有信息，每个宏的所有信息

        ;Tab所有页签
        this.TabNameArr := ["按键宏", "字串宏", "菜单宏", "定时宏", "宏", "按键替换", "工具", "设置", "帮助", "打赏作者", "特别感谢"]
        ;Tab页签对应的英文
        this.TabSymbolArr := ["Normal", "String", "Menu", "Timing", "SubMacro", "Replace", "Tool", "Setting", "Help",
            "Reward", "Thank"]

        ;特殊的按键，因为含有下划线，所有要特殊处理
        this.SpecialKeyMap := Map("Browser_Back", 0, "Browser_Forward", 0, "Browser_Refresh", 0, "Browser_Stop", 0,
            "Browser_Search", 0, "Browser_Favorites", 0, "Browser_Home", 0, "Volume_Mute", 0, "Volume_Down", 0,
            "Volume_Up", 0, "Media_Next", 0, "Media_Prev", 0, "Media_Stop", 0, "Media_Play_Pause", 0, "Launch_Mail", 0,
            "Launch_Media", 0, "Launch_App1", 0, "Launch_App2", 0)
        this.SpecialTableItem := TableItem()    ;特别的TableItem，用于编辑器模式测试指令

        ;这些按键不会重复触发按下的按键宏，特别标记特殊处理
        this.ContinueKeyMap := Map("LButton", "LButton", "~LButton", "LButton", "RButton", "RButton", "~RButton",
            "RButton", "MButton", "MButton", "~MButton", "MButton", "XButton1", "XButton1", "~XButton1", "XButton1",
            "XButton2", "XButton2", "~XButton2", "XButton2")
        this.ContinueIntervale := 50    ;连续触发间隔

        this.DataCacheMap := Map()      ;指令缓存，减少读取文件的次数

        this.GlobalVariMap := Map()     ;UI下拉显示变量
        this.VariableMap := Map()       ;真正的全局变量

        ;显示指令提示配置
        this.CMDTip := false
        this.CMDTipCtrl := ""
        this.CMDPosX := A_ScreenWidth - 225
        this.CMDPosY := 0
        this.CMDWidth := 225
        this.CMDHeight := 120
        this.CMDBGColor := "FFFFFF"
        this.CMDTransparency := 50
        this.CMDFontSize := "12"
        this.CMDFontColor := "000000"

        this.TriggerKeyMap := Map()     ;所有的按键宏，包括软件自身的快捷键
        this.SoftHotKeyArr := ["~WheelUp", "~WheelDown", "~LButton", "~Left", "~Right", "~Up", "~Down", "~Enter", "1",
            "2", "3", "4", "5", "6", "7", "8", "~F5", "~F6", "~Delete", "~NumpadDot"]

        this.SelectAreaAction := "" ;左键框选范围回调   显示框选范围       正常
        this.GetAreaAction := ""    ;左键框选范围回调   不显示框选范围      系统截图获取截图范围
        this.StartAreaPosX := ""    ;开始框选范围X坐标  记录点位，这样结束时就能直接获取点位信息
        this.StartAreaPosY := ""    ;开始框选范围Y坐标

        this.IsTogStartRecord := false  ;通过开关触发录制   区分触发形式，删除宏里面的快捷键触发的按键
        this.IsTogEndRecord := false    ;通过开关结束录制
        ;这些按键不会松开，特别处理
        this.SpecialNumKeyMap := Map("WheelDown", 0, "WheelUp", 0)
        
        this.MacroTotalCount := 0   ;宏运行次数
        this.LastShowMonth := 0     ;上次显示月数
    }
}

class KeyboardData {
    __New() {
        this.NodeSerial := 0
        this.KeyName := ""
        this.StartTime := 0
        this.EndTime := 0
        this.StartPos := []
        this.EndPos := []
    }

    Span() {
        return this.EndTime - this.StartTime
    }
}

class RecordNodeData {
    __New() {
        this.StartTime := 0
        this.EndTime := 0
    }

    Span() {
        return this.EndTime - this.StartTime
    }
}

class MoveData {
    __New() {
        this.EndPosX := 0
        this.EndPosY := 0
        this.NodeSerial := 0
    }
}

class SearchData {
    __New() {
        this.SerialStr := ""
        this.ConfigName := Format("{}*{}_{}", A_ScreenWidth, A_ScreenHeight, GetLang("全屏"))
        this.SearchType := 1       ;1 图片  2 颜色  3 文本
        this.SearchColor := "FFFFFF"
        this.SearchText := GetLang("检索文本")
        this.SearchImagePath := ""
        this.Similar := 90 ; 图片搜索模糊匹配度100  - 50
        this.OCRType := 1   ;1中文  2英文
        this.SearchImageType := 1 ; 1 opencv 2 rmt
        this.StartPosX := 0
        this.StartPosY := 0
        this.EndPosX := A_ScreenWidth
        this.EndPosY := A_ScreenHeight
        this.SearchCount := 1
        this.SearchInterval := 1000
        this.MouseActionType := 1   ;   1无动作 2移动到目标 3移动到目标点击
        this.Speed := 90
        this.ClickCount := 1
        this.ConfigArr := []    ;配置数组，不同的分辨率
        this.TrueMacro := ""
        this.FalseMacro := ""
        this.ResultToggle := 0
        this.ResultSaveName := GetLang("搜索结果")
        this.TrueValue := 1
        this.FalseValue := 0
        this.CoordToogle := 0
        this.CoordXName := GetLang("坐标X")
        this.CoordYName := GetLang("坐标Y")
    }

}

class CompareData {
    __New() {
        this.IsIgnoreExist := 0
        this.ToggleArr := [1, 0, 0, 0]
        this.NameArr := ["Num1", "Num2", "Num3", "Num4"]
        this.CompareTypeArr := [1, 1, 1, 1]  ;1大于 2大于等于 3等于 4小于等 5小于 6字符包含 7存在变量
        this.VariableArr := ["Num1", "Num2", "Num3", "Num4"]
        this.TrueMacro := ""
        this.FalseMacro := ""
        this.SaveToggle := 0
        this.SaveName := GetLang("结果")
        this.TrueValue := 1
        this.FalseValue := 0
        this.LogicalType := 1
    }
}

class CompareProData {
    __New() {
        this.VariNameArr := [["Num1"], ["Num2"]]
        this.CompareTypeArr := [[3], [3]]  ;1大于 2大于等于 3等于 4小于等 5小于 6字符包含 7存在变量
        this.VariableArr := [[1], [2]]
        this.LogicTypeArr := [1, 2]
        this.MacroArr := ["按键_a_3_100", "按键_b_3_100"]
        this.DefaultMacro := "按键_c_3_100"
    }

    ;用于逻辑树展示
    static GetCondiStr(Data, itemIndex) {
        CommandStr := ""
        symbolStr := Data.LogicTypeArr[itemIndex] == 1 ? GetLang("且") : GetLang("或")
        CompareTypeStrArr := GetLangArr(["大于", "大于等于", "等于", "小于等于",
            "小于", "字符包含", "变量存在"])

        loop Data.VariNameArr[itemIndex].Length {
            VariName := GetLang(Data.VariNameArr[itemIndex][A_Index])
            TypeStr := CompareTypeStrArr[Data.CompareTypeArr[itemIndex][A_Index]]
            Variable := GetLang(Data.VariableArr[itemIndex][A_Index])

            if (Data.CompareTypeArr[itemIndex][A_Index] != 7)
                CommandStr .= VariName " " TypeStr " " Variable " " symbolStr " "
            else
                CommandStr .= VariName " " TypeStr " " symbolStr " "
        }
        CommandStr := Trim(CommandStr, " ")
        CommandStr := Trim(CommandStr, symbolStr)
        CommandStr := Trim(CommandStr, " ")
        return CommandStr
    }
}

class MMProData {
    __New() {
        this.SerialStr := ""
        this.ConfigName := Format("{}*{}_{}", A_ScreenWidth, A_ScreenHeight, GetLang("全屏"))
        this.ConfigArr := []
        this.PosVarX := 100
        this.PosVarY := 100
        this.ActionType := 1          ;鼠标动作 1移动 2移动点击1次 3移动点击2次
        this.IsRelative := 0         ;相对位移
        this.IsGameView := 0        ;游戏视角
        this.Speed := 90           ;移动速度
        this.Count := 1
        this.Interval := 1000
    }
}

class FileData {
    __New() {
        this.SerialStr := ""
        this.RunPath := ""
        this.BackPlay := false
    }
}

class OutputData {
    __New() {
        this.SerialStr := ""
        this.Text := GetLang("将要输出的文本")
        this.OutputType := 1    ;sendtest  粘贴   粘贴
        this.FilePath := ""
        this.ExcelType := 1     ;1指定单元格    2 行号自增    3 列号自增
        this.NameOrSerial := 1
        this.RowVar := 1
        this.ColVar := 1
    }
}

class SubMacroData {
    __New() {
        this.SerialStr := ""
        this.MacroType := 1
        this.CallType := 1
        this.InsertCount := 1
        this.Index := 1
        this.MacroSerial := "009973"
    }
}

class LoopData {
    __New() {
        this.SerialStr := ""
        this.LoopCount := 10    ;循环次数
        this.CondiType := 1     ;条件类型 1：无 2：退出条件 3：继续条件
        this.LogicType := 1     ;逻辑关系  1：且    2：或
        this.ToggleArr := [1, 0, 0, 0]
        this.NameArr := ["Num1", "Num2", "Num3", "Num4"]
        this.CompareTypeArr := [1, 1, 1, 1]  ;1大于 2大于等于 3等于 4小于等 5小于 6字符包含 7存在变量
        this.VariableArr := ["Num1", "Num2", "Num3", "Num4"]
        this.LoopBody := ""     ;循环体
    }

    ;用于逻辑树展示
    static GetCondiStr(Data) {
        CommandStr := ""
        symbolStr := Data.LogicType == 1 ? GetLang("且") : GetLang("或")
        CompareTypeStrArr := GetLangArr(["大于", "大于等于", "等于", "小于等于",
            "小于", "字符包含", "变量存在"])

        loop 4 {
            if (!Data.ToggleArr[A_Index])
                continue

            VariName := GetLang(Data.NameArr[A_Index])
            TypeStr := CompareTypeStrArr[Data.CompareTypeArr[A_Index]]
            Variable := GetLang(Data.VariableArr[A_Index])
            if (Data.CompareTypeArr[A_Index] != 7)
                CommandStr .= VariName " " TypeStr " " Variable " " symbolStr " "
            else
                CommandStr .= VariName " " TypeStr " " symbolStr " "
        }

        CommandStr := Trim(CommandStr, " ")
        CommandStr := Trim(CommandStr, symbolStr)
        CommandStr := Trim(CommandStr, " ")
        return CommandStr
    }
}

class VariableData {
    __New() {
        this.SerialStr := ""
        this.IsIgnoreExist := 0
        this.ToggleArr := [1, 0, 0, 0]
        this.OperaTypeArr := [1, 1, 1, 1]   ;1赋值 2随机 3字符 4删除
        this.VariableArr := ["Num1", "Num2", "Num3", "Num4"]
        this.CopyVariableArr := ["1", "0", "0", "0"]
        this.MinVariableArr := ["0", "0", "0", "0"]
        this.MaxVariableArr := ["10", "10", "10", "10"]
    }
}

class ExVariableData {
    __New() {
        this.SerialStr := ""
        this.IsIgnoreExist := 0
        this.ToggleArr := [1, 0, 0, 0, 0, 0]
        this.VariableArr := ["Num1", "Num2", "Num3", "Num4", "Num5", "Num6"]
        this.ExtractStr := ""
        this.ExtractType := 1
        this.OCRType := 1
        this.StartPosX := 0
        this.StartPosY := 0
        this.EndPosX := A_ScreenWidth
        this.EndPosY := A_ScreenHeight
        this.SearchCount := 1
        this.SearchInterval := 1000
    }
}

class OperationData {
    __New() {
        this.SerialStr := ""
        this.IsIgnoreExist := 0
        this.ToggleArr := [1, 0, 0, 0]
        this.NameArr := ["Num1", "Num2", "Num3", "Num4"]
        this.OperationArr := ["", "", "", ""]
        this.UpdateNameArr := ["Num1", "Num2", "Num3", "Num4"]
        this.SymbolGroups := [[], [], [], []]  ;操作符号
        this.ValueGroups := [[], [], [], []]     ;运算对象
    }
}

class BGMouseData {
    __New() {
        this.SerialStr := ""
        this.TargetTitle := ""
        this.OperateType := 1 ;点击 双击 按下 松开
        this.MouseType := 1 ;左键 中键 右键
        this.PosVarX := 100
        this.PosVarY := 100
        this.ScrollV := 1 ;水平滚动
        this.ScrollH := 0 ; 垂直滚动
        this.ClickTime := 50 ;点击时间跨度
    }
}

class BGKeyData {
    __New() {
        this.SerialStr := ""
        this.FrontStr := ""
        this.KeyArr := []
        this.Type := 1  ;1按下 2松开 3点击
        this.ClickTime := 100
        this.ClickCount := 1
        this.ClickInterval := 100
    }
}

class TimingData {
    __New() {
        this.SerialStr := ""
        this.StartTime := A_Now
        this.EndTime := ""
        this.Type := 1  ;1单次 2每小时 3每天 4每周 5每月 6自定义
        this.CustomInterval := "10"
        this.NextTriggerTime := ""
    }
}

class RMTCMDData {
    __New() {
        this.SerialStr := ""
        this.OperateType := 1 ; 1截图 2截图中提取文本 3自由贴 4开启指令显示 5关闭指令显示 6启用键鼠 7禁用键鼠 8休眠 9终止所有宏 10重载
    }
}

class MouseWinData {
    __New() {
        this.WinTitle := ""
        this.WinClass := ""
        this.WinProcess := ""
        this.HasError := false
    }

    UpdateInfo() {
        this.HasError := false
        MouseGetPos &mouseX, &mouseY, &winId
        try {
            this.WinTitle := WinGetTitle(winId)
            this.WinClass := WinGetClass(winId)
            this.WinProcess := WinGetProcessName(winId)
        }
        catch as e {
            this.HasError := true
        }
    }

    CheckIfMatch(FrontInfoStr, isUpdate := false) {
        if (isUpdate)
            this.UpdateInfo()

        if (FrontInfoStr == "" || this.HasError)
            return false

        infoArr := StrSplit(FrontInfoStr, "⎖")
        if (infoArr.Length != 3)
            return false

        title := infoArr[1]
        className := infoArr[2]
        process := infoArr[3]

        if (title != "" && !InStr(this.WinTitle, title, "Off"))
            return false

        if (className != "" && className != this.WinClass)
            return false

        if (process != "" && process != this.WinProcess)
            return false

        return true
    }
}
