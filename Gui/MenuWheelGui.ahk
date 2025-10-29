#Requires AutoHotkey v2.0

class MenuWheelGui {
    __new() {
        this.Gui := ""
        this.MenuIndex := 1
        this.BtnConArr := []
        this.FocusCon := ""

        this.gfx := 0
        this.timerId := ""
    }

    ShowGui(MenuIndex) {
        if (this.Gui != "") {
            this.Gui.Show(this.GetGuiShowPos())
        }
        else {
            this.AddGui()
        }
        this.Init(MenuIndex)
        LineDrawer.Update(100, 100, 500, 500)
        LineDrawer.Clear()
        LineDrawer.Update(100, 100, 300, 500)
    }

    Init(MenuIndex) {
        this.MenuIndex := MenuIndex
        tableItem := MySoftData.TableInfo[3]
        loop 8 {

            remark := tableItem.RemarkArr[(MenuIndex - 1) * 8 + A_Index]
            btnName := remark != "" ? remark : "菜单配置" A_Index
            this.BtnConArr[A_Index].Text := btnName
        }
    }

    AddGui() {
        MyGui := Gui("-Caption +AlwaysOnTop +ToolWindow", "菜单轮")
        MyGui.SetFont("S11 W550 Q2", MySoftData.FontType)
        MyGui.BackColor := "EEAA99"
        WinSetTransColor("EEAA99", MyGui)
        this.Gui := MyGui
        PosX := 0
        PosY := 0
        this.FocusCon := MyGui.Add("Text", Format("x{} y{}", PosX, PosY), "")

        PosX := 130  ; 调整
        PosY := 10   ; 调整
        con := MyGui.Add("Button", Format("x{} y{} w80", PosX, PosY), "菜单配置1")
        con.OnEvent("Click", (*) => this.OnBtnClick(1))
        this.BtnConArr.Push(con)

        PosX := 225  ; 调整
        PosY := 55   ; 调整
        con := MyGui.Add("Button", Format("x{} y{} w80", PosX, PosY), "菜单配置2")
        con.OnEvent("Click", (*) => this.OnBtnClick(2))
        this.BtnConArr.Push(con)

        PosX := 260  ; 调整
        PosY := 110  ; 调整
        con := MyGui.Add("Button", Format("x{} y{} w80", PosX, PosY), "菜单配置3")
        con.OnEvent("Click", (*) => this.OnBtnClick(3))
        this.BtnConArr.Push(con)

        PosX := 225  ; 调整
        PosY := 165  ; 调整
        con := MyGui.Add("Button", Format("x{} y{} w80", PosX, PosY), "菜单配置4")
        con.OnEvent("Click", (*) => this.OnBtnClick(4))
        this.BtnConArr.Push(con)

        PosX := 130  ; 调整
        PosY := 210  ; 调整
        con := MyGui.Add("Button", Format("x{} y{} w80", PosX, PosY), "菜单配置5")
        con.OnEvent("Click", (*) => this.OnBtnClick(5))
        this.BtnConArr.Push(con)

        PosX := 35   ; 调整
        PosY := 165  ; 调整
        con := MyGui.Add("Button", Format("x{} y{} w80", PosX, PosY), "菜单配置6")
        con.OnEvent("Click", (*) => this.OnBtnClick(6))
        this.BtnConArr.Push(con)

        PosX := 0    ; 调整
        PosY := 110  ; 调整
        con := MyGui.Add("Button", Format("x{} y{} w80", PosX, PosY), "菜单配置7")
        con.OnEvent("Click", (*) => this.OnBtnClick(7))
        this.BtnConArr.Push(con)

        PosX := 35   ; 调整
        PosY := 55   ; 调整
        con := MyGui.Add("Button", Format("x{} y{} w80", PosX, PosY), "菜单配置8")
        con.OnEvent("Click", (*) => this.OnBtnClick(8))
        this.BtnConArr.Push(con)

        MyGui.Show(Format("{} w{} h{}", this.GetGuiShowPos(), 340, 260))
    }

    GetGuiShowPos() {
        if (MySoftData.FixedMenuWheel) {
            PosX := A_ScreenWidth * 0.5 - 170
            PosY := A_ScreenHeight * 0.70
        }
        else {
            CoordMode("Mouse", "Screen")
            MouseGetPos &mouseX, &mouseY
            PosX := mouseX - 170
            PosY := mouseY - 130
        }

        return Format("x{} y{}", PosX, PosY)
    }

    OnBtnClick(index) {
        MySoftData.CurMenuWheelIndex := -1
        this.FocusCon.Focus()
        this.Gui.Hide()
        macroIndex := (this.MenuIndex - 1) * 8 + index
        TriggerSubMacro(3, macroIndex)
    }
}

class LineDrawer {
    static hdc := 0               ; 屏幕设备上下文
    static hPen := 0              ; 画笔
    static hOldPen := 0           ; 原始画笔
    static lines := []            ; 存储线条及对应背景数据: [x1,y1,x2,y2,hBitmap,hMemDC]

    ; 初始化GDI资源
    static __New() {
        ; 获取屏幕DC
        this.hdc := DllCall("GetDC", "ptr", 0, "ptr")
        
        ; 创建红色画笔(可修改颜色：0x00BBGGRR)
        this.hPen := DllCall("CreatePen", "int", 0, "int", 2, "uint", 0x0000FF, "ptr")
        
        ; 保存原有画笔
        this.hOldPen := DllCall("SelectObject", "ptr", this.hdc, "ptr", this.hPen, "ptr")
    }

    ; 绘制线条并保存背景
    static Update(x1, y1, x2, y2) {
        ; 计算线条包围盒(确保覆盖整个线条区域)
        left := Min(x1, x2)
        top := Min(y1, y2)
        right := Max(x1, x2)
        bottom := Max(y1, y2)
        width := right - left + 1
        height := bottom - top + 1

        ; 创建内存DC和位图用于保存背景
        hMemDC := DllCall("CreateCompatibleDC", "ptr", this.hdc, "ptr")
        hBitmap := DllCall("CreateCompatibleBitmap", "ptr", this.hdc, "int", width, "int", height, "ptr")
        hOldBitmap := DllCall("SelectObject", "ptr", hMemDC, "ptr", hBitmap, "ptr")

        ; 保存线条区域的原始背景
        DllCall("BitBlt", 
            "ptr", hMemDC, "int", 0, "int", 0, 
            "int", width, "int", height, 
            "ptr", this.hdc, "int", left, "int", top, 
            "uint", 0x00CC0020)  ; SRCCOPY: 复制源像素

        ; 绘制线条
        DllCall("MoveToEx", "ptr", this.hdc, "int", x1, "int", y1, "ptr", 0, "int")
        DllCall("LineTo", "ptr", this.hdc, "int", x2, "int", y2, "int")

        ; 保存线条信息及背景数据(用于清除)
        this.lines.Push([x1, y1, x2, y2, hBitmap, hMemDC, hOldBitmap, left, top, width, height])
    }

    ; 清除所有线条(恢复原始背景)
    static Clear() {
        if (this.lines.Length = 0)
            return

        for line in this.lines {
            ; 从数组中解析数据
            x1 := line[1], y1 := line[2], x2 := line[3], y2 := line[4]
            hBitmap := line[5], hMemDC := line[6], hOldBitmap := line[7]
            left := line[8], top := line[9], width := line[10], height := line[11]

            ; 将保存的背景复制回屏幕(覆盖线条)
            DllCall("BitBlt", 
                "ptr", this.hdc, "int", left, "int", top, 
                "int", width, "int", height, 
                "ptr", hMemDC, "int", 0, "int", 0, 
                "uint", 0x00CC0020)  ; SRCCOPY: 恢复原始像素

            ; 清理内存DC资源
            DllCall("SelectObject", "ptr", hMemDC, "ptr", hOldBitmap, "ptr")
            DllCall("DeleteObject", "ptr", hBitmap)
            DllCall("DeleteDC", "ptr", hMemDC)
        }

        ; 清空线条记录
        this.lines := []
    }

    ; 清理资源
    static __Delete() {
        ; 确保退出前清除所有线条
        this.Clear()
        
        ; 恢复原始画笔
        DllCall("SelectObject", "ptr", this.hdc, "ptr", this.hOldPen, "ptr")
        
        ; 释放画笔和DC
        DllCall("DeleteObject", "ptr", this.hPen)
        DllCall("ReleaseDC", "ptr", 0, "ptr", this.hdc)
    }
}
