#Requires AutoHotkey v2.0

; =============================================================================
; AppThemeUtil — 统一主题调色板（窗口、节点、轮盘与运行浮层共用）
;
; 存储：MainSettings.ini [ThemeColors]
; 运行时：同步到 MainSoftData.ThemeColors，以及各消费字段（UIPanel* / CMD*）
; 通用窗口色：经 ApplyXamlTheme(..., useAppWinTheme:=true) 覆盖到 XAML Resource
;
; ---------- 扩展约定（增删改颜色 / 预设时请遵守）----------
; 1. 新增颜色项：
;    - 在 ColorDefs 增加 {Key, Group, Label}；Group/Label 用于调色板提示，不再生成分组标题
;    - 至少在默认主题（DefaultThemeKey）Preset 上写上同名属性；其它预设建议一并补齐
;    - 若该色需驱动运行时字段，在 ApplyToRuntime / ApplyWinThemeToXaml 增加映射
;    - 主题设置 UI 固定展开 14 个语义槽位为双列调色板，一般不必改 ThemeSettingGui
; 2. 删除颜色项：从 ColorDefs（及各 Preset 属性、ApplyToRuntime）移除即可；
;    旧 ini 残留键会被忽略，不影响加载
; 3. 颜色键直接使用固定的 14 个主题槽位，不迁移旧版本的颜色设置。
; 4. 缺省回退规则（兼容自定义主题与版本升级）：
;    任意路径取不到某 Key（未保存 / 预设未写 / Map 残缺）时，
;    一律使用默认主题（DefaultThemeKey）对应色，禁止用纯黑凑数（纯黑仅作开发兜底）
; 5. 自定义主题（AppTheme=Custom）：
;    以默认主题为底图，再叠加 ini 中已保存的逐项颜色；新增 Key 自动得默认色
; 6. 预设增删：只改 Presets；未知 Key 在 LoadFromIni 因 IsPresetKey 失败而回退到默认主题
; 7. ColorDefs 的 Group/Label 只描述颜色用途，不再作为主题设置页分组标题；
;    主题设置页固定显示 14 个语义槽位，修改一个槽位会同步其全部用途键。
; =============================================================================

class AppThemeUtil {
    ; Canonical theme palette. Every preset exposes these 14 slots in the same order.
    static ColorDefs := [
        {Key: "Theme_Color01", Source: "Win_ActionBg", Group: "主题颜色", Label: "主色", Uses: ["操作按钮背景", "图形选中边框", "进度条", "菜单轮盘划线", "界面浮窗按钮"]},
        {Key: "Theme_Color02", Source: "Win_ActionHoverBg", Group: "主题颜色", Label: "主色悬停", Uses: ["操作按钮悬停", "输入框悬停边框"]},
        {Key: "Theme_Color03", Source: "Win_EditHoverBg", Group: "主题颜色", Label: "浅色强调", Uses: ["输入框悬停背景", "菜单轮盘悬停填充", "指令运行背景"]},
        {Key: "Theme_Color04", Source: "Win_TitleBg", Group: "主题颜色", Label: "标题背景", Uses: ["通用窗口标题", "界面浮窗标题"]},
        {Key: "Theme_Color05", Source: "Win_TitleText", Group: "主题颜色", Label: "标题文字", Uses: ["通用窗口标题文字", "界面浮窗标题文字"]},
        {Key: "Theme_Color06", Source: "Win_WindowBg", Group: "主题颜色", Label: "窗口背景", Uses: ["通用窗口背景", "指令显示背景"]},
        {Key: "Theme_Color07", Source: "Win_InputBg", Group: "主题颜色", Label: "内容背景", Uses: ["输入框", "编辑框", "菜单轮盘普通填充", "界面浮窗内容"]},
        {Key: "Theme_Color08", Source: "Win_InputStroke", Group: "主题颜色", Label: "普通边框", Uses: ["输入框边框", "编辑框边框", "菜单轮盘普通边框"]},
        {Key: "Theme_Color09", Source: "Win_GroupStroke", Group: "主题颜色", Label: "强调边框", Uses: ["内容框选边框", "窗口外框"]},
        {Key: "Theme_Color10", Source: "Win_LabelColor", Group: "主题颜色", Label: "主文字", Uses: ["标签文字", "指令文字", "菜单轮盘普通文字"]},
        {Key: "Theme_Color11", Source: "Win_InputText", Group: "主题颜色", Label: "输入文字", Uses: ["输入框文字", "编辑框文字"]},
        {Key: "Theme_Color12", Source: "Win_GraphLine", Group: "主题颜色", Label: "图形线", Uses: ["图形节点网格线"]},
        {Key: "Theme_Color13", Source: "Win_GraphConn", Group: "主题颜色", Label: "图形连接面", Uses: ["图形节点连接线"]},
        {Key: "Theme_Color14", Source: "Win_ActionText", Group: "主题颜色", Label: "主色文字", Uses: ["操作按钮文字", "界面浮窗按钮文字"]}
    ]

    ; All runtime color keys resolve to the same canonical slot for every preset.
    static ColorAliases := Map(
        "Win_ActionBg", "Theme_Color01", "Win_ActionStroke", "Theme_Color01",
        "Win_GraphConnSel", "Theme_Color01", "Win_ProgressBar", "Theme_Color01",
        "Wheel_HoverText", "Theme_Color01", "Wheel_HoverStroke", "Theme_Color01",
        "Wheel_SwipeLineColor", "Theme_Color01", "Panel_BtnColor", "Theme_Color01",
        "Win_ActionHoverBg", "Theme_Color02", "Win_ActionHoverStroke", "Theme_Color02",
        "Win_EditHoverStroke", "Theme_Color02",
        "Win_EditHoverBg", "Theme_Color03", "Wheel_HoverFill", "Theme_Color03",
        "CMD_RunBGColor", "Theme_Color03",
        "Win_TitleBg", "Theme_Color04", "Panel_TitleBg", "Theme_Color04",
        "Win_TitleText", "Theme_Color05", "Panel_TitleText", "Theme_Color05",
        "Win_WindowBg", "Theme_Color06", "CMD_BGColor", "Theme_Color06",
        "Win_InputBg", "Theme_Color07", "Win_EditBg", "Theme_Color07",
        "Wheel_NormalFill", "Theme_Color07", "Panel_BgColor", "Theme_Color07",
        "Win_InputStroke", "Theme_Color08", "Win_EditStroke", "Theme_Color08",
        "Wheel_NormalStroke", "Theme_Color08",
        "Win_GroupStroke", "Theme_Color09",
        "Win_LabelColor", "Theme_Color10", "CMD_FontColor", "Theme_Color10",
        "Wheel_NormalText", "Theme_Color10",
        "Win_InputText", "Theme_Color11", "Win_EditText", "Theme_Color11",
        "Win_GraphLine", "Theme_Color12",
        "Win_GraphConn", "Theme_Color13",
        "Win_ActionText", "Theme_Color14", "Panel_BtnText", "Theme_Color14"
    )
    ; 颜色权威清单：UI 编辑项、ini 读写、完整 Map 均以此为准
    ; 分组顺序即主题选项页展示顺序；「通用窗口」置于菜单轮盘之上
    static Presets := [
        ; Win_GraphLine=背景网格；Win_GraphConn=节点连线；Win_GraphConnSel=选中连线色兼节点选中描边
        {Key: "Default", Name: "默认",
            Win_TitleBg: "#FFEBEBEB", Win_TitleText: "#FF1A1A1A",
            Win_WindowBg: "#FFF0F0F0", Win_GroupStroke: "#FF999999", Win_GraphLine: "#FF333333",
            Win_GraphConn: "#FFFFFFFF", Win_GraphConnSel: "#FF0078D7", Win_LabelColor: "#FF1A1A1A",
            Win_InputBg: "#FFFFFFFF", Win_InputStroke: "#FFCCCCCC", Win_InputText: "#FF1A1A1A",
            Win_EditBg: "#FFFFFFFF", Win_EditStroke: "#FFCCCCCC", Win_EditText: "#FF1A1A1A",
            Win_EditHoverBg: "#FFE3F2FD", Win_EditHoverStroke: "#FF0078D7",
            Win_ActionBg: "#FF0078D7", Win_ActionStroke: "#FF0078D7", Win_ActionText: "#FFFFFFFF",
            Win_ActionHoverBg: "#FF106EBE", Win_ActionHoverStroke: "#FF106EBE",
            Win_ProgressBar: "#FF0078D7",
            Wheel_NormalText: "#CC1A365D", Wheel_NormalFill: "#FFF0F7FF", Wheel_NormalStroke: "#FF90CAF9",
            Wheel_HoverText: "#FF0078D7", Wheel_HoverFill: "#FFE3F2FD", Wheel_HoverStroke: "#FF0078D7",
            Wheel_SwipeLineColor: "#FF0078D7",
            Panel_TitleBg: "#FF0078D7", Panel_TitleText: "#FFFFFFFF",
            Panel_BtnColor: "#FF0078D7", Panel_BtnText: "#FFFFFFFF", Panel_BgColor: "#F2F5F9FC",
            CMD_FontColor: "#FF1A1A1A", CMD_BGColor: "#FFF5F5F5", CMD_RunBGColor: "#FF90CAF9"},
        {Key: "FrostGray", Name: "霜灰",
            Win_TitleBg: "#FFE2E8F0", Win_TitleText: "#FF1E293B",
            Win_WindowBg: "#FFF8FAFC", Win_GroupStroke: "#FF94A3B8", Win_GraphLine: "#FF2E3540",
            Win_GraphConn: "#FFF8FAFC", Win_GraphConnSel: "#FF475569", Win_LabelColor: "#FF1E293B",
            Win_InputBg: "#FFFFFFFF", Win_InputStroke: "#FFCBD5E1", Win_InputText: "#FF1E293B",
            Win_EditBg: "#FFFFFFFF", Win_EditStroke: "#FF64748B", Win_EditText: "#FF334155",
            Win_EditHoverBg: "#FFE2E8F0", Win_EditHoverStroke: "#FF64748B",
            Win_ActionBg: "#FF475569", Win_ActionStroke: "#FF475569", Win_ActionText: "#FFFFFFFF",
            Win_ActionHoverBg: "#FF334155", Win_ActionHoverStroke: "#FF334155",
            Win_ProgressBar: "#FF64748B",
            Wheel_NormalText: "#CC4B5563", Wheel_NormalFill: "#FFF8FAFC", Wheel_NormalStroke: "#FFCBD5E1",
            Wheel_HoverText: "#FF334155", Wheel_HoverFill: "#FFE2E8F0", Wheel_HoverStroke: "#FF64748B",
            Wheel_SwipeLineColor: "#FF64748B",
            Panel_TitleBg: "#FF475569", Panel_TitleText: "#FFFFFFFF",
            Panel_BtnColor: "#FF334155", Panel_BtnText: "#FFFFFFFF", Panel_BgColor: "#F2F1F5F9",
            CMD_FontColor: "#FF1E293B", CMD_BGColor: "#FFF8FAFC", CMD_RunBGColor: "#FFCBD5E1"},
        {Key: "DarkNight", Name: "暗夜",
            Win_TitleBg: "#FF111111", Win_TitleText: "#FFE8E8E8",
            Win_WindowBg: "#FF1E1E1E", Win_GroupStroke: "#FF666666", Win_GraphLine: "#FF2A2A2A",
            Win_GraphConn: "#FFE8E8E8", Win_GraphConnSel: "#FFB0B0B0", Win_LabelColor: "#FFE0E0E0",
            Win_InputBg: "#FF2D2D2D", Win_InputStroke: "#FF6E6E6E", Win_InputText: "#FFE8E8E8",
            Win_EditBg: "#FF2D2D2D", Win_EditStroke: "#FF9E9E9E", Win_EditText: "#FFF0F0F0",
            Win_EditHoverBg: "#FF3D3D3D", Win_EditHoverStroke: "#FFB0B0B0",
            Win_ActionBg: "#FF4A4A4A", Win_ActionStroke: "#FF6A6A6A", Win_ActionText: "#FFFFFFFF",
            Win_ActionHoverBg: "#FF5A5A5A", Win_ActionHoverStroke: "#FFB0B0B0",
            Win_ProgressBar: "#FFB0B0B0",
            Wheel_NormalText: "#CCAAAAAA", Wheel_NormalFill: "#FF2D2D2D", Wheel_NormalStroke: "#FF555555",
            Wheel_HoverText: "#FFFFFFFF", Wheel_HoverFill: "#FF3D3D3D", Wheel_HoverStroke: "#FFB0B0B0",
            Wheel_SwipeLineColor: "#FFD0D0D0",
            Panel_TitleBg: "#FF111111", Panel_TitleText: "#FFE0E0E0",
            Panel_BtnColor: "#FF3A3A3A", Panel_BtnText: "#FFE0E0E0", Panel_BgColor: "#E01A1A1A",
            CMD_FontColor: "#FFE0E0E0", CMD_BGColor: "#FF1E1E1E", CMD_RunBGColor: "#FFBDBDBD"},
        {Key: "WarmSun", Name: "暖阳",
            Win_TitleBg: "#FFFFE4B5", Win_TitleText: "#FF5C3317",
            Win_WindowBg: "#FFFFF8DC", Win_GroupStroke: "#FFE8B86D", Win_GraphLine: "#FF3A3228",
            Win_GraphConn: "#FFFFF8DC", Win_GraphConnSel: "#FFFF8C00", Win_LabelColor: "#FF5C3317",
            Win_InputBg: "#FFFFFFFF", Win_InputStroke: "#FFE8B86D", Win_InputText: "#FF5C3317",
            Win_EditBg: "#FFFFFFFF", Win_EditStroke: "#FFFF8C00", Win_EditText: "#FF8B4513",
            Win_EditHoverBg: "#FFFFE4B5", Win_EditHoverStroke: "#FFFF8C00",
            Win_ActionBg: "#FFFF8C00", Win_ActionStroke: "#FFE67E00", Win_ActionText: "#FFFFFFFF",
            Win_ActionHoverBg: "#FFE67E00", Win_ActionHoverStroke: "#FFE67E00",
            Win_ProgressBar: "#FFFF8C00",
            Wheel_NormalText: "#CC8B4513", Wheel_NormalFill: "#FFFFF8DC", Wheel_NormalStroke: "#FFE8B86D",
            Wheel_HoverText: "#FFFF6347", Wheel_HoverFill: "#FFFFE4B5", Wheel_HoverStroke: "#FFFF6347",
            Wheel_SwipeLineColor: "#FFFF6347",
            Panel_TitleBg: "#FF8B4513", Panel_TitleText: "#FFFFFFFF",
            Panel_BtnColor: "#FFFF8C00", Panel_BtnText: "#FFFFFFFF", Panel_BgColor: "#C0FFE4B5",
            CMD_FontColor: "#FF5C3317", CMD_BGColor: "#FFFFF8DC", CMD_RunBGColor: "#FFFFE0B2"},
        {Key: "Ocean", Name: "海洋",
            Win_TitleBg: "#FFD6EAF8", Win_TitleText: "#FF1A365D",
            Win_WindowBg: "#FFF0F8FF", Win_GroupStroke: "#FF7EB3E8", Win_GraphLine: "#FF283848",
            Win_GraphConn: "#FFF0F8FF", Win_GraphConnSel: "#FF1E90FF", Win_LabelColor: "#FF1A365D",
            Win_InputBg: "#FFFFFFFF", Win_InputStroke: "#FF90CAF9", Win_InputText: "#FF1A365D",
            Win_EditBg: "#FFFFFFFF", Win_EditStroke: "#FF1E90FF", Win_EditText: "#FF1E90FF",
            Win_EditHoverBg: "#FFE0F0FF", Win_EditHoverStroke: "#FF1E90FF",
            Win_ActionBg: "#FF1E90FF", Win_ActionStroke: "#FF1E90FF", Win_ActionText: "#FFFFFFFF",
            Win_ActionHoverBg: "#FF187BCD", Win_ActionHoverStroke: "#FF187BCD",
            Win_ProgressBar: "#FF1E90FF",
            Wheel_NormalText: "#CC2C5282", Wheel_NormalFill: "#FFF0F8FF", Wheel_NormalStroke: "#FF4682B4",
            Wheel_HoverText: "#FF1E90FF", Wheel_HoverFill: "#FFE0F0FF", Wheel_HoverStroke: "#FF1E90FF",
            Wheel_SwipeLineColor: "#FF1E90FF",
            Panel_TitleBg: "#FF2C5282", Panel_TitleText: "#FFFFFFFF",
            Panel_BtnColor: "#FF1E90FF", Panel_BtnText: "#FFFFFFFF", Panel_BgColor: "#C0E0F0FF",
            CMD_FontColor: "#FF1A365D", CMD_BGColor: "#FFF0F8FF", CMD_RunBGColor: "#FFBBDEFB"},
        {Key: "PinkSakura", Name: "绯樱",
            Win_TitleBg: "#FFFFE4EC", Win_TitleText: "#FF9F1239",
            Win_WindowBg: "#FFFFF0F5", Win_GroupStroke: "#FFF9A8C4", Win_GraphLine: "#FF3A2830",
            Win_GraphConn: "#FFFFF0F5", Win_GraphConnSel: "#FFDB2777", Win_LabelColor: "#FF9F1239",
            Win_InputBg: "#FFFFFFFF", Win_InputStroke: "#FFFFB6C1", Win_InputText: "#FF9F1239",
            Win_EditBg: "#FFFFFFFF", Win_EditStroke: "#FFDB2777", Win_EditText: "#FFDB2777",
            Win_EditHoverBg: "#FFFFE4EC", Win_EditHoverStroke: "#FFDB2777",
            Win_ActionBg: "#FFDB2777", Win_ActionStroke: "#FFDB2777", Win_ActionText: "#FFFFFFFF",
            Win_ActionHoverBg: "#FFBE185D", Win_ActionHoverStroke: "#FFBE185D",
            Win_ProgressBar: "#FFF472B6",
            Wheel_NormalText: "#CC9F1239", Wheel_NormalFill: "#FFFFF0F5", Wheel_NormalStroke: "#FFFFB6C1",
            Wheel_HoverText: "#FFDB2777", Wheel_HoverFill: "#FFFFE4EC", Wheel_HoverStroke: "#FFDB2777",
            Wheel_SwipeLineColor: "#FFF472B6",
            Panel_TitleBg: "#FFDB2777", Panel_TitleText: "#FFFFFFFF",
            Panel_BtnColor: "#FFE11D48", Panel_BtnText: "#FFFFFFFF", Panel_BgColor: "#C0FFF0F5",
            CMD_FontColor: "#FF9F1239", CMD_BGColor: "#FFFFF0F5", CMD_RunBGColor: "#FFF8BBD0"},
        {Key: "Matcha", Name: "抹茶",
            Win_TitleBg: "#FFECF4D3", Win_TitleText: "#FF365314",
            Win_WindowBg: "#FFF7FBEA", Win_GroupStroke: "#FF8FA076", Win_GraphLine: "#FF2E3828",
            Win_GraphConn: "#FFF7FBEA", Win_GraphConnSel: "#FF65A30D", Win_LabelColor: "#FF365314",
            Win_InputBg: "#FFFFFFFF", Win_InputStroke: "#FFA3B18A", Win_InputText: "#FF365314",
            Win_EditBg: "#FFFFFFFF", Win_EditStroke: "#FF65A30D", Win_EditText: "#FF4D7C0F",
            Win_EditHoverBg: "#FFECF4D3", Win_EditHoverStroke: "#FF65A30D",
            Win_ActionBg: "#FF65A30D", Win_ActionStroke: "#FF65A30D", Win_ActionText: "#FFFFFFFF",
            Win_ActionHoverBg: "#FF4D7C0F", Win_ActionHoverStroke: "#FF4D7C0F",
            Win_ProgressBar: "#FF84CC16",
            Wheel_NormalText: "#CC3F6218", Wheel_NormalFill: "#FFF7FBEA", Wheel_NormalStroke: "#FFA3B18A",
            Wheel_HoverText: "#FF4D7C0F", Wheel_HoverFill: "#FFECF4D3", Wheel_HoverStroke: "#FF65A30D",
            Wheel_SwipeLineColor: "#FF84CC16",
            Panel_TitleBg: "#FF4D7C0F", Panel_TitleText: "#FFFFFFFF",
            Panel_BtnColor: "#FF65A30D", Panel_BtnText: "#FFFFFFFF", Panel_BgColor: "#C0F0F7E0",
            CMD_FontColor: "#FF365314", CMD_BGColor: "#FFF7FBEA", CMD_RunBGColor: "#FFDCEDC8"},
        {Key: "Celadon", Name: "青瓷",
            Win_TitleBg: "#FFCCFBF1", Win_TitleText: "#FF134E4A",
            Win_WindowBg: "#FFF0FDFA", Win_GroupStroke: "#FF5EEAD4", Win_GraphLine: "#FF283836",
            Win_GraphConn: "#FFF0FDFA", Win_GraphConnSel: "#FF0D9488", Win_LabelColor: "#FF134E4A",
            Win_InputBg: "#FFFFFFFF", Win_InputStroke: "#FF99F6E4", Win_InputText: "#FF134E4A",
            Win_EditBg: "#FFFFFFFF", Win_EditStroke: "#FF14B8A6", Win_EditText: "#FF0F766E",
            Win_EditHoverBg: "#FFCCFBF1", Win_EditHoverStroke: "#FF14B8A6",
            Win_ActionBg: "#FF0D9488", Win_ActionStroke: "#FF0D9488", Win_ActionText: "#FFFFFFFF",
            Win_ActionHoverBg: "#FF0F766E", Win_ActionHoverStroke: "#FF0F766E",
            Win_ProgressBar: "#FF14B8A6",
            Wheel_NormalText: "#CC115E59", Wheel_NormalFill: "#FFF0FDFA", Wheel_NormalStroke: "#FF99F6E4",
            Wheel_HoverText: "#FF0F766E", Wheel_HoverFill: "#FFCCFBF1", Wheel_HoverStroke: "#FF14B8A6",
            Wheel_SwipeLineColor: "#FF2DD4BF",
            Panel_TitleBg: "#FF0F766E", Panel_TitleText: "#FFFFFFFF",
            Panel_BtnColor: "#FF0D9488", Panel_BtnText: "#FFFFFFFF", Panel_BgColor: "#C0E6FFFA",
            CMD_FontColor: "#FF134E4A", CMD_BGColor: "#FFF0FDFA", CMD_RunBGColor: "#FFB2DFDB"},
        {Key: "DuskPurple", Name: "暮紫",
            Win_TitleBg: "#FFF3E8FF", Win_TitleText: "#FF4C1D95",
            Win_WindowBg: "#FFFAF5FF", Win_GroupStroke: "#FFC4B5FD", Win_GraphLine: "#FF322840",
            Win_GraphConn: "#FFFAF5FF", Win_GraphConnSel: "#FF7C3AED", Win_LabelColor: "#FF4C1D95",
            Win_InputBg: "#FFFFFFFF", Win_InputStroke: "#FFDDD6FE", Win_InputText: "#FF4C1D95",
            Win_EditBg: "#FFFFFFFF", Win_EditStroke: "#FF8B5CF6", Win_EditText: "#FF7C3AED",
            Win_EditHoverBg: "#FFF3E8FF", Win_EditHoverStroke: "#FF8B5CF6",
            Win_ActionBg: "#FF7C3AED", Win_ActionStroke: "#FF7C3AED", Win_ActionText: "#FFFFFFFF",
            Win_ActionHoverBg: "#FF6D28D9", Win_ActionHoverStroke: "#FF6D28D9",
            Win_ProgressBar: "#FFA78BFA",
            Wheel_NormalText: "#CC5B21B6", Wheel_NormalFill: "#FFFAF5FF", Wheel_NormalStroke: "#FFDDD6FE",
            Wheel_HoverText: "#FF7C3AED", Wheel_HoverFill: "#FFF3E8FF", Wheel_HoverStroke: "#FF8B5CF6",
            Wheel_SwipeLineColor: "#FFA78BFA",
            Panel_TitleBg: "#FF6D28D9", Panel_TitleText: "#FFFFFFFF",
            Panel_BtnColor: "#FF7C3AED", Panel_BtnText: "#FFFFFFFF", Panel_BgColor: "#C0F5F3FF",
            CMD_FontColor: "#FF4C1D95", CMD_BGColor: "#FFFAF5FF", CMD_RunBGColor: "#FFE1BEE7"}
    ]

    ; 程序默认主题（缺键 / 废弃预设 / Custom 底图均回退到此）
    static DefaultThemeKey := "Default"

    ; ---------- 预设查找 ----------

    static GetDefaultPreset() {
        for item in AppThemeUtil.Presets {
            if (item.Key == AppThemeUtil.DefaultThemeKey)
                return item
        }
        ; 开发期保底：Presets 首项应与 DefaultThemeKey 保持一致
        return AppThemeUtil.Presets[1]
    }

    static IsPresetKey(key) {
        if (key == "Custom")
            return true
        for item in AppThemeUtil.Presets {
            if (item.Key == key)
                return true
        }
        return false
    }

    static FindPreset(key) {
        for item in AppThemeUtil.Presets {
            if (item.Key == key)
                return item
        }
        return AppThemeUtil.GetDefaultPreset()
    }

    static FindPresetByName(name) {
        for item in AppThemeUtil.Presets {
            if (item.Name == name || GetLang(item.Name) == name)
                return item
        }
        return ""
    }

    ; ColorDefs 中 Group 去重顺序（兼容旧调用；主题设置页现在使用 BuildPalette）
    static GetGroupNames() {
        names := []
        seen := Map()
        for def in AppThemeUtil.ColorDefs {
            if (!seen.Has(def.Group)) {
                seen[def.Group] := true
                names.Push(def.Group)
            }
        }
        return names
    }

    ; 将主题的 14 个语义颜色键按固定槽位顺序展开，保证不同主题的颜色 X 用途一致。
    static BuildPalette(colors) {
        complete := AppThemeUtil.BuildCompleteColorMap(colors)
        palette := []
        for defIndex, def in AppThemeUtil.ColorDefs {
            color := AppThemeUtil.ResolveColor(complete, def.Key)
            uses := def.HasProp("Uses") ? def.Uses : [def.Group " · " def.Label]
            entry := {Color: color, Keys: [def.Key], Uses: uses, DefIndex: defIndex}
            entry.SortInfo := AppThemeUtil.PaletteColorInfo(entry.Color)
            palette.Push(entry)
        }
        return palette
    }
    ; 主题色优先，白/黑/灰等低饱和通用色放在末尾；同一色相按明度、饱和度相邻排列。
    static PaletteColorInfo(color) {
        c := AppThemeUtil.NormalizeArgb(color)
        r := Integer("0x" SubStr(c, 4, 2)) / 255.0
        g := Integer("0x" SubStr(c, 6, 2)) / 255.0
        b := Integer("0x" SubStr(c, 8, 2)) / 255.0
        maxC := Max(r, g, b)
        minC := Min(r, g, b)
        delta := maxC - minC
        light := (maxC + minC) / 2.0
        if (delta == 0) {
            hue := 0.0
            sat := 0.0
        } else {
            sat := delta / (1 - Abs(2 * light - 1))
            if (maxC == r) {
                hue := 60.0 * ((g - b) / delta)
                if (hue < 0)
                    hue += 360.0
            } else if (maxC == g) {
                hue := 60.0 * ((b - r) / delta + 2)
            } else {
                hue := 60.0 * ((r - g) / delta + 4)
            }
        }
        alpha := Integer("0x" SubStr(c, 2, 2))
        return {Neutral: sat < 0.08 ? 1 : 0, Hue: hue, Light: light, Sat: sat, Alpha: alpha}
    }

    static ComparePaletteEntries(left, right) {
        a := left.SortInfo
        b := right.SortInfo
        if (a.Neutral != b.Neutral)
            return a.Neutral < b.Neutral ? -1 : 1
        if (a.Hue != b.Hue)
            return a.Hue < b.Hue ? -1 : 1
        if (a.Light != b.Light)
            return a.Light < b.Light ? -1 : 1
        if (a.Sat != b.Sat)
            return a.Sat > b.Sat ? -1 : 1
        if (a.Alpha != b.Alpha)
            return a.Alpha > b.Alpha ? -1 : 1
        if (a.DefIndex != b.DefIndex)
            return a.DefIndex < b.DefIndex ? -1 : 1
        return StrCompare(left.Color, right.Color)
    }

    static PaletteTooltip(entry) {
        if (!IsObject(entry) || !entry.HasProp("Uses") || entry.Uses.Length == 0)
            return ""
        tip := "常用位置："
        for i, useName in entry.Uses
            tip .= (i == 1 ? "" : "；") useName
        return tip
    }

    ; 色块与输入框描边相同会融为一体，依次尝试主题描边/文字色，最后使用对比色。
    static PaletteSwatchStroke(colors, fillColor) {
        fill := AppThemeUtil.NormalizeArgb(fillColor)
        stroke := AppThemeUtil.ResolveColor(colors, "Win_InputStroke")
        if (stroke != fill)
            return stroke
        for key in ["Win_GroupStroke", "Win_LabelColor", "Win_ActionStroke"] {
            candidate := AppThemeUtil.ResolveColor(colors, key)
            if (candidate != fill)
                return candidate
        }
        return AppThemeUtil.RgbLuma(fill) >= 150 ? "#FF4B5563" : "#FFE5E7EB"
    }

    static SetPaletteColor(colors, entry, newColor) {
        if (!IsObject(colors) || !IsObject(entry) || !entry.HasProp("Keys"))
            return false
        normalized := AppThemeUtil.NormalizeArgb(newColor)
        for colorKey in entry.Keys
            colors[colorKey] := normalized
        return true
    }

    ; ---------- 颜色解析与完整 Map（兼容核心）----------

    ; 默认主题上某 Key 的标准色；默认主题也未定义时才回退纯黑（应避免出现）
    static GetDefaultColor(key) {
        canonical := AppThemeUtil.CanonicalKey(key)
        slots := AppThemeUtil.GetPresetSlotMap(AppThemeUtil.GetDefaultPreset())
        if (slots.Has(canonical))
            return slots[canonical]
        return "#FF000000"
    }

    ; 从 colors Map 取色；缺键 / 空值 → 默认主题
    static ResolveColor(colors, key) {
        if (IsObject(colors) && colors.Has(key)) {
            val := colors[key]
            if (val != "")
                return AppThemeUtil.NormalizeArgb(val)
        }
        canonical := AppThemeUtil.CanonicalKey(key)
        if (IsObject(colors) && colors.Has(canonical)) {
            val := colors[canonical]
            if (val != "")
                return AppThemeUtil.NormalizeArgb(val)
        }
        return AppThemeUtil.GetDefaultColor(key)
    }

    ; 以默认主题为底，再叠加 overlay（Map 或 Preset 对象），保证含 ColorDefs 全部 Key
    ; 用于：选预设、加载自定义残缺配置、克隆后补齐新增项
    static BuildCompleteColorMap(overlay := "") {
        colors := Map()
        used := Map()
        baseSlots := AppThemeUtil.GetPresetSlotMap(AppThemeUtil.GetDefaultPreset())
        overlaySlots := (IsObject(overlay) && !(overlay is Map) && overlay.HasProp("Key"))
            ? AppThemeUtil.GetPresetSlotMap(overlay)
            : Map()
        for def in AppThemeUtil.ColorDefs {
            key := def.Key
            val := ""
            if (IsObject(overlay)) {
                if (overlay is Map) {
                    if (overlay.Has(key) && overlay[key] != "")
                        val := overlay[key]
                } else if (overlay.HasProp(key)) {
                    propVal := overlay.%key%
                    if (propVal != "")
                        val := propVal
                }
            }
            if (val == "")
                val := overlaySlots.Has(key) ? overlaySlots[key] : (baseSlots.Has(key) ? baseSlots[key] : "#FF000000")
            val := AppThemeUtil.MakeDistinctColor(val, used)
            colors[key] := val
            used[val] := true
        }
        for alias, canonical in AppThemeUtil.ColorAliases
            colors[alias] := colors[canonical]
        return colors
    }

    static CanonicalKey(key) {
        return AppThemeUtil.ColorAliases.Has(key) ? AppThemeUtil.ColorAliases[key] : key
    }

    static GetPresetSlotMap(preset) {
        slots := Map()
        used := Map()
        base := AppThemeUtil.GetDefaultPreset()
        for def in AppThemeUtil.ColorDefs {
            val := ""
            if (IsObject(preset) && def.HasProp("Source") && preset.HasProp(def.Source))
                val := preset.%def.Source%
            if (val == "" && IsObject(base) && base.HasProp(def.Source))
                val := base.%def.Source%
            val := AppThemeUtil.MakeDistinctColor(val, used)
            slots[def.Key] := val
            used[val] := true
        }
        return slots
    }

    ; 由预设生成完整颜色 Map（预设缺属性时补默认主题色）
    static NewColorMapFromPreset(preset) {
        return AppThemeUtil.BuildCompleteColorMap(preset)
    }

    ; 克隆并补齐：旧自定义 / 内存残缺 Map 升级后自动带上新 Key（默认主题色）
    static CloneColorMap(src) {
        return AppThemeUtil.BuildCompleteColorMap(IsObject(src) ? src : "")
    }

    ; #AARRGGBB / AARRGGBB / RRGGBB -> 6 位 RGB（供 AHK Gui.BackColor）
    static ArgbToRgb6(color) {
        s := StrReplace(color, "#")
        if (StrLen(s) >= 8)
            return SubStr(s, 3, 6)
        if (StrLen(s) == 6)
            return s
        return "000000"
    }

    static NormalizeArgb(color) {
        s := StrUpper(StrReplace(String(color), "#"))
        if (StrLen(s) == 6)
            return "#FF" s
        if (StrLen(s) == 8)
            return "#" s
        return "#FF000000"
    }

    static MakeDistinctColor(color, used) {
        candidate := AppThemeUtil.NormalizeArgb(color)
        if (!used.Has(candidate))
            return candidate
        alpha := Integer("0x" SubStr(candidate, 2, 2))
        baseR := Integer("0x" SubStr(candidate, 4, 2))
        baseG := Integer("0x" SubStr(candidate, 6, 2))
        baseB := Integer("0x" SubStr(candidate, 8, 2))
        loop 255 {
            distance := Ceil(A_Index / 2)
            if (Mod(A_Index, 2) == 1)
                distance := -distance
            r := Max(0, Min(255, baseR + distance))
            g := Max(0, Min(255, baseG + distance))
            b := Max(0, Min(255, baseB + distance))
            candidate := Format("#{:02X}{:02X}{:02X}{:02X}", alpha, r, g, b)
            if (!used.Has(candidate))
                return candidate
        }
        return Format("#FF{:02X}{:02X}{:02X}", Mod(baseR + 1, 256), Mod(baseG + 3, 256), Mod(baseB + 5, 256))
    }

    static MapGet(colors, key, defaultVal) {
        if (IsObject(colors) && colors.Has(key) && colors[key] != "")
            return colors[key]
        return defaultVal
    }

    ; ---------- 运行时同步 ----------

    ; 将 ThemeColors 同步到各运行时字段（缺键走 ResolveColor → 默认主题）
    static ApplyToRuntime(colors) {
        if (!IsObject(colors))
            colors := Map()
        ; BuildComplete 只读取固定的 14 个主题槽位，并重新生成运行时别名。
        colors := AppThemeUtil.BuildCompleteColorMap(colors)

        MainSoftData.UIPanelTitleBg := AppThemeUtil.ResolveColor(colors, "Panel_TitleBg")
        MainSoftData.UIPanelTitleText := AppThemeUtil.ResolveColor(colors, "Panel_TitleText")
        MainSoftData.UIPanelBtnColor := AppThemeUtil.ResolveColor(colors, "Panel_BtnColor")

        ; 按钮文本由固定的主题槽位提供。
        MainSoftData.UIPanelBtnText := AppThemeUtil.ResolveColor(colors, "Panel_BtnText")
        MainSoftData.UIPanelFontColor := MainSoftData.UIPanelBtnText  ; 兼容旧字段名

        MainSoftData.UIPanelBgColor := AppThemeUtil.ResolveColor(colors, "Panel_BgColor")
        MainSoftData.CMDFontColor := AppThemeUtil.ArgbToRgb6(AppThemeUtil.ResolveColor(colors, "CMD_FontColor"))
        MainSoftData.CMDBGColor := AppThemeUtil.ArgbToRgb6(AppThemeUtil.ResolveColor(colors, "CMD_BGColor"))
        MainSoftData.CMDRunBGColor := AppThemeUtil.ArgbToRgb6(AppThemeUtil.ResolveColor(colors, "CMD_RunBGColor"))
    }

    static ApplyPreset(key) {
        preset := AppThemeUtil.FindPreset(key)
        MainSoftData.AppTheme := preset.Key
        MainSoftData.ThemeColors := AppThemeUtil.NewColorMapFromPreset(preset)
        AppThemeUtil.ApplyToRuntime(MainSoftData.ThemeColors)
    }

    ; ---------- ini 读写 ----------

    static LoadFromIni() {
        section := "ThemeColors"
        themeKey := IniRead(IniFile, section, "AppTheme", AppThemeUtil.DefaultThemeKey)
        ; 空值、未知 Key → 默认主题
        if (themeKey == "" || !AppThemeUtil.IsPresetKey(themeKey))
            themeKey := AppThemeUtil.DefaultThemeKey
        MainSoftData.AppTheme := themeKey

        ; Custom：底图=默认主题；具名预设：底图=该预设（缺属性仍补默认主题）
        baseKey := (themeKey == "Custom") ? AppThemeUtil.DefaultThemeKey : themeKey
        colors := AppThemeUtil.NewColorMapFromPreset(AppThemeUtil.FindPreset(baseKey))

        ; 逐项覆盖：ini 有值才覆盖；新增 ColorDefs Key 在 ini 中不存在时保留底图色
        for def in AppThemeUtil.ColorDefs {
            saved := IniRead(IniFile, section, def.Key, "")
            if (saved != "")
                colors[def.Key] := AppThemeUtil.NormalizeArgb(saved)
        }

        colors := AppThemeUtil.CloneColorMap(colors)
        MainSoftData.ThemeColors := colors
        AppThemeUtil.ApplyToRuntime(colors)
    }

    static SaveToIni() {
        section := "ThemeColors"
        ; 保存前补齐，避免漏写新增 Key
        MainSoftData.ThemeColors := AppThemeUtil.CloneColorMap(MainSoftData.ThemeColors)
        IniWrite(MainSoftData.AppTheme, IniFile, section, "AppTheme")
        for def in AppThemeUtil.ColorDefs {
            val := AppThemeUtil.ResolveColor(MainSoftData.ThemeColors, def.Key)
            IniWrite(val, IniFile, section, def.Key)
        }
        ; 其他界面设置仍写入原有配置段；主题颜色只写入 14 个 Theme_Color 槽位。
        IniWrite(MainSoftData.AppTheme, IniFile, IniSection, "AppTheme")
        if (MainSoftData.HasProp("FontSize"))
            IniWrite(MainSoftData.FontSize, IniFile, IniSection, "FontSize")
    }

    ; 轮盘取色：ThemeColors → 默认主题；defaultVal 仅作额外兜底（调用方可省略）
    static GetWheelColor(name, defaultVal := "") {
        key := "Wheel_" name
        if (IsObject(MainSoftData.ThemeColors)
            && (MainSoftData.ThemeColors.Has(key) || MainSoftData.ThemeColors.Has(AppThemeUtil.CanonicalKey(key))))
            return AppThemeUtil.ResolveColor(MainSoftData.ThemeColors, key)
        warm := AppThemeUtil.GetDefaultColor(key)
        if (warm != "#FF000000")
            return warm
        return (defaultVal != "") ? defaultVal : warm
    }

    ; 将「通用窗口」色写入已打开的 XAML 窗口 Resource（及标题栏 DragArea）
    ; colors 可传编辑中的草稿 Map；省略则用 MainSoftData.ThemeColors
    static ApplyWinThemeToXaml(ui, colors := "") {
        if (!IsObject(ui))
            return
        if (!IsObject(colors))
            colors := IsObject(MainSoftData.ThemeColors) ? MainSoftData.ThemeColors : Map()
        colors := AppThemeUtil.BuildCompleteColorMap(colors)

        titleBg := AppThemeUtil.ResolveColor(colors, "Win_TitleBg")
        titleText := AppThemeUtil.ResolveColor(colors, "Win_TitleText")
        windowBg := AppThemeUtil.ResolveColor(colors, "Win_WindowBg")
        groupStroke := AppThemeUtil.ResolveColor(colors, "Win_GroupStroke")
        graphLine := AppThemeUtil.ResolveColor(colors, "Win_GraphLine")
        graphConn := AppThemeUtil.ResolveColor(colors, "Win_GraphConn")
        graphConnSel := AppThemeUtil.ResolveColor(colors, "Win_GraphConnSel")
        labelColor := AppThemeUtil.ResolveColor(colors, "Win_LabelColor")
        textSub := AppThemeUtil.WithAlpha(labelColor, "99")
        inputBg := AppThemeUtil.ResolveColor(colors, "Win_InputBg")
        inputStroke := AppThemeUtil.ResolveColor(colors, "Win_InputStroke")
        inputText := AppThemeUtil.ResolveColor(colors, "Win_InputText")
        editBg := AppThemeUtil.ResolveColor(colors, "Win_EditBg")
        editStroke := AppThemeUtil.ResolveColor(colors, "Win_EditStroke")
        editText := AppThemeUtil.ResolveColor(colors, "Win_EditText")
        editHoverBg := AppThemeUtil.ResolveColor(colors, "Win_EditHoverBg")
        editHoverStroke := AppThemeUtil.ResolveColor(colors, "Win_EditHoverStroke")
        actionBg := AppThemeUtil.ResolveColor(colors, "Win_ActionBg")
        actionStroke := AppThemeUtil.ResolveColor(colors, "Win_ActionStroke")
        actionText := AppThemeUtil.ResolveColor(colors, "Win_ActionText")
        actionHoverBg := AppThemeUtil.ResolveColor(colors, "Win_ActionHoverBg")
        actionHoverStroke := AppThemeUtil.ResolveColor(colors, "Win_ActionHoverStroke")
        progress := AppThemeUtil.ResolveColor(colors, "Win_ProgressBar")
        ; 页签选中背景：主题强调色低透明度（各主题自动适配，见主窗口 tabItemStyle 的 TabSelBg）
        tabSelBg := AppThemeUtil.WithAlpha(progress, "80")
        btnPressBg := AppThemeUtil.AdjustRgbBrightness(groupStroke, 0.90)
        actionPressBg := AppThemeUtil.AdjustRgbBrightness(actionHoverBg, 0.92)
        ; 主界面主要轮廓描边：与「配置管理」按钮 hover 背景同色（ControlBorder / GroupStroke）
        outlineStroke := groupStroke

        ; 合并为一次 BatchUpdate：~28 条资源逐条 Update 是 28 次同步 IPC 往返（拖慢开窗）
        if (ui.HasMethod("BatchUpdate")) {
            batch := [
                {ControlName: "Resource", PropertyName: "TitleBarColor", Value: titleBg},
                {ControlName: "Resource", PropertyName: "TitleBarForeground", Value: titleText},
                {ControlName: "Resource", PropertyName: "BgColor", Value: windowBg},
                {ControlName: "Resource", PropertyName: "TextMain", Value: labelColor},
                {ControlName: "Resource", PropertyName: "TextSub", Value: textSub},
                {ControlName: "Resource", PropertyName: "ControlBg", Value: windowBg},
                {ControlName: "Resource", PropertyName: "ControlBorder", Value: groupStroke},
                {ControlName: "Resource", PropertyName: "GroupStroke", Value: groupStroke},
                {ControlName: "Resource", PropertyName: "GraphLine", Value: graphLine},
                {ControlName: "Resource", PropertyName: "GraphConn", Value: graphConn},
                {ControlName: "Resource", PropertyName: "GraphConnSel", Value: graphConnSel},
                {ControlName: "Resource", PropertyName: "InputBg", Value: inputBg},
                {ControlName: "Resource", PropertyName: "InputStroke", Value: inputStroke},
                {ControlName: "Resource", PropertyName: "InputText", Value: inputText},
                {ControlName: "Resource", PropertyName: "EditBg", Value: editBg},
                {ControlName: "Resource", PropertyName: "EditStroke", Value: editStroke},
                {ControlName: "Resource", PropertyName: "EditText", Value: editText},
                {ControlName: "Resource", PropertyName: "EditHoverBg", Value: editHoverBg},
                {ControlName: "Resource", PropertyName: "EditHoverStroke", Value: editHoverStroke},
                {ControlName: "Resource", PropertyName: "ActionBg", Value: actionBg},
                {ControlName: "Resource", PropertyName: "ActionStroke", Value: actionStroke},
                {ControlName: "Resource", PropertyName: "ActionText", Value: actionText},
                {ControlName: "Resource", PropertyName: "ActionHoverBg", Value: actionHoverBg},
                {ControlName: "Resource", PropertyName: "ActionHoverStroke", Value: actionHoverStroke},
                {ControlName: "Resource", PropertyName: "Accent", Value: progress},
                {ControlName: "Resource", PropertyName: "ProgressBar", Value: progress},
                ; 页签选中背景（主窗口 tabItemStyle 用）
                {ControlName: "Resource", PropertyName: "TabSelBg", Value: tabSelBg},
                {ControlName: "Resource", PropertyName: "BtnPressBg", Value: btnPressBg},
                {ControlName: "Resource", PropertyName: "ActionPressBg", Value: actionPressBg},
                {ControlName: "Resource", PropertyName: "OutlineStroke", Value: outlineStroke},
                ; 下拉弹出层与输入框同色，避免浅色底 + 深色主题文字导致看不清
                {ControlName: "Resource", PropertyName: "DropdownBg", Value: windowBg},
                ; 列表斑马纹：取标题色 RGB，降低透明度，随主题变化
                {ControlName: "Resource", PropertyName: "ListAltBg", Value: AppThemeUtil.MakeListAltBg(titleBg)},
                {ControlName: "Resource", PropertyName: "ListRowAltBg", Value: AppThemeUtil.MakeListRowAltBg(windowBg, actionBg)},
                {ControlName: "Resource", PropertyName: "ListRowForbidBg", Value: AppThemeUtil.MakeListRowForbidBg(windowBg, actionBg)},
                {ControlName: "Resource", PropertyName: "FoldHeaderBg", Value: AppThemeUtil.MakeFoldHeaderBg(windowBg, titleBg)},
                {ControlName: "Resource", PropertyName: "FoldAltBg", Value: AppThemeUtil.MakeFoldAltBg(windowBg, actionBg)},
                {ControlName: "Resource", PropertyName: "FoldDivider", Value: AppThemeUtil.WithAlpha(groupStroke, "55")},
                {ControlName: "DragArea", PropertyName: "Background", Value: titleBg},
                {ControlName: "Window", PropertyName: "Background", Value: windowBg}
            ]
            ui.BatchUpdate(batch)
        } else {
            try ui.Update("Resource", "TitleBarColor", titleBg)
            try ui.Update("Resource", "TitleBarForeground", titleText)
            try ui.Update("Resource", "BgColor", windowBg)
            try ui.Update("Resource", "TextMain", labelColor)
            try ui.Update("Resource", "TextSub", textSub)
            try ui.Update("Resource", "ControlBg", windowBg)
            try ui.Update("Resource", "ControlBorder", groupStroke)
            try ui.Update("Resource", "GroupStroke", groupStroke)
            try ui.Update("Resource", "GraphLine", graphLine)
            try ui.Update("Resource", "GraphConn", graphConn)
            try ui.Update("Resource", "GraphConnSel", graphConnSel)
            try ui.Update("Resource", "InputBg", inputBg)
            try ui.Update("Resource", "InputStroke", inputStroke)
            try ui.Update("Resource", "InputText", inputText)
            try ui.Update("Resource", "EditBg", editBg)
            try ui.Update("Resource", "EditStroke", editStroke)
            try ui.Update("Resource", "EditText", editText)
            try ui.Update("Resource", "EditHoverBg", editHoverBg)
            try ui.Update("Resource", "EditHoverStroke", editHoverStroke)
            try ui.Update("Resource", "ActionBg", actionBg)
            try ui.Update("Resource", "ActionStroke", actionStroke)
            try ui.Update("Resource", "ActionText", actionText)
            try ui.Update("Resource", "ActionHoverBg", actionHoverBg)
            try ui.Update("Resource", "ActionHoverStroke", actionHoverStroke)
            try ui.Update("Resource", "Accent", progress)
            try ui.Update("Resource", "ProgressBar", progress)
            ; 页签选中背景（主窗口 tabItemStyle 用）
            try ui.Update("Resource", "TabSelBg", tabSelBg)
            try ui.Update("Resource", "BtnPressBg", btnPressBg)
            try ui.Update("Resource", "ActionPressBg", actionPressBg)
            try ui.Update("Resource", "OutlineStroke", outlineStroke)
            ; 下拉弹出层与输入框同色，避免浅色底 + 深色主题文字导致看不清
            try ui.Update("Resource", "DropdownBg", windowBg)
            ; 列表斑马纹：取标题色 RGB，降低透明度，随主题变化
            try ui.Update("Resource", "ListAltBg", AppThemeUtil.MakeListAltBg(titleBg))
            try ui.Update("Resource", "ListRowAltBg", AppThemeUtil.MakeListRowAltBg(windowBg, actionBg))
            try ui.Update("Resource", "ListRowForbidBg", AppThemeUtil.MakeListRowForbidBg(windowBg, actionBg))
            try ui.Update("Resource", "FoldHeaderBg", AppThemeUtil.MakeFoldHeaderBg(windowBg, titleBg))
            try ui.Update("Resource", "FoldAltBg", AppThemeUtil.MakeFoldAltBg(windowBg, actionBg))
            try ui.Update("Resource", "FoldDivider", AppThemeUtil.WithAlpha(groupStroke, "55"))
            try ui.Update("DragArea", "Background", titleBg)
            try ui.Update("Window", "Background", windowBg)
        }
    }

    ; 列表交替行背景：标题色半透明（不同主题呈现不同色调）
    static MakeListAltBg(baseColor) {
        c := AppThemeUtil.NormalizeArgb(baseColor)  ; #AARRGGBB
        return "#40" SubStr(c, 4)                   ; ~25% 不透明度
    }

    ; 把 overlay 按 amt(0~1) 混进底色，得到不透明色（斑马纹/模块头跟主题色走）
    static BlendRgb(baseColor, overlayColor, amt) {
        amt := Max(0.0, Min(1.0, Float(amt)))
        b := AppThemeUtil.NormalizeArgb(baseColor)
        o := AppThemeUtil.NormalizeArgb(overlayColor)
        br := Integer("0x" SubStr(b, 4, 2)), bg := Integer("0x" SubStr(b, 6, 2)), bb := Integer("0x" SubStr(b, 8, 2))
        or_ := Integer("0x" SubStr(o, 4, 2)), og := Integer("0x" SubStr(o, 6, 2)), ob := Integer("0x" SubStr(o, 8, 2))
        r := Min(255, Max(0, Round(br * (1 - amt) + or_ * amt)))
        g := Min(255, Max(0, Round(bg * (1 - amt) + og * amt)))
        b2 := Min(255, Max(0, Round(bb * (1 - amt) + ob * amt)))
        return Format("#FF{:02X}{:02X}{:02X}", r, g, b2)
    }

    ; 禁用/跳过：同色轻微下沉，不铺灰块；内容变淡靠 Opacity
    static MakeListRowForbidBg(windowBg, actionBg) {
        factor := (AppThemeUtil.RgbLuma(windowBg) >= 140) ? 0.94 : 0.86
        return AppThemeUtil.AdjustRgbBrightness(windowBg, factor)
    }

    ; 宏行斑马：浅粉（比窗口白粉略深），混入少量操作色
    static MakeListRowAltBg(windowBg, actionBg) {
        c := AppThemeUtil.BlendRgb(windowBg, actionBg, 0.04)
        if (AppThemeUtil.RgbLuma(c) >= AppThemeUtil.RgbLuma(windowBg) - 3)
            c := AppThemeUtil.AdjustRgbBrightness(windowBg, 0.98)
        return c
    }

    ; 模块斑马：混入操作色，比宏行更深一档，无分割线时也能分清
    static MakeFoldAltBg(windowBg, actionBg) {
        c := AppThemeUtil.BlendRgb(windowBg, actionBg, 0.22)
        if (AppThemeUtil.RgbLuma(c) >= AppThemeUtil.RgbLuma(windowBg) - 8)
            c := AppThemeUtil.AdjustRgbBrightness(windowBg, 0.88)
        return c
    }

    static RgbLuma(color) {
        c := AppThemeUtil.NormalizeArgb(color)
        r := Integer("0x" SubStr(c, 4, 2)), g := Integer("0x" SubStr(c, 6, 2)), b := Integer("0x" SubStr(c, 8, 2))
        return Round(0.299 * r + 0.587 * g + 0.114 * b)
    }

    ; 模块头与偶数宏行同色（ControlBg / 窗口底），奇数行才用斑马纹加深
    static MakeFoldHeaderBg(windowBg, titleBg) {
        return windowBg
    }

    ; 按 factor 缩放 RGB（factor<1 略加深，用于按钮按下背景）
    static AdjustRgbBrightness(color, factor := 1.0) {
        c := AppThemeUtil.NormalizeArgb(color)  ; #AARRGGBB
        r := Min(255, Max(0, Round(Integer("0x" SubStr(c, 4, 2)) * factor)))
        g := Min(255, Max(0, Round(Integer("0x" SubStr(c, 6, 2)) * factor)))
        b := Min(255, Max(0, Round(Integer("0x" SubStr(c, 8, 2)) * factor)))
        return Format("#FF{:02X}{:02X}{:02X}", r, g, b)
    }

    ; #AARRGGBB 颜色上叠加透明度：alphaHex 为两位十六进制（"40"≈25%）
    static WithAlpha(color, alphaHex) {
        c := AppThemeUtil.NormalizeArgb(color)      ; #AARRGGBB
        return "#" alphaHex SubStr(c, 4)
    }

    ; 刷新已打开的全部 XAML 窗口（主题确定后主界面、编辑窗、设置窗等）
    static RefreshAllOpenWindows() {
        colors := IsObject(MainSoftData.ThemeColors) ? MainSoftData.ThemeColors : Map()
        try {
            if (IsSet(XAMLHost) && XAMLHost.HasOwnProp("_instances")) {
                for , host in XAMLHost._instances {
                    if (!IsObject(host) || !host.HasProp("wpfHwnd") || !host.wpfHwnd)
                        continue
                    if (!DllCall("user32\IsWindow", "Ptr", host.wpfHwnd, "Int"))
                        continue
                    AppThemeUtil.ApplyWinThemeToXaml(host, colors)
                }
            }
        }
        AppThemeUtil.RefreshOpenSettingWindows()
        if (IsSet(MacroGraphGui) && IsObject(MacroGraphGui))
            try MacroGraphGui.RefreshOpenThemes()
        if (IsSet(MyUIMacroGui) && IsObject(MyUIMacroGui))
            MyUIMacroGui.ApplyThemeColors()
        if (IsSet(MyCMDTipGui) && IsObject(MyCMDTipGui))
            MyCMDTipGui.ApplyThemeColors()
        if (IsSet(MyMenuWheel) && IsObject(MyMenuWheel))
            MyMenuWheel.ApplyThemeColors()
    }

    ; 刷新已打开的通用窗口类设置界面（主题保存后同步）
    ; 用类名字符串动态解析：Worker 未 Include 这些 Gui，直接写类名会触发 #Warn / 编译失败
    static RefreshOpenSettingWindows() {
        classNames := ["HotkeySettingGui", "ToolRecordSettingGui", "MenuWheelGlobalSettingGui",
            "UIMacroPanelSettingGui", "CMDTipSettingGui", "ThemeSettingGui",
            "TimingGui", "MenuMacroSettingGui", "UIMacroSettingGui"]
        for name in classNames {
            try {
                if (!IsSet(%name%))
                    continue
                cls := %name%
                if (!IsObject(cls) || !cls.HasOwnProp("instances"))
                    continue
                for , inst in cls.instances {
                    if (!inst.closed && IsObject(inst.ui))
                        AppThemeUtil.ApplyWinThemeToXaml(inst.ui)
                }
            }
        }
        ; 变量监视器 / 变量修改（非 instances 模式）
        try {
            if (IsSet(MyVarListenGui) && IsObject(MyVarListenGui)
                && !MyVarListenGui.closed && IsObject(MyVarListenGui.ui))
                AppThemeUtil.ApplyWinThemeToXaml(MyVarListenGui.ui)
        }
        try {
            if (IsSet(MyVarListenGui) && IsObject(MyVarListenGui)
                && IsObject(MyVarListenGui.ModifyGui)
                && !MyVarListenGui.ModifyGui.closed && IsObject(MyVarListenGui.ModifyGui.ui))
                AppThemeUtil.ApplyWinThemeToXaml(MyVarListenGui.ModifyGui.ui)
        }
    }

    ; 已收缩：各窗标题栏铬钮请用 Style="{StaticResource TitleBarCloseButton}"（XAML_Host 补丁也会强制套上）。
    ; 本方法仅作旧 InjectResources 兼容，视觉与 TitleBarCloseButton 相同。
    static TitleCloseBtnStyle() {
        return '<Style TargetType="Button"><Setter Property="VerticalAlignment" Value="Stretch"/><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border x:Name="border" Background="{TemplateBinding Background}" CornerRadius="{DynamicResource CloseBtnRadius}" HorizontalAlignment="Stretch" VerticalAlignment="Stretch"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="0"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="border" Property="Background" Value="{DynamicResource ControlBorder}"/></Trigger><Trigger Property="IsPressed" Value="True"><Setter TargetName="border" Property="Background" Value="{DynamicResource BtnPressBg}"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>'
    }
}
