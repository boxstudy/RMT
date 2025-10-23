class TableItem {
    __New() {
        this.TKArr := []
        this.MacroArr := []
        this.HoldTimeArr := []
        this.ModeArr := []
        this.ForbidArr := []
        this.FrontInfoArr := []
        this.LoopCountArr := []
        this.RemarkArr := []
        this.TriggerTypeArr := []
        this.TKConArr := []
        this.MacroConArr := []
        this.KeyBtnConArr := []
        this.MacroBtnConArr := []
        this.DeleteBtnConArr := []
        this.ModeConArr := []
        this.ForbidConArr := []
        this.FrontInfoConArr := []
        this.LoopCountConArr := []
        this.RemarkTipConArr := []
        this.RemarkConArr := []
        this.ColorConArr := []
        this.ColorStateArr := []
        this.IndexConArr := []
        this.TriggerTypeConArr := []
        this.TimingSerialArr := []

        this.SerialArr := []
        this.HoldKeyArr := []
        this.KilledArr := []
        this.PauseArr := []         ;暂停
        this.ActionCount := []      ; 记录执行次数，用于循环次数判断
        this.ToggleStateArr := []   ; 触发键开关状态
        this.ToggleActionArr := []   ; 触发键开关Action
        this.VariableMapArr := []    ;  每条宏对应的变量映射
        this.UnderPosY := 0
        this.Index := 0             ;   tableIndex
        this.SliderValue := 0       ;   滑动值
        this.OffSetPosY := 0        ;   偏移值
        this.AllConArr := []
        this.AllGroup := []
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
        this.isWork := false
        this.ToolTipText := ""
        this.ToolTipEndTime := ""
        this.AgreeAgreement := false
        this.IsExecuteShow := true
        this.ShowWinCtrl := ""
        this.IsBootStart := false
        this.BootStartCtrl := ""
        this.NoVariableTip := false
        this.NoVariableTipCtrl := ""
        this.ScreenShotType := 1
        this.ScreenShotTypeCtrl := ""
        this.MutiThreadNum := 3
        this.MutiThreadNumCtrl := ""
        this.IsSuspend := false
        this.SuspendToggleCtrl := ""
        this.SuspendHotkey := ""
        this.SuspendHotkeyCtrl := ""
        this.IsPause := false
        this.PauseToggleCtrl := ""
        this.PauseHotkey := ""
        this.PauseHotkeyCtrl := ""
        this.KillMacroHotkey := ""
        this.KillMacroHotkeyCtrl := ""
        this.HoldFloat := 0
        this.HoldFloatCtrl := ""
        this.PreIntervalFloat := 0
        this.PreIntervalFloatCtrl := ""
        this.IntervalFloat := 0
        this.IntervalFloatCtrl := ""
        this.CoordXFloatCon := ""
        this.CoordYFloatCon := ""
        this.CoordXFloat := 0
        this.CoordYFloat := 0
        this.SoftBGColorCon := ""
        this.SoftBGColor := ""
        this.IsReload := false  ;重载
        this.TableIndex := 1
        this.HasSaved := false
        this.MacroEditGui := ""
        this.RecordToggleCon := ""
        this.FontType := "微软雅黑"
        this.FontList := []

        this.MyGui := {}
        this.CurSettingName := ""
        this.SettingArrStr := ""
        this.TabPosX := 0
        this.TabPosY := 0
        this.BtnAdd := ""
        this.BtnSave := ""

        this.EditHotKeyCtrl := ""
        this.EditHotStrCtrl := ""

        this.TabNameArr := ["按键宏", "字串宏", "菜单宏", "定时宏", "宏", "按键替换", "工具", "设置", "帮助", "打赏作者", "特别感谢"]
        this.TabSymbolArr := ["Normal", "String", "Menu", "Timing", "SubMacro", "Replace", "Tool", "Setting", "Help", "Reward", "Thank"]
        this.TabCtrl := {}
        this.TableInfo := []

        this.TimerActionMap := Map()

        this.SpecialKeyMap := Map("Browser_Back", 0, "Browser_Forward", 0, "Browser_Refresh", 0, "Browser_Stop", 0,
            "Browser_Search", 0, "Browser_Favorites", 0, "Browser_Home", 0, "Volume_Mute", 0, "Volume_Down", 0,
            "Volume_Up", 0, "Media_Next", 0, "Media_Prev", 0, "Media_Stop", 0, "Media_Play_Pause", 0, "Launch_Mail", 0,
            "Launch_Media", 0, "Launch_App1", 0, "Launch_App2", 0)
        this.SpecialTableItem := TableItem()

        this.ContinueKeyMap := Map("LButton", "LButton", "~LButton", "LButton", "RButton", "RButton", "~RButton",
            "RButton", "MButton", "MButton", "~MButton", "MButton", "XButton1", "XButton1", "~XButton1", "XButton1",
            "XButton2", "XButton2", "~XButton2", "XButton2")
        this.SpecialNumKeyMap := Map("WheelDown", 0, "WheelUp", 0)
        this.ContinueSecondIntervale := 200
        this.ContinueIntervale := 50
        this.DataCacheMap := Map()
        this.TestCount := 0

        this.GlobalVariMap := Map() ;UI下拉显示变量
        this.VariableMap := Map()

        ;显示指令提示配置
        this.CMDTip := false
        this.CMDTipCtrl := ""
        this.CMDPosX := A_ScreenWidth - 225
        this.CMDPosY := 0
        this.CMDWidth := 225
        this.CMDHeight := 120
        this.CMDLineNum := 5
        this.CMDBGColor := "FFFFFF"
        this.CMDTransparency := 50
        this.CMDFontSize := "12"
        this.CMDFontColor := "000000"

        this.TriggerKeyMap := Map()
        this.SoftHotKeyArr := ["~WheelUp", "~WheelDown", "~LButton", "~Left", "~Right", "~Up", "~Down", "~Enter"]
        this.SelectAreaAction := "" ;左键框选范围回调   显示框选范围
        this.GetAreaAction := ""    ;左键框选范围回调   不显示框选范围
        this.StartAreaPosX := ""
        this.StartAreaPosY := ""
        
        this.IsTogStartRecord := false  ;通过开关触发录制
        this.IsTogEndRecord := false    ;通过开关结束录制
    
        this.MacroTotalCount := 0   ;宏运行次数
        this.LastShowMonth := 0     ;
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
        this.SearchType := 1       ;1 图片  2 颜色  3 文本
        this.SearchColor := "FFFFFF"
        this.SearchText := "检索文本"
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
        this.ClickCount := 1
        this.Speed := 90
        this.TrueMacro := ""
        this.FalseMacro := ""
        this.ResultToggle := 0
        this.ResultSaveName := "搜索结果"
        this.TrueValue := 1
        this.FalseValue := 0
        this.CoordToogle := 0
        this.CoordXName := "坐标X"
        this.CoordYName := "坐标Y"
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
        this.SaveName := "结果"
        this.TrueValue := 1
        this.FalseValue := 0
        this.LogicalType := 1
    }
}

class MMProData {
    __New() {
        this.SerialStr := ""
        this.PosVarX := 100
        this.PosVarY := 100
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
        this.Text := "将要输出的文本"
        this.OutputType := 1    ;sendtest  粘贴   粘贴
        this.ContentType := 1   ;文本   变量    文本+变量
        this.VariName := "空"
    }
}

class SubMacroData {
    __New() {
        this.SerialStr := ""
        this.MacroType := 1
        this.CallType := 1
        this.Index := 1
        this.MacroSerial := "009973"
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
        this.ToggleArr := [1, 0, 0, 0]
        this.VariableArr := ["Num1", "Num2", "Num3", "Num4"]
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
