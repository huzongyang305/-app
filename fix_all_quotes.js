const fs = require('fs');
const path = require('path');

// Read manifest to get all lesson files
const manifest = JSON.parse(fs.readFileSync('assets/content/manifest.json', 'utf8'));

let fixedCount = 0;

for (const category of manifest.categories) {
  for (const lesson of category.lessons) {
    const filePath = path.join('assets/content', lesson.file);
    
    if (!fs.existsSync(filePath)) {
      continue;
    }
    
    let content = fs.readFileSync(filePath, 'utf8');
    const originalContent = content;
    
    // Fix common patterns:
    // 1. Replace straight quotes with curly quotes in quiz questions
    // Pattern: 围绕"XXX"中的 -> 围绕"XXX"中的
    content = content.replace(/围绕"([^"]+)"/g, '围绕\u201c$1\u201d');
    
    // Pattern: 按"XXX"中 -> 按"XXX"中
    content = content.replace(/按"([^"]+)"/g, '按\u201c$1\u201d');
    
    // Pattern: 把"XXX"的 -> 把"XXX"的
    content = content.replace(/把"([^"]+)"/g, '把\u201c$1\u201d');
    
    // Pattern: 选自"XXX"的 -> 选自"XXX"的
    content = content.replace(/选自"([^"]+)"/g, '选自\u201c$1\u201d');
    
    // Pattern: 与"XXX"的 -> 与"XXX"的
    content = content.replace(/与"([^"]+)"/g, '与\u201c$1\u201d');
    
    // Fix escaped Unicode sequences
    content = content.replace(/\\u201c/g, '\u201c');
    content = content.replace(/\\u201d/g, '\u201d');
    
    if (content !== originalContent) {
      fs.writeFileSync(filePath, content, 'utf8');
      fixedCount++;
      console.log(`Fixed: ${lesson.file}`);
    }
  }
}

console.log(`\nTotal files fixed: ${fixedCount}`);
