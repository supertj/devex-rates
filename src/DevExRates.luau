--!strict
--[[
	DevExRates
	Roblox Developer Exchange (DevEx) rates as a plain Luau table, with the small
	amount of arithmetic everyone re-implements around them.

	Data mirrors ../data/devex-rates.json. The JSON is the source of truth;
	`node scripts/check.mjs` fails if the numbers in this file drift from it.

	No HttpService, no yielding, no external calls. It is a table and five functions.

	Rates last verified against Roblox's documentation: 2026-08-23.
	Maintained by LootTally — https://loottally.com/devex-rates
	Code: MIT. Data: CC BY 4.0.
]]

export type RateId = "standard" | "us18" | "legacy"

export type Rate = {
	id: RateId,
	label: string,
	usdPerRobux: number,
	effectiveFrom: string, -- ISO date
	effectiveUntil: string?, -- ISO date, nil while the rate is still in force
	appliesTo: string,
	source: string,
}

export type HistoryEvent = {
	date: string, -- ISO date
	kind: "launch" | "increase" | "new_tier",
	usdPerRobux: number,
	previousUsdPerRobux: number?,
	headline: string,
	sourceTier: "first_party" | "secondary",
	source: string,
}

local DevExRates = {}

DevExRates.VERSION = "1.0.0"
DevExRates.RATES_LAST_VERIFIED = "2026-08-23"
DevExRates.SOURCE_OF_TRUTH = "https://loottally.com/devex-rates"

--- Earned Robux you need before a first cashout is possible.
DevExRates.MINIMUM_EARNED_ROBUX = 30000

DevExRates.Rates = {
	standard = {
		id = "standard",
		label = "Standard",
		usdPerRobux = 0.0038,
		effectiveFrom = "2025-09-05",
		effectiveUntil = nil,
		appliesTo = "All Earned Robux, unless it qualifies for the U.S. 18+ rate or sits in a pre-September 2025 balance.",
		source = "https://create.roblox.com/docs/production/monetization/developer-exchange",
	},
	us18 = {
		id = "us18",
		label = "U.S. 18+",
		usdPerRobux = 0.0054,
		effectiveFrom = "2026-06-08",
		effectiveUntil = nil,
		appliesTo = "Earned Robux from developer products, passes, subscriptions and private servers bought by U.S. players who verified they are 18+, in an experience that meets the R15 character requirements.",
		source = "https://create.roblox.com/docs/production/monetization/18-plus-devex-rate",
	},
	legacy = {
		id = "legacy",
		label = "Legacy",
		usdPerRobux = 0.0035,
		effectiveFrom = "2017-03-01",
		effectiveUntil = "2025-09-05",
		appliesTo = "Earned Robux balances held before September 5, 2025 at 10am PT. These cash out first, before any Robux earned at the current rate.",
		source = "https://create.roblox.com/docs/production/monetization/developer-exchange",
	},
} :: { [RateId]: Rate }

--- Every rate change on record, oldest first. The two earliest entries are
--- community-documented; Roblox publishes no rate archive.
DevExRates.History = {
	{
		date = "2013-10-01",
		kind = "launch",
		usdPerRobux = 0.0025,
		previousUsdPerRobux = nil,
		headline = "DevEx launches",
		sourceTier = "secondary",
		source = "https://roblox.fandom.com/wiki/Robux",
	},
	{
		date = "2017-03-01",
		kind = "increase",
		usdPerRobux = 0.0035,
		previousUsdPerRobux = 0.0025,
		headline = "Rate rises to $0.0035",
		sourceTier = "secondary",
		source = "https://roblox.fandom.com/wiki/Robux",
	},
	{
		date = "2025-09-05",
		kind = "increase",
		usdPerRobux = 0.0038,
		previousUsdPerRobux = 0.0035,
		headline = "Standard rate rises to $0.0038",
		sourceTier = "first_party",
		source = "https://create.roblox.com/docs/production/monetization/developer-exchange",
	},
	{
		date = "2026-06-08",
		kind = "new_tier",
		usdPerRobux = 0.0054,
		previousUsdPerRobux = 0.0038,
		headline = "U.S. 18+ rate introduced at $0.0054",
		sourceTier = "first_party",
		source = "https://create.roblox.com/docs/production/monetization/18-plus-devex-rate",
	},
} :: { HistoryEvent }

local function roundToCents(usd: number): number
	return math.floor(usd * 100 + 0.5) / 100
end

local function rateFor(id: RateId?): Rate
	local rate = DevExRates.Rates[id or "standard"]
	assert(rate ~= nil, `DevExRates: unknown rate id "{tostring(id)}"`)
	return rate
end

--- USD per Earned Robux for a rate. Defaults to the standard rate.
function DevExRates.rate(id: RateId?): number
	return rateFor(id).usdPerRobux
end

--- Gross USD for an amount of Earned Robux, rounded to the cent. Payout-method
--- fees and currency conversion are not included; Roblox pays in USD.
function DevExRates.robuxToUsd(robux: number, id: RateId?): number
	assert(robux >= 0, "DevExRates.robuxToUsd: robux must be non-negative")
	return roundToCents(robux * rateFor(id).usdPerRobux)
end

--- Earned Robux needed to gross at least this many USD at a rate.
function DevExRates.usdToRobux(usd: number, id: RateId?): number
	assert(usd >= 0, "DevExRates.usdToRobux: usd must be non-negative")
	return math.ceil(usd / rateFor(id).usdPerRobux)
end

--- Gross USD for a balance split across rates, as a real balance often is:
--- Robux held before September 5, 2025 (legacy), Robux earned since (standard),
--- and Robux from qualifying U.S. 18+ spend (us18). Missing parts count as zero.
function DevExRates.mixedBalanceUsd(parts: { legacy: number?, standard: number?, us18: number? }): number
	local total = (parts.legacy or 0) * DevExRates.Rates.legacy.usdPerRobux
		+ (parts.standard or 0) * DevExRates.Rates.standard.usdPerRobux
		+ (parts.us18 or 0) * DevExRates.Rates.us18.usdPerRobux
	return roundToCents(total)
end

--- The standard rate in force on an ISO date (YYYY-MM-DD). The U.S. 18+ tier is a
--- parallel rate rather than a change to the standard one, so it is skipped here.
--- Dates compare as strings, which is safe for the YYYY-MM-DD format. Intraday
--- cutoffs (the 2025 change took effect at 10am PT) are not modelled: the whole
--- day counts as the new rate.
function DevExRates.rateOn(isoDate: string): number?
	assert(string.match(isoDate, "^%d%d%d%d%-%d%d%-%d%d$") ~= nil, "DevExRates.rateOn: expected YYYY-MM-DD")
	local inForce: number? = nil
	for _, event in DevExRates.History do
		if event.kind ~= "new_tier" and event.date <= isoDate then
			inForce = event.usdPerRobux
		end
	end
	return inForce
end

--- Whether an Earned Robux balance clears the minimum for a first cashout.
--- The other eligibility conditions (verified email, Premium, tax form, standing)
--- are not something a rate table can know.
function DevExRates.meetsMinimum(earnedRobux: number): boolean
	return earnedRobux >= DevExRates.MINIMUM_EARNED_ROBUX
end

return DevExRates
