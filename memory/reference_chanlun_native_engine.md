# 缠论 native 引擎使用规则

Date: 2026-07-25

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
| 中枢级别 / 走势结构规则 | `tdx/chanlun_swing/zhongshu_level.py` | 中枢关系、9 段延伸、a+A+b+B+c 结构门 |
| 线段 | `tdx/chanlun_swing/line_segments.py` | `build_segment_list` |
| 走势类型 | `tdx/chanlun_swing/trend_types.py` | `build_segment_zhongshu_list` / `classify_trend_type` |
| 趋势背驰 | `tdx/chanlun_swing/strict_trend_divergence.py` | `StrictTrendDivergence`（含 `detect_strict` 线段级趋势背驰） |
| 递归 proof 验证 | `tdx/chanlun_swing/recursive_proof_validation.py` | `validate_recursive_proof` 递归谱系验证 |
| 画图 | `tdx/tools/draw_chanlun_native.py` | native 笔 + 线段 + 中枢 + 走势类型 |

`tdx/chanlun_swing/chanlun_native.py` 的
`build_label_discipline_table(..., course_evidence_by_candidate=...)` 用于接入
第 82-86 课这类外部课程证据,例如分型对应小级别中枢确认、最小中枢构造纪律、
大小级别买卖点作用域、级别不能按时间升级。该参数只把已按信号时点截断的
证据写入每行 `course_evidence`,不改变候选数量、严格结论或交易许可。

`tdx/chanlun_swing/zhongshu_level.py` 的
`build_center_extension_higher_level_candidates()` 用于把单中枢连续 9 段同级别
延伸暴露为高一级中枢候选 evidence;它不拆分原中枢,也不说明本级别已形成趋势。
`classify_ababc_bsp_structure()` 组合 B 段完成门和标准背驰结构门,只判断
`a+A+b+B+c` 是否具备 `1B/1S` 结构候选前置;通过也不授予交易许可,不改变
`find_candidates()` 输出。

## 引擎演进记录（N5-N8）

### N5：买卖点候选 + 置信度（2026-06）

- 六类候选（B1/B2/B3/S1/S2/S3）统一从 `find_candidates()` 输出。
- 置信度基于笔完成度、证据条数、均线趋势加权；段未完成时硬性封顶 0.5。
- 健康度守卫：`_buy_bi_is_healthy()` 抑制回撤过深的向上笔候选；`_candidate_bi_is_recent()` 按级别检查笔是否过期。

### N6：MACD 四关背驰（2026-06-14）

- `_macd_bottom_divergence` / `_macd_top_divergence` 实现原文四关：
  - 关① 趋势前提（至少 2 个同级别中枢，后 GG < 前 DD / 后 DD > 前 GG）
  - 关② 波力度比较（`_wave_area` 按连续同向 MACD 柱运行分割，取最后一波）
  - 关③ DIF 极值验证（不再创新低/新高）+ B 段回抽 0 轴
  - 最终判决：趋势背驰（面积比 < 0.8）与盘整背驰分流
- B1 相对产出门：c 段低点相对 a 段，非全窗口最低。

### N7：线段级走势类型集成（2026-07-19）

- `ChanlunAnalyzer` 集成线段列表、线段中枢、走势类型分类。
- 所有候选证据自动附带线段级走势类型信息（trend/consolidation/expansion/…）。
- `detect_strict()` 线段级趋势背驰：用真线段 + 走势类型引擎替代连续同向笔近似，比 `detect()` 更贴近原文「中枢由次级别走势类型构成」。

### N8：线段中枢优先（2026-07-21）

- `_effective_centers_for_trend()` 在趋势/背驰关① 优先使用线段级中枢。线段中枢未形成时回退到笔级 strict 中枢。
- 原理：线段级中枢由次级别走势类型重叠构成，比笔级中枢更接近原文「中枢由次级别走势类型构成」。

## 笔状态机恢复路径

笔构建 `build_bi_list()` 对同向更极端分型的处理有 4 条恢复路径，按严格降序：

1. **`_replace_last_bi_with_more_extreme_end`** — 标准同向极值延伸。
2. **`_recompose_last_two_bis_with_pending_opposite`** — 若 pending 反向分型能与后面的同向分型组成严格笔，拆分末两笔重组。
3. **`_extend_last_bi_over_too_small_pending_opposite`** — 若 pending 反向分型级别过小（前后双向均缺独立 K），按小级别转折忽略，末笔直接延伸。延伸后的笔携带 `ignored_opposite_fx` 字段供后续复检沿用同一豁免口径。
4. **`_recover_with_bridge_bi`** — 前三条路径全败时，用一根 `is_complete=False, bi_kind="bridge"` 桥接笔解锁状态机，再接 strict 笔。桥接笔不进 strict 中枢/买卖点（`strict_bis()` 过滤）。

路径 3 和 4 解决 600438（2025-08 豁免区极点导致续笔永远失败）和 000963（2023-12-27 锚点永久冻结）两类实战案例。

## 次级别区间套确认（2026-07-19）

- B1/B2 候选可通过 `sub_candidates` 参数传入次级别 B3/S3 候选，由 `_validate_b1_sub_level()` / `_validate_b2_sub_level()` 做区间套确认。
- S1/S2 同样支持次级别确认（`_validate_s2_sub_level()`）。
- 次级别 3B/3S 确认 → 置信度 +0.10；次级别索引超出父级别笔范围 → 忽略。

## 过期笔阈值

`MAX_STALE_BARS_BY_LEVEL` 控制候选笔距最新 K 线的最大允许距离：

| 级别 | 阈值（K线根数） |
|------|----------------|
| weekly | 6 |
| daily | 12 |

超出阈值的笔不生成买卖点候选，避免基于陈旧结构的信号。这是 2026-07-21 随 N8 一起收紧的（原 daily=20, weekly=8），理由：日线 2.5 个月、周线 1.5 个月无新结构时应重判走势。

## 判定步骤

1. 拉取对应级别 K 线。
2. 转为 `RawBar(dt, open, high, low, close, vol)`。
3. 用 `ChanlunAnalyzer(bars, level=...)` 生成笔、严格中枢、线段、走势类型。
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
segments = ana.segment_list
segment_zss = ana.segment_zhongshu_list
trend = ana.trend_type
```

## ChanlunAnalyzer 字段

| 属性/方法 | 说明 |
|---|---|
| `newbars` / `fx_list` / `bi_list` | 包含关系、分型、严格笔 |
| `zhongshu_list` / `zhongshu_list_all` / `zhongshu_list_strict` | 笔级中枢 |
| `segment_list` | 线段列表(基于严格笔) |
| `segment_zhongshu_list` | 线段级中枢 |
| `trend_type` | 线段级走势类型(no_center/consolidation/trend/...) |
| `get_segment_snapshot()` | 线段级结构摘要字典 |
| `get_candidates()` | 候选买卖点(自动带入线段级 evidence) |
| `snapshot()` | 笔级+线段级综合摘要 |

## 中枢 gg/dd 口径

`Zhongshu.gg/dd` 只反映中枢核心构成笔的外部波动边界。`leaving_up` / `leaving_down` / 横跨笔虽参与中枢状态判断,但其趋势段极值不并入 `gg/dd`,避免把后续 `后GG<前DD` / `后DD>前GG` 的趋势关系误判为级别扩张。

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
