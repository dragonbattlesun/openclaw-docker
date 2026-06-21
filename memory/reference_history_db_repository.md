# History DB Repository Reference

Date: 2026-06-21

## 适用场景

适用于所有读写 TDX `history.db` 的代码和工具,包括日线 / 分钟 K 线同步、缠论扫描、回测、dashboard、严格 3B/3S 次级别确认、EOD 链路和后续新增脚本。

只要新代码或改动代码涉及 `stock_daily`、`stock_min1`、`stock_min5`、`stock_min30`、`stock_min60` 或 `fetch_meta`,默认必须走统一 repository,不能在业务模块里重复写散落 SQLite 连接、表名映射和 schema 初始化。

## 核心定义

- `history.db` 是本地 TDX K 线主库,标准路径由 `tdx/services/runtime_config.py` 的 `history_db_path()` 决定,默认指向 `/Volumes/T7-APFS/DbWorkspace/history.db`,仓库内 `tdx/history.db` 只是软链入口。
- `tdx/services/history_db.py` 是 `history.db` 的统一 repository。K 线表名、连接、schema、索引和标准读取都从这里进入。
- 标准连接必须使用 `connect_history_db()`,统一设置 `PRAGMA journal_mode=WAL` 和 `PRAGMA busy_timeout=60000`,减少同步链路和分析链路互相抢锁失败。
- 标准 schema 必须使用 `ensure_kline_schema()`,覆盖 `stock_daily`、`stock_min1`、`stock_min5`、`stock_min30`、`stock_min60`、`fetch_meta` 以及日期 / 时间 + 代码索引。
- 标准读取必须优先使用 `fetch_kline_rows(code, level, count, as_of=...)`,结果按时间正序返回;历史回放、回测、严格 3B/3S 次级别确认必须传 `as_of` 防止未来函数。
- 策略层、缠论结构层、评分层应消费 bars / rows,不要直接感知 SQLite;拉库和 API fallback 应放在 repository 或 fetcher 边界。

## 判定步骤

1. 需要 DB 路径时,先用 `history_db_path()`,不要硬编码 `tdx/history.db` 或外置绝对路径。
2. 需要 SQLite 连接时,用 `connect_history_db(db_path=None, timeout=60)`,不要在业务模块直接 `sqlite3.connect(...)`。
3. 需要初始化或补齐 K 线表时,用 `ensure_kline_schema(conn, levels=...)`。
4. 需要表名时,用 `kline_table(level)`;未知级别必须失败,不能静默拼接不存在的表。
5. 需要读取 K 线时,用 `fetch_kline_rows(...)`;如果调用方已有连接,传 `conn=` 复用连接。
6. 需要写入 K 线时,仍通过 repository 建连接和 schema,再在同步脚本内执行写入;表结构和索引不要在脚本里另起一套。
7. 严格 3B/3S 自动下钻时,优先用 `build_label_discipline_table(..., code=..., auto_fetch_third_bsp_child=True, third_bsp_as_of=...)`;显式传入次级别数据时,仍要保证 `as_of` 截断。
8. 数据缺失时只能降级为候选 / 人工复核,不能因为次级别库不可用就把 3B/3S 输出为严格可交易。

## 输出要求

- Review 或实现说明中,凡涉及 `history.db`,必须说明数据来源、级别、count、是否使用 `as_of` 截断、缺数据时的降级行为。
- 用户问 3B/3S 自动识别时,必须区分“自动拉取次级别数据”和“严格结论已成立”;没有直接次级别确认时,只能输出强候选或人工复核。
- 排障时先检查 `TDX_HISTORY_DB`、`history_db_path()`、软链和 WAL 锁,再看业务规则。
- 新增脚本如必须临时写原生 SQL,要把连接、schema、表名映射留在 repository 边界,并补测试覆盖。

## 正例

```python
from services.history_db import connect_history_db, ensure_kline_schema, fetch_kline_rows

conn = connect_history_db()
ensure_kline_schema(conn, levels=("daily", "30min", "5min"))
rows = fetch_kline_rows("600000", "30min", 80, as_of="2026-06-19 15:00:00", conn=conn)
```

```python
table = build_label_discipline_table(
    labels,
    code="600000",
    level="30min",
    auto_fetch_third_bsp_child=True,
    third_bsp_as_of="2026-06-19 15:00:00",
)
```

## 反例

```python
conn = sqlite3.connect("tdx/history.db")
```

```python
TBL = {"daily": "stock_daily", "5min": "stock_min5"}
```

```python
cursor.execute("SELECT * FROM stock_min5 WHERE code=?", (code,))
```

历史回测里自动拉取 5 分钟数据却不传 `as_of`,属于未来函数风险;严格 3B/3S 识别里次级别数据缺失却仍输出 `★可交易`,属于标签纪律错误。

## 优先级

本规则优先于旧脚本中散落的 SQLite 连接和表名映射。既有遗留代码可以分批迁移;但任何新代码、被本次任务触碰的代码、以及涉及严格 3B/3S 次级别确认的代码,必须按本文件执行。

若本文件与 `AGENTS.md` / 项目同级 context 的 TDX runtime 规则冲突,以 `AGENTS.md` / 项目同级 context 为准;若与旧 `CLAUDE.md` 长段落冲突,以本文件为准。

## 教训案例

2026-06-21:补全严格 3B/3S 自动识别时,次级别数据拉取最初容易把 `history.db` 连接、K 线表名和 schema 逻辑散落到 `multilevel_confirmation`、`fetch_minute`、`fetch_history` 等模块。最终统一封装为 `tdx/services/history_db.py`,并让分钟 / 日线同步和严格 3B/3S 自动下钻复用同一个 repository;测试覆盖 `connect_history_db`、`ensure_kline_schema`、`fetch_kline_rows`、未知级别失败、环境变量路径和 `as_of` 截断。
