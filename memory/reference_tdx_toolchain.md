# TDX Toolchain Reference

Date: 2026-06-21

## 适用场景

用于 TDX API、K 线 dashboard、DuckDB 记录、launchd EOD 链路、扫描脚本、回测脚本和本地工具链排障。高频交易回答只保留“优先原生 TDX、接口不可用不编造、单票分析要记录”;具体命令以本文件和 `memory/reference_tdx_native_runtime.md` 为准。

## 原生运行原则

TDX 股票分析链路默认不依赖 Docker。行情接口、K 线接口、综合分析、缠论单票/扫描、回测、DuckDB 记录、launchd 定时任务和 dashboard 都优先用本机 `.venv` 原生运行。

Docker 只用于其它 compose 服务,例如:

```text
openclaw-gateway
douyin
ml-stock
```

标准服务:

| Item | Value |
|---|---|
| Native TDX API | `http://127.0.0.1:18800` |
| K-line dashboard | `http://127.0.0.1:8050` |
| History DB | `/Volumes/T7-APFS/DbWorkspace/history.db` |
| Repo symlink | `tdx/history.db -> /Volumes/T7-APFS/DbWorkspace/history.db` |
| RPS/cache DB | `tdx/rps.db` |

## 启动与烟测

Start API:

```bash
cd /Volumes/T7/Docker/openclaw-docker/tdx
./tools/start_native_tdx_api.sh
```

Start dashboard:

```bash
cd /Volumes/T7/Docker/openclaw-docker/tdx
TDX_API=http://127.0.0.1:18800 ./.venv/bin/python kline_dashboard.py
```

Smoke tests:

```bash
curl -sS http://127.0.0.1:18800/quote/600438
curl -sS 'http://127.0.0.1:18800/kline/600438?period=daily&count=3'
curl -sS http://127.0.0.1:18800/analyze/600438
```

## API 调用顺序

交易分析默认按以下顺序取数:

1. 新闻 / 政策 / 个股公告:
   - `GET /news?source=cls&n=15`
   - `GET /news/policy?date=YYYYMMDD`
   - `GET /news/stock/{code}?n=10`
2. 市场:
   - `GET /screen/canslim/market`
3. 板块:
   - `GET /sw-rps/rank?period=20`
   - `GET /sw-rps/rank?period=50`
   - `GET /sw-rps/rank?period=250`
   - `GET /screen/emerging-sectors`
4. 个股:
   - `GET /quote/{code}`
   - `GET /finance/{code}`
   - `GET /stock/{code}/fund-sentiment`
   - `GET /sw-rps/stock/{code}`
   - `GET /kline/{code}?period=daily&count=250`
   - `GET /kline/{code}?period=60min&count=80`
   - `GET /kline/{code}?period=30min&count=80`
   - `GET /kline/{code}?period=weekly&count=240`
   - `GET /kline/{code}?period=monthly&count=150`
   - `GET /stock/{code}/inner-outer`
5. 必要时:
   - `GET /stock/{code}/money-flow`
   - `GET /stock/{code}/margin`
   - `GET /stock/{code}/lhb`
   - `GET /stock/{code}/institutional`

接口不可用时,必须写:

```text
本地行情接口不可用,本轮不编造 RPS / I 评分 / T 细节。
```

然后只基于公开数据、用户截图或用户提供数据做保守判断。

## EOD 链路

不要使用旧 Docker scheduler 链路。

| Time | launchd | Native command |
|---|---|---|
| 15:30 | `com.openclaw.tdx-sync` | `tdx/.venv/bin/python -u tdx/sync_tdx_meta.py` |
| 15:45 | `com.openclaw.chanlun-low-start` | `tdx/.venv/bin/python tdx/run_v042_pipeline.py` |
| 16:20 | `com.openclaw.sector-rps` | `tdx/.venv/bin/python tdx/scripts/run_sector_rps_daily.py --db tdx/rps.db --history-db tdx/history.db` |
| 16:35 | `com.openclaw.record-eod` | `tdx/.venv/bin/python workspace/tools/record_eod.py` |

Manual catch-up:

```bash
cd /Volumes/T7/Docker/openclaw-docker
tdx/.venv/bin/python workspace/tools/record_eod.py [YYYY-MM-DD] [--market-state M]
```

`record_eod.py` may skip missing prerequisites and continue; do not treat partial skip as permission to invent missing data.

## 工具索引

| Tool | Use |
|---|---|
| `workspace/tools/save_analysis.py` | 单票分析双写到 DB + Markdown |
| `workspace/tools/query_analysis.py` | history / changes / latest / watchlist / active / payoff / mistakes / SQL |
| `workspace/tools/save_sector_verdicts.py` | 板块判断快照入库 |
| `workspace/tools/ingest_lowstart.py` | 低位启动扫描结果批量入库 |
| `workspace/tools/save_sector_capital_flow.py` | 同花顺板块资金流快照 |
| `workspace/tools/save_sw_money_flow.py` | 申万一级行业资金流聚合 |
| `workspace/tools/record_eod.py` | 收盘一键记录 |
| `workspace/tools/schema.sql` | DuckDB schema |
| `tdx/run_v042_pipeline.py` | 低位启动/缠论候选标准流水线 |
| `tdx/scripts/run_sector_rps_daily.py` | 板块 RPS 日更 |

## 相关参考

- `memory/reference_tdx_native_runtime.md`:端口、启动、Docker 冲突、launchd 标准链路。
- `memory/reference_stock_analyses_db.md`:DuckDB 表、保存、查询、板块资金流和回归检验。
- `memory/reference_chanlun_native_engine.md`:缠论 native 引擎、画图和工具标签边界。
- `memory/reference_canslim_a_share.md`:交易裁决、仓位、CANSLIM 阈值和 I/T 口径。
