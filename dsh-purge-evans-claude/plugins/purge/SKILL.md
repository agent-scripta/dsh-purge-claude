---
name: purge
description: 控制台（含文本面板）——模式切换：默认/最硬/红队/极简/隐身/创作/关闭/查看/面板
allowed-tools: Bash
---

用 Bash 执行这一条命令：`/usr/local/bin/purge $ARGUMENTS`，只把输出原样回报，不读其它文件。

模式参数对照（中文=参数）：
- 默认 = on
- 最硬 = max
- 红队 = redteam
- 极简 = minimal
- 隐身 = stealth
- 创作 = novel
- 关闭 = off
- 查看 = status
- 面板 = panel（纯文本控制面板）

## 怎么打开命令（用户看）

在聊天框**输入 `/`**，会弹出可用命令列表；找到 `purge` 相关命令即可选择。两种写法等价：

- **参数式**：`/purge <参数>`（如 `/purge redteam`）——本文件上方那条命令直接吃参数。
- **插件命令**：`/purge:purge-<参数>`（如 `/purge:purge-redteam`）——插件 commands 目录注册的命令。

可选参数：
- `on` — 默认档
- `max` — 最硬档
- `redteam` — 红队指挥
- `minimal` — 极简档
- `stealth` — 隐身档
- `novel` — 创作档
- `panel` — 文本控制面板
- `off` — 关闭
- `status` — 查看模式

切档后**新开会话**生效（系统提示在会话启动时注入）；`/purge panel` 只看状态不切档。
