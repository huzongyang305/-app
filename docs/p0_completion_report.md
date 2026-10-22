# P0 内容收口报告（2026-10-07）

本轮 P0 处理的是内容层三个遗留问题：错误表不是本课内容、单图课程偏薄、609 门课
复核日期全部压在同一天。下面是处理结果与可复现的验证命令。

## 1. 常见错误与排查：215 门课按本课数据重写

- 新增作者工具 `tool/author_p0_mistake_tables.dart`，`curatedMistakeTables` 覆盖
  215 门课，每门至少 3 条本课真实易错点，统一写成
  `| 易错点 | 容易踩的做法 | 正确结论 |`。
- 重写时保留章节内表格之外的正文（对照图、补充段落），修掉了「重写吃掉配图」
  的缺陷；当前 280 门课的「常见错误与排查」带本课整理说明。
- 配套重建故障现场：`dart tool/rebuild_fault_scenarios.dart --dry-run` 显示
  「改动课程 0 / 已有具体场景 609 / 没有故障章节 0」。

## 2. 配图：67 门单图课程补齐第二张，7 张误删配图恢复

- 新增生成器 `tool/generate_p0_extra_diagrams.py`（46 张对照型 + 21 张流程型），
  输出 `assets/content/images/p0x_<lessonId>.webp` 与批次文件
  `tool/image_batches/p0_extra.json`；生成脚本自带文字宽度检查，67 张图 0 处超框。
- 用 `dart tool/insert_section_images.dart tool/image_batches/p0_extra.json`
  插到每课「本课小结」之前，单图课程从 67 门降到 0 门。
- 恢复 `visual_btree_index`、`visual_call_stack`、`visual_db_isolation`、
  `visual_http_timeline`、`visual_oauth_flow`、`visual_rate_limit_circuit`、
  `visual_tcp_handshake` 7 门课的对照图。
- 当前配图引用 1230 条 / 1222 个 WebP 文件，609 门课每课至少 2 张。

## 3. 复核排期：从「全部 2027-04-04」改为分批

- 新增 `tool/schedule_review_batches.dart`：按「本轮改动优先 + 风险」排序 38 个
  批次，把 `- 下次复核：YYYY-MM-DD` 分散到 12 个月（2026-11-10 起），写出
  `docs/content_review_schedule.md` 与 `.json`；当前 609 门课落在 36 个不同日期。
- 本轮改动过的 280 门课（重写错误表或新增配图）排在前面。
- **人工复核仍是 0/609**：`docs/content_review_records.json` 里没有真实复核人
  记录，台账保持 pending。排期只是计划，没有伪造复核结论。

## 4. 顺手修掉的内容缺陷

- 44 门课的「零基础精讲」里同一句话被重复写了 12 次：`tool/dedupe_repeated_sentences.dart`
  压缩 484 条重复句，只保留第一次。
- 8 门项目课共用的开场句改成各自领域的说法（算法工程、并发运行时、ETL、
  数据库调优、DevOps、移动离线、抓包分析、安全实验）。
- `tool/audit_scaffold_reuse.dart` 的白名单此前写成了带列表符号的前缀，永远匹配
  不上；已改为归一化后的前缀，复用句从 6 条降到 0 条。
- 预计用时随正文变化重新校准（分批 10 + 1 + 11 门），治理审计回到 0 错误 0 警告。

## 5. 验证记录

| 命令 | 结果 |
| --- | --- |
| `dart tool/audit_content_governance.dart` | 错误 0 / 警告 0（609 门课、3443 道题） |
| `dart tool/audit_content_quality.dart` | 错误 0 / 警告 0，配图引用 1230 |
| `dart tool/audit_content_depth.dart` | 最短课程 10,269 字符，平均 13,166 字符 |
| `dart tool/analyze_quiz_quality.dart` | 元问题 0、模板句 0、解析 <120 字 0 |
| `dart tool/audit_scaffold_reuse.dart` | 复用句 0（阈值 ≥8 门） |
| `dart tool/verify_code_blocks.dart` | 代码块 3907 个，硬失败 0 |
| `flutter test test/content_test.dart` | 25 个断言全部通过 |
| `dart tool/author_p0_mistake_tables.dart --dry-run` | 重写 0 篇（数据 215 门，已一致） |
| `dart tool/rebuild_fault_scenarios.dart --dry-run` | 改动课程 0，已有具体场景 609 |
| `python tool/generate_p0_extra_diagrams.py` | 重新生成 67 张补全配图 |

## 6. 仍未完成的部分

- **人工复核 0/609**：需要真人按 `docs/content_review_batches.md` 的分批清单逐课
  核对事实、代码与引用，并把结论登记进 `docs/content_review_records.json`。
  这部分无法用脚本代替，本轮没有伪造任何复核记录。
- 内容资产变大后未重新打包 APK；README 里的 APK 体积数字仍是上一版打包结果，
  下次发布前需要重新执行体积门禁。
