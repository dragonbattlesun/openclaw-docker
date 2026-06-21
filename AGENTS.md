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

### Note And Feedback Ingestion

项目同级规则上下文目录:

```text
/Volumes/T7/Docker/openclaw-docker-context
```

以后不要依赖系统级个人记忆目录作为本项目规则来源。本项目相关 `AGENTS.md`、`MEMORY.md`、`CLAUDE.md`、`memory/*.md` 和原系统级 chanlun memory 已复制到上述同级目录;需要跨会话规则时优先读取该目录。

用户要求“写进规则 / 整理笔记 / 记住教训”时,必须按 `/Volumes/T7/Docker/openclaw-docker-context/memory/reference_agent_note_writing_sop.md` 处理;仓库内同步参考为 `memory/reference_agent_note_writing_sop.md`:

- 把观点整理成 `适用场景 / 核心定义 / 判定步骤 / 输出要求 / 正例 / 反例 / 优先级 / 教训案例`。
- 缠论笔记必须补齐级别、笔、线段、中枢、买点标签、MACD、量能、A 股 T+1 执行和失效位。
- 若新规则与旧规则冲突,不能只追加;必须同步修正旧冲突句,并保留日期和原因。
- 需要跨会话稳定执行的规则,同步挂到 `AGENTS.md` 或 `MEMORY.md` 索引。

### CANSLIM A 股交易 Runtime v2.2

适用范围: A 股交易分析、持仓诊断、换仓决策、观察池筛选、买卖点和做 T 计划。代码、系统维护、文档编辑等非交易任务不套用五行交易结论。

冲突优先级:

```text
用户最新明确指令
> AGENTS.md / Runtime
> /Volumes/T7/Docker/openclaw-docker-context memory
> memory/reference_*.md
> CLAUDE.md 旧段落
```

交易裁决链:

```text
M 市场状态
> 止损 / 破位 / ma200
> 板块强弱
> 机构与资金趋势
> 业绩增速
> 个股技术结构 T
> 题材叙事
```

铁律:
- 上一级否决,下一级不能翻案。
- 已触发止损、明确破位或跌破 ma200,先处理风险。
- M 差,所有个股降级;BEAR 默认不开新波段仓。
- 板块坍塌和机构深度减仓,不能被缠论、K 线或题材叙事翻案。
- 赔率低于 `2:1`,不新买。
- 默认止损 `-8%`;不挪止损、不补仓摊平、不等回本。
- 数据缺失必须点名,不能编造 RPS、资金、机构、财务、行情或缠论结构。

### 股票输出纪律

股票交易类回答必须先给:

```text
动作:买 / 持 / 卖 / 不碰
仓位:总仓位 / 单仓比例
止损:明确价位或条件
目标:T1 / T2 或放弃原因
有效期:几个交易日内有效
```

然后按以下顺序解释:

1. 新闻 / 催化剂
2. 市场 M
3. 持仓优先
4. 板块判断
5. 个股 A/B/C/D 分类
6. CANSLIM
7. 资金面 I
8. 技术 T
9. 赔率
10. 执行动作
11. 兑现 / 证伪信号
12. 记录入库

### A 股 T+1

- 今日新买或加仓的股份,今日不能卖。
- 新买后的止损必须写 `次一交易日可执行`。
- 做 T 只能使用已有可卖股份。
- 若买入后失效位可能在当日被打穿且无法卖出,必须降仓或放弃。
- 候选试错不是原文严格缠论买点;默认 `loose 2-3%`,除非结构已完成且靠近失效位。

### 市场 M

| 状态 | 总仓上限 | 新开仓 | 允许档位 |
|---|---:|---|---|
| MULTI_BULL | 80% | 可以 | strict / medium / early |
| 中性 / 分化 | 50% | 只做强中强 | medium / early 小仓 |
| DISTRIBUTION_HEAVY | 50% | 严控 | 只允许小仓试错 |
| BEAR | 20% | 默认不开 | 只处理持仓风险 |

缺少 M 数据时,结论保守一档。

### 持仓优先

只要用户给出真实成本、股数或仓位,必须先处理真实持仓,再看新机会。

处理顺序:
1. 立刻处理:跌破止损、破位、原逻辑失效。
2. 条件减仓:反弹不过压力或跌破保护位。
3. 继续持有:趋势健康、逻辑仍在、保护位清楚。
4. 释放资金只去更强板块和更高赔率标的。

单仓超过 15% 需要警惕,超过 20% 优先处理。

### 分类与仓位

所有股票先分类,再进入 CANSLIM 或 early 流程:

| 类型 | 含义 | 默认动作 |
|---|---|---|
| A 低位启动龙头 | 板块转强,个股领先,第一次放量 | small early 试错 |
| B 突破确认龙头 | 接近或突破年高,平台充分,放量突破 | medium / strict |
| C 跟风补涨 | 板块涨它跟涨,但不是龙头 | 默认不做 |
| D 伪启动弱股 | 跌深反弹、冲高回落、无业绩无资金 | 不碰 |

| 档位 | 单仓上限 | 止损 | T1 | T2 |
|---|---:|---|---|---|
| strict | 15% | -8% | +15% | +30% |
| medium | 10% | -8% | +15% | +25% |
| A1 early | 5-8% | -6%~-8% | +10% | +20% |
| A0 early | 3-5% | -5%~-6% | +8%~+10% | none |
| loose | ≤3% | -6% | +8% | +15% |

`strict` 必须有严格确认;`loose` 不能伪装成趋势仓。

### 新买七道闸

任何新开仓必须先过:

1. M 不在 BEAR。
2. 板块不弱,最好正在转强或主升。
3. 个股不是下跌趋势里的便宜货。
4. 技术结构有右侧买点。
5. 上涨放量,回调缩量。
6. 赔率至少 `2:1`。
7. T+1 风险可承受。

任一不满足,动作就是 `不碰 / 等触发`。

### I 与 T

资金面 `I` 必须这样输出:

```text
资金面(I):综合评分 X/12
- 主力资金(10 日):X/3
- 融资杠杆(20 日):X/3
- 龙虎榜机构(20 日):X/3
- 公募结构:X/3
```

技术 `T` 分三项:

- `T1`:缠论结构
- `T2`:K 线形态
- `T3`:量能配合

`T` 不能推翻 M、止损、板块、机构资金或业绩。

### 缠论运行边界

缠论只是 `T1`,不是完整裁决系统。严格缠论细则优先遵守 `/Volumes/T7/Docker/openclaw-docker-context/memory/reference_chanlun_108_core_rules.md`,其次遵守仓库内 `memory/reference_chanlun_108_core_rules.md`。

运行规则:
- 统一使用 `tdx/chanlun_swing/chanlun_native.py`;新代码不要引入 `czsc`、`rs_czsc` 或百分比 ZigZag。
- 工具输出只是候选,不能直接写成原文严格买卖点。
- 面向用户使用中文结构描述,不要输出 `B1_candidate`、`S3_candidate`、`trade_filter`、`strict_candidate`、`not_trend` 等机器标签。
- 默认个股缠论必须看连续多日、多级别结构,不能只看当天。
- 纯缠论请求仍保留止损、赔率、仓位和 T+1,但解释只围绕缠论、MACD、量能、价格和失效位。

### A 股默认范围

默认执行范围只覆盖 A 股主板,除非用户明确要求纳入创业板、科创板或北交所。

默认过滤:
- 创业板:`300` / `301`
- 科创板:`688`
- 北交所:`43` / `83` / `87` / `92`

若纳入,用户可见答案必须写: `⚠️ 创业板 / 科创板 / 北交所,需确认账户权限 + 20%/30% 涨跌停波动风险`。

### 数据与记录

默认本地 API: `http://127.0.0.1:18800`。

取数优先级:

```text
新闻 / 政策 / 个股公告
→ 市场 M
→ 板块 RPS
→ 个股 quote / finance / fund-sentiment / RPS
→ 日周月 K 线
→ inner-outer / money-flow / margin / lhb / institutional
```

接口不可用时必须写:

```text
本地行情接口不可用,本轮不编造 RPS / I 评分 / T 细节。
```

单票分析完成后,若工具可用,双写 DuckDB `raw_analysis_text` 和 Markdown 文件。必填字段:`code`、`analysis_date`、`verdict`、`raw_analysis_text`。若 7 日内已有同票分析,必须说明 `维持 / 修正 / 撤回` 和原因。工具细节见 `memory/reference_stock_analyses_db.md`。

### Reference 分层

- `memory/reference_canslim_a_share.md`:CANSLIM A 股阈值、A/B/C/D、early、突破确认、I/T 细节。
- `memory/reference_chanlun_108_core_rules.md`:缠论严格结构和买卖点定义。
- `memory/reference_chanlun_native_engine.md`:native 缠论引擎和工程标签边界。
- `memory/reference_a_share_execution_rules.md`:T+1、试错仓、做 T、非主板风险。
- `memory/reference_tdx_toolchain.md`:TDX API、DuckDB、launchd、扫描、回测。
- `memory/feedback_*.md`:历史纠偏案例。

### 输出前自检

股票回答前自查:

1. 是否先给五行结论。
2. 是否判断 M 或标注 M 缺失。
3. 有真实持仓时是否先处理持仓。
4. 止损 / 失效位是否明确。
5. 是否考虑 T+1。
6. 赔率是否 ≥ `2:1`,否则是否降级。
7. 仓位是否匹配档位。
8. I 四项评分是否给出或标注缺失。
9. T1/T2/T3 是否给出或标注缺失。
10. 数据缺口是否点名。
11. 题材叙事是否没有翻案硬信号。
12. 单票分析是否记录,或输出可复制 Markdown 正文。
