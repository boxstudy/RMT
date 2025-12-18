#Requires AutoHotkey v2.0
#Include "..\Main\DataClass.ahk"
#Include "..\Main\JsonUtil.ahk"
#Include "..\Main\AssetUtil.ahk"
#Include "..\Main\HotkeyUtil.ahk"
#Include "..\Main\Gdip_All.ahk"
#Include "..\Main\CompareUtil.ahk"
#Include "..\Main\FixCompatUtil.ahk"
#Include "..\Main\LangUtil.ahk"
#Include "..\Joy\SuperCvJoyInterface.ahk"
#Include "..\Joy\JoyMacro.ahk"
#Include "..\Plugins\RapidOcr\RapidOcr.ahk"
#Include "..\Plugins\IbInputSimulator.ahk"
#Include "WorkUtil.ahk"
#SingleInstance Force
DetectHiddenWindows true
Persistent
#NoTrayIcon

global parentHwnd := A_Args[1]
global workIndex := A_Args[2]
global ReceiveInfoMap := Map()
global MySoftData := SoftData()
global ToolCheckInfo := ToolCheck()
global MyMouseInfo := MouseWinData()
global MyvJoy := SuperCvJoyInterface().GetMyvJoy()
global MyJoyMacro := JoyMacro()
global IniFile := A_WorkingDir "\..\Setting\MainSettings.ini"
global LangDir := A_WorkingDir "\..\Lang"
; global ReceiveTiming := 0     ;通讯收发间隔，防止在收到信息时立刻回复，信息丢失问题
LoadMainSetting()   ;加载配置
InitWorkFilePath()  ;初始化文件路径
LoadCurMacroSetting()   ;加载当前配置宏
InitData()
InitWork()

;放后面初始化，因为这初始化时间比较长
global MyChineseOcr := RapidOcr(A_ScriptDir "\..")
global MyEnglishOcr := RapidOcr(A_ScriptDir "\..", 2)
global MyPToken := Gdip_Startup()
global MySubMacroStopAction := WorkSubMacroStopAction
global MyTriggerSubMacro := WorkTriggerSubMacro
global MySetGlobalVariable := WorkSetGlobalVariable
global MyDelGlobalVariable := WorkDelGlobalVariable
global MyCMDReportAciton := WorkCMDReport
global MyExcuteRMTCMDAction := WorkExcuteRMTCMDAction
global MySetTableItemState := WorkSetTableItemState
global MySetItemPauseState := WorkSetItemPauseState
global MyMsgBoxContent := WorkMsgBoxContent
global MyToolTipContent := WorkToolTipContent
global MyMacroCount := WorkMacroCount
WorkOpenCVLoadDll()

; 注册消息
OnMessage(WM_TR_MACRO, OnWorkTriggerMacro)
OnMessage(WM_STOP_MACRO, OnWorkStopMacro)
OnMessage(WM_CLEAR_WORK, OnExit)
OnMessage(WM_COPYDATA, OnWorkGetCmdStr)
OnMessage(WM_RECEIVE_INFO, OnMainReceiveInfo)

myTitle := "RMTWork" workIndex
mygui := Gui("+ToolWindow")          ; 创建 GUI，无标题栏
mygui.Title := myTitle               ; 设置窗口标题（这才是 WinGetTitle 能读到的）
mygui.Show("Hide")                   ; 隐藏窗口
global myHwnd := mygui.Hwnd
MsgPostHandler(WM_LOAD_WORK, workIndex, 0)