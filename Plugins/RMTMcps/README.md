# RMT MCP（RMTMcps.exe）

若梦兔 `.rmt` 配置的 MCP 工具说明。本目录的 `RMTMcps.exe` 是独立 stdio 服务：**不启动 RMT 主程序也能用**；启动 RMT 也不会自动拉起本服务。

| 路径 | 说明 |
|------|------|
| `RMTMcps.exe` | MCP 服务（打包产物，无需本机 Python） |
| `mcp.example.json` | Cursor / AstrBot 配置示例 |
| `README.md` | 本文件：工具清单 + 接入说明（内置 AI 读取下方标记段） |
| `workspaces/` | 解包临时区 |
| `output/` | 生成的 `.rmt` |

运行时以 MCP `tools/list` 为准；**改工具后只更新本文件（尤其标记段），不必改 `AiAssistUtil.ahk`。**

---

<!-- RMT_AI_PROMPT_BEGIN -->
## 内置 AI 能力参考（RMTMcps）

内置助手已能直接改当前打开的配置（`list_macros` / `read_macro` / `update_macro` / `add_macro`）。用户要改宏时必须调用这些工具，不要只口述步骤。下列 MCP 工具名供对照能力；不要假装已经调用了 `RMTMcps.exe`。

### 工具一览

| 工具 | 作用 |
|------|------|
| `parse_rmt` | 下载/读取 `.rmt`，解包到临时工作区，返回 `workspace_id` |
| `list_rmt_files` | 列出工作区内文件 |
| `read_rmt_file` | 读工作区某文件（可限 `max_chars`，默认约 12000） |
| `write_rmt_file` | 写/改工作区文件（易踩 INI/编码坑，优先用 `edit_rmt_macro`） |
| `explain_rmt` | 配置可读摘要（触发键、指令中文描述等） |
| `validate_rmt` | 校验合法性，返回分级问题清单 |
| `edit_rmt_macro` | 结构化增/删/改一条宏，并自动复校验 |
| `generate_rmt_config` | 按 JSON 规格生成并打包 `.rmt` |
| `pack_rmt` | 已编辑工作区重新打包为 `.rmt` |
| `list_rmt_outputs` | 列出 `output` 下已有 `.rmt` |
| `export_rmt_file` | 将 output 中文件导出为 base64（大包/沙盒发送） |
| `cleanup_rmt_workspace` | 清理：`workspace_id` / `all` / `expired` |

### 推荐流程

1. **解读已有配置**：`parse_rmt(source)` → `explain_rmt(workspace_id)` 或 `read_rmt_file` → 用完可 `cleanup_rmt_workspace`
2. **从零生成**：`generate_rmt_config(spec_json)`；小包看 `delivery.base64`；过大再 `export_rmt_file`
3. **改一条宏再打包**：`parse_rmt` → `edit_rmt_macro`（看 `validation`）→ `pack_rmt`
4. **只校验**：`validate_rmt(workspace_id=...)` 或 `validate_rmt(source=...)`

### 关键约定

- `setting_name` / `pack_rmt` 的 `output_name`：纯英文（字母数字下划线连字符）；中文标题放 `title`
- `module`：Symbol 或中文均可，如 `Normal` / `按键宏`、`String` / `字串宏`、`Timing` / `定时宏`
- 宏序号 `index` 为 **1-based**；`edit_rmt_macro` 的 `operation`：`update`（默认）/ `add` / `delete`
- `changes_json` / `commands` 可含：`trigger_key`、`remark`、`forbid`/`enabled`、`trigger_type`（1–6 或 按下/松开/松止/开关/长按/双击）、`mode`、`hold_time`、`loop_count`、`macro` 指令串或 `commands` 数组（二者优先 commands）
- 指令示例：`{"type":"key","key":"a","action":"点击","duration":100,"count":10,"interval":200}`；`{"type":"interval","ms":3000}`
- 使用说明字段：`bot_name`（作者）、`config_purpose`（配置作用）、`operation_instructions`（操作步骤），须中文且结合实际配置
- 沙盒与宿主机文件系统隔离时：不要对宿主机 `output/` 做 `cp`；用响应内 `delivery.base64` 或 `export_rmt_file`
<!-- RMT_AI_PROMPT_END -->

---

## Cursor / AstrBot 接入

1. 参考同目录 [mcp.example.json](mcp.example.json)：`command` 为 `./RMTMcps.exe`，`workspaces` / `output` 用相对路径。
2. **RMT / 与 exe 同目录启动**：工作目录设为本目录，相对路径即可。
3. **Cursor 全局** `%USERPROFILE%\.cursor\mcp.json`：可先试相对路径；若不生效再改成指向本目录的绝对路径。
4. Cursor：**Settings → MCP** 确认启用；必要时 Reload / 重启。
5. 验证：应能列出 `parse_rmt`、`pack_rmt` 等（命名空间多为 `user-rmt-mcp`，服务名 `rmt-mcp`）。

AstrBot 同理：`args` 为空数组，按需设 `env`。换机优先带整目录，相对路径不用改盘符。

### 环境变量

| 变量 | 默认（相对 exe 旁） | 含义 |
|------|---------------------|------|
| `RMT_MCP_WORK_ROOT` | `./workspaces` | 解包工作区根目录 |
| `RMT_MCP_OUTPUT_ROOT` | `./output` | 打包输出目录 |
| `RMT_MCP_TTL_HOURS` | `24` | 过期清理 TTL（小时） |

### 能力发现（外部宿主）

- 宿主启动 exe 后走 MCP `tools/list`，得到工具名、描述与参数 schema。
- 本文档供人读、Code Review、以及 **RMT 内置 AI**（读取上方标记段）离线了解能力；不必为「列工具」去启动 RMT 主程序。

---

## 工具参数详解

### parse_rmt

- **必填** `source`：HTTP(S) 链接或本地路径  
- **返回**：`workspace_id`、解包文件列表、使用说明摘要等

### list_rmt_files

- **必填** `workspace_id`

### read_rmt_file

- **必填** `workspace_id`、`relative_path`（如 `MacroFile.ini`、`使用说明&署名.txt`）
- **可选** `max_chars`（默认约 12000）

### write_rmt_file

- **必填** `workspace_id`、`relative_path`、`content`  
- 注意：直接改 INI 需处理 UTF-16、π 数组等长、FoldInfo JSON、Serial 唯一等；日常改宏优先 `edit_rmt_macro`

### explain_rmt

- **二选一**（优先 `workspace_id`）：`workspace_id` 或 `source`  
- **返回**：`total_macros`、`tab_count`、`tabs[]`（每条宏含 trigger / enabled / remark / commands 可读描述）

### validate_rmt

- **二选一**（优先 `workspace_id`）：`workspace_id` 或 `source`  
- **校验项摘要**：调用链死循环、页签字段齐全、触发键/按键名合法、指令类型与字段数、单宏指令过多（>1000 提醒）、分隔符/序列码/FoldInfo、数组等长与折叠框覆盖、定时宏结束时间、英文语系污染等  
- **返回**：`valid`、`summary`、`issues[]`（severity/code/message/location）、`stats`

### edit_rmt_macro

- **必填** `workspace_id`、`module`
- **可选** `index`（update/delete 必填）、`changes_json`、`operation`（`update`/`add`/`delete`）
- **返回**：`operation`、`module`、`macro_count`、`edited_macro`、`validation`

### generate_rmt_config

- **必填** `spec_json`（字符串）。核心字段示例：

```json
{
  "setting_name": "F6ClickA",
  "title": "F6连点A键10次",
  "bot_name": "小助手",
  "config_purpose": "按下F6后自动连续点击A键10次，减少重复操作。",
  "operation_instructions": "1. 在若梦兔中导入并启用本配置。\n2. 按下F6即可连续点击A键10次。",
  "macros": [
    {
      "module": "Normal",
      "trigger_key": "F6",
      "remark": "连点A",
      "forbid": false,
      "commands": [
        {"type": "key", "key": "a", "action": "点击", "duration": 100, "count": 10, "interval": 200},
        {"type": "interval", "ms": 3000}
      ]
    }
  ]
}
```

- 高级：`files.MacroFile.ini` 直接给完整 INI；`files.*` / `extra_files` 附加其它相对路径文件  
- 中文 `setting_name` 会被改写，见响应 `name_adjusted`  
- 小包响应常带 `delivery.base64` 与 `delivery.send_workflow`

### pack_rmt

- **必填** `workspace_id`  
- **可选** `output_name`（纯英文文件名，不含路径）

### list_rmt_outputs

- 无参数；列出 output 下全部 `.rmt`

### export_rmt_file

- **必填** `file_path`：`output_path` 或 output 下文件名  
- 仅当内联 `delivery.base64` 为 null（包过大）时需要

### cleanup_rmt_workspace

- **必填** `workspace_id`：具体 ID，或 `all`（清 workspaces + output 下 `.rmt`），或 `expired`（按 TTL）

---

## 沙盒发文件

AstrBot 等沙盒与宿主机文件系统隔离，**不要**对宿主机 `output/` 做 `cp`。  
小包用响应内联的 `delivery.base64`；大包先 `export_rmt_file` 再解码写入沙盒可写目录后发送。

---

## 维护

- **源码仓库中的发行文档模板是 `Release.README.md`**：增删工具、改参数说明、改 `RMT_AI_PROMPT` 标记段时，先改该文件，再同步到 `Release\README.md`（以及已拷贝的 `Dev\Plugins\RMTMcps\README.md`）。
- `.\build.ps1` 打包时会自动把 `Release.README.md`、`mcp.example.json` 复制进 `Release\`。
- 重新打包 exe 后：替换本目录 `RMTMcps.exe`，并核对本文（尤其 `RMT_AI_PROMPT` 标记段）是否仍一致。**无需改 AHK。**
- 内置 AI 只注入标记段；改标记段时注意控制长度（避免撑爆每次对话的 system prompt）。
- Python 源码可独立维护于其它目录；本目录只放 **exe + 配置示例 + 本文档**。
