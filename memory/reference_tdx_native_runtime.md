# TDX Native Runtime Reference

Date: 2026-05-22

TDX stock-analysis workflows should run natively by default, without Docker.

## Standard Runtime

- Native TDX API: `http://127.0.0.1:18800`
- K-line dashboard: `http://127.0.0.1:8050`
- History DB: `/Volumes/T7-APFS/DbWorkspace/history.db`
- Repo symlink: `tdx/history.db -> /Volumes/T7-APFS/DbWorkspace/history.db`
- RPS/cache DB: `tdx/rps.db`

## Start Commands

```bash
cd /Volumes/T7/Docker/openclaw-docker/tdx
./tools/start_native_tdx_api.sh
```

```bash
cd /Volumes/T7/Docker/openclaw-docker/tdx
TDX_API=http://127.0.0.1:18800 ./.venv/bin/python kline_dashboard.py
```

## Smoke Tests

```bash
curl -sS http://127.0.0.1:18800/quote/600438
curl -sS 'http://127.0.0.1:18800/kline/600438?period=daily&count=3'
curl -sS http://127.0.0.1:18800/analyze/600438
```

## Notes

- Do not default to Docker for TDX API, dashboard, Chanlun, backtests, or DuckDB records.
- Docker is only needed for unrelated compose services such as `openclaw-gateway`, `douyin`, or `ml-stock`.
- If `18800` is occupied by Docker, stop Docker Desktop or use temporary port `18802`.
- `com.docker.vmnetd` can remain after killing Docker Desktop and usually does not occupy business ports.

## Native EOD Sync Chain

Do not use the old Docker scheduler chain for TDX sync or EOD records.

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

`record_eod.py` depends on same-day `sw_rps` and `logs/chanlun_low_start_v04_1_YYYYMMDD.json`; if a prerequisite is missing, that step skips and the command continues.
