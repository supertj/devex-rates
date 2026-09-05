# Changelog

All notable changes to the data or the module. Dates are when the change landed here; each entry names the Roblox source it follows.

## 1.0.0 — 2026-09-05

- First release: three rates in force (standard $0.0038, U.S. 18+ $0.0054, legacy $0.0035), the four-event rate history from 2013 to 2026, the 30,000 Earned Robux minimum, legacy-balance rules and U.S. 18+ experience requirements.
- `DevExRates.luau` with `rate`, `robuxToUsd`, `usdToRobux`, `mixedBalanceUsd`, `rateOn` and `meetsMinimum`.
- `scripts/check.mjs` validating the JSON and its parity with the Luau module, wired to GitHub Actions.
- Rates last verified against Roblox's documentation on 2026-08-23 ([Developer Exchange](https://create.roblox.com/docs/production/monetization/developer-exchange), [U.S. 18+ rate](https://create.roblox.com/docs/production/monetization/18-plus-devex-rate)).
