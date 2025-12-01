#Requires AutoHotkey v2.0

class FolderPackager {
    ; 打包文件夹为二进制文件
    static PackFolder(folderPath, outputFile) {
        if !DirExist(folderPath)
            throw Error("文件夹不存在: " folderPath)

        ; 获取所有文件列表
        files := this._GetAllFiles(folderPath)
        totalFiles := files.Length

        ; 预计算总大小
        totalSize := 16 ; 头部大小
        for filePath in files {
            relativePath := StrReplace(filePath, folderPath "\")
            fileNameLen := StrPut(relativePath, "utf-8")
            fileSize := FileGetSize(filePath)
            totalSize += 4 + fileNameLen + 8 + fileSize ; 文件名长度 + 文件名 + 文件大小 + 文件数据
        }

        ; 创建主缓冲区
        mainBuffer := Buffer(totalSize)
        pos := 0

        ; 写入文件头
        header := this._CreateHeader()
        DllCall("RtlMoveMemory", "ptr", mainBuffer.ptr + pos, "ptr", header.ptr, "uint", header.Size)
        pos += header.Size

        ; 遍历文件夹并添加文件
        processedFiles := 0
        for filePath in files {
            relativePath := StrReplace(filePath, folderPath "\")
            fileChunk := this._AddFile(relativePath, filePath)

            ; 将文件块复制到主缓冲区
            DllCall("RtlMoveMemory", "ptr", mainBuffer.ptr + pos, "ptr", fileChunk.ptr, "uint", fileChunk.Size)
            pos += fileChunk.Size

            processedFiles++
        }

        ; 保存到文件
        FileOpen(outputFile, "w").RawWrite(mainBuffer)
        MsgBox("打包完成: " outputFile)

        return true
    }

    ; 解包二进制文件为文件夹
    static UnpackFile(packedFile, outputFolder, callback := "") {
        if !FileExist(packedFile)
            throw Error("打包文件不存在: " packedFile)

        if callback
            callback("开始解包文件: " packedFile)

        ; 读取二进制数据 - 修正这里
        file := FileOpen(packedFile, "r")
        fileSize := FileGetSize(packedFile)  ; 使用 FileGetSize 获取文件大小
        data := Buffer(fileSize)
        bytesRead := file.RawRead(data, fileSize)  ; 读取指定字节数
        file.Close()

        if bytesRead != fileSize
            throw Error("文件读取不完整，期望 " fileSize " 字节，实际读取 " bytesRead " 字节")

        ; 解析文件头
        headerInfo := this._ParseHeader(data)
        if !headerInfo
            throw Error("无效的打包文件格式")

        pos := headerInfo.endPos
        totalSize := data.Size
        processedSize := pos

        ; 创建输出文件夹
        DirCreate(outputFolder)

        ; 解析并提取文件
        fileCount := 0
        while pos < data.Size {
            fileInfo := this._ParseFile(data, pos)
            if !fileInfo
                break

            ; 创建子目录（如果需要）
            fileDir := outputFolder "\" fileInfo.dir
            if fileDir != outputFolder "\"
                DirCreate(fileDir)

            ; 写入文件
            outputPath := outputFolder "\" fileInfo.path
            FileOpen(outputPath, "w").RawWrite(fileInfo.data)

            pos := fileInfo.nextPos
            processedSize := pos
            fileCount++

            if callback {
                progress := Round((processedSize / totalSize) * 100)
                callback("解包进度: " progress "% - " fileInfo.path, progress)
            }
        }

        if callback
            callback("解包完成: " outputFolder " (共 " fileCount " 个文件)", 100)

        return true
    }

    static CheckPack(selectedFile) {
        tempPath := outputFolder := A_WorkingDir "\Temp"
        FolderPackager.UnpackFile(selectedFile, tempPath)
        if (!FileExist(tempPath "\使用说明&署名.txt")) {
            MsgBox("使用说明&署名文件不存在，请再完善使用说明&署名文件后，导出上传配置")
            return false
        }

        loop read, tempPath "\使用说明&署名.txt" {
            if (A_LoopReadLine == "(请在导出配置前，务必完善操作说明，该文件目录可下增加图片解释说明)[上传导出前请删除此行，否则判定没有完善使用说明]") {
                MsgBox("请在完善使用说明&署名文件后，导出上传配置")
                return false
            }
        }
        DirDelete(tempPath)
        return true
    }

    ; 私有方法
    static _CreateHeader() {
        header := Buffer(16)
        ; 文件标识符 (4字节)
        StrPut("RMPK", header, 4, "cp0")
        ; 时间戳 (8字节)
        NumPut("uint64", A_TickCount, header, 4)
        ; 版本号 (4字节)
        NumPut("uint", 1, header, 12)
        return header
    }

    static _ParseHeader(data) {
        ; 检查文件标识符
        if data.Size < 4 || StrGet(data, 4, "cp0") != "RMPK"
            return false

        return { endPos: 16 } ; 头部总长度
    }

    static _GetAllFiles(folderPath) {
        files := []
        loop files folderPath "\*", "R" {
            if !InStr(FileExist(A_LoopFileFullPath), "D")
                files.Push(A_LoopFileFullPath)
        }
        return files
    }

    static _AddFile(relativePath, filePath) {
        ; 文件头格式: [文件名长度(4字节)][文件名][文件大小(8字节)][文件数据]
        fileNameLen := StrPut(relativePath, "utf-8")
        nameBuffer := Buffer(fileNameLen)
        StrPut(relativePath, nameBuffer, "utf-8")

        fileData := FileRead(filePath, "RAW")

        chunk := Buffer(4 + fileNameLen + 8 + fileData.Size)
        NumPut("uint", fileNameLen, chunk, 0)           ; 文件名长度
        DllCall("RtlMoveMemory", "ptr", chunk.ptr + 4, "ptr", nameBuffer.ptr, "uint", fileNameLen) ; 文件名
        NumPut("uint64", fileData.Size, chunk, 4 + fileNameLen) ; 文件大小
        DllCall("RtlMoveMemory", "ptr", chunk.ptr + 4 + fileNameLen + 8, "ptr", fileData.ptr, "uint", fileData.Size) ; 文件数据

        return chunk
    }

    static _ParseFile(data, startPos) {
        if startPos + 12 > data.Size ; 至少需要文件名长度(4) + 文件大小(8)
            return false

        ; 读取文件名长度
        nameLen := NumGet(data, startPos, "uint")
        if startPos + 4 + nameLen + 8 > data.Size
            return false

        ; 读取文件名
        fileNameBuf := Buffer(nameLen)
        DllCall("RtlMoveMemory", "ptr", fileNameBuf.ptr, "ptr", data.ptr + startPos + 4, "uint", nameLen)
        fileName := StrGet(fileNameBuf, "utf-8")

        ; 读取文件大小
        fileSize := NumGet(data, startPos + 4 + nameLen, "uint64")

        ; 计算数据位置
        dataStart := startPos + 4 + nameLen + 8
        dataEnd := dataStart + fileSize

        if dataEnd > data.Size
            return false

        ; 提取文件数据
        fileData := Buffer(fileSize)
        DllCall("RtlMoveMemory", "ptr", fileData.ptr, "ptr", data.ptr + dataStart, "uint", fileSize)

        ; 分离目录和文件名
        splitPos := InStr(fileName, "\", , -1)
        if splitPos {
            fileDir := SubStr(fileName, 1, splitPos - 1)
            fileNameOnly := SubStr(fileName, splitPos + 1)
        } else {
            fileDir := ""
            fileNameOnly := fileName
        }

        return {
            path: fileName,
            dir: fileDir,
            name: fileNameOnly,
            data: fileData,
            nextPos: dataEnd
        }
    }
}
