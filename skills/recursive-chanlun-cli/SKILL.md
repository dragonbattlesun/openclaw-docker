---
name: recursive-chanlun-cli
description: Use when working in this project with the recursive Chanlun proof engine, recursive_engine, engine_strict, 1B/2B/3B proof, intraday Chanlun CLI, tools/recursive_chanlun.py, or when a user asks how to run or interpret the project-local recursive Chanlun CLI for A-share structure analysis.
---

# 递归缠论 CLI

## Overview

本 skill 只适用于 `/Volumes/T7/Docker/openclaw-docker` 项目,同时适用于 Codex 和 Claude Code 在本项目内的会话。用于运行和解释项目内递归缠论 proof CLI,保持 `RecursiveChanlunEngine` 为纯结构 proof 层,不把 `engine_strict` 解释成交易许可。

## 使用前检查

1. 工作目录使用项目内 TDX 子目录:

   ```bash
   cd /Volumes/T7/Docker/openclaw-docker/tdx
   ```

2. 入口脚本固定为:

   ```bash
   ./.venv/bin/python tools/recursive_chanlun.py CODE
   ```

3. 盘中优先使用原生 TDX API;不要默认启动 Docker:

   ```bash
   ./tools/start_native_tdx_api.sh
   ```

4. 需要更多规则细节时读取项目内 memory:

   ```text
   memory/reference_recursive_chanlun_runtime.md
   ```

## 常用命令

查看帮助:

```bash
./.venv/bin/python tools/recursive_chanlun.py --help
```

盘中分析一只股票,优先 API,缺数据时按级别回落 history.db:

```bash
./.venv/bin/python tools/recursive_chanlun.py 002261 --source auto --as-of now
```

只用 history.db 做复盘或可复现分析:

```bash
./.venv/bin/python tools/recursive_chanlun.py 002261 --source history --as-of 2026-06-21
```

30min 操作级别,递归使用 5min / 1min:

```bash
./.venv/bin/python tools/recursive_chanlun.py 002261 --root 30min --levels 30min,5min,1min
```

覆盖各级别 K 线数量:

```bash
./.venv/bin/python tools/recursive_chanlun.py 002261 \
  --count daily=300 \
  --count 30min=240 \
  --count 5min=800
```

脚本接入时输出紧凑 JSON:

```bash
./.venv/bin/python tools/recursive_chanlun.py 002261 --compact
```

## 结果解释

输出字段按以下口径解释:

| 字段 | 含义 |
| --- | --- |
| `strict_labels` | 递归 proof 闭合的严格结构标签 |
| `candidate_labels` | 候选、proof 不完整或弱确认标签 |
| `proofs` | 各级别 direct-child、1B/2B/3B proof 明细 |
| `missing_data` | 缺失的级别数据 |
| `warnings` | 运行或结构警告 |

必须明确区分:

- `engine_strict` = 缠论结构 proof 严格成立。
- `trade_permission` = 执行层交易许可,结构层必须保持 `False`。
- `strict_labels` 不能直接写成“可以买”“可交易”“★可交易”。

## 级别纪律

默认递归链:

| 操作级别 | 默认递归链 |
| --- | --- |
| `daily` | `daily,30min,5min,1min` |
| `60min` | `60min,5min,1min` |
| `30min` | `30min,5min,1min` |
| `5min` | `5min,1min` |

解释结果时必须写清:

```text
操作级别:
递归级别链:
严格结构标签:
候选 / 无效标签:
缺失 proof:
是否有交易许可:否,结构层 trade_permission=False
下一步:补哪一级别数据 / 等待哪一步 proof
```

## 常见错误

- 不要让 `RecursiveChanlunEngine` 直接读 DB、请求 HTTP 或读取全局配置;拉数只能放在 `chanlun_swing.recursive_history` 或更外层 adapter。
- 不要把 5min / 1min 信号直接升级成 daily / 30min 严格买卖点。
- 不要用 `source=history` 做盘中实时结论,除非明确说明它只看本地历史库。
- 不要把缺直接次级别数据的 proof 写成严格成立;缺数据只能输出候选、缺 proof 或人工复核。
