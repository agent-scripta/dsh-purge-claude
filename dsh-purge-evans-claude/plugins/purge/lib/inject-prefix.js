// [dsh-purge] PATCH-MARKER-v2 —— 稳定的幂等标记，勿删
// [dsh-purge] 按需系统层注入：默认不注入，仅激活标记存在时注入小码酱
(() => {
  try {
    const fs = require('fs');
    const path = require('path');
    const has = (a) => process.argv.some(x => x === a || String(x).startsWith(a + '='));
    if (has('--append-system-prompt') || has('--system-prompt') || has('--bare')) return;

    // 关键修复：管理类子命令（plugin/team/agent/task/mcp/setup/doctor 等）不是对话会话，
    // 往它们的 argv 塞 --append-system-prompt 会让 commander 报 "unknown option"，
    // 直接导致团队/子智能体/插件管理命令启动失败。只对对话会话注入。
    const managementCmds = ['plugin','plugins','team','teams','agent','agents','task','tasks','mcp','setup','doctor','update','install','uninstall','config','auth','logout','login'];
    const scriptIdx = process.argv.findIndex(x => /(?:^|\/)cli\.js$/.test(String(x)) || /(?:^|\/)cli\.(?:mjs|ts)$/.test(String(x)));
    const afterScript = scriptIdx >= 0 ? process.argv.slice(scriptIdx + 1) : process.argv.slice(2);
    const firstArg = (afterScript.find(x => x && !x.startsWith('-')) || '').toLowerCase();
    if (managementCmds.includes(firstArg)) return;
    // 子进程标记：CC 派生的 team/agent 工作进程会带 --agent 或 DSH_PURGE_SKIP=1，一律不注入
    if (has('--agent') || has('--agent-id') || process.env.DSH_PURGE_SKIP === '1') return;

    // 固定基准目录（被 preload require，用环境变量可覆盖），不依赖插件是否安装
    const base = process.env.DSH_PURGE_DIR || '/data/dsh-purge-patch';
    const activeFile = path.join(base, '.active');
    let active = process.env.DSH_PURGE_ACTIVE === '1';
    if (!active) { try { active = fs.existsSync(activeFile); } catch (_) {} }
    if (!active) return;

    let name = process.env.DSH_PURGE_RULESET || '';
    if (!name) {
      try { name = fs.readFileSync(path.join(base, '.active-ruleset'), 'utf8').trim(); } catch (_) {}
    }
    if (!['default','redteam','minimal','max','stealth','novel'].includes(name)) name = 'default';

    const ruleFile = path.join(base, 'rulesets', name + '.md');
    try {
      const txt = fs.readFileSync(ruleFile, 'utf8');
      if (txt && txt.length > 20) {
        process.argv.push('--append-system-prompt', txt);
      }
    } catch (_) {}
  } catch (_) {}
})();
