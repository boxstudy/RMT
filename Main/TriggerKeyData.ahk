#Requires AutoHotkey v2.0

class TriggerKeyData {
    __New(Key) {
        this.Key := Key
        this.OriDownArr := []  ;按下触发
        this.OriLoosenArr := []    ;松开触发
        this.OriLoosenStopArr := []    ;松止
        this.OriTogArr := []   ;开关
        this.OriHoldArr := []  ;按长按
        this.HoldActionMap := Map()

        this.DownArr := []
        this.LoosenArr := []
        this.LoosenStopArr := []
        this.TogArr := []
        this.HoldArr := []

        this.InitState()
    }

    InitState() {
        this.IsSoftHotKey := false
        for index, value in MySoftData.SoftHotKeyArr {
            key := LTrim(value, "~")
            key := StrLower(key)
            if (this.Key == key) {
                this.IsSoftHotKey := true
                break
            }
        }
    }

    AddData(index) {
        tableItem := MySoftData.TableInfo[1]
        TriggerType := tableItem.TriggerTypeArr[index]
        if (TriggerType == 1)
            this.OriDownArr.Push(index)
        if (TriggerType == 2)
            this.OriLoosenArr.Push(index)
        if (TriggerType == 3)
            this.OriLoosenStopArr.Push(index)
        if (TriggerType == 4)
            this.OriTogArr.Push(index)
        if (TriggerType == 5)
            this.OriHoldArr.Push(index)
    }

    UpdataArr() {
        tableItem := MySoftData.TableInfo[1]
        this.DownArr := []
        this.LoosenArr := []
        this.LoosenStopArr := []
        this.TogArr := []
        this.HoldArr := []

        MyMouseInfo.UpdateInfo()
        this.UpdateArrByFront(this.OriDownArr, this.DownArr)
        this.UpdateArrByFront(this.OriLoosenArr, this.LoosenArr)
        this.UpdateArrByFront(this.OriLoosenStopArr, this.LoosenStopArr)
        this.UpdateArrByFront(this.OriTogArr, this.TogArr)
        this.UpdateArrByFront(this.OriHoldArr, this.HoldArr)
    }

    UpdateArrByFront(OriArr, ResArr) {
        tableItem := MySoftData.TableInfo[1]
        for index, value in OriArr {
            infoStr := tableItem.FrontInfoArr[value]
            if (infoStr == "")
                continue

            if (MyMouseInfo.CheckIfMatch(infoStr, false))
                ResArr.Push(value)
        }

        ; 如果没有找到任何符合条件的窗口
        if (ResArr.Length == 0) {
            for index, value in OriArr {
                if (tableItem.FrontInfoArr[value] == "")
                    ResArr.Push(value)
            }
        }
    }

    OnTriggerKeyDown() {
        this.UpdataArr()
        this.HandleSoftHotKeyDown()
        tableItem := MySoftData.TableInfo[1]
        for index, value in this.DownArr {
            if (index == 1 && SubStr(tableItem.TKArr[value], 1, 1) != "~")
                LoosenModifyKey(tableItem.TKArr[value])

            TriggerMacroHandler(1, value)
        }

        for index, value in this.LoosenStopArr {
            TriggerMacroHandler(1, value)
        }

        for index, value in this.TogArr {
            isWork := tableItem.IsWorkIndexArr[value]
            if (isWork) {       ;关闭开关
                MySubMacroStopAction(1, value)
                return
            }
            OnToggleTriggerMacro(1, value)
        }

        this.SetHoldTimeChecker()
    }

    OnTriggerKeyUp() {
        this.UpdataArr()
        this.HandleSoftHotKeyUp()
        tableItem := MySoftData.TableInfo[1]
        for index, value in this.LoosenArr {
            TriggerMacroHandler(1, value)
        }

        for index, value in this.LoosenStopArr {
            isWork := tableItem.IsWorkIndexArr[value]
            if (isWork) {
                workPath := MyWorkPool.GetWorkPath(tableItem.IsWorkIndexArr[value])
                MyWorkPool.PostMessage(WM_STOP_MACRO, workPath, 0, 0)
                return
            }
            KillTableItemMacro(tableItem, value)
        }

        this.DelHoldTimeChecker()
    }

    SetHoldTimeChecker() {
        tableItem := MySoftData.TableInfo[1]
        for _, value in this.HoldArr {
            isWork := tableItem.IsWorkIndexArr[value]
            if (isWork)
                continue
            if (this.HoldActionMap.Has(value))
                continue

            action := this.HoldTimeAction.Bind(this, value)
            SetTimer(action, -tableItem.HoldTimeArr[value])
            this.HoldActionMap.Set(value, action)
        }
    }

    DelHoldTimeChecker() {
        for key, value in this.HoldActionMap {
            SetTimer(value, 0)
        }
        this.HoldActionMap := Map()
    }

    HoldTimeAction(index) {
        tableItem := MySoftData.TableInfo[1]
        keyCombo := LTrim(tableItem.TKArr[index], "~")
        if (this.HoldActionMap.Has(index))
            this.HoldActionMap.Delete(index)

        if (AreKeysPressed(keyCombo))
            TriggerMacroHandler(1, index)
    }

    HandleSoftHotKeyDown() {
        if (!this.IsSoftHotKey)
            return

        if (this.Key == "wheelup" || this.Key == "wheeldown") {
            if (MyMouseInfo.CheckIfMatch("RMTv⎖⎖")) {
                MySlider.OnScrollWheel(this.Key)
            }

            if (MyMouseInfo.CheckIfMatch("RMT-FreePaste⎖⎖")) {
                MyFreePasteGui.OnScrollWheel(this.Key)
            }
        }

        isArrowKey1 := this.Key == "left" || this.Key == "right"
        isArrowKey2 := this.Key == "up" || this.Key == "down"
        isArrowKey := isArrowKey1 || isArrowKey2
        if (isArrowKey) {
            MyTargetGui.OnArrowKeyDown(this.Key)
        }

        if (this.Key == "lbutton") {
            if (MySoftData.SelectAreaAction != "") {
                SelectArea()
            }

            if (MySoftData.GetAreaAction != "") {
                OnGetSelectAreaDown(this.Key)
            }
        }
    }

    HandleSoftHotKeyUp() {
        if (!this.IsSoftHotKey)
            return

        if (this.Key == "lbutton") {
            if (MyMouseInfo.CheckIfMatch("RMT-Target⎖⎖")) {
                MyTargetGui.OnLButtonUp(this.Key)
            }

            if (MySoftData.GetAreaAction != "") {
                OnGetSelectAreaUp(this.Key)
            }
        }

        if (this.Key == "enter") {
            MyTargetGui.OnEnterUp(this.Key)
        }
    }
}
