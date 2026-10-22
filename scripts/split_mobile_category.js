const fs = require('fs');

const manifestPath = 'F:/app/assets/content/manifest.json';
const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));

// 找到现有的 flutter 和 mobile_advanced 分类
const flutterCategory = manifest.categories.find(c => c.id === 'flutter');
const mobileAdvancedCategory = manifest.categories.find(c => c.id === 'mobile_advanced');

if (!flutterCategory || !mobileAdvancedCategory) {
  console.log('❌ 未找到 flutter 或 mobile_advanced 分类');
  process.exit(1);
}

// 合并所有课程
const allLessons = [...flutterCategory.lessons, ...mobileAdvancedCategory.lessons];

// 分类规则
const flutterLessons = allLessons.filter(l => 
  l.id.includes('flutter') || 
  l.title.zh.includes('Flutter') ||
  l.title.zh.includes('Widget')
);

const iosLessons = allLessons.filter(l => 
  l.id.includes('swift') || 
  l.title.zh.includes('Swift') ||
  l.title.zh.includes('iOS') ||
  l.title.zh.includes('SwiftUI')
);

const androidLessons = allLessons.filter(l => 
  l.id.includes('kotlin') || 
  l.id.includes('jetpack') ||
  l.title.zh.includes('Kotlin') ||
  l.title.zh.includes('Android') ||
  l.title.zh.includes('Jetpack')
);

const crossPlatformLessons = allLessons.filter(l => 
  l.id.includes('react_native') || 
  l.id.includes('miniprogram') ||
  l.id.includes('harmony') ||
  l.title.zh.includes('React Native') ||
  l.title.zh.includes('小程序') ||
  l.title.zh.includes('鸿蒙') ||
  l.title.zh.includes('跨平台')
);

// 性能优化课程放到 flutter
const performanceLessons = allLessons.filter(l => 
  l.title.zh.includes('性能优化') && !crossPlatformLessons.includes(l)
);

// 更新 flutter 分类
flutterCategory.title = { zh: 'Flutter 开发', en: 'Flutter Development' };
flutterCategory.lessons = [...flutterLessons, ...performanceLessons].map((l, i) => ({
  ...l,
  order: i
}));
console.log(`✅ Flutter 开发：${flutterCategory.lessons.length} 课`);

// 创建 iOS 开发分类
const iosCategory = {
  id: 'ios_development',
  title: { zh: 'iOS 开发', en: 'iOS Development' },
  icon: 'phone_iphone',
  color: '007AFF',
  lessons: iosLessons.map((l, i) => ({ ...l, order: i }))
};
console.log(`✅ iOS 开发：${iosCategory.lessons.length} 课`);

// 创建 Android 开发分类
const androidCategory = {
  id: 'android_development',
  title: { zh: 'Android 开发', en: 'Android Development' },
  icon: 'phone_android',
  color: '3DDC84',
  lessons: androidLessons.map((l, i) => ({ ...l, order: i }))
};
console.log(`✅ Android 开发：${androidCategory.lessons.length} 课`);

// 创建跨平台开发分类
const crossPlatformCategory = {
  id: 'cross_platform',
  title: { zh: '跨平台开发', en: 'Cross-Platform Development' },
  icon: 'devices',
  color: 'FF9800',
  lessons: crossPlatformLessons.map((l, i) => ({ ...l, order: i }))
};
console.log(`✅ 跨平台开发：${crossPlatformCategory.lessons.length} 课`);

// 删除旧的 mobile_advanced 分类
manifest.categories = manifest.categories.filter(c => c.id !== 'mobile_advanced');

// 添加新分类
manifest.categories.push(iosCategory, androidCategory, crossPlatformCategory);

// 保存
fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2), 'utf8');
console.log('\n✅ 移动开发分类已拆分为 4 个独立分类');
