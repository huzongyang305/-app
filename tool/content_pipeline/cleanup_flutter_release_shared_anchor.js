// 共享资料文件去重：flutter_release.md 只服务 flutter_release。
// 删掉属于 android_flutter_release 的资料锚点行，以及属于它的下次复核日期行。
const fs = require('fs');
const p = 'F:/app/assets/content/flutter_release.md';
const SCHEDULE = JSON.parse(fs.readFileSync('F:/app/docs/content_review_schedule.json', 'utf8'));
const planned = {};
for (const b of SCHEDULE.batches) for (const id of b.lesson_ids) planned[id] = b.planned_review_at;
const otherDate = planned['android_flutter_release'];   // 2027-01-03
const ownDate = planned['flutter_release'];             // 2027-08-10
if (!otherDate || !ownDate || otherDate === ownDate) throw new Error('schedule dates unusable');

const lines = fs.readFileSync(p, 'utf8').split('\n');
const anchor = lines.findIndex((l) =>
  l.includes('[本课资料锚点 android_flutter_release]'));
let removed = 0;
if (anchor >= 0) {
  lines.splice(anchor, 1);
  if (lines[anchor] !== undefined && lines[anchor].trim() === '' && lines[anchor - 1] !== undefined && lines[anchor - 1].trim() === '') {
    lines.splice(anchor, 1); // 顺带收掉多余空行
  }
  removed++;
}
const review = lines.findIndex((l) => l.trim() === '- 下次复核：' + otherDate);
if (review >= 0) {
  lines.splice(review, 1);
  removed++;
}
const out = lines.join('\n');
fs.writeFileSync(p, out, 'utf8');
console.log('removed lines:', removed);
console.log('anchor left:', out.includes('android_flutter_release'));
console.log('other date left:', out.includes('- 下次复核：' + otherDate));
console.log('own date kept:', out.includes('- 下次复核：' + ownDate));
console.log('last review kept:', out.includes('- 最后复核：2026-10-04'));
console.log('下次复核 count:', (out.match(/- 下次复核：/g) || []).length);
