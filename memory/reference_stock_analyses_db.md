# Stock Analyses DB Reference

Date: 2026-06-21

## 适用场景

用于单票分析、板块判断、低位启动扫描、盘后记录、回归检验和历史结论追踪。高频运行入口只需要知道“单票分析完成后双写 DuckDB + Markdown”;具体字段和命令以本文件为准。

## 单票分析双写

每次单票分析完成后,如果本地工具可用,必须双写:

- DuckDB `raw_analysis_text` 字段,供 SQL 查询。
- Markdown 文件,供人眼浏览和 git 留痕。

推荐调用方式:

```bash
python3 /Volumes/T7/Docker/openclaw-docker/workspace/tools/save_analysis.py /tmp/aaa.json
```

必填字段:

```text
code
analysis_date
verdict
raw_analysis_text
```

`verdict` 允许 `买 / 持 / 卖 / 不碰 / watchlist`;用户可见交易动作仍只能是 `买 / 持 / 卖 / 不碰`,`watchlist` 只是观察状态。

建议补全:

```text
name
tier
core_logic
CANSLIM 七维 pass + note
I 综合 + 四细分
T1 三级状态
位置三窗口(pos_d250 / pos_w240 / weeks_from_low)
赔率(entry / stop / T1 / T2 / rr_ratio)
Narrative 四问
业绩快照
signals[](兑现 + 证伪)
```

完整字段见:

```text
/Volumes/T7/Docker/openclaw-docker/workspace/tools/schema.sql
```

成功返回:

```text
{aid}\t{md_path}
```

如果 `save_analysis.py` 不存在或工具不可用,不影响当前回答,但必须输出完整可复制 Markdown 正文。

## 分析前查历史

同一只票若 7 日内有过分析,先查历史:

```bash
python3 query_analysis.py history {code}
```

本轮正文必须显式说明:

```text
维持 / 修正 / 撤回
原因:
```

## 常用查询

```bash
python3 query_analysis.py history {code}
python3 query_analysis.py changes 7
python3 query_analysis.py latest
python3 query_analysis.py latest --watchlist
python3 query_analysis.py active
python3 query_analysis.py payoff
python3 query_analysis.py mistakes
python3 query_analysis.py sql "SELECT ..."
```

Markdown 文件可直接读:

```bash
cat workspace/analysis_logs/2026-04/603369_*.md
```

## 板块判断快照

只要输出申万一级板块 RPS 排名或板块强弱判断,必须落库:

```bash
python3 /Volumes/T7/Docker/openclaw-docker/workspace/tools/save_sector_verdicts.py <YYYY-MM-DD> [--market-state <M>]
```

写入 `stock_analyses.duckdb` 的 `sector_verdicts` 表,31 行业按同日覆盖。

label 自动按规则生成:

```text
长牛主线 / 底部启动 / type4失速 / 退潮 / 主跌 / 中性
```

回归示例:

```sql
ATTACH '/Volumes/T7/Docker/openclaw-docker/tdx/rps.db' AS r;
SELECT sv.sw_name, sv.label, sv.rps20 d0, f.rps dN, (f.rps-sv.rps20) delta
FROM sector_verdicts sv
JOIN r.sw_rps f ON f.code=sv.sw_code AND f.period=20 AND f.date='<未来日>'
WHERE sv.snapshot_date='<快照日>' AND sv.label='底部启动';
```

底部启动/长牛主线后续 `delta > 0` 为对;type4失速/主跌后续 `delta < 0` 为对。

## 低位启动扫描记录

只要跑了 `chanlun_low_start_v04_1.py` 全市场扫描,必须批量入库:

```bash
python3 /Volumes/T7/Docker/openclaw-docker/workspace/tools/ingest_lowstart.py --latest
```

写入规则:

- `structure_candidates` 中 trade + watchlist 批量写入 `stock_analyses`。
- `verdict=watchlist`。
- `session_id=lowstart_<date>`。
- 同日重跑覆盖。
- tier 写可入场 / 观察池;risk_tags 写入 falsify 信号。

回归通过 `trigger_outcomes` 事后回填触发结果,再用 `query_analysis.py payoff` 按 tier 统计收益/回撤。

## 收盘一键记录

手动一键:

```bash
python3 /Volumes/T7/Docker/openclaw-docker/workspace/tools/record_eod.py [YYYY-MM-DD] [--market-state M]
```

省略日期时使用 `history.db` 最近交易日。

原生 launchd 标准链:

| Time | launchd | Native command |
|---|---|---|
| 15:30 | `com.openclaw.tdx-sync` | `tdx/.venv/bin/python -u tdx/sync_tdx_meta.py` |
| 15:45 | `com.openclaw.chanlun-low-start` | `tdx/.venv/bin/python tdx/run_v042_pipeline.py` |
| 16:20 | `com.openclaw.sector-rps` | `tdx/.venv/bin/python tdx/scripts/run_sector_rps_daily.py --db tdx/rps.db --history-db tdx/history.db` |
| 16:35 | `com.openclaw.record-eod` | `tdx/.venv/bin/python workspace/tools/record_eod.py` |

不要把收盘记录链挂回 Docker scheduler。

五类齐全才算“做了记录”:

1. 单票分析双写。
2. 板块排名落 `sector_verdicts`。
3. 低位启动扫描批量入库。
4. 板块资金流向落 `sector_capital_flow`。
5. 申万行业资金流落 `sector_money_flow_daily`。

## 板块资金流向快照

每日盘后写入板块资金流向,与板块 RPS 互相验证:

```bash
.venv/bin/python /Volumes/T7/Docker/openclaw-docker/workspace/tools/save_sector_capital_flow.py [YYYY-MM-DD]
```

数据源:同花顺即时接口,通过 host_fetch_relay 绕开东财 push2 TLS 切断。

写入表:`sector_capital_flow`

关键字段:`net_yi`,主力净额,正数为流入,单位亿元。

查询:

```bash
python3 query_analysis.py flow [日期]
python3 query_analysis.py flow-history 行业 半导体 30
```

用途:
- 连续 3 天净流出 > 50 亿 = 派发期。
- 连续 3 天净流入 > 20 亿 = 资金承认底部启动。
- RPS5 高 + 资金流出 = 反抽假启动。
- RPS5 低 + 资金流入 = 真底部启动候选。

## 申万一级行业资金流聚合

每日盘后写入东财个股聚合口径:

```bash
.venv/bin/python workspace/tools/save_sw_money_flow.py [YYYY-MM-DD]
.venv/bin/python workspace/tools/save_sw_money_flow.py --backfill 2026-05-01 2026-05-31
```

写入表:`sector_money_flow_daily`

数据源:`tdx/rps.db` 的 `money_flow_daily` × `sw_stock_industry`。

查询:

```bash
python3 query_analysis.py sw-flow [日期]
python3 query_analysis.py sw-flow-history 电子 30
python3 query_analysis.py sw-flow-rank 20
```

用途:
- N 日累计资金流向趋势观察。
- 换仓决策:旧仓行业 vs 新仓行业的 5 日 / 20 日累计净流入。
- L 维度长牛主线锁定:60 日累计排名前 3 行业 = 真主线候选。

口径警告:
- `main_net` 单位是元,与同花顺板块快照的亿元口径不能直接相减。
- 单看排名和方向可信;数值用于横向对比,不用于绝对量级。
