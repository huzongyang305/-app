// 共享资料文件去重：devops_monitoring.md 只服务 devops_monitoring。
// 删掉属于 devops_monitoring_alert 的资料锚点行，以及属于它的下次复核日期行。
const fs = require('fs');
const p = 'F:/app/assets/content/devops_monitoring.md';
const SCHEDULE = JSON.parse(fs.readFileSync('F:/app/docs/content_review_schedule.json', 'utf8'));
const planned = {};
for (const b of SCHEDULE.batches) for (const id of b.lesson_ids) planned[id] = b.planned_review_at;
const otherDate = planned['devops_monitoring_alert']; // 2027-02-17
const ownDate = planned['devops_monitoring'];         // 2027-01-13
if (!otherDate || !ownDate || otherDate === ownDate) throw new Error('schedule dates unusable');

const lines = fs.readFileSync(p, 'utf8').split('\n');
let removed = 0;
const anchor = lines.findIndex((l) => l.includes('[本课资料锚点 devops_monitoring_alert]'));
if (anchor >= 0) {
  lines.splice(anchor, 1);
  removed++;
  if (lines[anchor] !== undefined && lines[anchor].trim() === '' && lines[anchor - 1] !== undefined && lines[anchor - 1].trim() === '') {
    lines.splice(anchor, 1); // 顺带收掉多余空行
  }
}
const review = lines.findIndex((l) => l.trim() === '- 下次复核：' + otherDate);
if (review >= 0) {
  lines.splice(review, 1);
  removed++;
}
const out = lines.join('\n');
fs.writeFileSync(p, out, 'utf8');
console.log('removed lines:', removed);
console.log('alert anchor left:', out.includes('[本课资料锚点 devops_monitoring_alert]'));
console.log('alert date left:', out.includes('- 下次复核：' + otherDate));
console.log('own date kept:', out.includes('- 下次复核：' + ownDate));
console.log('last review kept:', out.includes('- 最后复核：2026-10-04'));
console.log('下次复核 count:', (out.match(/- 下次复核：/g) || []).length);
