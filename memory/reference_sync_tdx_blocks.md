# 板块同步与成分股 Reference

Date: 2026-06-21(2026-06-21 修订:删除 block.dat,改用东财成分)

## 适用场景

- 板块名称同步、板块 → 成分股、个股 → 所属板块查询。
- 板块 / 行业 RPS 计算时的成分来源疑问。
- 改动 `sync_tdx_meta.py` / `sync_board_members.py` 或新增板块元数据同步的任务。

## 核心结论:三个数据源各管各的,不要混用

| 需求 | 数据源 | 工具 / 表 | 截断? |
|---|---|---|---|
| 板块名称(880 指数 / 881 申万) | 通达信 + 静态映射 | `sync_tdx_meta.py` → `sector_names` / `sw_industry_names` | 无 |
| 个股 → 申万一级行业归属 | akshare `index_component_sw` | `sw_rps.py` → `sw_stock_industry` | 无 |
| 个股 → 概念 / 板块,板块全成分 | **东财** | `sync_board_members.py` → `stock_board_members` | 无 |
| **板块 / 行业 RPS** | **申万行业指数K线** | `sw_rps.py`(指数自带全成分) | **无,不依赖成分穷举** |
| ~~概念/风格/主题板块成分~~ | ~~通达信 block.dat~~ | **已删除(400 截断)** | — |

## block.dat 已删除(2026-06-21)

`sync_block_classification` 函数、`block_concept/style/theme` 三表、BlockReader import 全部删除(tdx@925c032)。

根因:**通达信 block.dat 格式每板块固定 2800 字节 = 400 只硬截断**(`BlockReader` 解析时 `pos = block_stock_begin + 2800`,2800/7字节=400)。这是文件格式死规定,不是读取 bug——文件里根本没存第 401 只之后的数据,改读取层无解。超过 400 只的大板块(光伏 / 新能源车等)成分永远不全。

且三表无真实消费方(只在摘要打印里被提名),删除安全。

## 关键:RPS 不依赖 block.dat,400 截断不影响 RPS

- **板块 / 行业 RPS** = `sw_rps.py` 取**申万行业指数(881xxx)本身的 K 线**算 N 日涨幅,31 个行业指数之间排名。指数由申万官方编制、自带全部成分,**不需要把成分股一只只加起来**,因此与 block.dat 的 400 截断完全无关。
- **个股 RPS** = 全市场个股各自算 N 日涨幅再排名,也不碰板块成分。
- 成分映射 `sw_stock_industry` 仅用于"个股属于哪个行业"反查,走 akshare 申万官方成分,非 block.dat。

## 当前板块同步入口

```bash
# 1) 板块名称(880/881)+ 股票名 + 行业归属
tdx/.venv/bin/python tdx/sync_tdx_meta.py

# 2) 个股↔概念/板块映射(东财,无截断,856 板块 / ~2091 只热门股 / 双向查)
tdx/.venv/bin/python tdx/sync_board_members.py            # 全量入库 stock_board_members
tdx/.venv/bin/python tdx/sync_board_members.py --stock 603009  # 某股所属板块
tdx/.venv/bin/python tdx/sync_board_members.py --board CPO概念   # 某板块成分股
```

`sync_board_members.py` 数据源东财 `RPT_F10_CORETHEME_BOARDTYPE`,原生直连 `datacenter-web.eastmoney.com`(通;`push2/push2his` 被 TLS 切,不用)。东财 filter 不支持 `like`,模糊查在本地 SQLite 用 LIKE。覆盖 ~2091 只有题材的股(F10 精选,非全市场穷举)。

## 与其他链路的区分

- 板块名称 = `sync_tdx_meta.py`,launchd `com.openclaw.tdx-sync`(每日 15:30)。
- 板块 RPS = `com.openclaw.sector-rps`(16:20)→ `run_sector_rps_daily.py` → rps.db。
- 板块资金流 = §23.8 `save_sector_capital_flow.py`(同花顺)/ §23.9 `save_sw_money_flow.py`(东财申万),见 reference_data_sync_chain。

## 教训案例

1. 880xxx 名称曾试图从 `block_zs.dat` 提取,但该文件装的是「股票→指数成分」(600519→沪深300),没有 880xxx 行;pytdx 也不暴露 880 名称字段,只能用 `services.sector_names` 静态映射兜底(~675 条)。
2. block.dat 每板块 400 只硬截断(2800 字节格式限制),读取层无法解决,应换数据源(东财)。RPS 用申万指数本身,从一开始就没踩这个坑。

## 优先级

板块名称走 `sync_tdx_meta.py`,板块成分走 `sync_board_members.py`(东财);不要再用 block.dat。写库走 history_db repository,单进程写 APFS(见 reference_history_db_repository / feedback_exfat_sqlite_corruption)。
