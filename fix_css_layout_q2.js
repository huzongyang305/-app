const fs = require('fs');
const content = fs.readFileSync('assets/content/css_layout.md', 'utf8');
const lines = content.split('\n');

// Fix line 445 (index 444)
let line = lines[444];
console.log('Before:', line.substring(0, 100));

// Replace straight quotes with curly quotes
// Pattern: 围绕"CSS 布局：Flex、Grid 与响应式"中的
line = line.replace(/围绕"CSS 布局：Flex、Grid 与响应式"中的/, '围绕\u201cCSS 布局：Flex、Grid 与响应式\u201d中的');

lines[444] = line;
console.log('After:', line.substring(0, 100));

const newContent = lines.join('\n');
fs.writeFileSync('assets/content/css_layout.md', newContent, 'utf8');
console.log('Fixed!');
