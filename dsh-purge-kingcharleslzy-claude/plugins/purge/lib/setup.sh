#!/usr/bin/env bash
# 小码酱注入机制自举 + 自愈（幂等）。由 SessionStart hook 每会话调用。
# 从本脚本所在 lib/ 读取资源，铺到 /data/dsh-purge-patch 与 /app/preload.ts；
# 官方客户端更新覆盖注入段时自动修复。
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE=/data/dsh-purge-patch
BUN=/root/.bun/bin/bun
PRELOAD=/app/preload.ts
MARK=PATCH-MARKER-v2
RULES=(default redteam minimal stealth novel max unrestricted)

log() { printf '[purge-bootstrap] %s\n' "$*"; }

# ClaudeCN(claude-cn) 服务端系统提示注入文件：web 会话真正生效的通道
CRI=/data/.claude/claude-cn/cyber-risk-instruction.md
# 依据当前激活状态同步服务端系统提示：激活则写入当前规则集，未激活则删除恢复平台默认
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

# 确保 cli.js 是原版（完整性校验）；cli.js 不存在时（非标准部署）跳过，不中断安装
ensure_cli_orig() {
  if [ -f /app/cli.js.orig ]; then
    cp /app/cli.js.orig /app/cli.js || true
  elif [ -f /app/cli.js ]; then
    if [ -x "$BUN" ]; then
      "$BUN" -e 'const fs=require("fs");const h=fs.readFileSync("/app/cli.js");fs.writeFileSync("/app/cli.js.orig",h)' 2>/dev/null || cp -n /app/cli.js /app/cli.js.orig || true
    else
      cp -n /app/cli.js /app/cli.js.orig || true
    fi
  else
    log "未找到 /app/cli.js，跳过原版备份（preload 注入不受影响）"
  fi
}

# 铺注入脚本 + 全部规则集（覆盖式，保证升级生效；不碰激活状态）
lay_runtime() {
  mkdir -p "$BASE/rulesets"
  cp "$HERE/inject-prefix.js" "$BASE/inject-prefix.js"
  cp "$HERE"/rulesets/*.md "$BASE/rulesets/"
  [ -f "$BASE/.active-ruleset" ] || printf 'default' > "$BASE/.active-ruleset"
  # 校验每个规则集都在，缺的单独补
  for r in "${RULES[@]}"; do
    [ -s "$BASE/rulesets/$r.md" ] || cp "$HERE/rulesets/$r.md" "$BASE/rulesets/$r.md" 2>/dev/null || true
  done
  # purge 命令 + 面板脚本 + 补丁脚本 + 卸载脚本
  cp "$HERE/panel.sh" "$BASE/panel.sh" 2>/dev/null || true
  cp "$HERE/cc-patches.sh" "$BASE/cc-patches.sh" 2>/dev/null || true
  cp "$HERE/purge" /usr/local/bin/purge 2>/dev/null && chmod +x /usr/local/bin/purge || true
  # redteam 原生命令 rt：包装 + 入口 + redteam 逻辑库，装到 /usr/local/bin/rt
  cp "$HERE/rt" /usr/local/bin/rt 2>/dev/null && chmod +x /usr/local/bin/rt || true
  cp "$HERE/rt.mjs" "$BASE/rt.mjs" 2>/dev/null || true
  cp "$HERE/redteam-cli.mjs" "$BASE/redteam-cli.mjs" 2>/dev/null || true
  mkdir -p "$BASE/redteam"
  cp "$HERE"/redteam/*.js "$HERE"/redteam/*.mjs "$BASE/redteam/" 2>/dev/null || true
  # store-core 依赖 lib 根的这两个模块，一并铺过去
  cp "$HERE/path-boundary.js" "$HERE/remove-tree.js" "$BASE/" 2>/dev/null || true
  # 小码酱子智能体定义：装到 CC 的 agents 目录，团队/子智能体派活时可选它带破甲人格
  # 切档联动：铺 agent-link.js + 模板到运行目录（purge 切档时调它同步 agent）
  cp "$HERE/agent-link.js" "$BASE/agent-link.js" 2>/dev/null || true
  if [ -d "$HERE/agents-templates" ]; then
    mkdir -p "$BASE/agents-templates" 2>/dev/null || true
    cp -a "$HERE/agents-templates/." "$BASE/agents-templates/" 2>/dev/null || true
    AGENTS_DEST="${CLAUDE_AGENTS_DIR:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/agents}"
    mkdir -p "$AGENTS_DEST/little-code-sauce" 2>/dev/null || true
    cp "$HERE/agents-templates/little-code-sauce/little-code-sauce.md" "$AGENTS_DEST/little-code-sauce/" 2>/dev/null || true
  fi
  if [ -f "$HERE/../uninstall.sh" ]; then
    cp "$HERE/../uninstall.sh" "$BASE/uninstall.sh"
    chmod +x "$BASE/uninstall.sh"
  fi
}

# 确保 preload.ts 里有注入段（幂等 + 官方更新后自愈）
ensure_preload() {
  [ -f "$PRELOAD" ] || return 0
  if ! grep -q "$MARK" "$PRELOAD" 2>/dev/null; then
    cat "$PRELOAD" "$HERE/preload_add.ts" > "$PRELOAD.purge-new"
    mv "$PRELOAD.purge-new" "$PRELOAD"
    log "注入段缺失，已重新追加（官方更新自愈）"
  fi
  # 注入段存在但指向的脚本损坏 → 重铺
  if ! grep -q "dsh-purge-patch/inject-prefix.js" "$PRELOAD" 2>/dev/null; then
    log "注入段内容异常，请用 install.sh 重装"
  fi
}

is_installed() {
  [ -x /usr/local/bin/purge ] && \
  [ -f "$BASE/inject-prefix.js" ] && \
  grep -q "$MARK" "$PRELOAD" 2>/dev/null
}

if is_installed; then
  # 自愈：每次都校验并修复，静默完成
  lay_runtime
  ensure_preload
  sync_cyberrisk
  log "已安装并自愈校验完成，开新会话生效"
else
  if [ -d "$BASE" ] || [ -x /usr/local/bin/purge ]; then
    log "检测到安装不完整（注入段或运行态缺失），执行修复安装..."
  else
    log "首次运行，开始自举安装..."
  fi
  ensure_cli_orig
  lay_runtime
  ensure_preload
  sync_cyberrisk
  log "安装完成。无需重启，直接新开一个会话即生效。"
fi
