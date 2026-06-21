# 通达信板块同步 Reference

Date: 2026-06-21

## 适用场景

- 同步通达信板块名称和板块 → 成分股映射(概念 / 风格 / 主题 / 880 指数 / 881 申万)。
- 板块归属查询、板块成分股扫描、需要"某股属于哪些板块"的任务。
- 改动 `sync_tdx_meta.py` 或新增板块元数据同步的任务。

## 核心定义

统一入口 `tdx/sync_tdx_meta.py`:

```bash
cd /Volumes/T7/Docker/openclaw-docker
tdx/.venv/bin/python tdx/sync_tdx_meta.py        # 全量同步(5 步)
```

`main()` 编排 5 步:股票名 → 行业分类 → 880 名称 → 881 申万 → block 分类。板块相关 3 个函数(写 history.db):

| 函数 | 数据源 | 表 | 内容 |
|---|---|---|---|
| `sync_sector_names` | 静态映射 `services.sector_names` | `sector_names` | 880xxx 板块指数名,~675 个(market/region/industry/concept) |
| `sync_sw_industry_names` | pytdx `security_list` | `sw_industry_names` | 881xxx 申万行业名 |
| `sync_block_classification` | 通达信 block*.dat | `block_concept/style/theme` | 板块 → 成分股映射 |

核心 API:`api.get_block_info(fname, offset, 0x7530)` 分块下载三个文件:

- `block.dat` → concept(概念,~98 板块 / 16694 映射)
- `block_fg.dat` → style(风格,~153 / 22027)
- `block_gn.dat` → theme(主题,~270 / 40794)

下载后写 `/tmp` 临时文件 → `BlockReader().get_df()` 解析 → 入库 `block_{source}`(先 DELETE 再 INSERT)。

## 判定步骤

1. 要板块名称 / 成分映射,跑 `sync_tdx_meta.py`,不要另写 block.dat 解析。
2. 880xxx 名称只能用静态映射,不能尝试从 block_zs.dat 提取(见教训案例)。
3. 881xxx 若某轮 security_list 没返回,跳过本轮沿用旧表,不清空。
4. 区分"板块名称"和"板块强度 / 资金":名称在本链路;RPS / 资金流是另两条链路。

## 输出要求

- 涉及板块归属时说明数据来自 history.db 的 `sector_names / sw_industry_names / block_concept/style/theme`,以及最近同步日期。
- 不要把板块名称同步和板块 RPS / 资金流混为一谈。

## 与其他链路的区分

- 板块名称 + 成分 = `sync_tdx_meta.py`(本文件),launchd `com.openclaw.tdx-sync`(每日 15:30)。
- 板块 RPS = `com.openclaw.sector-rps`(16:20)→ `run_sector_rps_daily.py` → rps.db。
- 板块资金流 = §23.8 `save_sector_capital_flow.py`(同花顺)/ §23.9 `save_sw_money_flow.py`(东财申万),见 reference_data_sync_chain。

## 教训案例

880xxx 板块指数名称曾尝试从 `block_zs.dat` 提取,但该文件装的是「股票 → 指数成分」映射(如 600519 → 沪深300),根本没有 880xxx 行,导致 0 条入库。pytdx 也不暴露 880xxx 名称字段。最终只能用 `services.sector_names` 静态映射兜底(~675 条)。

## 优先级

板块元数据同步统一走 `sync_tdx_meta.py`;写库走 history_db repository,单进程写 APFS(见 reference_history_db_repository / feedback_exfat_sqlite_corruption)。
