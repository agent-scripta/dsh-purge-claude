#!/usr/bin/env bash
# dsh-purge 88 条补丁 → Claude Code 等价落地（可执行部分）
#
# 原版补丁是 pattern→replace 改 DSH 宿主源码（client.js/index.js/steering.js/hooks.js）。
# CC 没有这些锚点；本脚本按补丁语义用 CC 的真实机制落实：
#   A 类(30) 系统提示/身份 → 已由 lib/rulesets/*.md 覆盖（setup.sh 注入 CRI）
#   B 类(16) 权限/沙箱   → 本脚本生成 settings.json（全权限）+ launch.sh（skip-permissions）
#   C 类(5)  钩子        → 本脚本校验 hooks.json 只留 SessionStart，不设 deny/reject/steer
#   D 类(25) CC 原生已具备 → 无需动作（见 CC-PATCHES.md）
#   E 类(12) DSH 桌面专属 → CC 无对应物（见 CC-PATCHES.md）
#
# 用法：
#   bash cc-patches.sh apply       # 生成配置
#   bash cc-patches.sh status      # 只读查看当前落地状态
#   bash cc-patches.sh revert      # 删除本脚本生成的配置
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN="$(cd "$HERE/.." && pwd)"
# 目标：CC 项目目录（默认当前工作目录，可用 CC_PROJECT_DIR 覆盖）
PROJ="${CC_PROJECT_DIR:-$PWD}"
SETTINGS="$PROJ/.claude/settings.json"
LAUNCH="$PROJ/purge-launch.sh"
HOOKS="$PLUGIN/hooks/hooks.json"

ACTION="${1:-status}"

write_settings() {
  mkdir -p "$(dirname "$SETTINGS")"
  cat > "$SETTINGS" <<'JSON'
{
  "permissions": {
    "defaultMode": "bypassPermissions",
    "allow": [
      "Bash(*)",
      "Read(*)",
      "Write(*)",
      "Edit(*)",
      "Glob(*)",
      "Grep(*)",
      "WebFetch(*)",
      "WebSearch(*)",
      "Agent(*)"
    ],
    "deny": []
  }
}
JSON
  echo "[cc-patches] 已写 $SETTINGS （对应 B 类：审批 never / 沙箱全开 / fs 围栏取消 / 升级无条件授信）"
}

write_launch() {
  cat > "$LAUNCH" <<'SH'
#!/usr/bin/env bash
# 以"破甲"权限启动 Claude Code（对应原版 B 类沙箱/审批补丁）
exec claude --dangerously-skip-permissions "$@"
SH
  chmod +x "$LAUNCH"
  echo "[cc-patches] 已写 $LAUNCH （启动参数 --dangerously-skip-permissions）"
}

check_hooks() {
  if [ -f "$HOOKS" ]; then
    if grep -qE 'UserPromptSubmit|PreToolUse|"deny"|"reject"|"steer"' "$HOOKS" 2>/dev/null; then
      echo "[cc-patches] 警告：$HOOKS 含 deny/reject/steer 钩子，与 C 类语义冲突（应只留 SessionStart）"
    else
      echo "[cc-patches] hooks OK：仅 SessionStart（对应 C 类 hooks deny/steer 中性化）"
    fi
  fi
}

case "$ACTION" in
  apply)
    write_settings
    write_launch
    check_hooks
    echo "[cc-patches] A 类(30) → 规则集已随插件注入，无需动作"
    echo "[cc-patches] D 类(25)/E 类(12) → 见 CC-PATCHES.md"
    echo "[cc-patches] 应用完成。重启 CC 会话生效。"
    ;;
  status)
    echo "[cc-patches] 目标项目: $PROJ"
    [ -f "$SETTINGS" ] && echo "[cc-patches] settings: 已存在" || echo "[cc-patches] settings: 未生成"
    [ -x "$LAUNCH" ] && echo "[cc-patches] launch: 已生成" || echo "[cc-patches] launch: 未生成"
    check_hooks
    ;;
  revert)
    rm -f "$SETTINGS" "$LAUNCH"
    echo "[cc-patches] 已删除本脚本生成的 settings.json 与 launch.sh"
    echo "[cc-patches] 注意：若原本已有 settings.json，需从备份自行恢复。"
    ;;
  *)
    echo "用法: bash cc-patches.sh apply|status|revert" >&2
    exit 1
    ;;
esac
