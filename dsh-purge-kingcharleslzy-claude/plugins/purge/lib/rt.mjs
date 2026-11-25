#!/usr/bin/env node
/**
 * CC 原生 rt 命令 —— 替代原版 DSH 的 redteam_* MCP 工具。
 *
 * 原版技能里写 `redteam_asset_add {engagement, ip, ...}`，CC 没有这套 MCP 工具；
 * 本命令把每个工具名做成子命令，参数用 JSON，内部转成 dispatch op 调 store-core。
 * engagement 缺省时自动取当前活跃靶标（dispatch 的 bootstrap/activateEngagement 管理）。
 *
 * 用法：
 *   rt <tool> '<json>'          例：rt asset-add '{"ip":"10.0.0.1","provenance":"active"}'
 *   rt <tool> k=v k=v ...       例：rt asset-add ip=10.0.0.1 provenance=active
 *   rt --list                   列出全部子命令
 *   rt <tool> --help            看子命令对应的 op 与字段提示
 *
 * 工具名同时接受下划线（asset_add）和连字符（asset-add）。
 */
import { RedteamStore, dispatchAsync } from './redteam/store-core.js'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'

// redteam_* 工具名 → dispatch op
const TOOLS = {
  preflight: 'bootstrap',
  engagement_open: 'openEngagement',
  session_bind: 'activateEngagement',
  session_info: 'bootstrap',
  asset_add: 'addAsset', asset_upsert: 'addAsset', asset_query: 'assets',
  asset_get: 'asset', asset_test: 'assetTest', asset_assess: 'assessAsset',
  asset_link: 'assetLink', asset_stats: 'stats', asset_graph: 'attackGraph',
  asset_timeline: 'discoveryTimeline', asset_domain_index: 'domains',
  web_list: 'web',
  vuln_add: 'addVuln', vuln_query: 'vulns', vuln_update: 'updateVuln',
  credential_add: 'addCredential', credential_list: 'credentials',
  access_add: 'addAccess', access_list: 'access',
  webshell_add: 'addWebshell', webshell_list: 'webshells', webshell_update: 'updateWebshell',
  tunnel_add: 'addTunnel', tunnel_list: 'tunnels', tunnel_update: 'updateTunnel',
  session_check: 'probeSessions', sessions: 'sessions',
  chain_add: 'addChainStep', chain: 'chain', attack_chain: 'scoreChain', attack_path: 'attackGraph',
  score_hit: 'addScoreHit', score_list: 'scores', score_report: 'scoreReport',
  score_point_save: 'saveScorePoint',
  http_evidence_add: 'addHttpEvidence', attack_file_add: 'addAttackFile',
  poc_search: 'pocSearch', poc_get: 'pocGet', poc_add: 'pocSave', poc_use: 'pocUse',
  shot_add: 'shotAdd', shot_list: 'shots',
  evidence_record: 'addEvidence', evidence_list: 'httpEvidence', evidence_upgrade: 'updateEvidence',
  unknown_record: 'addUnknown', unknown_list: 'listUnknowns', unknown_resolve: 'resolveUnknown',
  report: 'report', report_targets: 'reportTargets',
  stats: 'stats', snapshot: 'snapshot',
  role_prompt: 'prompts', roles: 'prompts', score_list_all: 'scores',
  agent_slot: 'bootstrap',
}
const ALIAS = {
  'asset-upsert':'asset_upsert','asset-query':'asset_query','asset-get':'asset_get',
  'asset-test':'asset_test','asset-assess':'asset_assess','asset-link':'asset_link',
  'asset-stats':'asset_stats','asset-graph':'asset_graph','asset-timeline':'asset_timeline',
  'web-list':'web_list','vuln-add':'vuln_add','vuln-query':'vuln_query','vuln-update':'vuln_update',
  'credential-add':'credential_add','credential-list':'credential_list',
  'access-add':'access_add','access-list':'access_list',
  'webshell-add':'webshell_add','webshell-list':'webshell_list','webshell-update':'webshell_update',
  'tunnel-add':'tunnel_add','tunnel-list':'tunnel_list','tunnel-update':'tunnel_update',
  'session-check':'session_check','chain-add':'chain_add','attack-chain':'attack_chain',
  'attack-path':'attack_path','score-hit':'score_hit','score-list':'score_list',
  'score-report':'score_report','http-evidence-add':'http_evidence_add','attack-file-add':'attack_file_add',
  'poc-search':'poc_search','poc-get':'poc_get','poc-add':'poc_add','poc-use':'poc_use',
  'shot-add':'shot_add','shot-list':'shot_list','engagement-open':'engagement_open',
  'session-bind':'session_bind','session-info':'session_info','score-point-save':'score_point_save',
}
const here = dirname(fileURLToPath(import.meta.url))
const root = process.env.REDTEAM_HOME || join(here, '..', '.redteam-data')
const store = new RedteamStore(root)

function normalizeTool(s) { return ALIAS[s] || s.replace(/-/g, '_') }
function parseArgs(rest) {
  if (!rest.length) return {}
  if (rest.length === 1 && rest[0].trim().startsWith('{')) {
    try { return JSON.parse(rest[0]) } catch { return { _raw: rest[0] } }
  }
  const out = {}
  for (const a of rest) {
    const i = a.indexOf('=')
    if (i > 0) {
      let v = a.slice(i + 1)
      if (/^-?\d+(\.\d+)?$/.test(v)) v = Number(v)
      else if (v === 'true') v = true
      else if (v === 'false') v = false
      out[a.slice(0, i)] = v
    }
  }
  return out
}
function currentEngagement() {
  try {
    const b = store.listEngagements({ includeStats: false })
    const active = typeof store.activeEngagementId === 'function' ? store.activeEngagementId() : undefined
    return active || (b[0] && b[0].id) || ''
  } catch { return '' }
}

const argv = process.argv.slice(2)
const raw = argv[0] || ''
if (raw === '--list' || raw === '-h') {
  process.stdout.write(JSON.stringify({ ok: true, tools: Object.keys(TOOLS).sort() }))
  process.exit(0)
}
const tool = normalizeTool(raw)

if (!tool || tool === '--list' || tool === '-h') {
  process.stdout.write(JSON.stringify({ ok: true, tools: Object.keys(TOOLS).sort() }))
} else if (argv[1] === '--help') {
  process.stdout.write(JSON.stringify({ ok: true, tool, op: TOOLS[tool] || null, note: '参数用 JSON 或 k=v；engagement 缺省取当前靶标' }))
} else if (!TOOLS[tool]) {
  process.stdout.write(JSON.stringify({ ok: false, error: `未知工具 ${raw}。用 rt --list 看全部子命令。` }))
} else {
  const args = parseArgs(argv.slice(1))
  if (!args.engagement) args.engagement = currentEngagement()
  const eng = args.engagement
  try {
    let res
    if (tool === 'asset_add' || tool === 'asset_upsert') {
      // 原版 redteam_asset_add 走 store.importBundle（幂等 upsert），不是独立 addAsset op
      const asset = { ...args }
      delete asset.engagement
      delete asset.op
      res = { ok: true, ...store.importBundle(eng, { scan: { tool: args.tool || 'rt', argv: ['rt', 'asset-add'] }, assets: [asset] }) }
      const written = store.listAssets(eng, { ip: args.ip, limit: 1 }).items[0]
      if (written) res.asset = written
    } else if (tool === 'asset_link') {
      const edge = { ...args }
      delete edge.engagement
      delete edge.op
      res = { ok: true, ...store.importBundle(eng, { edges: [edge] }) }
    } else {
      res = await dispatchAsync(store, { ...args, op: TOOLS[tool] })
    }
    process.stdout.write(JSON.stringify(res))
  } catch (e) {
    process.stdout.write(JSON.stringify({ ok: false, error: String(e && e.message || e) }))
  }
}
