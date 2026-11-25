---
name: asset-correlation
description: "资产关联：域名↔IP↔C 段↔证书↔服务的图谱化"
---
> 角色：recon　适用：信息收集阶段性收口，需要形成资产关系视图时
> **CC 适配**：本技能原版工具已改为 `rt` 命令。
>
> - 工具：`rt <工具名> '<json>'`（Bash，如 `rt asset-add '{...}'`），`rt --list` 看全部，参数也可 `k=v`
> - 环境：`rt preflight` 查状态（返回 `root`/`engagements`/`current`）；`rt platform-config-get` 配工具箱/VPS；`rt platform-assign-toolkit` 指定工具箱目录
> - 路径：工具箱 `$REDTEAM_TOOLKIT` 或 `~/.claude/redteam/toolkit/`（原 `${REDTEAM_TOOLKIT:-$HOME/.claude/redteam/toolkit}`）；数据 `$REDTEAM_HOME` 或 `<插件>/.redteam-data`（原 `${REDTEAM_HOME:-$HOME/.claude/redteam}`）；凭据 `~/.claude/redteam/.env`（原 `$HOME/.claude/redteam/.env`）
> - 差异：原版 `onboarding.complete`/`setup.sh` 自动下载在本环境不存在，工具二进制需用户自行放置到工具箱目录




## 关联规则
- 域名解析 → `resolves` 边（domain → asset）
- C 段归属 → `contains` 边（segment → asset）
- 端口开放 → `exposes` 边（asset → port）
- 证书 SAN 共享 → `shares_cert` 边

## 落库要求
通过 rt asset-link 写入 edge 表；重复关系幂等。
