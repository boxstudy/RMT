#Requires AutoHotkey v2.0

class VerticalSlider {
    __new() {
        this.tableItem := ""
        this.BaseOffsetY := 45      ;基础偏移值
        this.AeraHeight := 500       ;区域高度
        this.ContentHeight := ""    ;内容高度
        this.BarHeight := 500       ;滑动棒的高度
        this.BarMaxPosY := ""       ;滑动棒最大移动位置y
        this.CurBarOffsetPosY := ""       ;当前棒位置
        this.ShowSlider := false

        this.IsDragging := false
        this.DragOffsetPosY := 0      ;拖拽偏移位置Y
        this.DragAction := this.DragHandler.Bind(this)
    }

    ;内凹像素， 左边偏移（text左边点击不灵敏）
    SetStyleParams(Hindent, Vindent) {
        this.Hindent := Hindent
        this.Vindent := Vindent
        this.AreaCon.GetPos(&Ax, &Ay, &Aw, &Ah)
        this.AeraHeight := Ah - 2 * this.Vindent
    }

    SetSliderCon(AreaCon, BarCon) {
        this.AreaCon := AreaCon
        this.BarCon := BarCon
        this.BarCon.OnEvent("Click", this.OnDragBar.Bind(this))
        this.BindScrollHotkey("~WheelUp", this.OnScrollWheel.Bind(this))
        this.BindScrollHotkey("~WheelDown", this.OnScrollWheel.Bind(this))
        this.BindScrollHotkey("~+WheelUp", this.OnScrollWheel.Bind(this))
        this.BindScrollHotkey("~+WheelDown", this.OnScrollWheel.Bind(this))
    }

    SwitchTab(tableItem) {
        this.tableItem := tableItem
        this.ContentHeight := tableItem.UnderPosY - this.BaseOffsetY + 5
        this.BarHeight := ((this.AeraHeight + 2 * this.Vindent) / this.ContentHeight) * this.AeraHeight
        this.BarMaxPosY := this.AeraHeight - this.BarHeight
        this.CurBarOffsetPosY := this.tableItem.SliderValue * this.BarMaxPosY
        this.ShowSlider := this.ContentHeight > this.AeraHeight
        this.AreaCon.Visible := this.ShowSlider
        this.BarCon.Visible := this.ShowSlider
        if (!this.ShowSlider)
            return

        this.AreaCon.GetPos(&Ax, &Ay, &Aw, &Ah)
        this.BarCon.GetPos(&Bx, &By, &Bw, &Bh)
        PosY := Ay + this.CurBarOffsetPosY + this.Vindent
        this.BarCon.Move(Ax + this.Hindent, PosY, Aw - this.Hindent * 2, this.BarHeight)
    }

    RefreshTab() {
        this.ContentHeight := this.tableItem.UnderPosY - this.BaseOffsetY + 5
        this.BarHeight := ((this.AeraHeight + 2 * this.Vindent) / this.ContentHeight) * this.AeraHeight
        this.BarMaxPosY := this.AeraHeight - this.BarHeight
        this.CurBarOffsetPosY := this.tableItem.SliderValue * this.BarMaxPosY
        this.ShowSlider := this.ContentHeight > this.AeraHeight
        this.AreaCon.Visible := this.ShowSlider
        this.BarCon.Visible := this.ShowSlider
        if (!this.ShowSlider)
            return

        this.AreaCon.GetPos(&Ax, &Ay, &Aw, &Ah)
        this.BarCon.GetPos(&Bx, &By, &Bw, &Bh)
        PosY := Ay + this.CurBarOffsetPosY + this.Vindent
        this.BarCon.Move(Ax + this.Hindent, PosY, Aw - this.Hindent * 2, this.BarHeight)
        this.tableItem.OffSetPosY := (this.ContentHeight - this.AeraHeight - 2 * this.Vindent) * this.tableItem.SliderValue
        RefreshTabContent(this.tableItem, true)
    }

    OnValueChange(isDown) {
        RefreshTabContent(this.tableItem, isDown)
    }

    BindScrollHotkey(key, action) {
        HotIfWinActive("RMTv")
        Hotkey(key, action)
        HotIfWinActive
    }

    OnScrollWheel(*) {
        ;主界面评论范围不能滑动
        WinPosArr := GetWinPos()
        if (WinPosArr[1] >= 300 && WinPosArr[1] <= 600)
            if (WinPosArr[2] >= 35 && WinPosArr[2] <= 525)
                return

        isDown := InStr(A_ThisHotkey, "Down") ? true : false
        value := 80
        if ((value / this.BarMaxPosY) * (this.ContentHeight - this.AeraHeight - 2 * this.Vindent) >= 420) {
            value := (420 / (this.ContentHeight - this.AeraHeight - 2 * this.Vindent)) * this.BarMaxPosY
        }
        scrollValue := isDown ? value : -value
        this.AreaCon.GetPos(&Ax, &Ay, &Aw, &Ah)
        this.BarCon.GetPos(&Bx, &By, &Bw, &Bh)
        NewY := By + scrollValue
        NewY := Max(NewY, Ay + this.Vindent)
        NewY := Min(NewY, Ay + this.Vindent + this.BarMaxPosY)
        if (Integer(By) == Ceil(NewY) || Integer(By) == Floor(NewY))
            return
        this.BarCon.Move(Bx, NewY)
        this.CurBarOffsetPosY := NewY - Ay - this.Vindent
        this.tableItem.SliderValue := this.CurBarOffsetPosY / this.BarMaxPosY
        this.tableItem.OffSetPosY := (this.ContentHeight - this.AeraHeight - 2 * this.Vindent) * this.tableItem.SliderValue
        this.OnValueChange(isDown)
    }

    OnDragBar(*) {
        this.IsDragging := true
        MouseGetPos(&StartX, &StartY)
        this.BarCon.GetPos(&Bx, &By, &Bw, &Bh)
        this.DragOffsetPosY := StartY - By
        SetTimer(this.DragAction, 16)
    }

    DragHandler() {
        if (!GetKeyState("LButton") || !this.IsDragging) {
            this.IsDragging := false
            SetTimer(this.DragAction, 0)
            return
        }

        MouseGetPos(&CurrentX, &CurrentY)
        this.AreaCon.GetPos(&Ax, &Ay, &Aw, &Ah)
        this.BarCon.GetPos(&Bx, &By, &Bw, &Bh)
        NewY := CurrentY - this.DragOffsetPosY
        NewY := Max(NewY, Ay + this.Vindent)
        NewY := Min(NewY, Ay + this.Vindent + this.BarMaxPosY)
        isDown := NewY > By ? true : false
        if (Integer(By) == Ceil(NewY) || Integer(By) == Floor(NewY))
            return
        this.BarCon.Move(Bx, NewY)
        this.CurBarOffsetPosY := NewY - Ay - this.Vindent
        this.tableItem.SliderValue := this.CurBarOffsetPosY / this.BarMaxPosY
        this.tableItem.OffSetPosY := (this.ContentHeight - this.AeraHeight - 2 * this.Vindent) * this.tableItem.SliderValue
        this.OnValueChange(isDown)
    }
}
