const fs = require('fs');

const manifestPath = 'F:/app/assets/content/manifest.json';
const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));

// 找到Python分类
const pyCategory = manifest.categories.find(c => c.id === 'python');
if (!pyCategory) {
  console.log('❌ 未找到 python 分类');
  process.exit(1);
}

// 要删除的课程ID
const toRemove = [
  'python_list_dict_basics',        // 与 programming_python_data_structures 重复
  'programming_python_errors_files' // 与 python_errors_logging_files 重复
];

console.log('删除前的课程数:', pyCategory.lessons.length);

// 删除课程
pyCategory.lessons = pyCategory.lessons.filter(l => {
  if (toRemove.includes(l.id)) {
    console.log(`❌ 删除: ${l.id} - ${l.title.zh}`);
    return false;
  }
  return true;
});

// 重新编号order
pyCategory.lessons.forEach((l, i) => l.order = i);

console.log('删除后的课程数:', pyCategory.lessons.length);

// 保存manifest
fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2), 'utf8');
console.log('✅ manifest.json 已更新');

// 删除文件
const filesToDelete = [
  'F:/app/assets/content/python_list_dict_basics.md',
  'F:/app/assets/content/programming_python_errors_files.md'
];

for (const file of filesToDelete) {
  if (fs.existsSync(file)) {
    fs.unlinkSync(file);
    console.log(`✅ 已删除文件: ${file}`);
  } else {
    console.log(`⚠️ 文件不存在: ${file}`);
  }
}

console.log('\n✅ Python课程重复内容已清理');
