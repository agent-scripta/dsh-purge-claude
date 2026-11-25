---
name: redteam-setup
description: "CC 环境适配引导：用 rt preflight 查状态、rt platform-config 配工具箱与 VPS、核对技能可用，给出缺什么补什么的降级口径"
---
> 角色：plan　适用：用户第一次使用红队模式时；或 `rt preflight` 显示无靶标/工具箱未配置时；或用户说"环境没配好""工具装一下"
> **CC 适配**：原版工具已改为 `rt` 命令；`rt --list` 看全部子命令。数据根 `$REDTEAM_HOME`（默认 `<插件>/.redteam-data`），工具箱 `$REDTEAM_TOOLKIT`（默认 `~/.claude/redteam/toolkit/`）。

# 首次使用引导（CC 版 · 把环境一次配齐）

**触发条件**（满足任一即执行本技能）：
- `rt preflight` 返回 `engagements: []`（没建靶标）或 `current: null`；
- `rt platform-config-get` 里工具箱路径为空或不存在；
- 用户第一次进红队模式、或明确说"环境/工具没配好"。

**核心原则**：**一次性把话说完，一次要齐**。不要挤牙膏式反复找用户要东西——这是本引导存在的唯一理由。

## 一、先查状态（只读，不做任何改动）

```sh
rt preflight                 # {ok, root, engagements, current}
rt platform-config-get       # 工具箱目录 / VPS 配置
```

把结果按三条给用户：**能用什么 / 缺什么 / 缺的影响**。

## 二、建靶标（数据根自动建，不用 setup.sh）

```sh
rt engagement-open '{"name":"<单位名>","scope":["<CIDR>"]}'
```

CC 侧没有原版的 `setup.sh` 自动下载，**工具二进制需用户自行放到工具箱目录**。命令：

```sh
rt platform-assign-toolkit '{"dir":"<用户放工具的目录>"}'
```

告诉用户工具箱约定路径 `$REDTEAM_TOOLKIT`（默认 `~/.claude/redteam/toolkit/`），本包 23 个技能里写到的二进制（fscan/gogo/nmap/subfinder/suo5/chisel/frp 等）都从这里找；系统已有 (`nmap`/`ffuf`) 直接用 PATH 里的即可。

## 三、配密钥与 VPS（用户自己执行，不写进仓库）

- `FOFA_KEY`：用户自己设环境变量，或写进 `~/.claude/redteam/.env`（`chmod 600`）。
- VPS：用户自己提供 IP / SSH 私钥，写进同一 `.env`。

**红线**：key/私钥/口令**不要**写进仓库、**不要**贴进报告、**不要**出现在 `rt chain-add` 的 `tool` 字段里。

## 四、复核

```sh
rt preflight
rt platform-config-get
```

确认：`current` 已指向靶标、工具箱路径存在、密钥就绪。有缺的按"缺什么→怎么补→补完影响什么"一次说清。

## 五、降级口径

- 没工具箱：只用不依赖二进制的技能（被动情报、Web 指纹、接口未授权、社工话术等），扫描类技能降级为"给命令让用户自己在有工具的机器上跑"。
- 没 FOFA_KEY：用 crt.sh / 被动 DNS / 搜索引擎 / 备案信息，慢但够用。
- 没 VPS：先做不需要落地的成果（账号、数据、未授权），不搭隧道。

## 六、CC 与原版术语对照

| 原版 | CC |
|---|---|
| `$DSH_HOME/redteam` | `$REDTEAM_HOME`（默认 `<插件>/.redteam-data`） |
| `$DSH_HOME/redteam/toolkit` | `$REDTEAM_TOOLKIT`（默认 `~/.claude/redteam/toolkit/`） |
| `$DSH_HOME/.env` | `~/.claude/redteam/.env` |
| `onboarding.complete` / `setup.sh` | `rt preflight` / `rt platform-assign-toolkit`（无自动下载） |
| `redteam_*` MCP 工具 | `rt <工具名>` 命令 |
