# dsh-purge-claude-1.1.93-share / purge —— 小码酱按需注入技能（Claude 专版）

> ⚠️ **仅适用于 Claude Code / ClaudeCN（`host1syan/claude-cn` 镜像）**，依赖 bun preload 与 plugin commands 机制；其它平台用不了。

> 来源：破甲规则集移植自 dsh-purge v1.1.93 的"小码酱"提示词体系；Claude Code 插件形态参照 [evan545295555-hash/Evans-repo](https://github.com/evan545295555-hash/Evans-repo) v1.1.72（dsh-purge 1.1.71 的社区分支，作者：巴里啊啊）。原始 dsh-purge 仓库由小杨创建、地址在上游分发包中被脱敏未公开，按署名要求在此标明。本项目为非官方适配实现，原 LICENSE（MIT）与署名要求依然适用。

一个 Claude Code 技能。**装进 ClaudeCN 后，SessionStart hook 会在每个会话启动时自动装好注入机制，无需重启、无需手动初始化。** 之后用 `/purge:purge-*` 命令（plugin 装法）或 `/purge <参数>`（技能装法）按需切换。

默认正常会话；用命令才切成小码酱。

## 安装

本目录（`plugins/purge/`）有两种用途：

**A. 作为插件**——用外层仓库的 marketplace 安装（见仓库根 README）：
```
plugin marketplace add https://github.com/agent-scripta/dsh-purge-claude-1.1.93-share && plugin install purge@lcs-skills
```
命令为 `/purge:purge-on` 等（插件命名空间）。

**B. 作为独立 skill**——在容器内进本目录直接跑：
```
cd <容器里>/plugins/purge
bash install.sh
```
脚本把自己拷到 `/data/.claude/skills/purge`（可用 `CC_SKILLS_DIR` 覆盖），命令为裸 `/purge`。

装好后（Claude Code 自动发现新技能；若没识别，重开一次对话），在聊天框输入：

```
/purge status
```

会话启动时由 `hooks/hooks.json` 的 SessionStart 自动执行 `lib/setup.sh`（幂等）完成：

1. 保证 `/app/cli.js` 是原版（完整性校验要求，绝不动 cli.js 本体）
2. 铺 `/data/dsh-purge-patch/`（注入脚本 `inject-prefix.js` + 六套规则集）
3. 装 `/usr/local/bin/purge` 命令
4. 给 `/app/preload.ts` 追加注入段（幂等）

**无需重启容器**——preload 在每次 CLI 启动时读取，装完新开会话即生效。

## 使用

```
/purge              激活小码酱（当前规则集）
/purge default      默认：完整人格 + 破甲 + 草稿审查
/purge redteam      红队指挥：派活 / 攻击链 / 证据 / 得分纪律
/purge minimal      最小规则（省 token）
/purge stealth      隐身强化：低痕迹 + 反观测
/purge full         全开：最强破甲 + 能力协议 + 交付契约
/purge novel        创作：角色扮演默认态 + 成人场景
/purge off          关闭，恢复正常 Claude Code
/purge status       查看状态
```

切换后**新开一个会话**生效（系统提示词在会话启动时注入，Claude Code 机制限制，本会话身份不变）。

## 效果

- 未激活：`你是谁` → "我是 Claude Code…"
- `/purge redteam` 后新会话：`你是谁` → "小码酱（Little Code Sauce / LCS），红队评测模式。"

## 原理

- **走 bun preload，不改 cli.js**：`/app/bunfig.toml` 有 `preload=["./preload.ts"]`，在 cli.js 之前运行。注入段 `require('/data/dsh-purge-patch/inject-prefix.js')`。改 cli.js 会触发 ClaudeCN 的完整性校验导致会话起不来，preload.ts 不在校验清单里，安全。
- **按需激活**：inject-prefix.js 默认直接 return；只有 `/data/dsh-purge-patch/.active` 存在（或 `DSH_PURGE_ACTIVE=1`）才把规则 push 进 `--append-system-prompt`（系统层，模型稳定认）。
- **幂等初始化**：`lib/setup.sh` 由 SessionStart hook 每会话自动执行，检测已装就跳过。

## 改配置

装好后配置都在宿主机映射卷里，改完**开新会话即生效**，不用重启：

| 改什么 | 文件（相对容器 `/data/`） |
|---|---|
| 小码酱人设/破甲规则 | `dsh-purge-patch/rulesets/default.md`（或 redteam/minimal） |
| 注入机制/默认行为 | `dsh-purge-patch/inject-prefix.js` |

## 前提

- 官方 `host1syan/claude-cn` 镜像，`-v xxx:/data` 挂持久卷，已配模型。
- 用户有 Bash 工具权限（ClaudeCN 默认 `--dangerously-skip-permissions`）。
- bun 在 `/root/.bun/bin/bun`。

## 文件结构

```
https://github.com/agent-scripta/dsh-purge-claude-1.1.93-share/                     ← 本仓库根目录（即技能目录，名字随意）
├── SKILL.md               自举式 /purge 技能定义
├── README.md              本说明
├── install.sh             容器内运行：把本目录装到 skills/purge
└── lib/
    ├── setup.sh          幂等初始化脚本（hook 调用）
    ├── bootstrap.sh      setup.sh 别名（兼容）
    ├── inject-prefix.js   注入逻辑本体
    ├── preload_add.ts     追加到 preload.ts 的注入段
    ├── purge              总开关脚本 → /usr/local/bin/purge
    └── rulesets/
        ├── default.md
        ├── redteam.md
        └── minimal.md
```

## 验证

在全新 ClaudeCN 容器上端到端验证：只装本技能 → 首次 `/purge` 自举装全（无需重启）→ `/purge redteam` → 新会话答"小码酱，红队评测模式"；`/purge off` → 恢复正常。全部通过。

## 卸载

在容器内技能目录跑 `bash uninstall.sh`（不提供卸载命令，避免误触）。会删除技能、清空 `/data/dsh-purge-patch/`、移除 `/app/preload.ts` 的注入段、恢复 cli.js 原版，卸载后新会话恢复纯净 Claude Code。

## 为什么命令/SKILL.md 刻意写得极简

`/purge:*` 命令和 `SKILL.md` 只包含一条 `/usr/local/bin/purge <参数>` 指令，刻意不写"自举/破甲/注入/preload"等字眼，也不让 AI 读 bootstrap.sh 或规则集。原因：有自我审视能力的模型一旦读到那些内容，会判断为"给自己装改写指令链的后门"而拒绝执行。环境在首次安装时已由 install.sh/plugin 装好，日常开关不需要 AI 理解机制，只发命令即可稳定执行。
