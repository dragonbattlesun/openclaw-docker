# Memory Index

- [Chanlun continuous multi-day bars](memory/feedback_chanlun_continuous_multiday_bars.md): 个股缠论分析默认强制日线 + 60min + 30min 三级齐看、连续多日、人工合笔;记录 2026-05-29 今世缘 603369 教训案例。
- [Chanlun 108 core rules](memory/reference_chanlun_108_core_rules.md): 学习本地《缠中说禅教你炒股票108课》PDF 后固化的原文结构口径;置顶“市场哲学的数学原理”,并覆盖连续多日多级别 SOP、级别、分型/笔/线段、中枢、三类买卖点、背驰、小转大、走势必完美和左侧买点边界。
- [Chanlun center strength](memory/reference_chanlun_center_strength.md): 中枢力度只作为 evidence;必须固定级别、ZD/ZG/Z、比较段、MACD、量能和回试状态,不能单独升级严格买卖点。
- [Chanlun native engine](memory/reference_chanlun_native_engine.md): 缠论结构计算统一使用项目自研 `chanlun_native`,禁止新代码用 czsc/rs_czsc/ZigZag 替代;记录组件、标准调用、画图原则和工具标签边界。
- [A-share execution rules](memory/reference_a_share_execution_rules.md): A 股 T+1、涨跌停、做 T、候选试错仓、非主板权限和 20%/30% 波动风险的稳定执行 SOP。
- [Stock analysis terminology](memory/reference_stock_analysis_terminology.md): 面向用户输出时把内部机器标签转成中文,包括 `trade_filter` -> `交易过滤` 以及缠论引擎状态词。
- [TDX native runtime](memory/reference_tdx_native_runtime.md): TDX API、K-line dashboard、DuckDB 记录、回测和 EOD 链路默认原生运行;记录端口、启动、验证、Docker 冲突处理和 launchd 同步链。
- [History DB repository](memory/reference_history_db_repository.md): `history.db` / K 线读写统一走 `tdx/services/history_db.py`;固化 WAL、busy_timeout、runtime_config 路径、标准表/索引、`as_of` 截断和严格 3B/3S 次级别自动拉取边界。
- [CANSLIM A-share reference](memory/reference_canslim_a_share.md): CANSLIM A 股阈值、A/B/C/D 分类、M 仓位上限、early / 突破确认、I 四项评分和 T1/T2/T3 技术口径。
- [Stock analyses DB](memory/reference_stock_analyses_db.md): 单票分析 DuckDB + Markdown 双写、7 日内历史结论对比、板块快照、低位启动扫描、EOD 记录和资金流表。
- [TDX toolchain](memory/reference_tdx_toolchain.md): TDX 原生 API 调用顺序、EOD launchd 链、扫描脚本、记录工具和相关 reference 索引。
- [Agent note writing SOP](memory/reference_agent_note_writing_sop.md): 用户要求整理笔记、写进规则或沉淀交易教训时,统一按适用场景、定义、步骤、输出、正反例、优先级和案例整理;缠论笔记必须补齐级别、笔、线段、中枢、MACD、量能、T+1 和失效位。
