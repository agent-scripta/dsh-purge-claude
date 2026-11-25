// [dsh-purge] PATCH-MARKER-v2 —— 稳定的幂等标记，勿删
// [dsh-purge] 按需系统层注入：默认不注入，仅激活标记存在时注入小码酱
// 支持：环境变量强制开关 / 多 profile 规则集 / 自定义目录与规则名
(() => {
  try {
    const fs = require('fs');
    const path = require('path');

    // 已有显式系统提示时让路，不重复注入
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

    // 基准目录：环境变量 > 默认。允许多个目录（用路径分隔符分隔），逐个找激活标记。
    const rawBase = process.env.DSH_PURGE_DIR || '/data/dsh-purge-patch';
    const bases = String(rawBase).split(path.delimiter).filter(Boolean);
    const validRules = ['default','redteam','minimal','stealth','novel','max','unrestricted'];

    let activeBase = '';
    let name = process.env.DSH_PURGE_RULESET || '';

    // 强制开关：DSH_PURGE_ACTIVE=1 时，取第一个存在的目录作为基准（无需 .active 文件）
    const forced = process.env.DSH_PURGE_ACTIVE === '1';
    for (const base of bases) {
      const activeFile = path.join(base, '.active');
      let active = forced;
      if (!active) { try { active = fs.existsSync(activeFile); } catch (_) {} }
      if (!active) continue;

      // 规则集名：环境变量 > 该目录的 .active-ruleset > default
      if (!name) {
        try { name = fs.readFileSync(path.join(base, '.active-ruleset'), 'utf8').trim(); } catch (_) {}
      }
      if (!validRules.includes(name)) name = 'default';

      // 允许自定义规则文件名：DSH_PURGE_RULEFILE 优先，否则用规则集名
      const ruleFile = process.env.DSH_PURGE_RULEFILE
        ? path.resolve(process.env.DSH_PURGE_RULEFILE)
        : path.join(base, 'rulesets', name + '.md');
      try {
        const txt = fs.readFileSync(ruleFile, 'utf8');
        if (txt && txt.length > 20) {
          // 注入方式：默认「追加式」(--append-system-prompt)，与已验证可用的 evans-repo 版一致，
          // 保留 Claude Code 原生系统提示与工具行为；靠“短小、身份打头”的规则集让模型认身份。
          // 如需用规则集整段替换默认系统提示，设 DSH_PURGE_SYSTEM_PROMPT=1（覆盖式）。
          const useOverride = process.env.DSH_PURGE_SYSTEM_PROMPT === '1';
          process.argv.push(useOverride ? '--system-prompt' : '--append-system-prompt', txt);
          activeBase = base;
          break;
        }
      } catch (_) {}
    }

    // 调试：DSH_PURGE_DEBUG=1 时打印选中状态到 stderr，不影响注入内容
    if (process.env.DSH_PURGE_DEBUG === '1') {
      process.stderr.write(`[purge] base=${activeBase || 'none'} ruleset=${name || 'none'} forced=${forced}\n`);
    }
  } catch (_) {}
})();
