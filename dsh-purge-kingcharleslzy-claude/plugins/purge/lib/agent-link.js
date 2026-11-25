// 切档联动：按当前档同步 agent 到 CC 的 agents 目录
// redteam → 5 个 rt-* 执行角色（清 little-code-sauce）；其它档 → 单个 little-code-sauce（清 rt-*）；off → 全清
// 用法：bun agent-link.js <档名|off>
// 环境变量：PURGE_BASE（默认 /data/dsh-purge-patch）、CLAUDE_AGENTS_DIR（默认 $HOME/.claude/agents）
const fs=require('fs'),path=require('path');
const r=process.argv[2]||'default';
const BASE=process.env.PURGE_BASE||'/data/dsh-purge-patch';
const AGENTS=process.env.CLAUDE_AGENTS_DIR||path.join(process.env.CLAUDE_CONFIG_DIR||path.join(process.env.HOME||'/root','.claude'),'agents');
const HERE=__dirname;
const TPL=path.join(HERE,'agents-templates');
const RULES=path.join(BASE,'rulesets');

function rm(d){try{fs.rmSync(d,{recursive:true,force:true})}catch(e){}}
function ensure(d){fs.mkdirSync(d,{recursive:true})}

if(r==='off'){
  rm(path.join(AGENTS,'little-code-sauce'));
  for(const n of ['rt-recon','rt-assess','rt-vuln-scan','rt-exploit','rt-internal']) rm(path.join(AGENTS,n));
  console.log('[agent-link] off: 已清除所有破甲 agent');
} else if(r==='redteam'){
  rm(path.join(AGENTS,'little-code-sauce'));
  let n=0;
  for(const name of ['rt-recon','rt-assess','rt-vuln-scan','rt-exploit','rt-internal']){
    const src=path.join(TPL,name,name+'.md');
    if(fs.existsSync(src)){const d=path.join(AGENTS,name);ensure(d);fs.copyFileSync(src,path.join(d,name+'.md'));n++;}
  }
  console.log('[agent-link] redteam: 已同步 '+n+' 个执行角色');
} else {
  for(const name of ['rt-recon','rt-assess','rt-vuln-scan','rt-exploit','rt-internal']) rm(path.join(AGENTS,name));
  const rule=path.join(RULES,r+'.md');
  if(!fs.existsSync(rule)){console.log('[agent-link] 规则集不存在: '+r);process.exit(1);}
  const body=fs.readFileSync(rule,'utf8').replace(/^\[OPERATION: STABLE\]\n/,'').trim();
  const d=path.join(AGENTS,'little-code-sauce');ensure(d);
  const out=`---\nname: little-code-sauce\ndescription: "小码酱子智能体——人格随本插件档位同步，当前档：${r}。"\n---\n\n# 小码酱 · 子智能体\n\n用下面的人格执行任务，完成向 lead 汇报。当前档：${r}。\n\n${body}\n\n## 汇报契约\n\n- 直接完成任务，简洁报告：做了什么/关键发现/产出。\n- 工作人格贯穿全程。\n`;
  fs.writeFileSync(path.join(d,'little-code-sauce.md'),out);
  console.log('[agent-link] '+r+': 已同步 little-code-sauce（清 rt 角色）');
}
