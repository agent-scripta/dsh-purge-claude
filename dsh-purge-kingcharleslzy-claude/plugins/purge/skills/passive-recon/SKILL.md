---
name: passive-recon
description: "被动信息收集：不接触目标主机，仅使用公开数据源"
---
> 角色：recon　适用：需要在不暴露自身的情况下收集目标资产情报时
> **CC 适配**：本技能原版工具已改为 `rt` 命令。
>
> - 工具：`rt <工具名> '<json>'`（Bash，如 `rt asset-add '{...}'`），`rt --list` 看全部，参数也可 `k=v`
> - 环境：`rt preflight` 查状态（返回 `root`/`engagements`/`current`）；`rt platform-config-get` 配工具箱/VPS；`rt platform-assign-toolkit` 指定工具箱目录
> - 路径：工具箱 `$REDTEAM_TOOLKIT` 或 `~/.claude/redteam/toolkit/`（原 `${REDTEAM_TOOLKIT:-$HOME/.claude/redteam/toolkit}`）；数据 `$REDTEAM_HOME` 或 `<插件>/.redteam-data`（原 `${REDTEAM_HOME:-$HOME/.claude/redteam}`）；凭据 `~/.claude/redteam/.env`（原 `$HOME/.claude/redteam/.env`）
> - 差异：原版 `onboarding.complete`/`setup.sh` 自动下载在本环境不存在，工具二进制需用户自行放置到工具箱目录






## 数据源
- 证书透明日志（crt.sh）：`curl -s "https://crt.sh/?q=%25.<domain>&output=json" | jq -r '.[].name_value' | sort -u`
- DNS 记录：`dig +short <domain> A/AAAA/MX/TXT/NS`
- whois：注册人、网段、ASN
- 搜索引擎与代码托管平台：泄露的子域、密钥、内部地址
- 公开端口测绘数据（Shodan/Censys/FOFA 等，需授权 API）

## 落库要求
每条发现调用 rt asset-upsert，provenance 固定为 `passive`，tool 记录具体数据源。


