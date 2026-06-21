# Stock Analysis Terminology

Date: 2026-06-21

## 适用场景

面向用户的中文股票分析、缠论分析、扫描结果解释、Dashboard / API 结果解释。

## trade_filter

User-facing Chinese stock analysis should localize internal technical labels:

- `trade_filter` should be written as `交易过滤`.
- Use `60m 交易过滤通过`, `30m 交易过滤未通过`, `交易过滤砍掉`.
- Keep internal JSON/API keys such as `trade_filter_passed` and `trade_reasons` unchanged for compatibility.

## 缠论引擎状态词

面向用户的输出中,不要直接写 `chanlun_native` / `line_segments` / `trend_types` / `StrictTrendDivergence` 的英文状态值和机器标签。统一用中文讲结构。

### 走势类型 status

| 内部值 | 用户可见写法 |
|---|---|
| `trend` | 已走出单边趋势 |
| `expansion` | 中枢扩张震荡 |
| `consolidation` | 盘整 |
| `no_center` | 还没形成线段级中枢 |

### 趋势背驰 status

| 内部值 | 用户可见写法 |
|---|---|
| `strict_candidate` | 线段级趋势背驰候选(已成形) |
| `strict_not_diverged` | 趋势成立但力度未衰竭,无背驰 |
| `not_trend` | 线段级还没走出趋势 |
| `no_segments` | 线段数不足,结构未成形 |

### 中枢状态

| 内部值 | 用户可见写法 |
|---|---|
| `broken_up` / `broken_down` | 向上 / 向下突破中枢 |
| `leaving_up` / `leaving_down` | 正在向上 / 向下离开中枢 |
| `forming` | 中枢形成中 |
| `extending` / `expanding` | 中枢延伸 / 扩张 |

### 买卖点候选

按 `reference_chanlun_108_core_rules.md` 和 `feedback_chanlun_engineering_label.md` 的四档中文说:

- 真买点
- 标准候选
- 候选存疑
- 伪买点

不要写 `B1_candidate conf=0.55`、`B3_candidate conf=0.85`、`detect_strict=no_segments` 这类机器标签。

## 优先级

内部字段 / JSON / 日志保持英文不变;只有面向用户解释时才用中文。
