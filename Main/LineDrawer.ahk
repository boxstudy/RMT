#Requires AutoHotkey v2.0

class LineDrawer {
    static hdc := 0                ; 屏幕设备上下文
    static lines := []             ; 存储线条及对应背景数据
    ; 样式默认值
    static lineColor := 0x00FF00   ; 线条颜色(默认红色)
    static lineWidth := 2          ; 线条宽度(默认2px)
    static strokeColor := 0x000000 ; 描边颜色(默认白色)
    static strokeWidth := 1        ; 描边宽度(默认1px)

    ; 初始化GDI资源
    static __New() {
        this.hdc := DllCall("GetDC", "ptr", 0, "ptr")
    }

    ; 设置线条样式
    ; color: 线条颜色(0x00BBGGRR)
    ; width: 线条宽度(像素)
    ; strokeColor: 描边颜色(0x00BBGGRR)
    ; strokeWidth: 描边宽度(像素)
    static setStyle(color := "", width := "", strokeColor := "", strokeWidth := "") {
        if (color != "")
            this.lineColor := color
        if (width != "")
            this.lineWidth := width
        if (strokeColor != "")
            this.strokeColor := strokeColor
        if (strokeWidth != "")
            this.strokeWidth := strokeWidth
    }

    ; 绘制线条(带描边)并保存背景
    static Update(x1, y1, x2, y2) {
        ; 计算总包围盒(包含线条和描边的完整区域)
        totalWidth := this.lineWidth + 2 * this.strokeWidth
        left := Min(x1, x2) - totalWidth
        top := Min(y1, y2) - totalWidth
        right := Max(x1, x2) + totalWidth
        bottom := Max(y1, y2) + totalWidth
        widthBox := right - left + 1
        heightBox := bottom - top + 1

        ; 创建内存DC保存背景
        hMemDC := DllCall("CreateCompatibleDC", "ptr", this.hdc, "ptr")
        hBitmap := DllCall("CreateCompatibleBitmap", "ptr", this.hdc, "int", widthBox, "int", heightBox, "ptr")
        hOldBitmap := DllCall("SelectObject", "ptr", hMemDC, "ptr", hBitmap, "ptr")

        ; 保存原始背景
        DllCall("BitBlt", 
            "ptr", hMemDC, "int", 0, "int", 0, 
            "int", widthBox, "int", heightBox, 
            "ptr", this.hdc, "int", left, "int", top, 
            "uint", 0x00CC0020)  ; SRCCOPY

        ; 1. 先绘制描边(更粗的背景色线条)
        if (this.strokeWidth > 0) {
            hStrokePen := DllCall("CreatePen", "int", 0, "int", this.lineWidth + 2 * this.strokeWidth, "uint", this.strokeColor, "ptr")
            hOldStrokePen := DllCall("SelectObject", "ptr", this.hdc, "ptr", hStrokePen, "ptr")
            DllCall("MoveToEx", "ptr", this.hdc, "int", x1, "int", y1, "ptr", 0, "int")
            DllCall("LineTo", "ptr", this.hdc, "int", x2, "int", y2, "int")
            DllCall("SelectObject", "ptr", this.hdc, "ptr", hOldStrokePen, "ptr")
            DllCall("DeleteObject", "ptr", hStrokePen)
        }

        ; 2. 再绘制主线条(覆盖在描边上)
        hLinePen := DllCall("CreatePen", "int", 0, "int", this.lineWidth, "uint", this.lineColor, "ptr")
        hOldLinePen := DllCall("SelectObject", "ptr", this.hdc, "ptr", hLinePen, "ptr")
        DllCall("MoveToEx", "ptr", this.hdc, "int", x1, "int", y1, "ptr", 0, "int")
        DllCall("LineTo", "ptr", this.hdc, "int", x2, "int", y2, "int")
        DllCall("SelectObject", "ptr", this.hdc, "ptr", hOldLinePen, "ptr")
        DllCall("DeleteObject", "ptr", hLinePen)

        ; 保存线条信息(包含当前样式参数)
        this.lines.Push([
            x1, y1, x2, y2, 
            hBitmap, hMemDC, hOldBitmap, 
            left, top, widthBox, heightBox,
            this.lineColor, this.lineWidth,
            this.strokeColor, this.strokeWidth
        ])
    }

    ; 清除所有线条
    static Clear() {
        if (this.lines.Length = 0)
            return

        for line in this.lines {
            hBitmap := line[5], hMemDC := line[6], hOldBitmap := line[7]
            left := line[8], top := line[9], width := line[10], height := line[11]

            ; 恢复原始背景
            DllCall("BitBlt", 
                "ptr", this.hdc, "int", left, "int", top, 
                "int", width, "int", height, 
                "ptr", hMemDC, "int", 0, "int", 0, 
                "uint", 0x00CC0020)

            ; 清理资源
            DllCall("SelectObject", "ptr", hMemDC, "ptr", hOldBitmap, "ptr")
            DllCall("DeleteObject", "ptr", hBitmap)
            DllCall("DeleteDC", "ptr", hMemDC)
        }
        this.lines := []
    }

    ; 清理资源
    static __Delete() {
        this.Clear()
        if (this.hdc)
            DllCall("ReleaseDC", "ptr", 0, "ptr", this.hdc)
    }
}