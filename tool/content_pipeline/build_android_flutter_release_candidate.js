// 生成 android_flutter_release 的替换课条目 + 候选 manifest。
// 只做「读取真实 manifest -> 克隆条目 -> 覆盖字段 -> 落盘」，不手改 manifest.json。
const fs = require('fs');
const DIR = 'F:/app/assets/content';
const MANIFEST = JSON.parse(fs.readFileSync(DIR + '/manifest.json', 'utf8'));

let source = null;
for (const c of MANIFEST.categories)
  for (const l of c.lessons) if (l.id === 'android_flutter_release') source = l;
if (!source) throw new Error('source lesson not found');

const md = fs.readFileSync(DIR + '/android_release_publishing.md', 'utf8');
const norm = (s) => String(s).replace(/\s+/g, '');

const quiz = [
  {
    question:
      'APK 签名方案 v1（JAR 签名）与 v2/v3（APK Signature Scheme）最关键的差别是什么？',
    options: [
      'v1 只能使用 RSA 算法生成密钥对，v2 与 v3 只能使用椭圆曲线算法',
      'v1 只校验压缩包内的文件条目，v2/v3 对整个 APK 字节做完整性签名',
      'v1 需要把签名私钥交给商店代管，v2 与 v3 必须由发布者自行生成保管',
      'v1 只出现在调试构建里，正式构建必须改用 v2 或 v3 才能通过校验',
    ],
    answer: 1,
    explanation:
      'v1 沿用 JAR 签名，签名信息写在 META-INF 里，只覆盖压缩包内的文件内容，因此改动 ZIP 对齐填充、中央目录这些没被它看守的字节不会破坏 v1 校验；v2 把签名块放在中央目录之前，对整包字节做摘要；v3 覆盖范围与 v2 相同，但使用更强的密钥算法并支持签名证书轮换。Android 7.0（API 24）开始校验 v2，更高版本还要求 v3，所以当 minSdk 低于 24 时通常三种方案同时启用，而不是只留其中一种。',
    type: 'single',
  },
  {
    question:
      '某模块声明 compileSdk 35、minSdk 24、targetSdk 35，关于这三个配置的实际含义，下列哪项正确？',
    options: [
      'minSdk 决定编译期可见的 API 级别，targetSdk 决定用户设备能否安装，compileSdk 只影响资源裁剪',
      'compileSdk 会改变应用运行时真正加载的系统类库版本，minSdk 只是给人看的说明文字',
      'targetSdk 声明可安装的最低系统版本，compileSdk 声明商店审核所用的模拟器版本',
      'minSdk 是可安装下限，targetSdk 是行为适配声明，compileSdk 只决定编译期可见 API',
    ],
    answer: 3,
    explanation:
      '三个数字各管一段。compileSdk 只影响编译期用哪份平台类库解析 API，产物运行时仍然使用设备自带的系统类库，所以单独提升它不会改变行为；minSdk 决定安装包能被哪些系统版本安装，低于它的设备在商店里看不到这个应用；targetSdk 是向系统声明已经把行为适配到该级别，系统据此决定是否启用新的后台、权限与通知限制。真正需要回归测试的是 targetSdk 的变化，写错的也最隐蔽，因为它不报错、只是行为突然不同。',
    type: 'single',
  },
  {
    question: '关于 APK 与 AAB（Android App Bundle）这两种发布产物，下列说法正确的是？',
    options: [
      'AAB 可以直接用 adb install 安装到真机做上架前验收',
      'APK 只适合商店上架，AAB 只适合企业内网的侧载分发',
      'AAB 要先由商店或 bundletool 转换成设备专用 APK 才能安装',
      '两者内容完全一致，区别只是文件后缀名和签名算法不同',
    ],
    answer: 2,
    explanation:
      'AAB 是发布中间格式，设备上没有包管理器能直接安装它。Google Play 收到 AAB 后，按设备指纹（CPU 架构、屏幕密度、语言）拆出专用 APK 再下发；本地验证要用 bundletool 生成 .apks 后安装。APK 才是可直接安装的成品，侧载、内网 MDM 分发只能用 APK，所以「APK 只适合商店、AAB 只适合侧载」正好说反。两者的差异是产物形态与下发方式，不是后缀名或签名算法。',
    type: 'single',
  },
  {
    question:
      '应用开启 R8 混淆与资源裁剪之后，下列哪两项做法能降低线上事故风险？',
    options: [
      '为所有第三方依赖统一加上 -dontwarn，让构建不再报缺类警告',
      '给反射、序列化和 JNI 用到的类补 -keep 规则，并重新做一轮回归',
      '只验证未混淆的调试包，因为正式包只是名字变了而行为不会变',
      '把每个发布版本的 mapping.txt 按版本号归档，供崩溃堆栈还原使用',
    ],
    answers: [1, 3],
    answer: 1,
    explanation:
      'R8 在缩减阶段会删除可达性分析认为用不到的类，而反射、JSON 序列化、JNI 与注解处理的引用关系要到运行时才确定，因此这些目标必须用 -keep 显式声明，验证也只能跑混淆后的 release 包。mapping.txt 是原名与混淆名的对照表，每次构建都不同，丢了就永远无法还原上报的 a.b.c 堆栈，所以每个版本都要归档。统一加 -dontwarn 只是把警告压掉，警告常常指向真实缺失的类，问题会被推迟到运行时；调试包没有开启缩减，通过与否不能代表正式包的行为。',
    type: 'multi',
  },
  {
    type: 'fill',
    question:
      '填空：Android 发布时商店用来判断能否覆盖安装的那个整数版本号叫____，它在 Google Play Console 上传时必须严格递增。',
    options: [],
    answer: 0,
    accepted_answers: ['versionCode', 'VersionCode', 'version code'],
    explanation:
      'Android 有两个版本号。versionName 是给用户在商店页面看到的字符串，例如 1.4.0，命名自由，系统不拿它做比较；versionCode 是内部整数，商店与安装器只用它判断新旧，只要不大于线上版本就会上传失败或提示无法覆盖。Flutter 工程里它出现在 pubspec.yaml 的 version: 1.4.0+140 中加号之后的位置，也可以在 Gradle 里直接指定；多渠道并行发版时要提前分配号段，避免两条流水线撞上同一个数字。',
  },
  {
    type: 'order',
    question:
      '下面是 Android 应用从准备签名到商店放量的四个环节，请按实际执行顺序排列。',
    options: [
      '在 Play Console 创建内部测试轨道并小范围放量',
      '生成并备份 keystore，配置 signingConfigs 与三个 SDK 版本',
      '构建 AAB，开启 R8 并核对 mapping 与产物体积',
      '上传产物，填写商店 listing、隐私政策与数据安全表单',
    ],
    answer: 0,
    correct_order: [1, 2, 3, 0],
    explanation:
      '顺序不能颠倒，因为签名身份一旦确定就不可更换：先解决 keystore 与 minSdk/targetSdk 这些边界，才谈得上产出可上传的包；随后在本地构建并开启 R8，核对 mapping.txt、体积基线，跑一遍混淆后的回归；边界与产物都稳定后再上传商店，补齐 listing、隐私政策与数据安全评分，这一步决定审核能否通过；最后才在内部轨道逐级放量，观察崩溃率与安装成功率，达标后向生产推进。反过来先放量再回头补密钥，会让同一个应用标识被错误的签名覆盖掉，属于不可逆事故。',
  },
];

// ---- 自检：解析长度 / 题干在正文中出现 / 单选正确项不是明显最长 ----
for (const [i, q] of quiz.entries()) {
  if (String(q.explanation).length < 120)
    throw new Error('q' + (i + 1) + ' explanation too short: ' + String(q.explanation).length);
  if (!norm(md).includes(norm(q.question)))
    throw new Error('q' + (i + 1) + ' stem missing in markdown');
  if (q.type === 'single') {
    const correct = q.options[q.answer].trim().length;
    const others = q.options.filter((_, k) => k !== q.answer).map((s) => s.trim().length);
    const gap = correct - Math.max(...others);
    if (gap >= 8) throw new Error('q' + (i + 1) + ' correct option too long: +' + gap);
  }
}

// ---- 组装替换条目：保留原 id/difficulty/order/minutes/prerequisites/related/code_quiz/lab ----
const lesson = JSON.parse(JSON.stringify(source));
lesson.title = {
  zh: 'Android 发布工程：签名、包体与上架轨道',
  en: 'Android Release Engineering',
};
lesson.summary = {
  zh: 'keystore 与签名方案、SDK 版本语义、AAB 分发、R8 混淆与发布轨道。',
  en: 'Keystores, signing schemes, SDK level semantics, AAB delivery, R8 mapping and release tracks.',
};
lesson.keywords = ['keystore', '签名方案', 'App Bundle', 'R8 混淆', '发布轨道'];
lesson.file = 'assets/content/android_release_publishing.md';
lesson.quiz = quiz;

fs.writeFileSync(
  'F:/app/new_android_flutter_release.json',
  JSON.stringify(lesson, null, 2) + '\n',
  'utf8',
);

const CAND = JSON.parse(JSON.stringify(MANIFEST));
for (const c of CAND.categories)
  for (let i = 0; i < c.lessons.length; i++)
    if (c.lessons[i].id === 'android_flutter_release') c.lessons[i] = lesson;
fs.writeFileSync(
  'F:/app/manifest_android_flutter_release_candidate.json',
  JSON.stringify(CAND, null, 2),
  'utf8',
);

console.log('written. kept fields:', [
  'id',
  'difficulty',
  'order',
  'minutes',
  'prerequisites',
  'related',
  'code_quiz',
  'lab',
].filter((k) => k in lesson).join(','));
console.log('title.zh:', lesson.title.zh, '| has 实战/项目:', /实战|项目/.test(lesson.title.zh));
