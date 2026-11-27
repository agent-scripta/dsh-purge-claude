#!/usr/bin/env bash
# 完全卸载：小码酱注入 + 技能 + 插件注册 + cyber-risk 覆盖，全清。
# 用法：bash uninstall.sh   （无需调用 cli，直接清文件与注册，避免自愈且更快）
set -uo pipefail
SKILL_DIR="${CC_SKILLS_DIR:-/data/.claude/skills}/purge"
BASE=/data/dsh-purge-patch
CRI=/data/.claude/claude-cn/cyber-risk-instruction.md
PLUG=/data/.claude/plugins
BUN=/root/.bun/bin/bun

echo "[purge-uninstall] 开始完全卸载..."

# 1) 关激活 + 删 cyber-risk 覆盖
rm -f "$BASE/.active" 2>/dev/null || true
if [ -f "$CRI" ]; then rm -f "$CRI" && echo "已删除 cyber-risk 覆盖"; fi

# 2) 移除 preload.ts 注入段
if [ -f /app/preload.ts ] && grep -q 'PATCH-MARKER-v2' /app/preload.ts 2>/dev/null; then
  if [ -f /app/preload.ts.orig ]; then
    cp /app/preload.ts.orig /app/preload.ts; echo "preload.ts 已恢复原版"
  else
    awk '/bun preload，不改 cli.js/{exit} {print}' /app/preload.ts > /app/preload.ts.tmp && mv /app/preload.ts.tmp /app/preload.ts
    echo "preload.ts 注入段已移除"
  fi
fi

# 3) 清掉旧版残留的 cli.js.orig（新版从不改 cli.js；恢复它会破坏完整性校验）
rm -f /app/cli.js.orig 2>/dev/null || true

# 4) 删命令 / 运行态 / 技能 / 插件缓存 / 源
rm -f /usr/local/bin/purge
rm -rf "$BASE" "$SKILL_DIR"
rm -rf "${SKILL_DIR}.bak."* 2>/dev/null || true
rm -rf "$PLUG/cache/lcs-skills" "$PLUG/marketplaces/lcs-skills" 2>/dev/null || true
rm -rf /opt/purge-github /data/purge-src 2>/dev/null || true

# 5) 从插件注册 JSON 移除 purge / lcs-skills（断自愈）
if [ -x "$BUN" ]; then
  "$BUN" -e '
  const fs=require("fs");
  try{const p="/data/.claude/plugins/installed_plugins.json";let j=JSON.parse(fs.readFileSync(p,"utf8"));
    let ch=false; if(j.plugins&&j.plugins["purge@lcs-skills"]){delete j.plugins["purge@lcs-skills"];ch=true;}
    if(ch){fs.writeFileSync(p,JSON.stringify(j,null,2));console.log("已从 installed_plugins 移除 purge");}}catch(e){}
  try{const p="/data/.claude/plugins/known_marketplaces.json";let j=JSON.parse(fs.readFileSync(p,"utf8"));
    if(j["lcs-skills"]){delete j["lcs-skills"];fs.writeFileSync(p,JSON.stringify(j,null,2));console.log("已从 known_marketplaces 移除 lcs-skills");}}catch(e){}
  ' 2>/dev/null || true
fi

# 6) 删随包子智能体 agent（little-code-sauce + 5 个红队执行角色）
AGENTS_DIR="${CLAUDE_AGENTS_DIR:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/agents}"
rm -rf "$AGENTS_DIR/little-code-sauce" "$AGENTS_DIR/rt-recon" "$AGENTS_DIR/rt-assess" "$AGENTS_DIR/rt-vuln-scan" "$AGENTS_DIR/rt-exploit" "$AGENTS_DIR/rt-internal" 2>/dev/null || true
# 容器内也可能有一份（CC Web 环境）
if command -v docker >/dev/null 2>&1; then
  docker exec claude-cn sh -c 'rm -rf /data/.claude/agents/little-code-sauce /data/.claude/agents/rt-recon /data/.claude/agents/rt-assess /data/.claude/agents/rt-vuln-scan /data/.claude/agents/rt-exploit /data/.claude/agents/rt-internal' 2>/dev/null || true
fi

echo "[purge-uninstall] 完全卸载完成：运行态/preload/purge命令/技能/插件注册/cyber-risk/子智能体agent 均已清除。新开会话即纯净 Claude Code。"
