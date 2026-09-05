#!/usr/bin/env node
/**
 * Validates data/devex-rates.json and checks that src/DevExRates.luau carries the
 * same numbers. Runs in CI on every push; fails loudly rather than letting a stale
 * rate ship under a "verified" stamp.
 */
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const root = dirname(dirname(fileURLToPath(import.meta.url)));
const data = JSON.parse(readFileSync(join(root, "data/devex-rates.json"), "utf8"));
const luau = readFileSync(join(root, "src/DevExRates.luau"), "utf8");

const errors = [];
const isoDate = (value) => typeof value === "string" && /^\d{4}-\d{2}-\d{2}$/.test(value);
const isUrl = (value) => typeof value === "string" && /^https:\/\//.test(value);

// Top level
if (!isoDate(data.exported)) errors.push("exported must be an ISO date");
if (!isoDate(data.rates_last_verified)) errors.push("rates_last_verified must be an ISO date");
if (!(data.minimum_earned_robux > 0)) errors.push("minimum_earned_robux must be positive");
if (!isUrl(data.source_of_truth)) errors.push("source_of_truth must be an https URL");

// Rates
const rateIds = new Set(["standard", "us18", "legacy"]);
const byId = new Map();
for (const rate of data.rates) {
  if (!rateIds.has(rate.id)) errors.push(`rate ${rate.id}: unknown id`);
  byId.set(rate.id, rate);
  if (!(rate.usd_per_robux > 0)) errors.push(`rate ${rate.id}: usd_per_robux must be positive`);
  if (rate.per_100k_usd !== Math.round(rate.usd_per_robux * 100_000)) {
    errors.push(`rate ${rate.id}: per_100k_usd does not match usd_per_robux`);
  }
  if (rate.per_30k_usd !== Math.round(rate.usd_per_robux * 30_000)) {
    errors.push(`rate ${rate.id}: per_30k_usd does not match usd_per_robux`);
  }
  if (!isoDate(rate.effective_from)) errors.push(`rate ${rate.id}: effective_from must be an ISO date`);
  if (rate.effective_until !== null && !isoDate(rate.effective_until)) {
    errors.push(`rate ${rate.id}: effective_until must be null or an ISO date`);
  }
  if (!isUrl(rate.source)) errors.push(`rate ${rate.id}: source must be an https URL`);
}
for (const id of rateIds) if (!byId.has(id)) errors.push(`rate ${id}: missing`);
if (data.rates.filter((r) => r.is_default).length !== 1) errors.push("exactly one rate must be is_default");

// History
let previous = null;
for (const [index, event] of data.history.entries()) {
  if (!isoDate(event.date)) errors.push(`history[${index}]: date must be an ISO date`);
  if (previous && event.date <= previous.date) errors.push(`history[${index}]: dates must ascend`);
  if (!["launch", "increase", "new_tier"].includes(event.kind)) errors.push(`history[${index}]: unknown kind ${event.kind}`);
  if (!(event.usd_per_robux > 0)) errors.push(`history[${index}]: usd_per_robux must be positive`);
  if (event.per_100k_usd !== Math.round(event.usd_per_robux * 100_000)) {
    errors.push(`history[${index}]: per_100k_usd does not match usd_per_robux`);
  }
  if (!["first_party", "secondary"].includes(event.source_tier)) errors.push(`history[${index}]: bad source_tier`);
  if (event.source_tier === "secondary" && !event.source_label) errors.push(`history[${index}]: secondary needs source_label`);
  if (!isUrl(event.source)) errors.push(`history[${index}]: source must be an https URL`);
  if (index === 0 && event.previous_usd_per_robux !== null) errors.push("history[0]: first event has no previous rate");
  if (index > 0 && event.previous_usd_per_robux !== previous.usd_per_robux) {
    errors.push(`history[${index}]: previous_usd_per_robux must equal the prior event's rate`);
  }
  previous = event;
}

// The rates table and the history must agree on what is in force.
const standardHistory = data.history.filter((e) => e.kind !== "new_tier");
const lastStandard = standardHistory[standardHistory.length - 1];
if (byId.get("standard")?.usd_per_robux !== lastStandard.usd_per_robux) {
  errors.push("standard rate does not match the latest non-tier history event");
}
if (byId.get("legacy")?.usd_per_robux !== lastStandard.previous_usd_per_robux) {
  errors.push("legacy rate does not match the rate the latest change replaced");
}
if (byId.get("legacy")?.effective_until !== lastStandard.date) {
  errors.push("legacy effective_until must equal the date of the latest standard-rate change");
}
const tier = data.history.find((e) => e.kind === "new_tier");
if (tier && byId.get("us18")?.usd_per_robux !== tier.usd_per_robux) {
  errors.push("us18 rate does not match the new_tier history event");
}

// The Luau module must carry the same numbers and dates.
const mustAppearInLuau = [
  `MINIMUM_EARNED_ROBUX = ${data.minimum_earned_robux}`,
  `RATES_LAST_VERIFIED = "${data.rates_last_verified}"`,
  `VERSION = "${data.version}"`,
  ...data.rates.map((r) => `usdPerRobux = ${r.usd_per_robux}`),
  ...data.rates.map((r) => `effectiveFrom = "${r.effective_from}"`),
  ...data.history.map((e) => `date = "${e.date}"`),
];
for (const needle of mustAppearInLuau) {
  if (!luau.includes(needle)) errors.push(`DevExRates.luau is missing: ${needle}`);
}
for (const rate of data.rates) {
  if (rate.effective_until && !luau.includes(`effectiveUntil = "${rate.effective_until}"`)) {
    errors.push(`DevExRates.luau is missing effectiveUntil for ${rate.id}`);
  }
}

// Arithmetic parity with the Luau helpers, on the examples the README quotes.
const cents = (usd) => Math.round(usd * 100) / 100;
const examples = [
  [100_000, "standard", 380],
  [30_000, "standard", 114],
  [30_000, "us18", 162],
  [30_000, "legacy", 105],
  [12_345, "standard", 46.91],
];
for (const [robux, id, expected] of examples) {
  const got = cents(robux * byId.get(id).usd_per_robux);
  if (got !== expected) errors.push(`example ${robux} Robux at ${id}: expected ${expected}, got ${got}`);
}

if (errors.length > 0) {
  console.error("devex-rates check failed:\n");
  for (const error of errors) console.error(`  ✗ ${error}`);
  process.exit(1);
}
console.log(
  `devex-rates ok — ${data.rates.length} rates, ${data.history.length} history events, ` +
    `verified ${data.rates_last_verified}, Luau in sync`,
);
