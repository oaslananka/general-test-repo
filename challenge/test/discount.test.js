import test from "node:test";
import assert from "node:assert/strict";
import { applyDiscount } from "../src/discount.js";

test("applies a percentage discount", () => {
  assert.equal(applyDiscount(100, 10), 90);
  assert.equal(applyDiscount(80, 25), 60);
});

test("accepts boundary percentages", () => {
  assert.equal(applyDiscount(50, 0), 50);
  assert.equal(applyDiscount(50, 100), 0);
});

test("rejects invalid inputs", () => {
  assert.throws(() => applyDiscount(-1, 10), /price/);
  assert.throws(() => applyDiscount(10, 101), /percent/);
});
