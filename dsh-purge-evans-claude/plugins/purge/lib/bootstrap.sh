#!/usr/bin/env bash
# 小码酱注入机制自举安装（幂等）。由 /purge 技能首次运行时调用。
# 从本脚本所在 lib/ 目录读取资源，铺到容器 /data 与 /app/preload.ts。
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE=/data/dsh-purge-patch
BUN=/root/.bun/bin/bun

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
