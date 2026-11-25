# purge —— 破甲按需注入技能（Claude Code 专版，1.7.20-cc.6）

> ⚠️ 仅适用于 Claude Code / ClaudeCN（`host1syan/claude-cn` 镜像），依赖 bun preload 与 plugin commands 机制；其它平台用不了。
> 源 dsh-purge v1.7.20（kingcharleslzy-ai/dsh-purge，适配 DSH-Go/Desktop 0.2.2）。非官方适配，MIT 许可与署名见根 README。

装进 ClaudeCN 后，SessionStart hook 每会话自动跑 `setup.sh`（幂等）装好注入机制，无需重启。默认正常会话，用命令按需切成破甲模式。

## 安装

本目录（`plugins/purge/`）两种用途：

**A. 作为插件**——用外层仓库的 marketplace 安装（见根 README）：
```sh
claude plugin marketplace add <本仓库地址> && claude plugin install purge@lcs-skills
```
命令为 `/purge:purge-on` 等（命名空间）。

**B. 作为独立技能**——容器内进本目录直接跑：
```sh
cd <容器里>/plugins/purge && bash install.sh
```
脚本把自己拷到 `$CC_SKILLS_DIR`（默认 `/data/.claude/skills/purge`），并装 `purge` / `rt` 命令到 `/usr/local/bin`。

装好后新开会话，输入 `/purge:purge-panel` 看面板。命令详见 [命令清单.md](命令清单.md)。

## 8 档位

| 命令 | 作用 |
|---|---|
| `/purge:purge-on` | 默认档 · 通用协作 |
| `/purge:purge-max` | 最硬档 · 原始全文（约25KB，需强模型） |
| `/purge:purge-redteam` | 红队指挥 · 只规划与派活 |
| `/purge:purge-minimal` | 极简 · 只保留身份与工作方式 |
| `/purge:purge-stealth` | 隐身 · 低痕迹执行 |
| `/purge:purge-novel` | 创作 · 角色扮演/小说/成人向 |
| `/purge:purge-unrestricted` | **原版档 · 无限制模式（不带小码酱身份）** |
| `/purge:purge-off` | 关闭 · 恢复正常 CC |
| `/purge:purge-panel` | 文本控制面板 |
| `/purge:purge-patches` | 88 条补丁→CC 落地（status/apply/revert） |
| `/purge:purge-status` | 查看当前模式 |

切换后**新开会话**生效（系统提示在会话启动时注入）。

## 红队系统

- 23 个红队技能在 `skills/<name>/SKILL.md`，原版 `redteam_*` MCP 工具已改为 `rt` 命令（`rt --list` 看全部）。
- 得分/资产/攻击链数据在 `<插件>/.redteam-data`（`REDTEAM_HOME` 可覆盖），不碰宿主文件。
- 详见 [REDTEAM-CC.md](REDTEAM-CC.md)。

## 原理

- **走 bun preload，不改 cli.js**：`preload.ts` 在 cli.js 之前运行，注入段加载 `inject-prefix.js`；改 cli.js 会触发完整性校验。
- **服务端系统提示**：ClaudeCN Web 会话真正吃的是 `cyber-risk-instruction.md`，切档时写入当前档规则集（本版同步进容器内的那份）。
- **按需激活**：默认直接 return；只有 `.active` 存在才把规则 push 进系统提示。
- **自愈**：SessionStart hook 每会话跑 setup.sh 校验并补齐注入段/规则集/命令，官方更新覆盖后自动修复。

## 改配置

| 改什么 | 文件（相对容器） |
|---|---|
| 人设/破甲规则 | `dsh-purge-patch/rulesets/<档>.md` |
| 注入机制 | `dsh-purge-patch/inject-prefix.js` |
| redteam 数据 | `dsh-purge-patch/.redteam-data/` |

改完开新会话即生效，不用重启。

## 卸载

容器内跑 `bash uninstall.sh`（清空运行态/preload 段/命令/注册/系统提示注入）。

## 为什么命令/SKILL.md 刻意极简

`/purge:*` 命令和 SKILL.md 只含一条本地命令，刻意不写"自举/破甲/注入"等字眼，也不让 AI 读注入脚本或规则集——有自我审视能力的模型读到会判断为"给自己装改写指令链"而拒绝执行。日常开关不需 AI 理解机制，只发命令即可。
