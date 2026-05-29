# Agent Runtime Notes

## TDX Native Runtime

Prefer the native TDX runtime for stock analysis workflows. Docker is no longer required for the local TDX API, K-line dashboard, Chanlun analysis, backtests, DuckDB records, or launchd scheduled jobs.

### Standard Services

- Native TDX API: `http://127.0.0.1:18800`
- K-line dashboard: `http://127.0.0.1:8050`
- History DB: `/Volumes/T7-APFS/DbWorkspace/history.db`
- Repo symlink: `tdx/history.db -> /Volumes/T7-APFS/DbWorkspace/history.db`
- RPS/cache DB: `tdx/rps.db`

### Start Commands

Start the native TDX API:

```bash
cd /Volumes/T7/Docker/openclaw-docker/tdx
./tools/start_native_tdx_api.sh
```

Start the dashboard without Docker:

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

### Runtime Rules

- Do not default to `docker compose up` for TDX tasks.
- Use Docker only for unrelated compose services such as `openclaw-gateway`, `douyin`, or `ml-stock`.
- If `18800` is occupied by Docker, stop Docker Desktop or the old Docker TDX services before starting native API.
- `com.docker.vmnetd` may remain as a system helper after Docker Desktop is killed; it does not occupy the TDX API ports.
- Use `TDX_API`, `TDX_API_URL`, `TDX_HISTORY_DB`, and `TDX_RPS_DB` to override native defaults when needed.

### Native EOD Sync Chain

Do not use the old Docker scheduler chain for TDX sync or end-of-day records.

| Time | launchd | Native command |
|------|---------|----------------|
| 15:30 | `com.openclaw.tdx-sync` | `tdx/.venv/bin/python -u tdx/sync_tdx_meta.py` |
| 15:45 | `com.openclaw.chanlun-low-start` | `tdx/.venv/bin/python tdx/run_v042_pipeline.py` |
| 16:20 | `com.openclaw.sector-rps` | `tdx/.venv/bin/python tdx/scripts/run_sector_rps_daily.py --db tdx/rps.db --history-db tdx/history.db` |
| 16:35 | `com.openclaw.record-eod` | `tdx/.venv/bin/python workspace/tools/record_eod.py` |

Manual EOD catch-up:

```bash
cd /Volumes/T7/Docker/openclaw-docker
tdx/.venv/bin/python workspace/tools/record_eod.py [YYYY-MM-DD] [--market-state M]
```

### Stock Analysis Wording

- In user-facing Chinese analysis, write `trade_filter` as `交易过滤`.
- Prefer phrasing such as `60m 交易过滤通过`, `30m 交易过滤未通过`, and `交易过滤砍掉`.
- Keep internal JSON/API field names such as `trade_filter_passed` unchanged for compatibility.

### Chanlun Multi-Day Multi-Level Rule

所有个股分析的缠论判断,默认必须**三级齐看 + 连续多日 + 人工合笔**,不能只看工具 `last_bi` 或单日数据。

**必拉数据(每次个股分析强制)**:
- 日线:`/kline/{code}?period=daily&count=250`
- 60min:`/kline/{code}?period=60min&count=80`(覆盖 ~20 个交易日)
- 30min:`/kline/{code}?period=30min&count=80`(覆盖 ~10 个交易日)
- 周线 / 月线照旧拉取做大方向定位

**必做动作(6 步)**:
1. 每一级独立人工合笔(每笔 ≥ 5 根独立 K + 顶底分型不重叠),列出每一笔的方向 / 起讫 / 区间 / K 数
2. 每一级独立识别中枢(最近 3 段同向笔的重叠区,ZG = 笔高 min,ZD = 笔低 max)
3. 3B 第一步:检验是否离开中枢上沿
4. 3B 第二步:检验回踩是否不破中枢上沿 / 中枢区间
5. 3B 第三步:检验是否再创新高
6. 输出三级共振对照表(周 / 日 / 60min / 30min / 5min 方向是否一致);工具 `last_bi` 与人工合笔结果冲突时,以人工合笔为准,标注差异原因

**铁律**:周 / 月线只是大方向,**真正的入场 / 持仓 / 卖出决策必须基于日 + 60min + 30min 三级共振**。

教训案例:2026-05-29 今世缘 603369,工具 `last_bi=Down` → 人工合笔后实际是 Up 笔运行 +18.7%,30min/60min 3B 共振已成立。详见 `memory/feedback_chanlun_continuous_multiday_bars.md`。

适用于:CLAUDE.md §1-§32 的 T1 缠论判断 / §35 纯缠论波段 / §35.6 递归买卖点 / §9 持仓诊断 / §22 换仓决策。
