# Changelog

All notable changes to the data or the module. Dates are when the change landed here; each entry names the Roblox source it follows.

## 1.0.2 — 2026-09-27

- U.S. 18+ experience requirements now read as Roblox writes them: player characters must be one of three types (R15 platform avatar, custom human-form, custom nonhuman-form), not all three.

## 1.0.1 — 2026-09-27

- Re-verified every rate against Roblox's documentation on 2026-09-27. No rate, date or threshold changed.
- U.S. 18+ experience requirements follow Roblox's updated wording: a platform avatar with a standard or advanced R15 rig, and custom nonhuman-form characters (including games with no visible player character) also qualify.
- Fixed a comment in `DevExRates.luau` that listed Premium as a DevEx eligibility condition. It isn't one; the conditions are age, a verified email, a DevEx portal account, a tax form on file and good standing.

## 1.0.0 — 2026-09-05

- First release: three rates in force (standard $0.0038, U.S. 18+ $0.0054, legacy $0.0035), the four-event rate history from 2013 to 2026, the 30,000 Earned Robux minimum, legacy-balance rules and U.S. 18+ experience requirements.
- `DevExRates.luau` with `rate`, `robuxToUsd`, `usdToRobux`, `mixedBalanceUsd`, `rateOn` and `meetsMinimum`.
- `scripts/check.mjs` validating the JSON and its parity with the Luau module, wired to GitHub Actions.
- Rates last verified against Roblox's documentation on 2026-08-23 ([Developer Exchange](https://create.roblox.com/docs/production/monetization/developer-exchange), [U.S. 18+ rate](https://create.roblox.com/docs/production/monetization/18-plus-devex-rate)).
