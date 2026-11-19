# AI 与机器学习文献精读

![AI 论文四段式的英文信号词与对应读法](images/diagram_cs_english_ai_ml.webp)

> 内容更新时间：2026-10-06 · 学习阶段：进阶 · 预计用时：42 分钟

## 本节知识框架

**课程定位**：所属分类 `cs_english`（计算机专业英语），本课为第 6 门 · 学习阶段 进阶 · 建议用时 42 分钟。

先读一段真实摘要（arXiv 1706.03762，Attention Is All You Need 的开头三句）：

> The dominant sequence transduction models are based on complex recurrent or convolutional neural networks in an encoder-decoder configuration. The best performing models also connect the encoder and decoder through an attention mechanism. **We propose a new simple network architecture, the Transformer, based solely on attention mechanisms, dispensing with recurrence and convolutions entirely.**

三句话各干一件事：第一句给领域现状（`the dominant ... models are based on`），第二句给前人的共同做法（注意 `The best performing models also ...` 里的 also，它在暗示「大家都这样，所以还有改进空间」），第三句才是本文贡献。把第三句里 `based solely on attention mechanisms, dispensing with recurrence and convolutions entirely` 整块遮住，主干依然完整：`We propose a new simple network architecture, the Transformer.` 逗号后面那两段都是**分词短语作后置定语**，没有连词、没有谓语，是英文论文里最省字数的写法，也是中国读者最容易读成两个动作的一次性错觉。

配图把 AI 论文的四段（Abstract / Introduction / Method / Evaluation）排成四行三列：第一列给英文信号词，第二列说明它在文本里承担什么功能，第三列列出最容易读错的地方。**先认信号词，再读内容**，是本课贯穿始终的方法：它决定了你读到的是事实、主张，还是限制条件。

**复习清单**

- [ ] 能说出摘要四拍（问题、方法、结果、意义）各自的英文信号词
- [ ] 能区分 we propose、we show、we attribute this to 三档主张强度
- [ ] 能拆出含两个分词后置定语与两层 that 从句的方法句主干
- [ ] 能解释 transformer、attention、backpropagation、regularization 四个词的构词理据
- [ ] 能说清 training 与 inference 两个词在英文文本里的不同搭配对象
- [ ] 能从图注与表头里读出 x-axis、error bar、baseline、ground truth 四类信息
- [ ] 能判断 ablation study 一句在证明什么，以及它为什么不能当主结果引用

## 核心概念定义

| 术语 | 一句话说明 |
| --- | --- |
| 结构信号词 | 表明段落功能的固定短语，如 we propose、however、to our knowledge，读到就该切换阅读策略 |
| 研究缺口 | gap sentence，多以 However / Few studies / remains an open problem 起头，是引言段的转折点 |
| 后置定语 | based on、consisting of、trained on 等分词短语紧跟名词修饰它，不是句子的谓语 |
| 结果状语 | making、yielding 加分词短语，现在分词引出「因此造成」的结论，中文要补出「因此」 |
| that 从句嵌套 | the fact that ... shows that ... 中第一个 that 引导同位语从句，第二个引导宾语从句 |
| state of the art | 现有最优水平，作定语时写作 state-of-the-art；本文 establish a new state-of-the-art 表示刷新纪录 |
| ablation study | 消融实验，逐个拆掉组件再测，用来证明各部分的独立贡献，不属于主结果 |
| baseline | 对照方法，指被比较的已有模型或最简方法，不是坐标轴的原点 |
| ground truth | 标注真值，评测的参照标准，常见搭配是 evaluated against the ground truth |
| error bar | 误差棒，表示多次运行的波动范围，通常是标准差或置信区间 |
| overfitting | 过拟合，训练误差继续下降而验证误差回升；动词形式是 the model overfits the training set |
| inference | 推理阶段，模型训练完成后对外给出预测，与 training 阶段的动词搭配完全不同 |

## 原理与运行机制

### 一、摘要的四拍与三档主张强度

摘要平均 150~250 词，几乎都按「问题、方法、结果、意义」四拍推进。第二拍的动词决定主张强度：`we propose / we present / we introduce` 只声明「我们做了这个东西」；`we show / we demonstrate` 声明有证据支撑；`we prove` 在机器学习论文里极少见，出现时通常是理论工作。第三拍是量化结果，`outperforms the baseline by 2 BLEU`、`achieves 41.8 BLEU`、`yields a 12% reduction` 三种写法都算合格，缺数字的句子只是宣传。

1810.04805 的摘要第二、三拍非常标准：

> We introduce a new language representation model called BERT, which stands for Bidirectional Encoder Representations from Transformers. ... As a result, the pre-trained BERT model can be fine-tuned with just one additional output layer to create state-of-the-art models for a wide range of tasks, such as question answering and language inference, without substantial task-specific architecture modifications.

`which stands for ...` 是缩写还原的固定说法；`As a result` 后面的句子把「方法收益」和「代价之小（just one additional output layer、without substantial ... modifications）」写进了同一句，这是 AI 摘要最常见的自夸句式：**收益用数字，代价用 without / only / just 三个限定词**。读摘要时把这两个方向分开摘出来，两分钟就能建立一篇论文的定位。

### 二、长难句拆分：分词后置定语加三层 that

方法段爱用一句话说完整个机制。先把 1810.04805 里的关键句拆开：

> Unlike recent language representation models, BERT is designed to pre-train deep bidirectional representations from unlabeled text by jointly conditioning on both left and right context in all layers.

五层结构：`Unlike ...`（让步状语，先把对手推开）→ 主干 `BERT is designed to pre-train ... representations`（被动加不定式，`is designed to` 表示设计目的而非结果）→ `from unlabeled text`（数据来源）→ `by jointly conditioning on ...`（手段，by 加动名词）→ `in all layers`（范围限定）。`both left and right context` 才是这句话的技术要点：双向条件化。中文必须拆成三到四句，硬译成一句会得到谁也读不懂的结果。

再看一个方法段的典型三层 that 嵌套：

> The authors note that the model trained without regularization shows that attention weights concentrate on a few tokens, which is the reason that the gains disappear on longer inputs.

第一层 `note that` 带宾语从句；从句主干里 `the model trained without regularization` 的 trained 是后置定语不是谓语；第二层 `shows that ...` 又套一个宾语从句；`which` 指代前面整个事实，`the reason that` 后面是同位语从句。拆法永远是：找主句动词、把每个 that 后的从句降级成独立短句、把分词短语还原成「的」字结构。

### 三、术语构词与两个假朋友

`transformer` = `trans-`（跨越）+ `fer`（带来）+ `-er`，字面「把东西搬到另一边的东西」，所以 encoder-decoder 的搬运角色被整个名字概括；`attention` = `at-`（朝向）+ `tent`（伸展），字面「把心智伸向某处」，`attention weights` 就是「伸向哪些 token」的量化；`backpropagation` = `back`（回）+ `propagate`（传播，本义「繁殖、扩散」）+ `-ation`，与 `propagation delay`（传播时延）同源；`overfitting` 的 `over-` 表过度，与 `overhead`、`overflow` 同一前缀；`regularization` = `regular`（有规则的）+ `-ize`（使之）+ `-ation`（过程），语义是「给模型加规则」，即约束换泛化。

两个高频假朋友：`capacity` 在论文里是「模型能表达的复杂度」（模型容量），不是「生产能力」；`argument` 在代码里是「实参」，在论文里是「论证」，同一段文本里两者常同时出现。`inference` 也别只译成「推断」：工程语境里 `inference latency`、`inference cost` 说的是**上线后每次预测的开销**，与 `training` 阶段的 `training steps`、`checkpoint` 分属两套预算。

## 典型应用场景

### 场景一：读图注与坐标轴

```text
Figure 3. BLEU on the WMT 2014 English-to-German test set as a function of
training steps. Shaded regions show the standard deviation over four random
seeds. Baselines are reported from the original papers. Higher is better.
```

四个固定信息点：`as a function of` 说明横轴是自变量（横轴是训练步数，不是时间）；`Shaded regions show the standard deviation` 交代误差棒的口径，四颗随机种子意味着波动可能不小；`reported from the original papers` 是免责声明——基线数字不是作者复现的；`Higher is better` 给出箭头方向。图注里一旦出现 `best over 10 runs` 或 `mean of 3 seeds`，就要立刻判断这张图能不能与你的表格直接比较。

### 场景二：读实验表与脚注

| 表格里出现的英文 | 它在说什么 | 中文易错理解 |
| --- | --- | --- |
| Ours (large) | 本文的大模型变体，与 Ours (base) 同族 | 误以为是与本文无关的另一个工作 |
| bold / ↑ | 该列最优值；上箭头表示越大越好 | 只盯数字不看箭头方向 |
| † 或 \* 脚注 | 数字来源或统计约定，通常是复现设置不同 | 跳过脚注直接横向比较 |
| Baseline (published) | 引自原文的基线，未在本文环境重跑 | 当成同口径复现结果 |
| Ground truth | 评测参照的标注真值 | 当成「标准答案的模板代码」 |
| p < 0.05 | 差异显著性，与差距大小无关 | 把 significant 译成「很大」 |

### 场景三：结果段的比较与归因句

> Our model establishes a new single-model state-of-the-art BLEU score of 41.8 after training for 3.5 days on eight GPUs, a small fraction of the training costs of the best models from the literature.

主干之外两处信息：`after training for 3.5 days on eight GPUs` 把成本写进结果句，末尾 `a small fraction of the training costs ...` 是同位语形式的代价声明。`outperforms ... by` 的另一个常见变体是 `improving over the existing best results, including ensembles by over 2 BLEU`，这里 `including ensembles` 是插入语，用来强调「连集成模型也被超过」。归因句的骨架是 `We attribute this gain to ...`（我们把增益归因于……），它通常紧跟消融实验，语气比 `because` 更谨慎。

## 代码/协议/SQL 示例

### 用一段训练代码核对英文命名

```python
from sklearn.linear_model import Ridge
from sklearn.model_selection import train_test_split

X_train, X_test, y_train, y_test = train_test_split(X, y, random_state=0)
model = Ridge(alpha=10.0).fit(X_train, y_train)
print(model.score(X_test, y_test))
```

`Ridge` 的名字来自解曲面上那道凸起的脊，它是带 L2 惩罚的线性回归；`alpha` 是正则强度而不是学习率；`fit` 取「贴合」的日常义，表示训练；`score` 在回归器里默认返回 R²；预测新样本用的是 `predict`，这一步就是 inference。API 名本身是英文短句，把 `train_test_split` 读成「把数据切成训练集与测试集」比死记参数顺序可靠得多。

### 读训练与推理日志

```text
[train] epoch 12   loss 0.412   val_loss 0.455   lr 3e-4
[train] epoch 13   loss 0.398   val_loss 0.471   # val_loss 掉头，overfitting 的信号
[infer] samples 2048  batch_size 256  latency_p99 34.2ms  throughput 7400 req/min
[infer] cache miss 12.4%  oom_retries 0
```

`loss` 与 `val_loss` 的反向走势是过拟合最直观的英文证据；`lr` 是 learning rate 的缩写；`latency_p99` 与 `throughput` 分属延迟与吞吐两个口径，日志行里数字必须带着口径读，否则会把「p99 变好、均值变差」的退化看成优化成功。

## 时间/空间复杂度或性能分析

### 精读一篇论文的时间分配

以 12 页会议论文为例：摘要 3 分钟（只摘问题、方法、数字、结论）、引言 8 分钟（重点读 gap sentence）、方法 15 分钟（这一节必须动笔，把每个符号与图 2 对齐）、实验 10 分钟（先看表头再看数字）、related work 与结论 4 分钟扫读。总量约 40 分钟。判断自己有没有读懂方法段的标准很硬：能不能不看图注说出横纵轴是什么、哪个模块被消融掉了。

### 复杂度句式的英文形状

`Self-attention has quadratic complexity in sequence length, which dominates inference cost.` 里 `quadratic complexity in n` 是固定搭配（in 后接变量，不是 of），中文「关于序列长度的二次复杂度」；`The memory footprint grows linearly with the number of layers.` 用 `grows linearly with` 表达正比；`at the cost of additional parameters` 与 `with negligible overhead` 是一对代价描述。写作时用这三句替代「it is very fast/slow」，专业度立刻不同。

### 迭代成本：改一个词与改一个主张

术语级别的返工（把 `speedup` 改成 `latency reduction`）只影响单句；主张级别的返工（把 `we show` 降级成 `we suggest`）要求核对所有支撑句与图表；口径级别的返工（补上 `over 4 seeds`）往往要重做图。所以第一遍精读时就该把每篇论文的**数字口径**摘出来单独存档，第二遍只补口径缺口，比整篇重读省 60% 时间。

## 常见误区与易错点

| 序号 | 容易踩的做法 | 正确的判断 |
| --- | --- | --- |
| 1 | 把 `We propose ...` 读成作者在转述他人工作 | 主语是 we 时是本文贡献；转述他人常用 they propose 或 has been proposed |
| 2 | 把 `based solely on ...` 的分词当谓语 | 它是后置定语，主句谓语是 propose |
| 3 | 看到 `state of the art` 就译成「艺术状态」 | 固定短语，指现有最优水平，作定语加连字符 |
| 4 | 把 `significant` 译成「幅度很大」 | 它指统计检验显著，幅度大小是 substantial |
| 5 | 把误差棒长短直接读成性能差距 | 误差棒是波动范围，是否显著要看统计检验或脚注 |
| 6 | 把 `baseline` 理解成坐标原点 | 指被比较的已有方法或最简方法 |
| 7 | 把 ablation study 的数字当主结果引用 | 它是贡献拆解，绝对值通常低于完整模型 |
| 8 | 把 `inference` 一律译成「推断」 | 工程语境里指训练完成后的预测阶段与在线开销 |
| 9 | 把 `capacity` 译成生产能力 | 在模型语境里指模型能表达的复杂度，即容量 |
| 10 | 通读全文再回头查术语 | 先按信号词定位段落功能，再决定精读还是扫读 |

## 与其他知识点的关系

### 分类内的上下游

本课大量复用第 1 课 `cs_english_overview` 的派生词切分法（`trans/fer`、`regular/ize/ation`）与缩写还原路径，BERT、BLEU、GLUE 都要先还原再理解；第 3 课 `cs_english_os_software` 的被动语态读法在方法段完全同构；第 4 课 `cs_english_network_web` 里规范强度词 must、should 的语气分级，可以直接迁移到论文里 `we must` 与 `we should` 的差别；第 5 课 `cs_english_db_bigdata` 总结的「机制 + 代价」句式（`This typically involves ..., making ... a costly operation`），正是本课方法段与实验段共用的骨架。往后的第 7 课 `cs_english_paper_writing` 把这里的读法反转成写法，第 8 课讲文档与口语场景。

### 与技术类课程的对应

`ai` 分类里的 `ai_ml_fundamentals`、`ai_deep_learning_llm`、`ai_model_evaluation` 讲过梯度下降、transformer 与评测指标的实现，本课处理的是这些概念在英文里的名字与句式：为什么验证集叫 `validation set` 而不是 `test set`，为什么 `fine-tune` 与 `pre-train` 必须成对出现，为什么 `throughput` 与 `latency` 不能互换。把术语英文名记准，还能让你在检索时直接命中官方章节，绕开译文失真。

## 自测题与参考答案

下面 6 道题与「考点精讲」是同一批数据：题干、选项原文、答案字母（A 对应第 1 个选项）完全一致。建议先闭卷做完并记下自己的判断依据，再逐条核对。

### 题目 1（单选题）

论文摘要里 In this paper we propose a lightweight module that outperforms previous state-of-the-art systems on four benchmarks 一句话承担的功能，下列判断正确的是哪一项？

1. 只交代研究背景，说明这一领域此前的工作很多，尚未给出本文的贡献
2. 只交代实验设置，four benchmarks 说的是数据划分方式，与本文方法无关
3. 同时给出贡献声明与结果声明，propose 标记方法新颖性，outperforms 标记实验结论
4. 表示作者在转述他人工作，因为 propose 这个动词不能用于描述自己的工作

**参考答案**：同时给出贡献声明与结果声明，propose 标记方法新颖性，outperforms 标记实验结论

本题正确项是「同时给出贡献声明与结果声明，propose 标记方法新颖性，outperforms 标记实验结论」。摘要的四拍通常是问题、方法、结果、意义，第二句用 we propose / we present / we introduce 亮出方法，第三句用 outperforms / achieves / yields 给出量化结论，两句被压进同一行时，动词就是最可靠的定位标记。干扰项「表示作者在转述他人工作，因为 propose 这个动词不能用于描述自己的工作」把主语读错了：转述他人多用 they propose 或被动式 has been proposed，一旦出现 we propose 就是本文主张。干扰项「只交代实验设置，four benchmarks 说的是数据划分方式，与本文方法无关」把评测基准降格成分割说明，benchmarks 指公开数据集上的比较，不指 train-test split。

### 题目 2（单选题）

关于 overfitting 与 regularization 的构词与配对关系，下列说法正确的是哪一项？

1. over- 表过度，fit 加 -ing 指拟合过头；regularization 是用约束换泛化的手段
2. 两个词都直接借自拉丁语，与英语动词 fit 和形容词 regular 没有派生关系
3. -ization 表示一次完成的动作，正则化做完之后模型就不再需要任何约束
4. over- 在这里表不足，overfitting 说的是训练数据太少以致采样不充分

**参考答案**：over- 表过度，fit 加 -ing 指拟合过头；regularization 是用约束换泛化的手段

本题正确项是「over- 表过度，fit 加 -ing 指拟合过头；regularization 是用约束换泛化的手段」。这对词在论文里总是成对出现：方法段给出正则项（L2 penalty、dropout、early stopping），实验段报告它把验证误差压了下去；构词上 regular 加 -ize 是「使之有规则」，再加 -ation 名词化。干扰项「两个词都直接借自拉丁语，与英语动词 fit 和形容词 regular 没有派生关系」忽略了最表层的一层派生，英语母语者看到的就是 fit 与 regular 加词缀。干扰项「-ization 表示一次完成的动作，正则化做完之后模型就不再需要任何约束」把过程名词读成一次性事件，正则强度是训练全程都要设定的超参数。

### 题目 3（代码题）

读下面这段 scikit-learn 片段，关于 alpha、fit 与 score 三个英文名的实际含义，下列说法正确的是哪一项？

```python
from sklearn.linear_model import Ridge
from sklearn.model_selection import train_test_split

X_train, X_test, y_train, y_test = train_test_split(X, y, random_state=0)
model = Ridge(alpha=10.0).fit(X_train, y_train)
print(model.score(X_test, y_test))
```

1. alpha 是学习率，fit 表示绘制拟合曲线，score 输出训练集上的损失值
2. Ridge 一名说明该模型做无监督降维，train_test_split 只是把行打乱
3. score 只用到训练集，因此删掉 X_test 与 y_test 这段代码仍能运行
4. alpha 控制正则强度，fit 就是训练，score 在测试集上返回 R² 得分

**参考答案**：alpha 控制正则强度，fit 就是训练，score 在测试集上返回 R² 得分

本题正确项是「alpha 控制正则强度，fit 就是训练，score 在测试集上返回 R² 得分」。Ridge 回归的英文名来自解曲面上那道凸起的脊，alpha 是 L2 惩罚系数，值越大模型越平滑、越不容易 overfitting；fit 取「让曲线贴合数据」的日常义，score 在回归器里默认是 R² 而不是 accuracy。干扰项「alpha 是学习率，fit 表示绘制拟合曲线，score 输出训练集上的损失值」把三个名字全部挪到别的语境，学习率在梯度下降类框架里通常写作 learning_rate。干扰项「Ridge 一名说明该模型做无监督降维，train_test_split 只是把行打乱」混淆了有监督回归与 PCA；干扰项「score 只用到训练集，因此删掉 X_test 与 y_test 这段代码仍能运行」忽略了泛化评估的基本前提。

### 题目 4（多选题）

读 AI 论文的实验图与表，关于坐标轴、图例与脚注里几个英文词的作用，下列说法正确的有哪些？（多选）

1. error bar 表示不确定度，其跨度通常是标准差或置信区间而非性能差距
2. baseline 指的是横轴起点，也就是那个数值为零的参考线位置
3. ground truth 是标注真值，模型预测与之不符时应改模型而不是改标注
4. 表格里加粗与上标箭头通常表示该列最优或差异在统计上显著

**参考答案**：A、C、D

本题要同时选中「error bar 表示不确定度，其跨度通常是标准差或置信区间而非性能差距」、「ground truth 是标注真值，模型预测与之不符时应改模型而不是改标注」和「表格里加粗与上标箭头通常表示该列最优或差异在统计上显著」三条。误差棒描述多次随机种子运行之间的波动范围，两根柱子是否有差距要按统计检验判断，不能靠目测长短下结论；ground truth 是评测的参照标准，论文里写 evaluated against the ground truth。干扰项「baseline 指的是横轴起点，也就是那个数值为零的参考线位置」把 baseline 读成坐标原点，而论文里的 baseline 永远指用来对照的已有方法或最简方法，句子通常写成 compared with the strongest baseline。

### 题目 5（排序题）

把下面四句引言段的英文按论文正常的推进顺序（背景、缺口、方法、结果）排列，正确的是哪一项？

1. We therefore introduce a lightweight module that restores accuracy with fewer parameters.
2. Deep networks have been widely applied to image recognition tasks in recent years.
3. Experiments on three public datasets confirm the effectiveness of the proposed module.
4. However, these methods degrade sharply when the training set becomes small.

**参考答案**：B → D → A → C

引言段的推进是漏斗形的：先说这个方向已被广泛使用，再用 However 或 remains an open problem 打开缺口，然后用 We therefore / To address this problem 把自己的方法填进缺口，最后用 Experiments ... confirm 收口。排序线索就写在连接词里：therefore 必须紧跟在缺口之后，however 必须紧跟在背景之后，而 Experiments 一句只能落在段尾。把这四句的顺序记熟，读任何一篇会议论文的引言都能在两分钟内预判下一句说什么。

### 题目 6（填空题）

在空格处填入一个表示「消融」的英文术语：To show that each component matters, we conduct an ________ study by removing one module at a time.（填一个单词）

**参考答案**：ablation

本题正确项是「ablation」。这个词借自医学与气象学的 ablation（切除、移除），在机器学习里固定搭配是 ablation study 或 ablation experiment，含义是每次只拆掉一个模块再跑一遍，用性能落差证明各部分的独立贡献，论文里也常见 we ablate the attention block 这种动词用法。填 remove 或 delete 虽然意思接近，但不是文献里的标准术语，审稿人会认为作者没有做系统性对照。作答时先认出 conduct an ... study 这个空需要名词，再由 removing one module at a time 推出语义。

## 考点精讲

每条先给答案字母与正确项原文，再复述判断依据，字段内容与题库完全一致。

### 考点 1（单选题 · 摘要信号词）

- **题目**：论文摘要里 In this paper we propose a lightweight module that outperforms previous state-of-the-art systems on four benchmarks 一句话承担的功能，下列判断正确的是哪一项？
- **答案**：C
- **正确项**：同时给出贡献声明与结果声明，propose 标记方法新颖性，outperforms 标记实验结论
- **判断依据**：本题正确项是「同时给出贡献声明与结果声明，propose 标记方法新颖性，outperforms 标记实验结论」。摘要的四拍通常是问题、方法、结果、意义，第二句用 we propose / we present / we introduce 亮出方法，第三句用 outperforms / achieves / yields 给出量化结论，两句被压进同一行时，动词就是最可靠的定位标记。干扰项「表示作者在转述他人工作，因为 propose 这个动词不能用于描述自己的工作」把主语读错了：转述他人多用 they propose 或被动式 has been proposed，一旦出现 we propose 就是本文主张。干扰项「只交代实验设置，four benchmarks 说的是数据划分方式，与本文方法无关」把评测基准降格成分割说明，benchmarks 指公开数据集上的比较，不指 train-test split。

### 考点 2（单选题 · 术语构词）

- **题目**：关于 overfitting 与 regularization 的构词与配对关系，下列说法正确的是哪一项？
- **答案**：A
- **正确项**：over- 表过度，fit 加 -ing 指拟合过头；regularization 是用约束换泛化的手段
- **判断依据**：本题正确项是「over- 表过度，fit 加 -ing 指拟合过头；regularization 是用约束换泛化的手段」。这对词在论文里总是成对出现：方法段给出正则项（L2 penalty、dropout、early stopping），实验段报告它把验证误差压了下去；构词上 regular 加 -ize 是「使之有规则」，再加 -ation 名词化。干扰项「两个词都直接借自拉丁语，与英语动词 fit 和形容词 regular 没有派生关系」忽略了最表层的一层派生，英语母语者看到的就是 fit 与 regular 加词缀。干扰项「-ization 表示一次完成的动作，正则化做完之后模型就不再需要任何约束」把过程名词读成一次性事件，正则强度是训练全程都要设定的超参数。

### 考点 3（代码题 · API 命名）

- **题目**：读下面这段 scikit-learn 片段，关于 alpha、fit 与 score 三个英文名的实际含义，下列说法正确的是哪一项？
- **答案**：D
- **正确项**：alpha 控制正则强度，fit 就是训练，score 在测试集上返回 R² 得分
- **判断依据**：本题正确项是「alpha 控制正则强度，fit 就是训练，score 在测试集上返回 R² 得分」。Ridge 回归的英文名来自解曲面上那道凸起的脊，alpha 是 L2 惩罚系数，值越大模型越平滑、越不容易 overfitting；fit 取「让曲线贴合数据」的日常义，score 在回归器里默认是 R² 而不是 accuracy。干扰项「alpha 是学习率，fit 表示绘制拟合曲线，score 输出训练集上的损失值」把三个名字全部挪到别的语境，学习率在梯度下降类框架里通常写作 learning_rate。干扰项「Ridge 一名说明该模型做无监督降维，train_test_split 只是把行打乱」混淆了有监督回归与 PCA；干扰项「score 只用到训练集，因此删掉 X_test 与 y_test 这段代码仍能运行」忽略了泛化评估的基本前提。

### 考点 4（多选题 · 图表读法）

- **题目**：读 AI 论文的实验图与表，关于坐标轴、图例与脚注里几个英文词的作用，下列说法正确的有哪些？（多选）
- **答案**：A、C、D
- **正确项**：error bar 表示不确定度，其跨度通常是标准差或置信区间而非性能差距；ground truth 是标注真值，模型预测与之不符时应改模型而不是改标注；表格里加粗与上标箭头通常表示该列最优或差异在统计上显著
- **判断依据**：本题要同时选中「error bar 表示不确定度，其跨度通常是标准差或置信区间而非性能差距」、「ground truth 是标注真值，模型预测与之不符时应改模型而不是改标注」和「表格里加粗与上标箭头通常表示该列最优或差异在统计上显著」三条。误差棒描述多次随机种子运行之间的波动范围，两根柱子是否有差距要按统计检验判断，不能靠目测长短下结论；ground truth 是评测的参照标准，论文里写 evaluated against the ground truth。干扰项「baseline 指的是横轴起点，也就是那个数值为零的参考线位置」把 baseline 读成坐标原点，而论文里的 baseline 永远指用来对照的已有方法或最简方法，句子通常写成 compared with the strongest baseline。

### 考点 5（排序题 · 引言推进）

- **题目**：把下面四句引言段的英文按论文正常的推进顺序（背景、缺口、方法、结果）排列，正确的是哪一项？
- **答案**：B、D、A、C
- **正确项**：Deep networks have been widely applied to image recognition tasks in recent years. → However, these methods degrade sharply when the training set becomes small. → We therefore introduce a lightweight module that restores accuracy with fewer parameters. → Experiments on three public datasets confirm the effectiveness of the proposed module.
- **判断依据**：引言段的推进是漏斗形的：先说这个方向已被广泛使用，再用 However 或 remains an open problem 打开缺口，然后用 We therefore / To address this problem 把自己的方法填进缺口，最后用 Experiments ... confirm 收口。排序线索就写在连接词里：therefore 必须紧跟在缺口之后，however 必须紧跟在背景之后，而 Experiments 一句只能落在段尾。把这四句的顺序记熟，读任何一篇会议论文的引言都能在两分钟内预判下一句说什么。

### 考点 6（填空题 · 实验术语）

- **题目**：在空格处填入一个表示「消融」的英文术语：To show that each component matters, we conduct an ________ study by removing one module at a time.（填一个单词）
- **答案**：ablation
- **正确项**：ablation study
- **判断依据**：本题正确项是「ablation」。这个词借自医学与气象学的 ablation（切除、移除），在机器学习里固定搭配是 ablation study 或 ablation experiment，含义是每次只拆掉一个模块再跑一遍，用性能落差证明各部分的独立贡献，论文里也常见 we ablate the attention block 这种动词用法。填 remove 或 delete 虽然意思接近，但不是文献里的标准术语，审稿人会认为作者没有做系统性对照。作答时先认出 conduct an ... study 这个空需要名词，再由 removing one module at a time 推出语义。

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| we propose / we present | 摘要第二拍的贡献声明动词，主语是 we 时指本文而不是他人工作 |
| state of the art | 现有最优水平，定语形式写作 state-of-the-art，动词搭配是 establish / achieve |
| outperforms X by Y | 结果句骨架，by 后面是被超过的量，如 by 2 BLEU |
| ablation study | 消融实验，we ablate the module 是其动词写法，用来拆贡献而不是报主结果 |
| baseline | 对照方法，常见句是 compared with the strongest baseline |
| ground truth | 标注真值，评测参照，与 predicted label 成对出现 |
| error bar | 误差棒，标准差或置信区间的图形化，写作 shaded region |
| x-axis / y-axis | 横轴与纵轴，as a function of 后面的量通常在横轴 |
| attention | at-（朝向）+ tent（伸展），attention weights 记录模型把力气花在哪 |
| transformer | trans-（跨越）+ fer（带来），指把序列搬运成另一个序列的架构 |
| backpropagation | back + propagate（传播）+ -ation，梯度反向传播，与 propagation delay 同源 |
| overfitting / underfitting | over- 与 under- 的一对，前者记住噪声，后者连规律都没拟合上 |
| regularization | regular + ize + ation，用约束换泛化，L2 penalty、dropout 都属此类 |
| inference vs training | 前者是上线后的预测阶段与延迟开销，后者是训练步数与显存预算 |
| fine-tune / pre-train | 一对方向动词，pre-train 在无标注文本上，fine-tune 在下游任务上 |
| quadratic in sequence length | 复杂度句式，in 后接变量，表示关于序列长度是二次的 |

## 参考资料与复核

- 复核范围：arXiv 1706.03762 与 1810.04805 摘要引文逐字核对；图注、表头与复杂度句式的英文形状按原文页复核；scikit-learn 文档核对 Ridge 的 alpha 与 score 语义。
- 来源性质：预印本原文与官方文档，属一手语料；段落骨架的归纳为整理者总结。

| 参考资料 | 本课用途 |
| --- | --- |
| [arXiv 1706.03762: Attention Is All You Need](https://arxiv.org/abs/1706.03762) | `We propose a new simple network architecture` 与 state-of-the-art 结果句的原文出处 |
| [arXiv 1810.04805: BERT](https://arxiv.org/abs/1810.04805) | `which stands for ...` 缩写还原句与双向条件化长难句的原文出处 |
| [scikit-learn User Guide](https://scikit-learn.org/stable/user_guide.html) | Ridge 的 alpha、fit 与 score 三个 API 名的官方语义 |
| [NumPy linalg routines](https://numpy.org/doc/stable/reference/routines.linalg.html) | norm、matrix multiplication 等术语在数值库文档里的英文用法 |

- 最后复核：2026-10-04
- 下次复核：2027-03-24

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：进阶
- 预计用时：42 分钟
- 分类归属：`cs_english`（计算机专业英语），本课为第 6 门
- 适用环境：通用开发环境；本课聚焦 AI 与机器学习论文、图注与训练日志的英文原文读法。
- 内容来源：内置结构化课程与预印本、官方文档复核整理
- 相关主题：paper structure signal words, long sentence parsing, figure and metric reading
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全
