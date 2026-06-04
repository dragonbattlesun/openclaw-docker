# Stock Analysis Terminology

Date: 2026-05-25

User-facing Chinese stock analysis should localize internal technical labels:

- `trade_filter` should be written as `交易过滤`.
- Use `60m 交易过滤通过`, `30m 交易过滤未通过`, `交易过滤砍掉`.
- Keep internal JSON/API keys such as `trade_filter_passed` and `trade_reasons` unchanged for compatibility.
