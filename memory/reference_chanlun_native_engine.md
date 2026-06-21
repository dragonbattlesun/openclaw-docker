# 缠论 native 引擎使用规则

Date: 2026-06-21

## 适用场景

- 计算缠论分型、笔、线段、中枢、走势类型、趋势背驰、买卖点候选。
- 新写缠论分析、扫描、画图、回测、Dashboard 或工具解释。
- 对比工具标签和人工合笔结论。

## 核心定义

所有缠论结构计算统一使用项目自研 `chanlun_native` 引擎。禁止新代码使用三方缠论库或百分比 ZigZag 替代原文结构判断。

引擎路径:

| 组件 | 文件 | 作用 |
|---|---|---|
| 笔 / 分型 / 中枢 / 买卖点候选 | `tdx/chanlun_swing/chanlun_native.py` | `ChanlunAnalyzer` |
| 线段 | `tdx/chanlun_swing/line_segments.py` | `build_segment_list` |
| 走势类型 | `tdx/chanlun_swing/trend_types.py` | `build_segment_zhongshu_list` / `classify_trend_type` |
| 趋势背驰 | `tdx/chanlun_swing/strict_trend_divergence.py` | `StrictTrendDivergence` |
| 画图 | `tdx/tools/draw_chanlun_native.py` | native 笔 + 线段 + 中枢 + 走势类型 |

`tdx/chanlun_swing/chanlun_native.py` 的
`build_label_discipline_table(..., course_evidence_by_candidate=...)` 用于接入
第 82-86 课这类外部课程证据,例如分型对应小级别中枢确认、最小中枢构造纪律、
大小级别买卖点作用域、级别不能按时间升级。该参数只把已按信号时点截断的
证据写入每行 `course_evidence`,不改变候选数量、严格结论或交易许可。

## 判定步骤

1. 拉取对应级别 K 线。
2. 转为 `RawBar(dt, open, high, low, close, vol)`。
3. 用 `ChanlunAnalyzer(bars, level=...)` 生成笔和严格中枢。
4. 用线段、走势类型、趋势背驰模块补齐递归结构。
5. 工具候选只作候选;真买点必须连续多日、多级别、人工合笔复核。
6. `is_complete` 过滤未完成笔;未完成笔不能定性严格买卖点。

标准调用:

```python
import sys
sys.path.insert(0, "tdx")
from chanlun_swing.chanlun_native import RawBar, ChanlunAnalyzer

bars = [
    RawBar(dt=r.date, open=r.open, high=r.high, low=r.low, close=r.close, vol=r.vol)
    for r in df.itertuples()
]
ana = ChanlunAnalyzer(bars, level="daily")

bis = ana.bi_list
zss = ana.zhongshu_list_strict
```

## 输出要求

- 面向用户不要直接输出英文机器状态或 confidence 标签。
- 工具输出 `last_bi`、`B1_candidate`、`B3_candidate`、`decision.action` 只能翻译成候选或过滤状态,不能写成原文严格买卖点。
- 画图默认不做;只有用户明确要图、结构复杂需核对、或交付可视化报告时才画。

## 禁止事项

- 新写代码引入 `czsc` / `rs_czsc` / 百分比 ZigZag 做缠论结构判断。
- 手搓中枢替代 `zhongshu_list_strict`。
- 用工具 `last_bi` 替代连续多日人工合笔。
- 把机器标签直接展示给用户。

## 教训案例

2026-06-14 迁移复盘:裸 `czsc.CZSC().bi_list` 的笔端点受包含处理和分型确认影响,可能偏离真实极值约 1 天;笔端点错会导致中枢和买卖点全错。后续统一改用 native 笔端点真实极值。

## 关联

- `memory/reference_chanlun_108_core_rules.md`
- `memory/feedback_chanlun_continuous_multiday_bars.md`
- `memory/reference_stock_analysis_terminology.md`
