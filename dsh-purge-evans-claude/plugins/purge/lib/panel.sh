#!/usr/bin/env bash
# 小码酱 · Purge 文本控制面板（CC / ClaudeCN）— 1.1.72 适配版
# Claude Code 是 TUI，没有 DSH 左侧栏整页 UI，本脚本用 /purge:purge-panel 输出同等信息。
# 只读，不改激活状态；切换请用 /purge:purge-<档>。
set -uo pipefail
BASE=/data/dsh-purge-patch
MARK=$BASE/.active
RULES=$BASE/.active-ruleset

cur="$(cat "$RULES" 2>/dev/null || echo default)"
if [ -f "$MARK" ]; then state="已激活"; else state="未激活（正常会话）"; fi

desc() {
  case "$1" in
    default) echo "默认档 · 通用协作（代码/调试/架构/写作）" ;;
    max)     echo "最硬档 · 原始全文完整版（约25KB，需强模型）" ;;
    redteam) echo "红队指挥 · 只规划与派活（收集→梳理→发现→利用→内网）" ;;
    minimal) echo "极简档 · 只保留身份与基本工作方式" ;;
    stealth) echo "隐身档 · 低痕迹执行，反调试/免杀等本地测试" ;;
    novel)   echo "创作档 · 角色扮演/小说/成人向，写足不淡出" ;;
    *)       echo "未知档位" ;;
  esac
}

row() {
  if [ "$1" = "$2" ] && [ -f "$MARK" ]; then mark="●"; else mark="○"; fi
  printf '  %s %-9s %s\n' "$mark" "$1" "$(desc "$1")"
}

echo "═══════════════════════════════════════════════"
echo "  小码酱 · Purge 控制面板   [CC 适配 · 源 1.1.72]"
echo "═══════════════════════════════════════════════"
printf '  状态   : %s\n' "$state"
printf '  当前档 : %s\n' "$cur"
printf '  来源   : Evans-repo v1.1.72（基于 dsh-purge 1.1.71）\n'
printf '  平台   : Claude Code / ClaudeCN\n'
echo "───────────────────────────────────────────────"
echo "  档位（● = 当前）"
for r in default max redteam minimal stealth novel; do row "$r" "$cur"; done
echo "───────────────────────────────────────────────"
echo "  命令"
echo "    /purge:purge-panel     显示本面板"
echo "    /purge:purge-on        默认档"
echo "    /purge:purge-max       最硬档"
echo "    /purge:purge-redteam   红队指挥"
echo "    /purge:purge-minimal   极简档"
echo "    /purge:purge-stealth   隐身档"
echo "    /purge:purge-novel     创作档"
echo "    /purge:purge-off       关闭（恢复正常 CC）"
echo "    /purge:purge-status    查看模式"
echo "───────────────────────────────────────────────"
echo "  切档联动: 红队→5个rt执行角色 / 其它档→little-code-sauce"
echo "  切换后新开会话生效。规则集目录：$BASE/rulesets"
echo "═══════════════════════════════════════════════"
