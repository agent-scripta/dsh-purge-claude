# dsh-purge-kingcharleslzy-claude —— 破甲按需注入（Claude Code 适配版）

> 当前版本 **1.7.20-cc.1** · 源 dsh-purge **v1.7.20**（kingcharleslzy-ai/dsh-purge，适配 DSH-Go / Desktop 0.2.2）· 非官方 Claude Code / ClaudeCN 适配。
> 插件名与命令名仍是 `purge`（命令前缀 `/purge:purge-*`）。


## 怎么用（最快上手）

1. 装好后**新开一个会话**（默认正常会话，不自动破甲）。
2. 在聊天框**输入 `/`**，弹出命令列表，选 `purge` 相关命令；或直接打 `/purge <参数>`（如 `/purge redteam`）。
3. 切档后**再开新会话**生效；用 `/purge panel` 看当前档位和状态（只读、不切档）。
4. 想恢复正常 Claude Code，用 `/purge off`。

## 这是什么

把 dsh-purge 的"破甲"能力移植到 Claude Code / ClaudeCN：不改宿主源码，用 CC 原生机制（bun preload 注入 + plugin commands + SessionStart hook）实现。默认正常会话，用命令按需切成破甲模式。

**适用**：Claude Code / ClaudeCN（`host1syan/claude-cn` 镜像，bun preload + plugin commands）。其它平台（官方 Anthropic CC、DSH、Cursor）用不了——DSH 请用上游 [kingcharleslzy-ai/dsh-purge](https://github.com/kingcharleslzy-ai/dsh-purge)。

## 能力（1.7.20-cc.1）

| 模块 | 说明 |
|---|---|
| 8 档规则集 | on(default) / max(最硬) / redteam(红队指挥) / minimal / stealth / novel / **unrestricted(原版无限制，不带小码酱身份)** / off |
| 文本控制面板 | `/purge:purge-panel` —— CC 无侧栏整页 UI，用文本面板列状态/档位/命令 |
| 88 条补丁→CC | `/purge:purge-patches` —— 按语义转 CC 配置（A30 提示词→规则集 / B16 权限→settings+启动参数 / C5 钩子 / D25 CC原生 / E12 无对应物），详见 [CC-PATCHES.md](plugins/purge/CC-PATCHES.md) |
| 23 个红队技能 | `skills/<name>/SKILL.md`，覆盖收集→发现→利用→内网；原版 `redteam_*` 工具已改为 `rt` 命令 |
| redteam 得分系统 | `lib/redteam/` + `rt` 命令（61 子命令）：资产/漏洞/凭据/隧道/WebShell/得分/攻击链/POC 知识库 |
| 会话自愈 | SessionStart hook 跑 `setup.sh`，幂等铺注入+规则集+命令，官方更新覆盖后自动修复 |

## 安装

**方式一：plugin marketplace**（需有可访问的仓库地址）
```sh
claude plugin marketplace add <本仓库地址>
claude plugin install purge@lcs-skills
```

**方式二：容器内直接跑安装脚本**
```sh
cd <容器里>/plugins/purge && bash install.sh
```

装好后新开会话，输入 `/purge:purge-panel` 出面板。切换档位用 `/purge:purge-<档>`（如 `/purge:purge-unrestricted`），新开会话生效。

ClaudeCN 网页的"安装技能"只连内置市场，没有填任意 GitHub 地址的入口，需走上面的命令行。

## 命令一览

见 [命令清单.md](plugins/purge/命令清单.md)。速查：`/purge:purge-panel` / `patches` / `on` / `max` / `redteam` / `minimal` / `stealth` / `novel` / `unrestricted` / `off` / `status`。参数式 `/purge <档>` 等价。

## 来源与署名

- **破甲提示词**：dsh-purge v1.7.20（社区版 kingcharleslzy-ai/dsh-purge，小码酱 / Little Code Sauce 体系）+ 该版自带的 `unrestricted` 无限制人设。
- **插件形态参照**：evan545295555-hash/Evans-repo v1.1.72（dsh-purge 社区分支）。
- **原始作者**：dsh-purge 由小杨创建；本仓库为非官方适配实现。MIT 许可证与署名要求继续适用，详见 [LICENSE](LICENSE)。
- **适配线路**：原版改 DSH 宿主源码（86 条补丁）；本版改 CC 原生机制（preload 注入 / settings / hooks），两条路径不同，见 [适配说明.md](plugins/purge/适配说明.md) 与 [CC-PATCHES.md](plugins/purge/CC-PATCHES.md)。
- **redteam 系统**：`REDTEAM-CC.md` 说明技能/CLI 与原版 MCP 工具的映射。

## 项目结构

```
dsh-purge-claude/                    ← 本仓库根 = marketplace
├── .claude-plugin/marketplace.json
├── plugins/purge/                   ← 插件本体
│   ├── .claude-plugin/plugin.json
│   ├── SKILL.md                     参数式 /purge 技能
│   ├── commands/                    11 个 /purge:purge-* 命令
│   ├── hooks/hooks.json             SessionStart 自愈
│   ├── lib/
│   │   ├── setup.sh                幂等自举
│   │   ├── purge / panel.sh        开关 + 文本面板
│   │   ├── cc-patches.sh           88 补丁→CC 落地
│   │   ├── rt / rt.mjs             CC 原生 redteam 命令
│   │   ├── redteam-cli.mjs         redteam JSON CLI
│   │   ├── redteam/                得分/资产/攻击链逻辑
│   │   └── rulesets/               8 套规则集
│   ├── skills/<name>/SKILL.md       23 个红队技能（rt 原生）
│   ├── 命令清单.md / CC-PATCHES.md / REDTEAM-CC.md / 适配说明.md
│   └── install.sh / uninstall.sh
└── README.md / 适配说明.md
```
