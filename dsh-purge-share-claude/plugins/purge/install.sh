#!/usr/bin/env bash
# 在 ClaudeCN 容器内运行：一键安装
#   1) /purge 独立技能（技能页可见，靠参数）
#   2) purge plugin（/ 补全里列出 8 个独立命令）
#   3) 运行态（purge 命令 + 注入配置 + preload 段）
# 用法：bash install.sh
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${CC_SKILLS_DIR:-/data/.claude/skills/purge}"
REPO_ROOT="$(cd "$HERE/../.." && pwd)"   # = .../purge-github（marketplace 根）
BUN="${BUN_BIN:-/root/.bun/bin/bun}"
CLI_DIR=/app

echo "==> 源目录: $HERE"
echo "==> marketplace 根: $REPO_ROOT"

# ── 1) 独立技能 ────────────────────────────────────────────
mkdir -p "$(dirname "$DEST")"
if [ -d "$DEST" ]; then
  mv "$DEST" "$DEST.bak.$(date +%s)"
fi
cp -a "$HERE" "$DEST"
echo "==> 独立技能已安装到 $DEST"

# ── 2) 运行态（幂等）──────────────────────────────────────
if [ -f "$HERE/lib/setup.sh" ]; then
  echo "==> 初始化运行态..."
  bash "$HERE/lib/setup.sh"
else
  echo "!! 找不到 lib/setup.sh，运行态未初始化" >&2
fi

# ── 3) plugin（让 / 补全自动列出 8 个命令，幂等）────────────
if [ -f "$REPO_ROOT/.claude-plugin/marketplace.json" ] && [ -x "$BUN" ]; then
  echo "==> 安装 plugin（命令补全）..."
  ( cd "$CLI_DIR" && \
    CC_CN_SKIP_DOTENV=1 "$BUN" cli.js plugin marketplace add "$REPO_ROOT" 2>&1 || true; \
    CC_CN_SKIP_DOTENV=1 "$BUN" cli.js plugin install purge@lcs-skills 2>&1 || true )
else
  echo "!! 未找到 marketplace 或 bun，跳过 plugin 安装" >&2
fi

echo "==> 全部完成。"
echo "    - 技能页: purge（/purge on|max|redteam|minimal|stealth|novel|off|status）"
echo "    - / 补全: /purge:purge-on /purge:purge-max /purge:purge-redteam /purge:purge-minimal /purge:purge-stealth /purge:purge-novel /purge:purge-off /purge:purge-status"
