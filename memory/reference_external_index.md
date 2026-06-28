# 外部引用索引(CLAUDE.md §33 完整版)

CLAUDE.md §33 只留指针;reference / feedback / 工具链三张完整索引表在此。冲突时以各 reference 文件自身为权威。

---

## 33.1 跨会话 reference 文件(memory/)

| 文件 | 引用位置 | 用途 |
|---|---|---|
| reference_chanlun_terminology.md | §16.2.5 | 缠论 12 类核心名词 + 实战翻译表 + 5 句心法完整版 |
| reference_chanlun_108_core_rules.md | §16 / §35 | 缠论原文结构规则 + 连续多日多级别 SOP + 买卖点严格定性 |
| reference_chanlun_center_strength.md | §16.2 / §16.4 | 中枢力度 evidence(级别/ZD/ZG/Z/MACD/量能/回试),禁单独升级买卖点 |
| reference_chanlun_native_engine.md | §16.0.1 | 自研 chanlun_native 引擎组件、调用、画图、三方库禁用 |
| reference_chanlun_recursive_buy_sell_framework.md | §16.1.1 / §35.6 | 递归买卖点 + 六类走势归档 + 固定操作级别 + 自同构 6 条 |
| reference_a_share_execution_rules.md | §2 / §5.6 / §16.3.1 | A 股 T+1、做 T、试错仓、非主板风险、执行约束 |
| reference_canslim_a_share.md | §0-§32 | CANSLIM A 股阈值、M 仓位、A/B/C/D、early、突破确认、I/T |
| reference_stock_analysis_terminology.md | §36.1 | 用户可见术语中文化(交易过滤、缠论状态词) |
| reference_output_templates.md | §26 | 标准单票 / 持仓诊断 / 换仓 / 市场分析 输出模板完整骨架 |
| reference_tdx_native_runtime.md | §36 | TDX 原生运行、端口、验证、EOD、Docker 冲突 |
| reference_history_db_repository.md | §36 | history.db repository、表/索引、as_of 截断、3B/3S 数据边界 |
| reference_tdx_toolchain.md | §23 / §36 | TDX API 顺序、DuckDB、launchd、扫描/回测脚本索引 |
| reference_chart_patterns.md | §20 | 30+ 经典 K 线形态完整列表 |
| reference_canslim_perf.md | §7 | CANSLIM 性能数据参考 |
| reference_tdxapi_defaults.md | §23.2 | TDX API 默认参数对照表 |
| reference_stock_analyses_db.md | §23.4 | stock_analyses.duckdb 工具链详细说明 |
| reference_sector_jump_v1.md | §13.3 | sector_jump_v1 板块跳升公式 + 完整修订策略 (-bi_low/-8% / +15%+25%+40% / 加仓 v2) |
| reference_agent_note_writing_sop.md | §33.2 | 用户笔记 / 交易反馈 / 缠论纠错的标准整理格式 |

---

## 33.2 跨会话 feedback 文件(memory/)

| 文件 | 核心教训 |
|---|---|
| feedback_user_chart_is_truth.md | 用户提供图表为准,证伪时立刻撤回 |
| feedback_position_must_use_250d.md | 位置判断必须用 250 日 HHV |
| feedback_resonance_actual_chart_only.md | 共振判定只看实际 K 线 |
| feedback_tech_combo_chanlun_kline_volume.md | 技术分析三件套(T1+T2+T3) |
| feedback_three_system_resonance_sop.md | 形态/缠论/CANSLIM 三方共振 SOP |
| feedback_external_mnemonic_audit.md | 外部口诀按"收编/警惕/不用"三档体检 |
| feedback_api_params_strict.md | TDX API 参数严格按文档,不能猜 |
| feedback_early_classification_multiwindow.md | A 类 early 必须三窗口位置 + 升势 ≤ 26 周校验 |
| feedback_breakout_validity_check.md | 月线突破前高 3 项校验(对应 §13.0) |
| feedback_position_class_abc.md | A/B/C 三类位置定义不能混淆(对应 §7.1) |
| feedback_monthly_filter_only.md | A 类 early 月线只做否决器(对应 §12.3) |
| feedback_early_essence_weekly.md | early 本体在周线 + A0/A1 分档 v4 终稿(对应 §12) |
| feedback_global_gitignore_pitfall.md | ~/.gitignore_global 含 ".gitignore" 异常规则会屏蔽项目级 .gitignore(对应 §34.3.7) |
| feedback_a_share_execution_constraints.md | A股约束让回测打 75% 折扣,单仓降 4%(§13.3) |
| feedback_segmented_profit_taking.md | 分段止盈 +15/+25/+40% 比单一 +40% Sharpe +22%(§13.3) |
| feedback_chanlun_engineering_label.md | 原文严格 1B/2B/3B 只定性,候选按 T+1 折扣给试错仓(§16.3.1) |
| feedback_chanlun_chart_tool_and_levels.md | 画图首选 draw_chanlun_native.py 多级别叠加;§16.1.1 第5条禁拼买点非禁一图多级别 |

> 注:全局 auto-memory 的 MEMORY.md 索引了更全的 feedback 清单(含 chanlun_native_engine / bsp_grading / strict_restore 等),与本表互补。

---

## 33.3 工具链(workspace/tools/)

| 工具 | 用途 |
|---|---|
| save_analysis.py | 单票分析双写到 DB + .md(§23.4) |
| query_analysis.py | 9 个常用查询封装(§23.4 + §23.8 flow / flow-history) |
| save_sector_verdicts.py | 板块判断快照入库 sector_verdicts(§23.5) |
| ingest_lowstart.py | 低位启动扫描 json 批量入库(§23.6) |
| save_sector_capital_flow.py | 板块资金流向(同花顺)入库 sector_capital_flow(§23.8) |
| save_sw_money_flow.py | 申万一级行业资金流(东财个股聚合)入库 sector_money_flow_daily(§23.9) |
| record_eod.py | 收盘一键:§23.5 + §23.6 + §23.8 + §23.9 |
| schema.sql | DuckDB schema 定义(stock_analyses 40+ 字段 + sector_verdicts + sector_capital_flow + sector_money_flow_daily) |
| scan_sector_jump_optimal.py | sector_jump_v1 实盘扫描, 输出含 A股 真实约束的完整交易计划 (§13.3) |
| scan_dual_track.py | v1 严格 + v2 放宽 双轨扫描, S/A/B 三档分级 (§13.3) |
| backtest_sector_jump_chanlun.py | 板块跳升 + 缠论结构层 14 月真实回测 (验证最优参数) |
| backtest_a_share_realistic.py | 加 A股 真实约束 (T+1/涨跌停/滑点/手续费) 的回测器 |
| scan_2560.py | 2560 战法 4 态扫描(诱多/冲量/做量/缩量),25日价均线+5/60日量线 + 纪律护栏 |
| scan_low_start_v2.py | 低位启动 v2:板块底共振 + 启动时序三段(启动当周抓底),`--rebound` 含箱体回踩底 |
| scan_earnings.py | 业绩硬门槛扫描(C+A:净利同比≥25%+扣非>0+ROE≥8),RPS 缩池;`--max-pos` 限位置 |
| draw_chanlun_detail.py | 缠论详图:`czsc_adapter` 用 chanlun_native 引擎 + 走势中枢(state)+ 量能 + MACD。**默认前复权**(除权股才准),`--raw` 用本地不复权;`--period weekly/daily/60min/30min/5min` |

> ⚠️ 上述 workspace/tools/ 脚本按 .gitignore 约定不入父 repo,仅本地保留。

---

## 33.4 备份文件

- `CLAUDE_v1_20260426.md`:整理前的 v1 演化堆叠版,留存历史。
