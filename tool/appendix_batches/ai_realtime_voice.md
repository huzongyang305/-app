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
