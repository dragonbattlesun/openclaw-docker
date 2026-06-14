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

### Trading Output Discipline

股票交易、持仓诊断、选股、买卖点、做 T 相关答复,必须先给 5 行以内的执行结论:

```text
动作:买 / 持 / 卖 / 不碰
仓位:总仓位 / 单仓比例
止损:明确价位或条件
目标:T1 / T2 或放弃原因
有效期:几个交易日内有效
```

规则:
- 先决策,后解释;先处理持仓,再谈新机会。
- 数据不完整时必须说明缺口,不能编造行情、资金、业绩或技术指标。
- 用户给出成本 / 股数 / 仓位时,真实持仓优先于历史系统信号;先给止损、减仓、做 T 或继续持有条件。
- 用户明确要求纯缠论 / 缠论分析时,执行结论仍保留,但解释只围绕缠论、MACD、量能、价格结构和失效位;不主动扩展大盘叙述。

### Trading Decision Chain

默认股票主流程按 `CLAUDE.md` §4 裁决链执行:

```text
M 市场状态 → 止损 / 破位 / ma200 → 板块强弱 → 机构与资金趋势 → 业绩增速 → 个股技术结构 T → 题材叙事
```

铁律:
- 上一级否决,下一级不能翻案;技术结构不能推翻止损、破位、板块、机构、业绩等硬信号。
- 已破止损 / 明确破位 / 跌破 ma200 时,先处理风险,再解释原因。
- 用户明确要求纯缠论波段时,按 `CLAUDE.md` §35 独立模块处理,不展开 §4 大盘叙述;但仍必须保留止损、赔率和仓位纪律。

### Risk, Position, And Classification

- 默认止损:`-8%`;触发即执行,不挪止损、不补仓摊平、不等回本。
- 赔率不足 `2:1` 时,即使逻辑好也不新买。
- 波段只做右侧确认,不把下跌趋势中的便宜、跌深反弹、故事预期写成买点。
- 做 T 必须给操作级别、触发价、失效位、可动用股数或仓位;不能把 T 计划包装成新开仓买点。
- 所有候选股先分 `A 低位启动龙头 / B 突破确认龙头 / C 跟风补涨 / D 伪启动弱股`,再决定是否进入 CANSLIM、early 或缠论波段框架。
- 仓位档位沿用 `CLAUDE.md` §11: `strict ≤15%`, `medium ≤10%`, `A1 early 5-8%`, `A0 early 3-5%`, `loose ≤3%`;档间不能混用。

### A-Share Default Scope

默认个股筛选、交易分析、买卖执行只覆盖 A 股主板,除非用户明确要求纳入创业板、科创板或北交所。

默认过滤:
- 创业板:`300` / `301`
- 科创板:`688`
- 北交所:`43` / `83` / `87` / `92`

例外:
- 用户明确说“看创业板 / 科创板 / 北交所”。
- 只是研究或上下文说明,不涉及买卖执行。

若出现非主板标的,必须在用户可见答案中额外标注:

```text
⚠️ 创业板 / 科创板 / 北交所,需确认账户权限 + 20%/30% 涨跌停波动风险
```

### A-Share T+1 Execution Constraint

A 股默认为 T+1 交易制度。以后所有买点、做 T、止损和仓位建议必须显式考虑:今日买入的股份今日不能卖出。

规则:
- 新开仓 / 加仓 / 候选试错买入后,当天不能用“跌破就走”作为可立即执行的止损;必须写成“次一交易日可执行止损”或“盘中只减已有可卖股份”。
- 候选试错仓不是原文严格买点,只能写成 `执行试错仓`,默认 `loose 2-3%`;只有临近收盘、结构已完成、且离失效位足够近时,才可提高到 `A0 early 3-5%`。
- 候选试错只允许在靠近失效位 / 中枢下沿 / 回踩确认位执行;当前价在中枢中部、上沿追高位或距离失效位过远时,必须写“等待,不试错”。
- 做 T 只能针对已有可卖股份制定卖出或回补计划;当天新买入股份被锁定到下一交易日,不能写成同日完整 T+0 闭环。
- 若失效位可能在当天买入后立即被打穿,但当天无法卖出,必须降低仓位或放弃;候选收益空间不足以覆盖隔夜和次日低开风险时,不做。

### Chanlun Multi-Day Multi-Level Rule

**强制核心规则**:以后所有涉及缠论的分析、选股、持仓诊断、买卖点判断、换仓决策,必须遵守 `/Volumes/T7/Docker/openclaw-docker-context/system-memories/chanlun/chanlun_108_core_rules.md`;项目同级同步参考为 `/Volumes/T7/Docker/openclaw-docker-context/memory/reference_chanlun_108_core_rules.md`,仓库内同步参考为 `memory/reference_chanlun_108_core_rules.md`。若本段摘要与 `chanlun_108_core_rules.md` 的细则冲突,以项目同级目录版本为准。

**置顶哲学原则(2026-06-05)**:缠论是“市场哲学的数学原理”:人的贪 / 嗔 / 痴 / 疑 / 慢在不同时间尺度上反复出现,形成价格走势的自相似性;缠论用 `分型 → 笔 → 线段 → 中枢 → 走势类型 → 买卖点` 的递归几何结构描述走势自同构和级别自组织。后续解释缠论或做个股缠论分析时,必须先把这条原则落成执行纪律:先定操作级别,本级别独立完成结构判断,小级别只作支持 / 反证 / 精确定位,不能替代本级别买卖点。突然直线拉涨停、没有回踩、且小级别也没有低风险参与点时,必须写“无清晰买点,错过就错过”,不能事后把突破或涨停包装成严格 3B。

**工程标签纪律**:以后所有缠论买卖点输出还必须遵守 `memory/feedback_chanlun_engineering_label.md`。工具或脚本输出的 `1B/2B/3B` 只是扫描候选,不能直接等同原文严格一买/二买/三买;人工分析必须分清 `工具标签`、`人工结构候选`、`原文严格买点`、`当前执行买点`。

所有个股分析的缠论判断,默认必须**三级齐看 + 连续多日 + 人工合笔**,不能只看工具 `last_bi` 或单日数据。

**禁止只看当天**:即使用户只给股票代码或只问一句买卖点,也必须回看连续多日结构;输出时要明确列出最近几笔的起讫日期 / 价格区间 / 方向,不能只引用当天 K 线、当天分时或当天涨跌幅下结论。

**纯缠论边界**:用户说“缠论分析 / 纯缠论 / 看中枢 / 买点 / 做 T”时,默认只使用缠论结构、MACD、成交量、价格位置、失效位和操作级别;除非用户主动提供板块资金或要求综合判断,不要主动加入大盘相关分析。

**走势自同构与级别递归**:缠论走势的自同构性必须写入每次结构判断。任一级别都使用同一套规则 `分型 → 笔 → 线段 → 中枢 → 走势类型 → 买卖点`,但买卖点定性只能在本操作级别完成。
- 大级别的一笔 / 一段,内部可以由次级别完整走势类型递归生成;下钻小级别只用于精确定位、背驰验证、三买三卖回试验证、止损 / 卖点确认。
- 小级别信号不能直接替代大级别信号: `5m 底背驰 ≠ 30m 严格1B`, `30m 三买 ≠ 日线三买`, `小级别二买 ≠ 大级别三买`。
- 小转大必须按链条输出:小级别背驰候选 → 本级别反向笔 / 走势类型完成 → 本级别中枢形成 → 离开中枢 → 第一次回踩不回中枢。链条缺一步,只能写候选或观察。
- 禁止混级别画图:不能用 30m 的笔、5m 的回试、日线的中枢拼成一个买点;每个中枢必须说明由哪个级别的次级别走势构成。
- 输出必须区分 `本级别结论`、`次级别支持/反证`、`能否递归升级`、`升级触发位`、`升级失败位`。

**必拉数据(每次个股分析强制)**:
- 日线:`/kline/{code}?period=daily&count=250`
- 60min:`/kline/{code}?period=60min&count=80`(覆盖 ~20 个交易日)
- 30min:`/kline/{code}?period=30min&count=80`(覆盖 ~10 个交易日)
- 周线 / 月线照旧拉取做大方向定位

**必做动作(9 步)**:
1. 每一级独立人工合笔(每笔 ≥ 5 根独立 K + 顶底分型不重叠),列出每一笔的方向 / 起讫 / 区间 / K 数
2. 每一级独立识别中枢(最近 3 段同向笔的重叠区,ZG = 笔高 min,ZD = 笔低 max)
3. 每一级必须输出最近笔端点 / 中枢区间 / 买卖点归属 / MACD 背驰或红绿柱变化 / 走势类型 / 区间位置
4. 每一级必须输出量能配合:上涨放量、回调缩量、放量下跌、缩量反抽或量价背离
5. 做走势自同构递归校验:本级别结构是什么,次级别是否支持 / 反证,小级别信号能否升级,缺哪一步
6. 3B 第一步:检验是否离开中枢上沿
7. 3B 第二步:检验回踩是否不破中枢上沿 / 中枢区间
8. 3B 第三步:检验是否再创新高
9. 输出三级共振对照表(周 / 日 / 60min / 30min / 5min 方向是否一致)和买点标签表: `工具标签` / `人工结构` / `原文严格结论` / `当前执行` / `失效位`;工具 `last_bi` 与人工合笔结果冲突时,以人工合笔为准,标注差异原因,禁止只写“有买点”或“没有买点”。

**铁律**:周 / 月线只是大方向,**真正的入场 / 持仓 / 卖出决策必须基于日 + 60min + 30min 三级共振**;任何只基于当天走势给出的缠论买卖结论一律视为无效。

**买点纪律**:缠论买点必须区分“候选、严格、执行”,不能把候选包装成交易买点。
- `人工结构候选`:一买候选 / 二买候选 / 三买候选 / 盘整背驰候选 / 小转大候选,必须给触发位与失效位;候选不是原文严格买点,不能包装成确认仓或趋势仓。
- `执行试错仓`:候选结构若已到触发位、靠近失效位、MACD / 量能未明显反证,可按 A 股 T+1 约束给 `loose 2-3%` 小仓试错;必须写清“非严格买点、次日止损位、不能当天卖出新买股份”。
- `原文严格买点`:只有满足 `reference_chanlun_108_core_rules.md` 的严格定义后,才能写“严格 1B/2B/3B 已成立”,并给对应执行节奏。严格 1B → `A1 early 5-8%`;严格 2B → `medium 5-10%`;严格 3B → `strict ≤15%`;未达严格 → 只能观察或按 `执行试错仓` 处理,不能写成确认入场。
- `纯缠论波段`:按 `CLAUDE.md` §35 执行时,1B 默认只入观察池,实盘入场优先 2B / 3B;不能把左侧 1B 候选当成当前买点。
- `当前位置执行`:当前价若在中枢中部、上沿追高位、下跌未止跌位,必须写“当前位置无执行买点”;不能省略候选路径。
- `回溯确认`:后续出现不破前低、突破前高、离开中枢、回踩不回中枢后,才把前点定性为一买 / 二买 / 三买。
- `失效纪律`:候选失效位被破,候选立刻失败;不能升级成更大级别持仓叙事。
- `持仓成本优先`:用户给成本 / 股数时,只围绕真实持仓和同一操作级别给止损、减仓、加仓或做 T 条件;不能用旧系统买点安慰当前亏损持仓。

**中枢震荡口径**:中枢震荡没有本级别严格 1B/2B/3B,只存在更小级别买卖点或中枢上下沿短差。输出时必须说明:
- 本级别:中枢震荡,无本级别严格买点。
- 小级别:是否存在 `1B候选 / 等待2B / 等待3B / 盘整背驰候选`。
- 当前执行:在中枢中部不追、不低吸、不做无优势 T;靠近下沿看回补候选,靠近上沿看卖点或做 T 候选。

教训案例:2026-05-29 今世缘 603369,工具 `last_bi=Down` → 人工合笔后实际是 Up 笔运行 +18.7%,30min/60min 3B 共振已成立。详见 `memory/feedback_chanlun_continuous_multiday_bars.md`。

教训案例:2026-06-03 拓维信息 002261,30m 处于 `29.94-30.86` 中枢震荡。`29.47` 可标为 30m 盘整背驰 / 1B 候选观察点,但不是原文严格 1B;当前价在中枢中部时必须写“当前位置无执行买点”,并说明等待 2B 或 3B 的触发条件。详见 `memory/feedback_chanlun_engineering_label.md`。

适用于:CLAUDE.md §1-§32 的 T1 缠论判断 / §35 纯缠论波段 / §35.6 递归买卖点 / §9 持仓诊断 / §22 换仓决策。
