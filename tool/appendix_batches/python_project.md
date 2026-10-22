## requests 速查

| 目的 | 写法 |
| --- | --- |
| GET 请求 | `requests.get(url, params={"q": "x"}, timeout=5)` |
| POST JSON | `requests.post(url, json=payload, timeout=5)` |
| 表单提交 | `requests.post(url, data={"k": "v"})` |
| 自定义头 | `headers={"User-Agent": "..."}` |
| 检查状态 | `resp.raise_for_status()` |
| 解析 JSON | `resp.json()` |
| 读取文本 | `resp.text`（配合 `resp.encoding`） |
| 重试 | `HTTPAdapter` + `Retry` |
| 会话复用 | `with requests.Session() as s:` |
| 超时设置 | 元组 `(连接超时, 读取超时)` |

```python
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

session = requests.Session()
session.mount("https://", HTTPAdapter(max_retries=Retry(
    total=3, backoff_factor=0.5,
    status_forcelist=[429, 500, 502, 503, 504],
)))

try:
    resp = session.get("https://example.com/api/items",
                       params={"page": 1}, timeout=(3, 10))
    resp.raise_for_status()
    items = resp.json()["data"]
except requests.RequestException as exc:
    print("请求失败：", exc)
```

## pandas 速查

| 目的 | 写法 |
| --- | --- |
| 读 CSV / Excel | `pd.read_csv("a.csv")` / `pd.read_excel("a.xlsx")` |
| 查看概览 | `df.head()`、`df.info()`、`df.describe()` |
| 选列 | `df[["name", "price"]]` |
| 条件过滤 | `df[df["price"] > 100]` |
| 多条件 | `df[(df.a > 1) & (df.b == "x")]` |
| 分组聚合 | `df.groupby("category")["price"].mean()` |
| 透视表 | `df.pivot_table(index="cat", columns="month", values="price", aggfunc="sum")` |
| 排序 | `df.sort_values("price", ascending=False)` |
| 去重 | `df.drop_duplicates(subset=["id"])` |
| 缺失值 | `df.isna().sum()`、`df.fillna(0)`、`df.dropna()` |
| 新增列 | `df["total"] = df.price * df.qty` |
| 合并 | `df.merge(other, on="id", how="left")` |
| 应用函数 | `df["c"] = df.a.apply(lambda v: v * 2)` |
| 时间处理 | `pd.to_datetime(df.created_at)` |
| 导出 | `df.to_csv("out.csv", index=False, encoding="utf-8-sig")` |

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| `requests.get` 不设超时 | 请求可能永久挂起 | 一律设置 `timeout=(连接, 读取)` |
| 忽略 `raise_for_status()` | 4xx/5xx 当成正常数据处理 | 显式检查状态码 |
| 频繁创建新连接 | 慢且容易被限流 | 复用 `Session` 并配置重试 |
| 高频请求不控制速率 | 被封 IP | 加延时与并发上限，遵守 robots 与条款 |
| `df["a"] > 1 and df["b"] == 2` | `ValueError: truth value is ambiguous` | 用 `&` 并给每个条件加括号 |
| 链式赋值 `df[df.a > 1]["b"] = 0` | `SettingWithCopyWarning`，改动可能丢失 | 用 `.loc[df.a > 1, "b"] = 0` |
| 逐行 `for` 遍历 DataFrame | 慢几十倍 | 用向量化或 `apply`，必要时 `numpy` |
| 忘记 `index=False` 导出 | CSV 多出一列索引 | 导出时显式指定 |
| 日期字段当字符串比较 | 排序与筛选结果错误 | 先 `pd.to_datetime` |
| 中文 CSV 在 Excel 打开乱码 | 编码不匹配 | 导出用 `utf-8-sig` |

## 自测清单

- [ ] 所有网络请求都设超时、重试与状态检查。
- [ ] 抓取前确认目标站点的 robots 与使用条款。
- [ ] 数据清洗优先向量化，避免逐行循环。
- [ ] 分组统计用 `groupby` + 聚合函数。
- [ ] 导出 CSV 指定编码与 `index=False`。
