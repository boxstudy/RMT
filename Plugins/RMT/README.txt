### RMT.dll 源码与编译

本目录 C# 源码（`Http.cs` / `Device.cs` / `AiAssist.cs` …）由项目内 `csc.exe` 自编译为 `RMT.dll`，
**无需**再开 Visual Studio 类库工程手动替换 DLL（与 AHK-XAML 的 BridgeUtil 同类做法）。

#### 一键编译

```powershell
cd Plugins\RMT
.\buildDll.ps1
```

或在仓库根目录：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File Plugins\RMT\buildDll.ps1 -NoPause
```

#### 运行时自动编译（开发）

主进程启动 `InitRMTHttpPlugin` 时：若某个 `.cs` 比 `RMT.dll` 新，或 DLL 不存在，
会调用 `EnsureRmtDll()` 用本机 `csc` 重新编译（脚本未编译打包时）。
打包发布（`A_IsCompiled`）只加载已有 `RMT.dll`，不再现场编译。

#### 引用

- `System.Net.Http`（Http / AiAssist）
- `System.Management`（Device）

#### AHK 调用

```ahk
RMT_ASM := CLR_LoadLibrary(A_ScriptDir "\Plugins\RMT\RMT.dll")
RMT_Http := RMT_ASM.CreateInstance("RMT.Http")
RMT_Ai   := RMT_ASM.CreateInstance("RMT.AiAssist")
```
