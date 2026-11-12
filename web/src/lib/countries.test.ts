import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { COUNTRY_CODES, COUNTRY_OPTIONS, US_STATES, countryName } from "./countries.ts";

function backendList(name: string): string[] {
  const source = readFileSync(new URL("../../../backend/app/models/country.rb", import.meta.url), "utf8");
  const match = source.match(new RegExp(`${name} = %w\\[([^\\]]*)\\]`));
  assert.ok(match, `${name} not found in backend/app/models/country.rb`);
  return match[1].split(/\s+/).filter(Boolean);
}

test("country and state codes match the backend", () => {
  assert.deepEqual([...COUNTRY_CODES], backendList("CODES"));
  assert.deepEqual([...US_STATES], backendList("US_STATES"));
});

test("countries have English names and are sorted by name", () => {
  assert.equal(countryName("US"), "United States");
  assert.equal(countryName("DE"), "Germany");
  const names = COUNTRY_OPTIONS.map((c) => c.name);
  assert.deepEqual(names, [...names].sort((a, b) => a.localeCompare(b, "en")));
});
