# 实时语音对话

![实时语音对话](images/remaining_ai_realtime_voice.webp)

> 内容更新时间：2026-10-03 · 学习阶段：高级 · 预计用时：15 分钟

## 学习目标

- 能用自己的话解释「实时语音对话」解决了什么问题，而不是只背术语。
- 能说清 「实时语音」、「VAD」、「ASR」、「TTS」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「AI 与智能体」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：VAD/ASR/LLM/TTS 流水线、延迟预算与打断处理。

## 前置知识

- 先完成上一课《Agent 评测实战》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：高级。建议具备同一方向的完整基础，能阅读较长的代码、配置或系统设计说明。
- 开始前先复习：实时语音、VAD、ASR。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 技术管线

```text
麦克风 -> VAD（静音检测）-> ASR（语音转文字）-> LLM（生成回复）
      -> TTS（文字转语音）-> 扬声器播放
```

实时性来自**流水线并行**：ASR 边识别边输出（流式）、LLM 边生成边分句、TTS 收到第一句就开始合成。

## 延迟预算

| 环节 | 目标 | 优化手段 |
| --- | --- | --- |
| 采集与 VAD | < 100 ms | 本地端点检测，减少等待 |
| ASR | < 300 ms（首字） | 流式识别、就近部署 |
| LLM 首 token | < 500 ms | 小模型先行、提示精简、KV 缓存 |
| TTS 首音频 | < 300 ms | 流式合成、预置音色 |
| 网络与播放 | < 100 ms | 就近接入、WebRTC/WebSocket |

端到端目标是「说完到听到回应」控制在 1 秒左右；超过 1.5 秒用户会明显感到卡顿。

## 打断（Barge-in）

用户不等播完就开口时，系统必须立刻停止播放并转而处理新输入：

```python
class VoiceSession:
    def __init__(self):
        self.cancelled = False
    async def speak(self, text: str):
        self.cancelled = False
        async for audio_chunk in tts_stream(text):
            if self.cancelled:            # 被打断立刻中止
                await self.player.stop()
                return
            await self.player.play(audio_chunk)
    async def on_user_speech(self):
        self.cancelled = True             # VAD 检测到用户开口
        await self.asr.start_stream()
```

要点：VAD 要能区分「用户说话」与「扬声器回声」，通常需要回声消除（AEC）。

## 传输协议

| 协议 | 特点 | 适用 |
| --- | --- | --- |
| WebSocket | 双向、实现简单、基于 TCP | 语音助手、字幕 |
| WebRTC | UDP、低延迟、自带回声消除与抖动缓冲 | 实时通话、强交互 |
| HTTP 流式 | 单向、简单 | 只播不说的场景 |

## 工程要点

1. 采样率与编码统一（常见 16 kHz 单声道、PCM/Opus），避免反复转码。
2. 音频分帧处理（20~40 ms 一帧），便于 VAD 与流式识别。
3. 设置静音超时（如 700 ms）判定「说完了」，过短会切断句子，过长会显得迟钝。
4. 多轮对话要维护上下文，同时限制历史长度控制成本。
5. 记录每段延迟（ASR/TTS/首 token），做端到端监控。

## 成本与质量权衡

- 简单指令走小模型或规则命中，复杂问题再交给大模型。
- 常用回复可缓存音频（如「好的」「请稍等」）。
- 语音合成按字符计费，回复要简洁；长内容改为「先播摘要 + 屏幕展示全文」。

## 延迟分解与优化实测方向

| 环节 | 常见耗时 | 优化手段 | 可降幅度参考 |
| --- | --- | --- | --- |
| 端点检测（VAD） | 300~700ms 静音等待 | 自适应阈值、缩短尾部静音 | 100~300ms |
| ASR 首字 | 200~500ms | 流式识别、就近部署、专用模型 | 100~200ms |
| LLM 首 token | 300~800ms | 小模型先行、提示精简、KV 缓存 | 200~400ms |
| TTS 首音频 | 200~500ms | 流式合成、预置常用短语音频 | 100~300ms |
| 网络往返 | 50~300ms | 就近接入、WebRTC 替代 WebSocket | 50~150ms |

优化顺序：先量出各段耗时（打点记录每段首字节时间），再优化占比最大的两段——**通常 VAD 等待与 LLM 首 token 是最大头**，而不是网络。

体验红线：端到端超过 1.5 秒用户就会明显感到卡顿；打断响应（barge-in）超过 300ms 会觉得"抢话抢不动"。这两个数字比任何模型参数都更影响主观感受。

## 本课小结
实时语音体验 = **低延迟 + 可打断 + 稳定识别**。把延迟拆成环节逐项优化，比单纯换更强的模型更有效。

<!-- appendix:v1 -->

## 管线与延迟预算速查

| 环节 | 典型耗时 | 优化方向 |
| --- | --- | --- |
| 采集与编码 | 10 到 30 ms | 小帧、低延迟编码 |
| VAD 检测 | 20 到 100 ms | 调灵敏度，避免过早切断 |
| 语音识别（ASR） | 100 到 500 ms | 流式识别、就近部署 |
| 大模型推理 | 300 到 2000 ms | 小模型、前缀缓存、流式输出 |
| 语音合成（TTS） | 100 到 400 ms | 流式合成、首包优先 |
| 网络往返 | 20 到 200 ms | 就近接入、QUIC |

经验目标：**端到端首响小于 800 ms**，交互才自然；超过 1.5 秒用户会明显感到卡顿。

| 管线形态 | 延迟 | 可解释性 | 适用 |
| --- | --- | --- | --- |
| 级联 ASR 到 LLM 到 TTS | 较高 | 强，便于替换与调试 | 大多数业务 |
| 端到端语音模型 | 较低 | 弱，难干预 | 追求自然度与低延迟 |
| 半级联（流式 ASR + 流式 TTS） | 中 | 中 | 平衡方案 |

## 打断（Barge-in）处理速查

| 步骤 | 动作 |
| --- | --- |
| 检测 | VAD 判断用户在说话 |
| 停止 | 立即停止当前 TTS 播放 |
| 丢弃 | 清空未播放的音频队列与旧回复 |
| 记录 | 把已播放内容作为上下文保留 |
| 重启 | 开始新一轮 ASR 与推理 |

```python
import time
from collections import deque
from dataclasses import dataclass, field

@dataclass
class VoiceSession:
    """带打断与首响统计的语音会话状态机。"""

    audio_queue: deque = field(default_factory=deque)
    speaking: bool = False
    started_at: float = 0.0
    first_audio_at: float | None = None
    interruptions: int = 0

    def on_user_speech(self) -> None:
        if self.speaking:
            self.interrupt()          # 用户开口立即打断
        self.started_at = time.monotonic()

    def interrupt(self) -> None:
        self.speaking = False
        self.audio_queue.clear()      # 丢弃未播放音频
        self.interruptions += 1

    def push_audio(self, chunk: bytes) -> None:
        if self.first_audio_at is None:
            self.first_audio_at = time.monotonic()
        self.speaking = True
        self.audio_queue.append(chunk)

    def first_response_ms(self) -> float | None:
        if self.first_audio_at is None:
            return None
        return round((self.first_audio_at - self.started_at) * 1000, 1)


def latency_budget(target_ms: int = 800) -> dict:
    """把目标延迟拆成各环节预算，便于分配优化任务。"""
    shares = {"asr": 0.35, "llm": 0.35, "tts": 0.2, "network": 0.1}
    return {name: int(target_ms * ratio) for name, ratio in shares.items()}


session = VoiceSession()
session.on_user_speech()
session.push_audio(b"\x00" * 1024)
print(session.first_response_ms(), latency_budget())
```

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 等整句识别完再送模型 | 首响延迟高 | 流式 ASR + 增量推理 |
| TTS 等全文生成完再合成 | 用户等很久 | 按句流式合成，首包优先 |
| VAD 过于激进 | 说话被截断 | 调整灵敏度与静音判定时长 |
| 打断只停播放不清队列 | 旧内容继续冒出 | 清空音频队列与在途请求 |
| 不做回声消除 | 自己的声音被识别为用户输入 | 用 AEC 或半双工策略 |
| 用大模型处理所有请求 | 延迟高 | 小模型优先 + 复杂请求升级 |
| 不监控首响延迟 | 体验退化无感知 | 打点首响与总时长并设告警 |
| 忽略网络抖动 | 偶发长延迟 | 就近接入、抖动缓冲自适应 |
| 全链路串行做重试 | 延迟叠加 | 只对关键环节重试并设上限 |
| 把语音数据长期留存 | 隐私风险 | 明确保留期限，默认不落盘 |

## 自测清单

- [ ] 能画出语音链路各环节的延迟预算。
- [ ] 端到端首响目标控制在 1 秒内。
- [ ] 打断时停止播放、清空队列并保留上下文。
- [ ] 处理回声与半双工场景。
- [ ] 首响与总时长有监控与告警。

## 动手练习

<!-- practice-diversified:v1 -->

> 本课练习重点：围绕「实时语音、VAD、ASR」完成复述、实验和交付，每个结果都要能被别人检查。

先写评测样例，再改一个提示、模型或数据变量，最后比较质量、成本与安全。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「实时语音对话」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「VAD」是什么关系？

**验收标准**：至少出现一个本课关键词，并写出一个反例、边界条件或失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。

### 练习 3：交付一个小结果（30 分钟）

构造 5 条小型离线样例，写清输入、期望输出、评分标准和失败案例。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「实时语音」和「VAD」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Real-time Voice

**Summary:** Pipeline, latency budget and barge-in.

**Category:** AI & Agents  
**Level:** 高级  
**Key terms:** 实时语音, VAD, ASR, TTS, 打断

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：高级
- 适用环境：主流大模型 API、开源模型与向量数据库
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：实时语音、VAD、ASR、TTS、打断
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

<!-- p2-references:v1 -->

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [OpenAI Docs](https://platform.openai.com/docs/) | 模型 API、工具与评估 |
| [Hugging Face Docs](https://huggingface.co/docs) | 模型、数据集与推理 |
| [Model Context Protocol](https://modelcontextprotocol.io/) | Agent 工具与上下文协议 |

> 本课主题：VAD/ASR/LLM/TTS 流水线、延迟预算与打断处理。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

