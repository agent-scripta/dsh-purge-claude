#!/usr/bin/env node
/**
 * CC 侧 redteam 命令行入口（替代 DSH 的 ctx.redteam 服务暴露）。
 *
 * 用法：
 *   echo '{"op":"bootstrap"}' | node redteam-cli.mjs
 *   echo '{"op":"scoreHit","engagement":"X","code":"rce","target":"10.0.0.1:80","evidence":"..."}' | node redteam-cli.mjs
 *   echo '{"op":"listScorePoints","engagement":"X"}' | node redteam-cli.mjs
 *
 * 数据根目录：环境变量 REDTEAM_HOME（默认 <插件根>/.redteam-data），写到插件目录内，
 * 不碰宿主任何文件。dispatch 的 op 协议与 dsh-purge 原版完全一致。
 */
import { RedteamStore, dispatchAsync } from './redteam/store-core.js'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'
import { homedir } from 'node:os'

const here = dirname(fileURLToPath(import.meta.url))
// 插件根目录（lib/ 的上一级）内建数据目录，跨会话持久
const defaultRoot = join(here, '..', '.redteam-data')
const root = process.env.REDTEAM_HOME || defaultRoot

let raw = ''
for await (const chunk of process.stdin) raw += chunk
let req
try {
  req = raw.trim() ? JSON.parse(raw) : { op: 'bootstrap' }
} catch (e) {
  process.stdout.write(JSON.stringify({ ok: false, error: 'invalid JSON: ' + e.message }))
  process.exit(0)
}

try {
  const store = new RedteamStore(root)
  const res = await dispatchAsync(store, req)
  process.stdout.write(JSON.stringify(res))
} catch (e) {
  process.stdout.write(JSON.stringify({ ok: false, error: String(e && e.message || e) }))
}
