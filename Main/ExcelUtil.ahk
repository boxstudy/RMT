#Requires AutoHotkey v2.0

ExcelCellToWrite(wbPath, sheetIdentifier, row, col, value) {
    try {
        xlWorkbook := ComObjGet(wbPath)
        xlApp := xlWorkbook.Application
        if (!xlApp.Visible) {
            xlWorkbook.Close()
            xlApp.Quit()
            xlApp := ComObject("Excel.Application")
            xlWorkbook := xlApp.Workbooks.Open(wbPath, 0, false)  ; 非只读模式打开
        }
        if (IsInteger(sheetIdentifier))
            sheetIdentifier := Integer(sheetIdentifier)
        sheet := xlWorkbook.Sheets(sheetIdentifier)
        sheet.Cells(row, col).Value := value
        xlWorkbook.Save()
        return true
    }
    catch as e {
        MsgBox "写入失败：" e.Message
        return false
    }
    finally {
        xlApp := xlWorkbook.Application
        if (!xlApp.Visible) {
            xlWorkbook.Close()
            xlApp.Quit()
        }
        xlWorkbook := ""
        xlApp := ""
    }
}

ExcelRowToWrite(wbPath, sheetIdentifier, col, value) {
    try {
        xlWorkbook := ComObjGet(wbPath)
        xlApp := xlWorkbook.Application
        if (!xlApp.Visible) {
            xlWorkbook.Close()
            xlApp.Quit()
            xlApp := ComObject("Excel.Application")
            xlWorkbook := xlApp.Workbooks.Open(wbPath, 0, false)  ; 非只读模式打开
        }
        if (IsInteger(sheetIdentifier))
            sheetIdentifier := Integer(sheetIdentifier)
        sheet := xlWorkbook.Sheets(sheetIdentifier)
        row := 1
        loop {
            if (sheet.Cells(A_Index, col).Text == "") {
                row := A_Index
                break
            }
        }
        sheet.Cells(row, col).Value := value
        xlWorkbook.Save()
        return true
    }
    catch as e {
        MsgBox "写入失败：" e.Message
        return false
    }
    finally {
        xlApp := xlWorkbook.Application
        if (!xlApp.Visible) {
            xlWorkbook.Close()
            xlApp.Quit()
        }
        xlWorkbook := ""
        xlApp := ""
    }
}

ExcelColToWrite(wbPath, sheetIdentifier, row, value) {
    try {
        xlWorkbook := ComObjGet(wbPath)
        xlApp := xlWorkbook.Application
        if (!xlApp.Visible) {
            xlWorkbook.Close()
            xlApp.Quit()
            xlApp := ComObject("Excel.Application")
            xlWorkbook := xlApp.Workbooks.Open(wbPath, 0, false)  ; 非只读模式打开
        }
        if (IsInteger(sheetIdentifier))
            sheetIdentifier := Integer(sheetIdentifier)
        sheet := xlWorkbook.Sheets(sheetIdentifier)
        col := 1
        loop {
            if (sheet.Cells(row, A_Index).Text == "") {
                col := A_Index
                break
            }
        }
        sheet.Cells(row, col).Value := value
        xlWorkbook.Save()
        return true
    }
    catch as e {
        MsgBox "写入失败：" e.Message
        return false
    }
    finally {
        xlApp := xlWorkbook.Application
        if (!xlApp.Visible) {
            xlWorkbook.Close()
            xlApp.Quit()
        }
        xlWorkbook := ""
        xlApp := ""
    }
}