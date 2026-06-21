# Chanlun Chart Tool & Level Rule Feedback

Date: 2026-06-21

画缠论图默认用 `tdx/tools/draw_chanlun_native.py`(最完整,多级别叠加),不要用单级别工具或临时手画脚本。并且不要误读 CLAUDE.md §16.1.1 第 5 条"禁止混级别画图"。

## 教训 1:绘图工具选错(北特科技 603009)

先用了 `chanlun_viz`(单级别)和临时 matplotlib 手画,都只画一个级别的笔 + 中枢,没标 30min 中枢。用户指出"有专用绘图类"。

正确工具 `tdx/tools/draw_chanlun_native.py` 一张日线图叠 7 层:
- 笔(如 52)
- 非严格桥接
- 线段(如 9)
- 笔级中枢
- 笔中枢扩张候选
- **线段级中枢**
- **30min 中枢(投影到日线,绿色小框)**

并输出走势类型(如"盘整方向待定")和买卖点标注数。

标准调用:

```bash
cd tdx && PYTHONPATH=. .venv/bin/python tools/draw_chanlun_native.py <code> \
  --period daily --bars 800 --name <名称> --save
```

- `--period` 支持 weekly/daily/60min/30min/15min/5min
- 默认本地不复权,除权股加 `--qfq`
- `--save` 归档到 `workspace/charts/{当日}/`(默认只写 /tmp,会被清)

## 教训 2:§16.1.1 第 5 条规则误读

我把"禁止混级别画图"当成"每张图只能画一个级别",据此用了单级别工具。

原文(CLAUDE.md §16.1.1 第 5 条):

> 禁止混级别画图:不能用 30m 的笔、5m 的回试、日线的中枢**拼成一个买点**;每个中枢必须说明由哪个级别的次级别走势构成。

禁的是**买卖点定性**层面用混级别零件拼结论,不是**画图展示**层面。原文后半句"每个中枢必须说明由哪个级别次级别构成" + 第 848 行"大级别中枢内部可含多个小级别中枢",反而鼓励一张图标清多级别来源。

## 正确区分

| 层面 | 规则 |
|---|---|
| 画图 / 展示 | ✅ 一张图可叠多级别结构,只要每层标明级别(draw_chanlun_native 即范本) |
| 买卖点定性 | ❌ 禁止用混级别零件拼一个买点;买点只能由本级别结构定性,小级别仅做触发 / 背驰 / 回试确认(§16.1.1 第 2、3、5 条) |

## 附带:用线段级中枢判盘整 / 趋势

draw_chanlun_native 输出走势类型时,用**线段级中枢**判定,别用近端小中枢误判"跌破 = 下跌"。

北特科技 603009 实例:现价 42.67 仍在**线段级大中枢 37.36-60.28 内部**,引擎判定走势类型 = 盘整(方向待定)、买卖点标注 = 0。这是"大中枢内盘整下沿震荡",不是"下跌趋势"。先前用近端小中枢说"跌破中枢 = 下跌"是错的。

## 相关

- `memory/reference_chanlun_native_engine.md`:结构权威引擎
- `memory/feedback_chanlun_continuous_multiday_bars.md`:连续多日多级别
- `memory/reference_chanlun_center_strength.md`:中枢力度
- CLAUDE.md §16.1.1 / §36.1
