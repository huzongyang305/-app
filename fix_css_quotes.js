const fs = require('fs');
let content = fs.readFileSync('assets/content/css_basics.md', 'utf8');

// Replace escaped Unicode sequences with actual curly quotes
content = content.replace(/\\u201c/g, '\u201c');
content = content.replace(/\\u201d/g, '\u201d');

fs.writeFileSync('assets/content/css_basics.md', content, 'utf8');
console.log('Fixed Unicode quotes in css_basics.md!');
