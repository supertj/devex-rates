# devex-rates

Roblox Developer Exchange (DevEx) rates as data: the three rates in force today, every rate change on record, the payout minimum, and a dependency-free Luau module that does the arithmetic.

Maintained by [LootTally](https://loottally.com), synced from [loottally.com/devex-rates](https://loottally.com/devex-rates). Rates last verified against Roblox's documentation on **2026-08-23**.

## Why this exists

Roblox does not publish a rate archive, and since June 2026 there are three DevEx rates in force at once. Most calculators, spreadsheets and in-experience dashboards hardcode one number, and it goes stale the next time Roblox moves. This repository keeps the numbers in one place, with the date and source for each, so you can depend on it instead of retyping it.

## The data

| Rate | USD per Earned Robux | Per 100,000 Robux | In force | Applies to |
| --- | ---: | ---: | --- | --- |
| Standard | $0.0038 | $380 | since Sep 5, 2025 (10am PT) | All Earned Robux, unless it qualifies for U.S. 18+ or sits in a pre-September 2025 balance |
| U.S. 18+ | $0.0054 | $540 | since Jun 8, 2026 | Spend by age-verified 18+ U.S. players on developer products, passes, subscriptions and private servers, in experiences meeting the R15 character requirements |
| Legacy | $0.0035 | $350 | Mar 1, 2017 to Sep 5, 2025 | Balances held before the 2025 change; these cash out first |

Minimum for a first cashout: **30,000 Earned Robux** ($114 at the standard rate).

Rate history:

| Date | Change | Rate | Source |
| --- | --- | ---: | --- |
| Oct 1, 2013 | DevEx launches | $0.0025 | community-documented |
| Mar 1, 2017 | Rate rises | $0.0035 | community-documented |
| Sep 5, 2025 | Standard rate rises | $0.0038 | [Roblox Creator Hub](https://create.roblox.com/docs/production/monetization/developer-exchange) |
| Jun 8, 2026 | U.S. 18+ rate introduced | $0.0054 | [Roblox Creator Hub](https://create.roblox.com/docs/production/monetization/18-plus-devex-rate) |

The two earliest entries are marked `community-documented` in the data because no Roblox archive of them exists. They are never upgraded to first-party without a Roblox source.

Everything above is in [`data/devex-rates.json`](data/devex-rates.json), including the legacy-balance rules and the U.S. 18+ experience requirements.

## Use it in Luau

`src/DevExRates.luau` is a plain ModuleScript: a table and five functions, no `HttpService`, no yielding. Drop it into `ReplicatedStorage` (or sync it with Rojo using the included `default.project.json`) and:

```lua
local DevExRates = require(ReplicatedStorage.DevExRates)

DevExRates.robuxToUsd(100000)            --> 380.00 (standard rate)
DevExRates.robuxToUsd(30000, "us18")     --> 162.00
DevExRates.usdToRobux(100)               --> 26316 Earned Robux at the standard rate
DevExRates.rateOn("2024-01-15")          --> 0.0035 (the standard rate in force that day)
DevExRates.meetsMinimum(28500)           --> false

-- A real balance is often split across rates:
DevExRates.mixedBalanceUsd({ legacy = 20000, standard = 50000, us18 = 5000 })
--> 287.00
```

Results are gross USD rounded to the cent. Payout-method fees and currency conversion are not included, because Roblox pays in USD and the processor's fee depends on your method.

## Use it anywhere else

The JSON is the source of truth. Fetch it directly:

```
https://raw.githubusercontent.com/supertj/devex-rates/main/data/devex-rates.json
https://cdn.jsdelivr.net/gh/supertj/devex-rates@main/data/devex-rates.json
```

Pin a tag instead of `main` if you need the numbers to stay put.

## Caveats worth knowing

- Only **Earned** Robux can be exchanged. Purchased, gifted or transferred Robux never qualifies at any rate.
- The 2025 change took effect at 10am PT. `rateOn` treats the whole day as the new rate; if you need the intraday cutoff, use the timestamp from the source.
- The U.S. 18+ rate is a parallel rate with conditions on the purchase type, the player and the experience, not a replacement for the standard rate.
- Legacy balances must be cashed out before newer Robux, and spending Robux does not clear them.

## Maintenance

- The data is re-verified against Roblox's documentation at least every 45 days, and within a week of any announced change. `rates_last_verified` in the JSON is that date.
- `node scripts/check.mjs` runs in CI on every push. It validates the JSON, checks the arithmetic, and fails if the Luau module's numbers drift from the data.
- Every change is listed in [CHANGELOG.md](CHANGELOG.md).
- Found a discrepancy? Open an issue with a link to the Roblox source.

## Sources

- [Roblox Developer Exchange Program](https://create.roblox.com/docs/production/monetization/developer-exchange)
- [U.S. 18+ DevEx rate](https://create.roblox.com/docs/production/monetization/18-plus-devex-rate)
- [Earned Robux, Earned Robux Balance and DevEx Rates](https://en.help.roblox.com/hc/en-us/articles/27984458742676-Earned-Robux-Earned-Robux-Balance-and-DevEx-Rates)

## License

Code (the Luau module and scripts) is [MIT](LICENSE). Data (`data/devex-rates.json` and the tables in this README) is [CC BY 4.0](LICENSE-DATA.md): use it freely, and credit "DevEx rate data by LootTally (loottally.com)".

LootTally is not affiliated with Roblox Corporation. Calculators are estimates, not tax advice.
