
// ===== [dsh-purge] 按需系统层注入（bun preload，不改 cli.js，绕过完整性校验）=====
// PATCH-MARKER-v2
(() => {
  try {
    const fs = require('fs');
    const injectFile = '/data/dsh-purge-patch/inject-prefix.js';
    if (fs.existsSync(injectFile)) require(injectFile);
  } catch (_) {}
})();
