import { test } from "node:test";
import assert from "node:assert/strict";
import { formatPaymentCode, normalizePaymentCode } from "./payment-code.ts";

const CODE = "KNK189Z1N3XGHP23ADCXRXP4HP9G";

test("normalizePaymentCode accepts pasted codes in any case, with spaces or dashes", () => {
  assert.equal(normalizePaymentCode(CODE), CODE);
  assert.equal(normalizePaymentCode(CODE.toLowerCase()), CODE);
  assert.equal(normalizePaymentCode(` ${formatPaymentCode(CODE)} \n`), CODE);
  assert.equal(normalizePaymentCode(formatPaymentCode(CODE).replace(/ /g, "-")), CODE);
});

test("normalizePaymentCode maps Crockford look-alikes", () => {
  assert.equal(normalizePaymentCode("KNK1OOOOOOOOOOIIIIILLLLL0000"), "KNK1000000000011111111110000");
});

test("normalizePaymentCode rejects the wrong shape", () => {
  for (const bad of ["", "KNK1", CODE.slice(0, -1), `${CODE}0`, CODE.replace("KNK1", "KNK2"), CODE.replace(/.$/, "U"), CODE.replace(/.$/, "*")]) {
    assert.equal(normalizePaymentCode(bad), null, `expected ${JSON.stringify(bad)} to be rejected`);
  }
});

test("formatPaymentCode groups by 4", () => {
  assert.equal(formatPaymentCode(CODE), "KNK1 89Z1 N3XG HP23 ADCX RXP4 HP9G");
});
