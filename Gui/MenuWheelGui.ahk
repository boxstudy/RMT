#Requires AutoHotkey v2.0

class MenuWheelGui {
    __new() {
        this.Gui := ""
        MenuIndex := 1

        ShowPosX := 540
        ShowPosY := 300
    }

    ShowGui(MenuIndex) {
        if (this.Gui != "") {
            this.Gui.Show()
        }
        else {
            this.AddGui()
        }
        this.Init(MenuIndex)
    }

    Init(MenuIndex) {
        this.MenuIndex := MenuIndex

    }

    AddGui() {
        MyGui := Gui(, "菜单轮")
        this.Gui := MyGui
        MyGui.SetFont("S11 W550 Q2", MySoftData.FontType)

        PosX := 120
        PosY += 40
        con := MyGui.Add("Button", Format("x{} y{} w100 h40", PosX, PosY), "确定")
        con.OnEvent("Click", (*) => this.OnBtnClick(1))

        MyGui.Show(Format("w{} h{}", 360, 180))
    }

    OnBtnClick(index) {
        MsgBox("!23")
    }
}
