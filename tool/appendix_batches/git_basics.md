## 场景速查：改错了怎么退

| 想撤销的范围 | 命令 | 是否改写历史 | 说明 |
| --- | --- | --- | --- |
| 只丢弃工作区改动 | `git restore <file>` | 否 | 危险：未提交的修改会永久丢失 |
| 把文件移出暂存区 | `git restore --staged <file>` | 否 | 保留工作区改动 |
| 修改最近一次提交 | `git commit --amend` | 是 | 只对**未推送**的提交使用 |
| 撤销已推送的提交 | `git revert <commit>` | 否 | 生成一个反向提交，团队协作首选 |
| 回退本地未推送提交 | `git reset --soft HEAD~1` | 是 | 保留改动在暂存区；`--mixed` 保留在工作区 |
| 彻底丢弃若干提交 | `git reset --hard HEAD~1` | 是 | 危险操作，改动会丢失 |
| 恢复被 reset 掉的提交 | `git reflog` + `git reset --hard <sha>` | 是 | reflog 是本地操作的后悔药 |
| 临时切换分支 | `git stash push -m "说明"` | 否 | `git stash pop` 恢复并删除记录 |
| 只取某个提交的改动 | `git cherry-pick <sha>` | 否 | 常用于把修复同步到发布分支 |
| 放弃合并 | `git merge --abort` | 否 | 回到合并前状态 |

## 常用命令速查

| 目的 | 命令 |
| --- | --- |
| 查看简洁历史 | `git log --oneline --graph --decorate` |
| 查看某人改动 | `git log --author="张三" --oneline` |
| 查某行的最后修改者 | `git blame <file>` |
| 查某个字符串何时引入 | `git log -S "关键词" --oneline` |
| 查看工作区与暂存区差异 | `git diff` / `git diff --staged` |
| 暂存部分改动 | `git add -p` |
| 拉取并变基（保持线性） | `git pull --rebase` |
| 查看所有分支（含远程） | `git branch -a` |
| 删除已合并的本地分支 | `git branch -d <name>` |
| 打补丁文件 | `git format-patch -1 <sha>` / `git apply` |
| 临时排查（不切分支） | `git worktree add ../hotfix <branch>` |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| `git push -f` 到共享分支 | 同事的提交被抹掉 | 共享分支用 `--force-with-lease`，或直接 `revert` |
| 在共享分支上 `rebase` 并强推 | 所有人历史冲突 | 只在自己未共享的分支上 rebase |
| `git add .` 之后直接提交 | 把密钥、构建产物一起提交 | 先用 `git status` 与 `git diff --staged` 检查，维护 `.gitignore` |
| 提交了密钥 | 即使后续删除仍在历史中 | 立刻轮换密钥，再用 `git filter-repo` 清理历史 |
| 提交了几百 MB 的大文件 | 仓库体积永久变大 | 用 Git LFS 或外部存储；历史清理需重写提交 |
| 在 detached HEAD 上提交 | 切走后提交「消失」 | 先建分支：`git switch -c my-work` |
| 冲突时直接删掉对方代码 | 功能被静默移除 | 逐块理解双方意图，合并后跑测试 |
| 反复 merge 主分支 | 历史像麻花，排查困难 | 用 rebase 保持线性，或统一团队策略 |
| 忘记 `.gitignore` 忽略 `.env` | 环境配置被推送 | 项目初始化就把敏感文件加进忽略列表 |
| 直接在主分支开发 | 紧急修复无法发布 | 每个需求一个功能分支，通过 PR 合并 |

## 提交信息与协作约定

```text
<type>(<scope>): <简短描述>

fix(order): 修复超卖问题
feat(search): 支持按关键词高亮
docs(readme): 补充本地运行步骤
refactor(cache): 抽取缓存重建逻辑
```

常见 type：`feat` 新功能、`fix` 修复、`docs` 文档、`refactor` 重构、`test` 测试、`chore` 构建与杂项。

## 自测清单

- [ ] 能根据「是否已推送」选择 `revert` 还是 `reset`。
- [ ] 知道 `git restore`、`git restore --staged`、`git reset` 的区别。
- [ ] 会看 `git status` 再提交，避免误加文件。
- [ ] 共享分支上不做 rebase 与强推。
- [ ] 记得 `git reflog` 能救回误删的本地提交。
