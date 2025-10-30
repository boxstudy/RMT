#Requires AutoHotkey v2.0

class LineOverlay {
    static hwnd := 0
    static hdc := 0
    static memDC := 0
    static bmp := 0
    static oldBmp := 0

    static Init() {
        if this.hwnd
            return

        curGui := Gui("-Caption +AlwaysOnTop +ToolWindow +E0x20") ; 鼠标穿透
        curGui.BackColor := "000000"
        WinSetTransColor("000000", curGui)

        curGui.Show("x0 y0 w" A_ScreenWidth " h" A_ScreenHeight)
        this.hwnd := curGui.Hwnd

        this.hdc := DllCall("GetDC", "ptr", this.hwnd, "ptr")
        this.memDC := DllCall("CreateCompatibleDC", "ptr", this.hdc, "ptr")
        this.bmp := DllCall("CreateCompatibleBitmap", "ptr", this.hdc, "int", A_ScreenWidth, "int", A_ScreenHeight,
            "ptr")
        this.oldBmp := DllCall("SelectObject", "ptr", this.memDC, "ptr", this.bmp, "ptr")
    }

    static Clear() {
        ; 用透明色画满内存位图 (SRCERASE 或 0x00)
        DllCall("Gdi32.dll\PatBlt", "ptr", this.memDC
            , "int", 0, "int", 0
            , "int", A_ScreenWidth, "int", A_ScreenHeight
            , "uint", 0x00000042) ; PATINVERT OR CLEAR

        this.Flush()
    }

    static Flush() {
        DllCall("BitBlt", "ptr", this.hdc, "int", 0, "int", 0, "int", A_ScreenWidth, "int", A_ScreenHeight, "ptr", this
            .memDC, "int", 0, "int", 0, "uint", 0x00CC0020)
    }

    static DrawLine(x1, y1, x2, y2
        , lineColor := 0x00FF00, lineWidth := 3
        , strokeColor := 0x3a88f5, strokeWidth := 1) {

        ; === 1️⃣ 描边线（先画更粗） ===
        if (strokeWidth > 0) {
            strokePen := DllCall("CreatePen"
                , "int", 0
                , "int", lineWidth + strokeWidth * 2
                , "uint", strokeColor
                , "ptr")

            oldStroke := DllCall("SelectObject", "ptr", this.memDC, "ptr", strokePen, "ptr")
            DllCall("MoveToEx", "ptr", this.memDC, "int", x1, "int", y1, "ptr", 0)
            DllCall("LineTo", "ptr", this.memDC, "int", x2, "int", y2)

            DllCall("SelectObject", "ptr", this.memDC, "ptr", oldStroke)
            DllCall("DeleteObject", "ptr", strokePen)
        }

        ; === 2️⃣ 主线 ===
        pen := DllCall("CreatePen"
            , "int", 0
            , "int", lineWidth
            , "uint", lineColor
            , "ptr")

        oldPen := DllCall("SelectObject", "ptr", this.memDC, "ptr", pen, "ptr")
        DllCall("MoveToEx", "ptr", this.memDC, "int", x1, "int", y1, "ptr", 0)
        DllCall("LineTo", "ptr", this.memDC, "int", x2, "int", y2)

        DllCall("SelectObject", "ptr", this.memDC, "ptr", oldPen)
        DllCall("DeleteObject", "ptr", pen)

        this.Flush()
    }
}
