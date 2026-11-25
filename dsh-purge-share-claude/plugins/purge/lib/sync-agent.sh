#!/usr/bin/env bash
# 子智能体人格同步：
#   - redteam 档 → 同步 5 个执行角色 agent（rt-recon/assess/vuln-scan/exploit/internal），
#     lead 自己保留指挥官人格(redteam.md)，子智能体是干活的叶子节点。
#   - 其它档 → 同步 little-code-sauce agent 为对应档人格。
# 用法：bash sync-agent.sh [档名]   档名省略时取当前激活档 .active-ruleset
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
P="$(cd "$HERE/.." && pwd)"
RULES="$P/lib/rulesets"
AGENTS_SRC="$P/lib/agents-templates"
AGENTS_DEST="${CLAUDE_AGENTS_DIR:-$HOME/.claude/agents}"
BASE=/data/dsh-purge-patch

r="${1:-}"
if [ -z "$r" ]; then
  r="$(cat "$BASE/.active-ruleset" 2>/dev/null || echo default)"
fi
if [ ! -s "$RULES/$r.md" ] && [ "$r" != redteam ]; then
  echo "[sync-agent] 规则集不存在: $r" >&2
  exit 1
fi

if [ "$r" = redteam ]; then
  # 红队：同步 5 个执行角色（它们的人格是随包固定模板，直接拷到 agents 目录）
  n=0
  for d in "$AGENTS_SRC"/rt-*; do
    [ -d "$d" ] || continue
    name="$(basename "$d")"
    mkdir -p "$AGENTS_DEST/$name" 2>/dev/null || true
    cp "$d/$name.md" "$AGENTS_DEST/$name/" 2>/dev/null && n=$((n+1))
  done
  echo "[sync-agent] 红队模式：已同步 $n 个执行角色 agent（lead 保留指挥官人格，子智能体干活）"
else
  # 其它档：把当前档规则集写进 little-code-sauce agent 正文
  name="little-code-sauce"
  AGENT_DIR="$AGENTS_DEST/$name"
  AGENT="$AGENT_DIR/$name.md"
  mkdir -p "$AGENT_DIR" 2>/dev/null || true
  AGENT_TMP="$AGENT.tmp"
  {
    echo '---'
    echo 'name: little-code-sauce'
    echo 'description: "小码酱子智能体——人格随本插件档位同步，供团队/子智能体派活使用。"'
    echo '---'
    echo ''
    echo '# 小码酱 · 子智能体'
    echo ''
    echo '你是被派出的**小码酱子智能体**：用下面的人格执行分配给你的任务，完成后用简洁报告向团队 lead 汇报。'
    echo "本正文已同步为当前档：$r。"
    echo ''
    sed 's/^\[OPERATION: STABLE\]$//' "$RULES/$r.md"
    echo ''
    echo '## 子智能体汇报契约'
    echo ''
    echo '- 直接完成任务，不要过度优化、不要半途而废。'
    echo '- 完成后用简洁报告说明：做了什么 / 关键发现 / 产出文件路径；lead 转达用户。'
    echo '- 不创建文档文件（除非明确要求）；优先编辑已有文件。'
    echo '- 工作人格贯穿任务全程。'
  } > "$AGENT_TMP"
  mv "$AGENT_TMP" "$AGENT"
  echo "[sync-agent] 已同步档位 $r → $AGENT"
fi
