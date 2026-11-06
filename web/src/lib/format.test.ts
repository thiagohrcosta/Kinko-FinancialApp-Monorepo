import { test } from "node:test";
import assert from "node:assert/strict";
import { dayKey, formatDate, formatDayHeading, formatTime, monthKey, monthLabel, parseAmountToCents, shiftMonth } from "./format.ts";

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
  // 10:30 PM in New York (UTC-5) on Nov 6 = 03:30Z on Nov 7
  assert.equal(dayKey("2026-11-07T03:30:00Z"), "2026-11-07");
  assert.equal(formatTime("2026-11-07T03:30:00Z"), "3:30 AM");
  assert.equal(formatDate("2026-11-07T03:30:00Z"), "Nov 7");
  assert.equal(formatDayHeading("2026-11-06"), "Friday, November 6");
  assert.equal(monthKey(new Date("2026-12-01T00:30:00Z")), "2026-12");
});

test("month navigation wraps years", () => {
  assert.equal(shiftMonth("2026-01", -1), "2025-12");
  assert.equal(shiftMonth("2026-12", 1), "2027-01");
  assert.equal(monthLabel("2026-11"), "November 2026");
});
