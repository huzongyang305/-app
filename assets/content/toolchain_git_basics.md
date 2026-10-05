# Git 版本控制

![Git 版本控制](images/category_git_basics.webp)

> 内容更新时间：2026-10-03 · 学习阶段：基础 · 预计用时：15 分钟

## 学习目标

- 能用自己的话解释「Git 版本控制」解决了什么问题，而不是只背术语。
- 能说清 「Git」、「提交」、「分支」、「合并」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「工具链」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：工作区、暂存区与仓库，以及分支和撤销操作。

## 前置知识

- 会进行基本的文件、命令行或浏览器操作；遇到不熟悉的术语先查本课关键词。
- 本课阶段：基础。建议会读写简单代码或命令，并理解变量、输入输出等基本概念。
- 开始前先复习：Git、提交、分支。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 为什么需要版本控制

Git 记录文件的每一次变化，让你可以查看历史、回退错误、多人并行开发而不互相覆盖。它的核心模型是**快照 + 指针**，而不是简单的「文件差异列表」。

## 三个工作区域

```text
工作区(Working Directory)
    ↓ git add
暂存区(Staging Area / Index)
    ↓ git commit
本地仓库(Repository)
    ↓ git push
远程仓库(Remote)
```

## 最常用的命令

```bash
git init                          # 初始化仓库
git clone <url>                   # 克隆远程仓库

git status                        # 查看当前状态
git add .                         # 添加所有改动到暂存区
git commit -m "feat: 添加登录功能"  # 提交

git log --oneline --graph         # 查看提交历史
git diff                          # 查看未暂存的改动
git diff --staged                 # 查看已暂存的改动
```

## 分支与合并

```bash
git branch feature/login          # 创建分支
git switch feature/login          # 切换分支
git switch -c fix/typo            # 创建并切换

git merge main                    # 把 main 合并到当前分支
git rebase main                   # 变基，使历史更线性
git branch -d feature/login       # 删除已合并的分支
```

## 撤销与回退

| 场景 | 命令 |
| --- | --- |
| 放弃工作区某个文件的修改 | `git restore file.txt` |
| 取消暂存 | `git restore --staged file.txt` |
| 修改最后一次提交信息 | `git commit --amend` |
| 回退提交但保留改动 | `git reset --soft HEAD~1` |
| 安全地撤销某次提交 | `git revert <commit>` |

共享分支上优先使用 `git revert`，不要用 `git reset` 改写已推送的历史。

## .gitignore

```gitignore
# 依赖与构建产物
build/
node_modules/
__pycache__/

# 本地配置与密钥
.env
*.keystore

# 编辑器
.idea/
.vscode/
```

## 写好提交信息

推荐 Conventional Commits 风格：

```text
feat: 新功能
fix: 修复缺陷
docs: 文档变更
refactor: 重构
test: 测试相关
chore: 构建与工具
```

## 冲突处理的完整流程

**合并冲突（merge）**

1. `git status` 看冲突文件（both modified），打开文件找到 `<<<<<<<`、`=======`、`>>>>>>>` 三处标记。
2. 决定保留哪一侧或手工融合，删掉全部标记行。
3. `git add <file>` 标记已解决，全部解决后 `git commit` 完成合并。
4. 想放弃这次合并：`git merge --abort` 回到合并前状态。

**变基冲突（rebase）**

1. 冲突后按同样方式解决并 `git add`。
2. `git rebase --continue` 继续；若发现方向错了用 `git rebase --abort` 完全放弃。
3. 变基会重写提交历史，**只对尚未推送的本地提交使用**；已推送的分支用 merge 或 revert。

减少冲突的实践：小步提交、频繁同步主干、同一文件的改动尽量由一人集中完成、避免长期分支。

## 救火命令速查

| 场景 | 命令 | 说明 |
| --- | --- | --- |
| 改乱了想丢弃工作区改动 | `git restore <file>` | 丢弃未暂存修改，不可恢复 |
| 提交信息写错 | `git commit --amend` | 只对未推送的提交使用 |
| 想撤销最近一次提交但保留改动 | `git reset --soft HEAD~1` | 改动回到暂存区 |
| 线上分支要撤销某次提交 | `git revert <sha>` | 生成反向提交，安全 |
| 误删分支 | `git reflog` + `git branch <name> <sha>` | reflog 记录 HEAD 移动历史 |
| 找回误删的暂存内容 | `git fsck --lost-found` | 找回 dangling 对象 |
| 查看某行是谁改的 | `git blame <file>` | 定位变更来源与提交 |

原则：**已推送的历史不改写**（revert 代替 reset），未推送的可以随意整理（amend、rebase、reset）。

## 本课小结
日常工作流就是：**改代码 → `git add` → `git commit` → `git push`**。养成小步提交的习惯，回退时才不会痛苦。


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

## 动手练习


> 本课练习重点：围绕「Git、提交、分支」完成复述、实验和交付，每个结果都要能被别人检查。

先在临时环境执行完整命令链，再模拟失败，最后验证回滚和清理。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「Git 版本控制」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「提交」是什么关系？

**验收标准**：至少出现一个本课关键词，并写出一个反例、边界条件或失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。

### 练习 3：交付一个小结果（30 分钟）

在一个临时目录或本地仓库执行完整命令链，并记录失败时的回滚办法。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「Git」和「提交」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。


## 考点精讲：把测验题还原成判断过程

本课有 5 个判断点。先自己作答，再看「判断依据」；如果结论正确但理由不完整，回到正文对应章节补足概念。

### 考点 1：git add 命令的作用是什么？

- **正确判断**：把改动添加到暂存区
- **判断依据**：git add 把工作区的改动放入暂存区，之后再执行 git commit 才会生成一次提交。 其他选项：生成提交要用 git commit，推送远程要用 git push，创建分支要用 git branch；git add 只负责把工作区改动放入暂存区。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 2：在已推送到远程的共享分支上，撤销某次提交应优先使用？

- **正确判断**：git revert
- **判断依据**：git revert 生成一个反向提交，不改写已有历史，适合共享分支；reset 和强推会影响其他协作者。 其他选项：reset --hard 与 push -f 都会改写共享分支的历史，影响其他协作者；git clean 清理的是未跟踪文件，属于工作区维护。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 3：想用一行一条的形式查看提交历史，应使用哪个命令？

- **正确判断**：git log --oneline
- **判断依据**：git log --oneline 每条提交只显示一行摘要，加上 --graph 还能查看分支结构。 其他选项：git diff 查看差异，git branch -a 列出分支，git status 显示工作区状态，只有 git log --oneline 以一行一条的形式输出提交历史。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 4：git rebase 与 git merge 的区别是？

- **正确判断**：rebase 把提交搬到新基底上得到线性历史，merge 生成合并提交保留分支结构
- **判断依据**：rebase 会改写历史，所以只在自己未共享的本地分支上使用。其他选项：rebase 产生的是线性历史，只有 merge 才生成合并提交。被 rebase 的提交哈希会改变，而 merge 不会重写已有提交。正确项「rebase 把提交搬到新基底上得到线性历史，merge 生成合并提交保留分支结构」是该问题的规范说法，换成其他表述都会丢失条件。错误项「两者完全等价」把因果关系颠倒了，不能作为正确结论。错误项「rebase 会产生合并提交（混淆了相邻概念，也没有覆盖题干给出的全部条件）」忽略了题目中的限制条件，因此不成立。错误项「merge 会重写提交哈希」属于相邻主题的说法，范围与本题要求不一致。把题干「git rebase 与 git merge 的区别是？」放回《Git 版本控制》的「工作区、暂存区与仓库，以及分支和撤销操作」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 5：git stash 的典型用途是？

- **正确判断**：临时保存未提交的改动
- **判断依据**：pop 恢复并删除记录，apply 则保留 stash 记录。其他选项：stash 不创建分支、不推送远程、更不会永久删除改动。它把未提交改动临时存起来，pop 恢复并删除记录，apply 恢复但保留记录。正确项「临时保存未提交的改动」既符合定义也满足题干限定的场景，因此应当选择。错误项「把改动的提交推送到远程」把因果关系颠倒了，不能作为正确结论。错误项「创建新的分支」把不同概念混在一起，缺少题干限定的前提。把题干「git stash 的典型用途是？」放回《Git 版本控制》的「工作区、暂存区与仓库，以及分支和撤销操作」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「git add 命令的作用是什么？」的判断依据。
- [ ] 不看解析，能说出「在已推送到远程的共享分支上，撤销某次提交应优先使用？」的判断依据。
- [ ] 不看解析，能说出「想用一行一条的形式查看提交历史，应使用哪个命令？」的判断依据。
- [ ] 不看解析，能说出「git rebase 与 git merge 的区别是？」的判断依据。
- [ ] 不看解析，能说出「git stash 的典型用途是？」的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## English Overview

**Title:** Git Basics

**Summary:** Working tree, staging area, branching and undo.

**Category:** Toolchain  
**Level:** 基础  
**Key terms:** Git, 提交, 分支, 合并, revert, 暂存区

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：基础
- 适用环境：Git / Docker / Kubernetes / CI 平台
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：Git、提交、分支、合并、revert、暂存区
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全


## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [Git 文档](https://git-scm.com/doc) | 版本控制与协作 |
| [Docker 文档](https://docs.docker.com/) | 容器与镜像 |
| [Kubernetes 文档](https://kubernetes.io/docs/) | 编排与运维 |

> 本课主题：工作区、暂存区与仓库，以及分支和撤销操作。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

