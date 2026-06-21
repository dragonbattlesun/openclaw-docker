# Agent Runtime Notes

本仓库的运行规则唯一入口是 `CLAUDE.md`。

## 规则入口

- 开始任何项目任务前,先读取 `CLAUDE.md`,再按其中索引读取必要的 `memory/reference_*.md` 或 `memory/feedback_*.md`。
- 不在本文件重复维护 CANSLIM、缠论、TDX、`history.db`、DuckDB、输出纪律、笔记沉淀或回测规则。
- 若本文件与 `CLAUDE.md` 有任何冲突,以 `CLAUDE.md` 当前版本为准。
- 用户要求“写进规则 / 整理笔记 / 记住教训 / 更新 memory”时,按 `CLAUDE.md` 索引的 `memory/reference_agent_note_writing_sop.md` 执行。

## 修改规则

- 需要新增或修正规则时,优先更新 `CLAUDE.md` 的索引和对应 `memory/reference_*.md` 文件。
- 需要长期跨会话执行的项目规则,不要只写在本文件;必须挂到 `CLAUDE.md` 或 `MEMORY.md` 可检索索引。
- 本文件只保留“使用 `CLAUDE.md` 作为唯一规则源”的启动约定。
