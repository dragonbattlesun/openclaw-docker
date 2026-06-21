# 递归缠论运行封装

## 适用场景

当需要在脚本、盘中监控、CLI 或单票分析里调用递归缠论引擎时使用本规则。尤其适用于:

- 盘中快速检查某只 A 股的 `daily -> 30min -> 5min` 或 `30min -> 5min -> 1min` 递归 proof。
- 报告层需要读取 `strict_labels / candidate_labels / proofs / missing_data`。
- 新代码想复用递归引擎,但不应该把 DB / HTTP 拉数逻辑塞进 `RecursiveChanlunEngine`。

## 核心定义

递归缠论分三层:

1. `RecursiveChanlunEngine`:纯结构 proof 引擎。只消费调用方传入的多级别 `RawBar`,不访问 DB/API,不授予交易许可。
2. `chanlun_swing.recursive_history`:运行时适配层。负责从 history.db 或原生 TDX API 读取多级别 K 线,再交给 engine。
3. `tools/recursive_chanlun.py`:盘中 / 手工使用的独立 CLI。默认 `source=auto`,优先原生 API,失败按级别回落到 history.db。

项目内 skill 入口为 `skills/recursive-chanlun-cli/SKILL.md`;Claude Code 兼容包为 `skills/recursive-chanlun-cli.skill`。

`engine_strict` 只表示对应级别严格结构 proof 成立,不是“可交易”。`proof.trade_permission` 在结构层必须保持 `False`。

级别一致性:

- `LevelStructure.centers` 必须理解为当前节点自身图级别 K 线生成的 strict 笔中枢,来源是 `ChanlunAnalyzer.zhongshu_list_strict`。
- 它不能由直接子级别中枢代替,也不能把子级别 `centers` 拼成父级别中枢。
- 一买 / 一卖最终趋势背驰 proof 使用 `StrictTrendDivergence.detect_strict()` 从本级别严格笔重建线段、线段中枢和走势类型;`len(structure.centers) >= 2` 只是趋势背驰可见性前置门,不是最终 proof。
- 二买 / 二卖当前 recursive proof 只覆盖前置严格一买 / 一卖 + 直接次级别五段门 + 不破前点主路径;盘整背驰确认型二买 / 二卖应作为后续独立 `second_bsp_consolidation_divergence` proof 分支实现,不能直接放宽五段门。

二买 / 二卖盘整背驰 proof 设计:

- `second_bsp_consolidation_divergence` 只是严格 2B/2S 的另一条 proof 路径,不是新买卖点类型。
- strict 2B 必须同时满足:前置同级别严格 1B proof confirmed、直接次级别匹配、只取前置 1B 锚点之后到当前候选之前的窗口、该窗口是第一次回调、第 61 课五段直接次级别骨架 confirmed、回调内部有可比较盘整结构、A/C 段力度背驰、回调后有反弹确认笔、回调低点不破前置 1B 极值、`as_of` 无未来数据。
- strict 2S 完全镜像:前置严格 1S、第一次直接次级别反弹、第 61 课五段直接次级别骨架 confirmed、顶部盘整背驰、反弹后有回落确认笔、反弹高点不破前置 1S 极值。
- MACD 只作结构背驰辅助 proof;缺 MACD 或 A/C 不可比时降级 candidate,不能直接 invalid。
- 硬反证包括:非第一次回调 / 反弹、A/C 不背驰、回调破一买低点 / 反弹破一卖高点、方向冲突、子级别不匹配、引用未来数据;但不能把三买 / 三卖的“回原中枢即否决”口径无条件套到二买 / 二卖。
- `2B/2S engine_strict = second_bsp 五段门 confirmed OR (second_bsp_consolidation_divergence confirmed AND refs.five_segment_status=confirmed)`;两个 proof kind 必须在 `proofs` 中独立保留,报告层必须说明成立路径。
- `proof.trade_permission` 仍固定 `False`;结构 strict 不等于可交易。

## 判定步骤

1. 先确定操作级别:
   - 日线递归默认 `daily,30min,5min`。
   - 30min 递归默认 `30min,5min,1min`。
2. 盘中使用优先走:

   ```bash
   cd /Volumes/T7/Docker/openclaw-docker/tdx
   ./.venv/bin/python tools/recursive_chanlun.py 002261 --source auto
   ```

3. 只看本地历史库时:

   ```bash
   ./.venv/bin/python tools/recursive_chanlun.py 002261 --source history
   ```

4. 指定 30min 递归链时:

   ```bash
   ./.venv/bin/python tools/recursive_chanlun.py 002261 --root 30min --levels 30min,5min,1min
   ```

5. 代码调用优先使用:

   ```python
   from chanlun_swing.recursive_history import analyze_recursive_intraday

   result = analyze_recursive_intraday("002261", source="auto")
   ```

6. 输出必须看:
   - `strict_labels`: proof 闭合的严格结构标签。
   - `candidate_labels`: 候选、缺 proof 或结构反证标签。
   - `proofs`: 直接子级别、1B/2B/3B 等 proof 明细。
   - `missing_data`: 缺少的直接子级别或 proof 项。

## 输出要求

对用户解释递归引擎结果时必须写:

```text
操作级别:
递归级别链:
严格结构标签:
候选 / 无效标签:
缺失 proof:
是否有交易许可:否,结构层 trade_permission=False
下一步:补哪一级别数据 / 等待哪一步 proof
```

禁止把 `engine_strict` 直接写成 `可交易`、`可以买`、`★可交易`。

## 正例

```text
002261 daily 递归链 daily->30min->5min:
direct_child proof 已确认 daily->30min 和 30min->5min。
5min->1min 缺数据,因此 5min 级别继续向下递归 proof 不完整。
当前没有 strict_labels,只能说明本次递归未输出严格买卖点结构。
```

## 反例

错误写法:

```text
递归引擎跑通,所以 002261 有可交易买点。
```

错因:

- 跑通只说明数据链和结构 proof 可以计算。
- `engine_strict` 也只是结构成立。
- 交易动作还需要持仓、位置、止损、赔率、T+1 和市场过滤。

## 优先级

- 本规则优先于临时脚本里手写 SQLite / HTTP 拉 K 线的做法。
- 新代码不得让 `RecursiveChanlunEngine` 直接连接 DB、请求 API 或读取全局 runtime 配置。
- 若要换数据源,只能扩展 `recursive_history` 的 provider / runtime adapter。
- 与 `memory/reference_history_db_repository.md` 冲突时,数据库连接、WAL、busy_timeout、表名和 `as_of` 截断以 history DB repository 规则为准。

## 教训案例

2026-06-21 封装 `tools/recursive_chanlun.py` 时,直接在受限沙箱读取 `tdx/history.db` symlink 会因外部 DB 权限失败;真实本机运行需使用项目标准 runtime 权限 / 本地环境。CLI 设计因此保留 `--source history / api / auto`、`--db` 和 `--api-base`,让盘中使用可以显式切换数据源。

2026-06-21 review 第四轮确认:递归引擎的一买最终 proof 使用线段级 `StrictTrendDivergence.detect_strict()`,不是用次级别中枢冒充本级别中枢;二买盘整背驰路径尚未内生到 recursive proof,属于保守漏覆盖,不是误判严格二买。
