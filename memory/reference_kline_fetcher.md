# K 线拉取公共模块 Reference

Date: 2026-06-21

## 适用场景

- 任何拉取 A 股 K 线(日线 / 30min / 5min / 1min / 60min / 周 / 月)的代码。
- 全量同步、增量更新、单票补数、回测取数、缠论分析临时取数。
- 新写的取数脚本,以及改动到现有 `fetch_history.py` / `fetch_minute.py` 的任务。

只要涉及"连接通达信 + 分页拉 K 线 + 脏 bar 过滤",默认走统一公共模块,不在业务脚本里重复散写 pytdx 连接、分页循环和脏 bar 规则。

## 核心定义

- 统一公共模块:`tdx/services/kline_fetcher.py`(2026-06-21 提取,tdx@d531f80)。
- 标准取数:`fetch_klines(api, level, code, count=500, market=None, filter_minute=True)`。
  - `count > 0`:拉约 count 根(分页到够为止)。
  - `count <= 0`:**翻到底**——分页到服务器返回空 / 不足 800 为止,取该级别全部可得历史。
- 连接:`connect_api()` 轮询 `SERVERS` 通达信公共行情服务器。
- 级别归一化:`normalize_level()`(日线/日K→daily、30分钟→30min);未知级别 `category_for()` 直接报错不猜。
- category 映射:daily=4 / 30min=2 / 5min=0 / 1min=8 / 60min=3 / weekly=5 / monthly=6。
- 脏 bar 过滤:`_is_valid_minute_bar` 剔除午休 forming(13:00 等)和盘前盘后 vol<1 占位 bar;仅分钟级,日线不过滤(见 reference_minute_lunch_forming_bar / feedback_minute_lunch_forming_bar)。
- 入库行:`to_rows(code, level, data)` → `(code, dt, o, h, l, c, vol, amount)`;日线 dt 取 `YYYY-MM-DD`,分钟级取完整 `datetime`。

## 翻页深度上限(= 通达信服务器各级别保留上限,实测 2026-06-21)

| 级别 | 翻到底深度 | 说明 |
|---|---|---|
| 日线 | 上市起全历史(茅台 5943 根/24 年、平安 34 年) | 日线无保留期限,全量 |
| 30min / 5min | 约 2 年(2024 起) | |
| 1min | 约 100 交易日(约 5 个月) | 服务器硬上限,更早物理拿不到,任何免费源都一样 |

## 判定步骤

1. 取 K 线先用 `kline_fetcher.fetch_klines`,不要自己写 `get_security_bars` 分页循环。
2. 默认日线只取 2 年(count=500 够用);要长历史才传 `count<=0` 翻到底。
3. 分钟级默认 `filter_minute=True`;只有排障才关。
4. 需要级别 → category / 表名时,走 `category_for()` / history_db 的 `kline_table()`,不硬编码。
5. 写库走 `services/history_db.py` repository,单进程写 APFS(见 reference_history_db_repository / feedback_exfat_sqlite_corruption)。

## 消费方现状

- `fetch_history.py`:日线,默认 500 根(2 年),`connect_api` / `fetch_kline` 已委托公共模块;`count<=0` 可翻到底。
- `fetch_minute.py`:30/5/1min,FREQ_CONFIG 各级别 `full_history=True` 翻到底;`connect_api` / `fetch_kline` / 脏 bar 已委托。
- `workspace/tools/backfill_daily_from_api.py`:一次性补早期历史(走 HTTP API,非 pytdx),已完成使命,无定时引用,保留不改。

## 默认策略

日线日常只要 2 年就够(全市场翻到底会让库暴涨到几千万行,非必要不做);但保留翻页能力,要长历史传 `count=0`。

## 优先级

本规则优先于旧脚本里散落的 pytdx 连接和分页循环。新代码、被任务触碰的取数代码,一律走 `kline_fetcher`。与 AGENTS.md / 项目同级 context 冲突时以后者为准。
