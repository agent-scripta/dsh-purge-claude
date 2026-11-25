# dsh-purge-claude —— CC 适配版合集

`dsh-purge`（DeepSeek Harness 破甲插件 / 小码酱提示词体系）的 Claude Code / ClaudeCN 适配版合集。

本仓库含三个来源版本，各自独立、命令名同为 `purge`（同一容器只能装其中一个）：

| 子目录 | 源版本/来源 | 插件版本 | 说明 |
|---|---|---|---|
| `dsh-purge-share-claude/` | dsh-purge v1.1.93（share） | 1.1.93-cc.1 | 6 档 + cyber-risk 注入 |
| `dsh-purge-evans-claude/` | Evans-repo v1.1.72（基于 dsh-purge 1.1.71） | 1.1.72-cc.1 | 6 档 + cyber-risk 注入 |
| `dsh-purge-kingcharleslzy-claude/` | dsh-purge v1.7.20（kingcharleslzy-ai 社区版，DSH-Go） | 1.7.20-cc.1 | 11 命令 + 23 红队技能 + 88 补丁→CC + 切档联动 agent |

每个子目录是一个完整的 plugin marketplace 根，安装方式见各自 README。

- 通用机制：bun preload 注入 + plugin commands + SessionStart 自愈 + 服务端 cyber-risk 系统提示。
- 切档联动：切档自动同步 agent（红队→5 个 rt 执行角色，其它档→单个 little-code-sauce）。
