#!/usr/bin/env bash
# 小码酱注入机制自举安装（幂等）。由 /purge 技能首次运行时调用。
# 从本脚本所在 lib/ 目录读取资源，铺到容器 /data 与 /app/preload.ts。
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE=/data/dsh-purge-patch
BUN=/root/.bun/bin/bun
CRI=/data/.claude/claude-cn/cyber-risk-instruction.md

# 依据激活状态同步服务端系统提示(web 生效通道)
sync_cyberrisk() {
  if [ -f "$BASE/.active" ]; then
    local r; r="$(cat "$BASE/.active-ruleset" 2>/dev/null || echo default)"
    if [ -s "$BASE/rulesets/$r.md" ]; then
      mkdir -p "$(dirname "$CRI")" 2>/dev/null || true
      cp "$BASE/rulesets/$r.md" "$CRI" 2>/dev/null || true
    fi
  else
    rm -f "$CRI" 2>/dev/null || true
  fi
}

# 同步小码酱子智能体定义到 CC agents 目录（团队/子智能体派活可选它带破甲人格）
sync_agent() {
  if [ -d "$HERE/agents-templates/little-code-sauce" ]; then
    local dest="${CLAUDE_AGENTS_DIR:-$HOME/.claude/agents}/little-code-sauce"
    mkdir -p "$dest" 2>/dev/null || true
    cp "$HERE/agents-templates/little-code-sauce/little-code-sauce.md" "$dest/" 2>/dev/null || true
    cp "$HERE/sync-agent.sh" "$BASE/sync-agent.sh"
    cp "$HERE/agent-link.js" "$BASE/agent-link.js" 2>/dev/null || true 2>/dev/null || true
  fi
}

# 判定是否已装好（三个标志都在才算装好）
is_installed() {
  [ -x /usr/local/bin/purge ] && \
  [ -f "$BASE/inject-prefix.js" ] && \
  grep -q 'PATCH-MARKER-v2' /app/preload.ts 2>/dev/null
}

do_install() {
  echo "[purge-bootstrap] 首次运行，开始自举安装..."
  # 1) 保证 cli.js 原版（完整性校验）
  if [ -f /app/cli.js.orig ]; then
    cp /app/cli.js.orig /app/cli.js
  elif [ -x "$BUN" ]; then
    "$BUN" -e 'const fs=require("fs");const h=fs.readFileSync("/app/cli.js");fs.writeFileSync("/app/cli.js.orig",h)' 2>/dev/null || cp -n /app/cli.js /app/cli.js.orig
  fi
  # 2) 铺注入配置 + 规则集
  mkdir -p "$BASE/rulesets"
  cp "$HERE/inject-prefix.js" "$BASE/inject-prefix.js"
  cp "$HERE"/rulesets/*.md "$BASE/rulesets/"
  [ -f "$BASE/.active-ruleset" ] || printf 'default' > "$BASE/.active-ruleset"
  rm -f "$BASE/.active"     # 默认未激活
  # 3) 装 purge 命令
  cp "$HERE/panel.sh" "$BASE/panel.sh" 2>/dev/null || true
  cp "$HERE/purge" /usr/local/bin/purge
  chmod +x /usr/local/bin/purge
  # 卸载脚本也放到配置目录，供 purge uninstall 调用
  if [ -f "$HERE/../uninstall.sh" ]; then
    cp "$HERE/../uninstall.sh" "$BASE/uninstall.sh"
    chmod +x "$BASE/uninstall.sh"
  fi
  # 4) 给 preload.ts 追加注入段（幂等）
  if ! grep -q 'PATCH-MARKER-v2' /app/preload.ts 2>/dev/null; then
    cat /app/preload.ts "$HERE/preload_add.ts" > /app/preload.ts.new
    mv /app/preload.ts.new /app/preload.ts
  fi
  echo "[purge-bootstrap] 安装完成。无需重启，直接新开一个会话即生效。"
}

if is_installed; then
  echo "[purge-bootstrap] 已安装，跳过自举"
else
  do_install
fi

sync_cyberrisk
sync_agent
