import { test } from "node:test";
import assert from "node:assert/strict";
import { dayKey, formatTime, monthKey, monthLabel, parseAmountToCents, shiftMonth } from "./format.ts";

test("parseAmountToCents accepts valid USD amounts", () => {
  assert.equal(parseAmountToCents("10"), 10_00);
  assert.equal(parseAmountToCents("10.5"), 10_50);
  assert.equal(parseAmountToCents("10.55"), 10_55);
  assert.equal(parseAmountToCents("1,234.56"), 1234_56);
  assert.equal(parseAmountToCents("1,234,567"), 1234567_00);
  assert.equal(parseAmountToCents("50,25"), 50_25);
  assert.equal(parseAmountToCents(" $ 25 "), 25_00);
});

test("parseAmountToCents rejects ambiguous or invalid input instead of guessing", () => {
  for (const bad of ["", "0", "0.00", "abc", "10.999", "5.125", "1.234", "1,23,4", "-5", "1e3", "10.", ".5"]) {
    assert.equal(parseAmountToCents(bad), null, `expected ${JSON.stringify(bad)} to be rejected`);
  }
});

test("dates are bucketed in UTC like the backend", () => {
  // 22:30 em Brasília (UTC-3) = 01:30Z do dia seguinte
  assert.equal(dayKey("2026-11-07T01:30:00Z"), "2026-11-07");
  assert.equal(formatTime("2026-11-07T01:30:00Z"), "01:30");
  assert.equal(monthKey(new Date("2026-12-01T00:30:00Z")), "2026-12");
});

test("month navigation wraps years", () => {
  assert.equal(shiftMonth("2026-01", -1), "2025-12");
  assert.equal(shiftMonth("2026-12", 1), "2027-01");
  assert.equal(monthLabel("2026-11"), "Novembro de 2026");
});
