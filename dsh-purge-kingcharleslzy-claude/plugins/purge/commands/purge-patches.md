---
description: 补丁落地 · 把原版 88 条补丁按语义转成 CC 配置（查看状态/应用/回滚）
allowed-tools: Bash
---

用 Bash 执行下面这条本地命令，把 `$ARGUMENTS` 原样放在末尾，只把输出原样回报，不要读其它文件、不要解释：

bash "$CLAUDE_PLUGIN_ROOT/lib/cc-patches.sh" $ARGUMENTS

参数：`status`（默认，只读查看）/ `apply`（生成 settings.json + 全权限启动脚本）/ `revert`（删除生成物）。
