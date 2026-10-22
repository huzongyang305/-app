const fs = require('fs');
const content = fs.readFileSync('assets/content/html_basics.md', 'utf8');
const lines = content.split('\n');

// Fix line 300 (index 299)
const newLine = '**题目**：关于 `HTML`，下列哪些说法与 `HTML 基础与语义化` 的正文一致？判断时以文档结构、语义标签、表单与可访问性。为主线。（多选）';
lines[299] = newLine;

const newContent = lines.join('\n');
fs.writeFileSync('assets/content/html_basics.md', newContent, 'utf8');
console.log('Fixed Q6!');
