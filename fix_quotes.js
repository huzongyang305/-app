const fs = require('fs');
const content = fs.readFileSync('assets/content/html_basics.md', 'utf8');
const lines = content.split('\n');
let line = lines[273];

console.log('Before fix:');
console.log('Position 8:', line.charCodeAt(8), '(should be 8220)');
console.log('Position 20:', line.charCodeAt(20), '(should be 8221)');

// Replace character at position 8 with left curly quote (U+201C = 8220)
line = line.substring(0, 8) + '\u201c' + line.substring(9);

console.log('\nAfter fix:');
console.log('Position 8:', line.charCodeAt(8));

lines[273] = line;
const newContent = lines.join('\n');
fs.writeFileSync('assets/content/html_basics.md', newContent, 'utf8');
console.log('\nFixed!');
