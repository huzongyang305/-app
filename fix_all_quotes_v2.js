const fs = require('fs');
const path = require('path');

// Read manifest to get all lesson files
const manifest = JSON.parse(fs.readFileSync('assets/content/manifest.json', 'utf8'));

let fixedCount = 0;
const fixedFiles = [];

for (const category of manifest.categories) {
  for (const lesson of category.lessons) {
    const filePath = path.join('assets/content', lesson.file.replace('assets/content/', ''));
    
    if (!fs.existsSync(filePath)) {
      continue;
    }
    
    let content = fs.readFileSync(filePath, 'utf8');
    const originalContent = content;
    
    // Find all instances of 围绕"..."中的 pattern and replace with curly quotes
    // This regex matches: 围绕"any text"中的
    content = content.replace(/围绕"([^"]+)"中的/g, (match, p1) => {
      return `围绕\u201c${p1}\u201d中的`;
    });
    
    // Also fix: 按"..."中 pattern
    content = content.replace(/按"([^"]+)"中/g, (match, p1) => {
      return `按\u201c${p1}\u201d中`;
    });
    
    // Also fix: 把"..."的 pattern
    content = content.replace(/把"([^"]+)"的/g, (match, p1) => {
      return `把\u201c${p1}\u201d的`;
    });
    
    // Also fix: 选自"..."的 pattern
    content = content.replace(/选自"([^"]+)"的/g, (match, p1) => {
      return `选自\u201c${p1}\u201d的`;
    });
    
    // Also fix: 与"..."的 pattern
    content = content.replace(/与"([^"]+)"的/g, (match, p1) => {
      return `与\u201c${p1}\u201d的`;
    });
    
    if (content !== originalContent) {
      fs.writeFileSync(filePath, content, 'utf8');
      fixedCount++;
      fixedFiles.push(lesson.file);
    }
  }
}

console.log(`\nTotal files fixed: ${fixedCount}`);
if (fixedFiles.length > 0) {
  console.log('\nFixed files:');
  fixedFiles.forEach(f => console.log(`  - ${f}`));
}
