# Chanlun Continuous Multi-Day Bars Feedback

Date: 2026-05-29

所有个股分析的缠论判断,默认必须三级齐看 + 连续多日 + 人工合笔。不能只看工具 `last_bi`,也不能只看单日数据。

## Mandatory Data

每次个股分析强制拉取:

- 日线:`/kline/{code}?period=daily&count=250`
- 60min:`/kline/{code}?period=60min&count=80`
- 30min:`/kline/{code}?period=30min&count=80`
- 周线 / 月线照旧拉取,但只做大方向定位

## Required Actions

1. 每一级独立人工合笔:每笔至少 5 根独立 K,顶底分型不重叠,列出方向 / 起讫 / 区间 / K 数。
2. 每一级独立识别中枢:最近 3 段同向笔的重叠区,ZG = 笔高 min,ZD = 笔低 max。
3. 3B 第一步:检验是否离开中枢上沿。
4. 3B 第二步:检验回踩是否不破中枢上沿 / 中枢区间。
5. 3B 第三步:检验是否再创新高。
6. 输出三级共振对照表;工具 `last_bi` 与人工合笔冲突时,以人工合笔为准,并标注差异原因。

## Hard Rules

- 周 / 月线只做大方向。
- 入场 / 持仓 / 卖出决策必须基于日线 + 60min + 30min 三级共振。
- 工具 `last_bi` 与人工合笔冲突时,以人工合笔为准。

## Lesson

2026-05-29 今世缘 603369:

- 工具 `last_bi=Down`。
- 人工合笔后实际是 Up 笔运行 +18.7%。
- 30min / 60min 3B 共振已成立。

结论:工具单点判断会漏掉连续多日、多级别结构;个股分析必须人工复核日线 + 60min + 30min。

## Applies To

- CANSLIM T1 缠论判断
- 纯缠论波段
- §35.6 递归买卖点
- 持仓诊断
- 换仓决策
