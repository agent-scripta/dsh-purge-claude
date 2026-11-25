# redteam 得分/资产系统 · CC 适配说明

原版 dsh-purge 的 redteam 系统通过 DSH 宿主把 `ctx.redteam` 服务暴露给角色智能体（MCP 工具 `redteam_*`）。CC 没有这套宿主，本版改用两条路对齐能力：

## 1. 23 个红队技能（已就位）

`skills/<name>/SKILL.md` 共 23 个，从原版 `skills/redteam/` 逐字迁移，frontmatter 转成 CC 格式（`name` + `description`），原 `role` / `whenToUse` 保留为正文首行注记。装进 CC 后由宿主自动发现。涵盖：

- 信息收集：passive-recon / fofa-recon / recon-pipeline / active-scan / web-fingerprint / asset-correlation / browser-automation / kimi-webbridge
- 漏洞发现：nuclei-scan / dir-bruteforce / cn-proxy-pool / unauth-exploit
- 漏洞利用：credential-attack / shell-handler / vps-reverse-shell / webshell-toolkit
- 内网与隧道：suo5-tunnel / chisel-tunnel / frp-tunnel / fscan-intranet / gogo-intranet / lateral-movement
- 环境：redteam-setup

## 2. redteam 数据/得分 CLI（已就位）

`lib/redteam-cli.mjs` 把原版 `lib/redteam/store-core.js` 的 `dispatchAsync` 包装成命令行：**stdin 收一个 JSON 请求，stdout 回一个 JSON 响应**，op 协议与原版完全一致。数据在插件目录 `.redteam-data/`，`REDTEAM_HOME` 可改路径，不碰宿主文件。

调用方式（Bash 工具直接跑）：

```sh
CLI="<插件目录>/lib/redteam-cli.mjs"

echo '{"op":"bootstrap"}' | node "$CLI"                     # 初始化/列出靶标
echo '{"op":"openEngagement","name":"某单位","scope":["10.0.0.0/24"]}' | node "$CLI"
echo '{"op":"assets","engagement":"某单位"}' | node "$CLI"   # 资产库
echo '{"op":"scores","engagement":"某单位"}' | node "$CLI"   # 得分面板（25 项规则）
echo '{"op":"addScoreHit","engagement":"某单位","code":"<新规则code>","target":"ip:port","evidence":"结果"}' | node "$CLI"
echo '{"op":"scoreChain","engagement":"某单位"}' | node "$CLI" # 五阶段攻击链
echo '{"op":"scoreReport","engagement":"某单位"}' | node "$CLI" # 复现报告
```

得分 code 已按《突破入侵类得分规则（合并版）》重构为 25 项，旧 code（rce / webshell / server-shell 等）作废，先用 `scores` 看当前 code 再记分。

支持的 op（节选）：`bootstrap` / `openEngagement` / `activateEngagement` / `assets` / `asset` / `assetTest` / `assessAsset` / `vulns` / `addVuln` / `updateVuln` / `credentials` / `addCredential` / `tunnels` / `addTunnel` / `webshells` / `addWebshell` / `scores` / `addScoreHit` / `saveScorePoint` / `scoreChain` / `addChainStep` / `scoreReport` / `chain` / `graph` / `attackGraph` / `pocSearch` / `pocGet` / `pocSave` / `shotAdd` / `sessions` / `snapshot` / `report` 等。

## 3. 技能调用已改成 CC 原生 `rt` 命令

23 个技能正文里的 `redteam_*` 工具名已全部（110 处）改写为 `rt <工具名>`，`rt` 是装到 `/usr/local/bin/rt` 的 CC 原生命令，参数用 JSON 或 `k=v`，内部转成 `store-core` 的 dispatch op：

```sh
rt asset-add '{"ip":"10.0.0.1","provenance":"active","tool":"nmap"}'
rt asset-query '{"q":"10.0.0.1"}'
rt score-hit '{"code":"<新规则code>","target":"ip:port","evidence":"结果"}'
rt chain-add '{"title":"...","stage_code":"recon","stage":"recon","tool":"nmap -sV ...","result":"..."}'
rt --list          # 看全部 40+ 子命令
```

`engagement` 省略时自动取当前活跃靶标。技能正文顶部的"CC 调用"注记有同样说明。原来的 `redteam-cli.mjs`（stdin JSON）仍保留，用于脚本化批量调用。

## 4. 与原版的差异（对齐口径）

| 能力 | 原版 DSH | 本版 CC |
|---|---|---|
| 红队技能 | DSH skill-filesystem 加载 | `skills/<name>/SKILL.md` 自动发现 |
| 得分/资产服务 | `ctx.redteam` 进程级服务 + MCP 工具 | `redteam-cli.mjs` 命令行（同一 dispatch 协议/同一套 SQLite 数据结构） |
| 技能内提到的 `redteam_*` 工具名 | 直接可调用 | 用 `echo '{...}' \| node redteam-cli.mjs` 等价替代（技能正文的工具名是原版语义，按此映射） |
| 数据目录 | `$DSH_HOME/redteam` | `<插件目录>/.redteam-data`（`REDTEAM_HOME` 可覆盖） |

依赖闭合：`lib/redteam/` 20 个模块 + `lib/remove-tree.js` + `lib/path-boundary.js` 已全部随包，`store-core.js` / `score-rules.js` 在 Node 24 下导入通过，25 个得分点与全部计分函数可用。
