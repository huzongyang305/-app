const fs = require('fs');
let content = fs.readFileSync('assets/content/a11y_aria.md', 'utf8');

// Fix line 563 - replace straight quotes with curly quotes
content = content.replace(
  /服务于"原生优先原则、常用 ARIA 属性与键盘焦点管理。"/,
  '服务于\u201c原生优先原则、常用 ARIA 属性与键盘焦点管理。\u201d'
);

fs.writeFileSync('assets/content/a11y_aria.md', content, 'utf8');
console.log('Fixed a11y_aria.md!');
