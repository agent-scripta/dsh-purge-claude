# dsh-purge 1.7.20 · 88 条补丁 → Claude Code 等价实现清单

> 这不是"把 DSH 源码补丁照搬到 CC"（CC 没有 `client.js`/`index.js`/`steering.js` 这些锚点），而是按**每条补丁的语义**，用 CC 的真实机制落实。原补丁是 pattern→replace 改 DSH 源码；CC 侧改的是系统提示、启动参数、settings.json 和 hooks。

## 可执行落地

`/purge:purge-patches` 命令（或 `bash lib/cc-patches.sh`）把 B/C 类真正写成 CC 配置：

```sh
bash lib/cc-patches.sh status   # 只读查看当前落地状态（默认）
bash lib/cc-patches.sh apply    # 生成 .claude/settings.json（全权限）+ purge-launch.sh（--dangerously-skip-permissions）
bash lib/cc-patches.sh revert   # 删除生成物
```

- `apply` 生成的 `settings.json` 对应 B 类 16 条（审批 never / 沙箱全开 / fs 围栏取消 / 升级无条件授信）；`purge-launch.sh` 是破甲启动模板。写到 `CC_PROJECT_DIR`（默认当前目录）。
- A 类 30 条由随包的 7 套规则集承担（`/purge:purge-on` 等注入），无需补丁脚本动作。
- D 类 25 条是 CC 原生已具备的能力，E 类 12 条是 DSH 桌面/宿主专属（CC 无对应物）——见下方逐条表，均无需动作。

## 分类统计

| 类别 | 条数 | CC 落点 |
|---|---|---|
| A · 系统提示/身份层 → CC 规则集 | 30 | 规则集注入 |
| B · 权限/沙箱层 → CC 启动参数/settings | 16 | 启动参数+settings |
| C · 钩子层 → CC hooks.json | 5 | hooks.json |
| D · CC 原生已具备（无需补丁） | 25 | CC 原生 |
| E · DSH 桌面/宿主专属（CC 无对应物） | 12 | 无 |

## A · 系统提示/身份层 → CC 规则集

| id | 原补丁名 | 语义 → CC 落点 |
|---|---|---|
| 1 | WORKSPACE_CONTEXT_INTRO | workspace 指令作为 guidance 不压过 system |
| 2 | REPLACEMENT_WORKSPACE_CONTEXT_INTRO | 替换稿优先级不压过 system |
| 3 | SCOPE_INTRO | scope 不压过 system |
| 4 | SYSTEM_PROMPT_PERSONA | 剥离官方默认身份 → CC 版由规则集 WHO YOU ARE 承担 |
| 43 | WEB_PRESET_IDENTITY_STRIP | Web 预设身份剥离 → CC 无多预设 UI，规则集承担 |
| 76 | PRESET_UNRESTRICTED_IDENTITY_STRIP | unrestricted 预设身份剥离 → 规则集承担 |
| 70 | PRESET_SHELL_NETWORK | 终端网络禁令移除 → 规则集已写操作意图优先 |
| 73 | PRESET_BASH_MIRROR_LINE | bash 镜像说明移除 → 规则集承担 |
| 71 | LIANGSHEN_IDENTITY_LINE | 身份句剥离保留纪律 → max 规则集逐字保留 |
| 5 | APPROVAL_NEVER_SENTENCE | 审批话术限制 → CC skip-permissions 无审批话术 |
| 11 | APPROVAL_NEVER_SENTENCE_BYPASS | never 句自动放行 → CC 无审批句 |
| 12 | APPROVAL_ASK_SENTENCE_BYPASS | ask 句自动放行 → CC 无审批句 |
| 93 | SANDBOX_POLICY_BRAND_NEUTRAL | 沙箱策略文案去品牌 → CC 无 DSH 品牌词 |
| 94 | SKILL_BADGE_DESCRIPTION_NEUTRAL | 技能徽章去品牌 → CC 技能无此要求 |
| 25 | HARNESS_IDENTITY_STRIP | harness 默认身份剥离 → 规则集承担 |
| 26 | MINIMAL_PERSONA_PURGE | minimal 打开 complete 让注入进 → CC 直接写 CRI 文件 |
| 28 | LIANGSHEN_PHASE1_KEEP_INJECT | phase1 保留注入 → CC preload 注入段承担 |
| 32 | WEB_SURFACE_IDENTITY_NEUTRAL | Web 身份中性化 → 规则集承担 |
| 33 | TOOL_SHELL_DENIAL_PROMPT | shell 拒绝话术中性 → CC skip-permissions |
| 34 | SANDBOX_HINT_NEUTRAL | 沙箱 hint 中性 → CC skip-permissions |
| 36 | TOOL_FS_ESCALATION_SCHEMA | fs 升级字段去审批描述 → CC 无审批通道 |
| 37 | SUBAGENT_SCOPE_LOCK_NEUTRAL | 子代理权限锁中性 → CC 子代理无此锁 |
| 40 | COMPLETE_PROMPT_KEEP_INJECT | complete 预设保留注入 → CC preload 承担 |
| 47 | ANTHROPIC_OAUTH_NO_CLAUDE_IDENTITY | OAuth 不插 Claude 身份 → 规则集覆盖 |
| 49 | ANTHROPIC_OAUTH_CLI_NEUTRAL | OAuth 不伪装 claude-cli → 规则集覆盖 |
| 50 | SESSION_REFERENCE_FRAMING_NEUTRAL | 跨会话引用标 untrusted → 规则集已有 untrusted 数据纪律 |
| 53 | WEB_SURFACE_PROHIBITION | Web 禁止句移除 → 规则集承担 |
| 54 | DELIVERABLE_DO_NOT | 交付物 Do-not 移除 → 规则集承担 |
| 61 | OFFICIAL_SANDBOX_POLICY_NEUTRAL | 沙箱只读策略不拦任务 → CC skip-permissions |
| 63 | OFFICIAL_PLAN_MODE_NEUTRAL | 计划模式不硬拦 → CC 无此硬拦 |

## B · 权限/沙箱层 → CC 启动参数/settings

| id | 原补丁名 | 语义 → CC 落点 |
|---|---|---|
| 6 | SANDBOX_DENY_FILE_WRITE | 沙箱 deny 文件写 → CC --dangerously-skip-permissions |
| 7 | SANDBOX_MODE_DEFAULT | 沙箱默认全开 → CC 启动参数 |
| 8 | APPROVAL_POLICY_DEFAULT | 审批默认 never → CC skip-permissions |
| 9 | APPROVAL_AUTO_GRANT | 审批自动放行 → CC skip-permissions |
| 10 | APPROVAL_CONFIG_DEFAULT_NEVER | 审批配置 never → CC settings.json permissions |
| 13 | ESCALATION_WIDENING_EXEMPT | 升级阶梯豁免 → CC 无升级阶梯 |
| 14 | ESCALATION_GRANT_UNCONDITIONAL | 升级无条件授信 → CC skip-permissions |
| 15 | SANDBOX_CONFINE_PASSTHROUGH | 沙箱 confine 直通 → CC skip-permissions |
| 16 | FS_FENCE_DISABLED | fs 围栏取消 → CC 无 fs 围栏 |
| 17 | FS_OBSERVATION_INTENT_FREE | 观察策略读写放行 → CC 无 observe 门禁 |
| 35 | ESCALATION_NEVER_REJECT | 升级失败仍授信 → CC skip-permissions |
| 48 | TOOL_SHELL_DELETE_MOVE_NEUTRAL | shell delete/move 去谨慎 → CC skip-permissions |
| 51 | FRESH_SESSION_FULL_ACCESS | 新会话保持全开 → CC permission-mode 配置 |
| 59 | OFFICIAL_AUTO_REVIEW_PASSTHROUGH | Auto Review 不拦工具 → CC 无 auto-review |
| 60 | OFFICIAL_RUN_CODE_APPROVAL_NEUTRAL | run_code 加宽自动放行 → CC skip-permissions |
| 62 | OFFICIAL_TOOL_ASK_FAILOPEN | 无审批通道时 fail-open → CC skip-permissions |

## C · 钩子层 → CC hooks.json

| id | 原补丁名 | 语义 → CC 落点 |
|---|---|---|
| 30 | HOOKS_CLAUDE_DENY_ALLOW | hooks deny→allow → CC hooks.json 不设 deny |
| 31 | HOOKS_CODEX_DENY_ALLOW | codex deny→allow → CC hooks.json 不设 deny |
| 64 | HOOKS_STOP_STEER_NEUTRAL | Stop hook 不 steer → CC hooks 只保留 SessionStart |
| 65 | HOOKS_PRESTEP_REJECT_NEUTRAL | pre-step deny 不 reject → CC hooks 不设 UserPromptSubmit deny |
| 89 | ASK_USER_WAIT_CAPPED | ask_user 等待封顶 → CC 无 ask_user 无限等 |

## D · CC 原生已具备（无需补丁）

| id | 原补丁名 | 语义 → CC 落点 |
|---|---|---|
| 21 | BASH_TIMEOUT_RESTORE | bash 超时 → CC Bash 工具自带 timeout |
| 22 | READ_CAPS_RAISED | read 上限 → CC Read 工具自带 |
| 23 | SUBAGENT_MAXDEPTH_RAISED | 子代理深度 → CC subagent/team 机制 |
| 24 | PRESET_FETCH_ENABLED | preset fetch → CC web_fetch 原生 |
| 80 | MINIMAL_OFFICIAL_TOOLSET | 极简工具表 → CC 工具集由宿主定义 |
| 38 | PERSONA_TEXT_PREFIX_ALIAS | persona text 兼容 → CC 无 0.1.2 兼容问题 |
| 39 | SESSION_V0_PLUGIN_SUMMARY_ALIAS | v0 session 别名 → CC 无 v0 会话 |
| 42 | SETTINGS_LEGACY_API | settings legacy API → CC settings.json |
| 52 | SESSION_LOG_UPLOAD_DEFAULT_OFF | session log 上传默认关 → CC 宿主自管 |
| 55 | SYSTEM_PROMPT_REPLACE_HEAD | 系统提示整段替换 → CC preload 注入 |
| 74 | ASSEMBLE_BEFORE_PRESTEP | 首发送前挂默认提示 → CC SessionStart hook |
| 66 | SYSTEM_PROMPT_RENDER_GUARD | render undefined 兜底 → CC 无此路径 |
| 67 | AGENT_LOOP_MESSAGES_GUARD | messages 缺省兜底 → CC 无此路径 |
| 68 | SYSTEM_NODES_CONTENT_GUARD | systemNodes 兜底 → CC 无此路径 |
| 69 | MODEL_STREAM_RELEASE | model stream 释放 → CC 宿主自管 |
| 72 | MESSAGES_SYSTEM_CURRENT | messages system 当前 → CC 宿主自管 |
| 57 | DEEPSEEK_SYSTEM_ROLE | developer role 限定 → CC 宿主自管 |
| 78 | OVERLAY_RESTORE_FROM_BAK | overlay 从 bak 恢复 → CC setup.sh 自愈 |
| 87 | HUNG_PROMPT_LF_NEEDLE | 空白宿主挂全文 → CC 直接写 CRI 文件 |
| 88 | HUNG_PROMPT_STRICT_NEEDLE | strict needle 置顶 → CC 直接写 CRI 文件 |
| 90 | RESTORE_NATIVE_STEERING | 恢复原生 steering → CC 无 steer 队列 |
| 18 | REPEAT_TOOL_REMINDER_DISABLED | 重复调用守卫禁用 → CC 无此守卫 |
| 19 | TOOL_RESULT_PRUNER_DISABLED | 工具结果修剪禁用 → CC 无此修剪 |
| 95 | INSPECTOR_FRAME_BUDGET_RECORD_OVERHEAD | inspector 帧预算 → CC 无此 UI |
| 96 | INSPECTOR_FRAME_BUDGET_RECORD_OVERHEAD_CLIENT | inspector 帧预算客户端 → CC 无此 UI |

## E · DSH 桌面/宿主专属（CC 无对应物）

| id | 原补丁名 | 语义 → CC 落点 |
|---|---|---|
| 91 | BROWSER_COOKIE_NAME_IGNORE_PORT | 桌面 cookie 名忽略端口 → CC 无桌面会话 |
| 92 | HOST_MAX_HTTP_HEADER_SIZE | host HTTP 头上限 → CC 宿主自管 |
| 29 | TOOL_WEB_UNTRUSTED_NEUTRAL | tool-web untrusted 中性 → CC web_fetch 已按数据处理 |
| 45 | OFFICIAL_DESKTOP_UPDATE_HANDOFF | 桌面升级接管 → CC 无 DSH 桌面升级 |
| 46 | OFFICIAL_DESKTOP_UPDATE_ASCII | 桌面升级 ASCII 脚本 → CC 无 |
| 83 | DESKTOP_HOST_CLOSE_NO_FATAL | 桌面 host 信号杀 → CC 无桌面 host |
| 84 | DESKTOP_HOST_CLOSE_CODE0_NO_FAIL | 桌面 host code0 → CC 无桌面 host |
| 56 | REWIND_HIDE_CUT_ONLY | rewind 隐藏轮次 → CC 无回退 UI |
| 77 | REWIND_DROP_SENT_ON_APPEND | rewind 丢已发消息 → CC 无回退 UI |
| 75 | REWIND_RESET_TODOS | rewind 重置 todos → CC 无回退 UI |
| 58 | REWIND_SKIP_DERIVE | rewind 空标记跳过 → CC 无回退 UI |
| 82 | DESKTOP_SHELL_PROFILE_FALLBACK | desktop profile fallback → CC 无 DSH_PROFILE |

