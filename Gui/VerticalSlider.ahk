#Requires AutoHotkey v2.0

class VerticalSlider {
    __new() {
        this.tableItem := ""
        this.AreaCon := ""
        this.BarCon := ""
        this.AreaOverlay := ""
        this.BarOverlay := ""

        this.BaseOffsetY := 45      ;基础偏移值
        this.GuiHeight := 500       ;区域高度
        this.ContentHeight := ""    ;内容高度
        this.BarHeight := 500       ;滑动棒的高度
        this.BarMaxPosY := ""       ;滑动棒最大移动位置y
        this.CurBarPosY := ""       ;当前棒位置
        this.ShowSlider := false

        this.IsDragging := false
        this.DragOffsetPosY := 0      ;拖拽偏移位置Y
    }

    SetSliderCon(AreaCon, AreaOverlay, BarCon, BarOverlay) {
        this.AreaCon := AreaCon
        this.AreaOverlay := AreaOverlay
        this.BarCon := BarCon
        this.BarOverlay := BarOverlay
        this.BarOverlay.OnEvent("Click", this.OnDragBar.Bind(this))
    }

    SwitchTab(tableItem) {
        this.tableItem := tableItem
        this.ContentHeight := tableItem.UnderPosY - this.BaseOffsetY
        this.ContentHeight := 800
        this.ShowSlider := this.ContentHeight > this.GuiHeight
        this.AreaCon.Visible := this.ShowSlider
        this.BarCon.Visible := this.ShowSlider
        this.BarHeight := (this.GuiHeight / this.ContentHeight) * this.GuiHeight
        this.BarMaxPosY := this.GuiHeight - this.BarHeight
        this.CurBarPosY := this.tableItem.SliderValue * this.BarMaxPosY

        if (!this.ShowSlider)
            return

        this.AreaCon.GetPos(&Ax, &Ay, &Aw, &Ah)
        this.BarCon.GetPos(&Bx, &By, &Bw, &Bh)
        PosY := Ay + this.CurBarPosY
        this.BarCon.Move(Ax, PosY, , this.BarHeight)
        this.BarOverlay.Move(Ax - 2, PosY, , this.BarHeight)
    }

    OnValueChange() {
        ; ToolTip("fjei")
    }

    OnDragBar(*) {
        ToolTip("Clck")
        this.IsDragging := true
        MouseGetPos(&StartX, &StartY)
        this.BarOverlay.GetPos(&Bx, &By, &Bw, &Bh)
        this.DragOffsetPosY := StartY - By

        loop {
            Sleep(30)
            ; 如果鼠标左键释放，停止拖拽
            if (!GetKeyState("LButton")) {
                break
            }

            MouseGetPos(&CurrentX, &CurrentY)
            this.AreaCon.GetPos(&Ax, &Ay, &Aw, &Ah)
            this.BarOverlay.GetPos(&Bx, &By, &Bw, &Bh)
            NewY := CurrentY - this.DragOffsetPosY
            if (By != NewY) {
                ToolTip("123")
                ; 更新文本位置
                this.BarOverlay.Move(Ax - 2, NewY)
                this.BarCon.Move(Ax, NewY)
                this.CurBarPosY := NewY - Ay
                this.tableItem.SliderValue := this.CurBarPosY / this.BarMaxPosY
                this.tableItem.OffSetPosY := this.ContentHeight * this.tableItem.SliderValue + this.BaseOffsetY
                this.OnValueChange()
            }
        }
    }
}
