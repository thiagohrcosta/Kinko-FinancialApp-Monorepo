// The backend buckets and filters months in UTC (Rails' default Time.zone). To make
// dates, day headings and the "current month" match what the API returns, all
// formatting uses that same zone regardless of the Next server's time zone.
export const DISPLAY_TIME_ZONE = "UTC";
const LOCALE = "en-US";

export function formatCurrency(value: number, currency = "USD") {
  return new Intl.NumberFormat(LOCALE, { style: "currency", currency }).format(value);
}

/** "Nov 6" */
export function formatDate(iso: string) {
  return new Intl.DateTimeFormat(LOCALE, { month: "short", day: "numeric", timeZone: DISPLAY_TIME_ZONE }).format(
    new Date(iso),
  );
}

/** "1:30 AM" */
export function formatTime(iso: string) {
  return new Intl.DateTimeFormat(LOCALE, { hour: "numeric", minute: "2-digit", timeZone: DISPLAY_TIME_ZONE }).format(
    new Date(iso),
  );
}

/** Entry date (YYYY-MM-DD) in the display zone — used to group the statement by day. */
export function dayKey(iso: string) {
  return new Date(iso).toISOString().slice(0, 10); // DISPLAY_TIME_ZONE is UTC
}

/** "Friday, November 6" */
export function formatDayHeading(day: string) {
  return new Intl.DateTimeFormat(LOCALE, {
    weekday: "long",
    month: "long",
    day: "numeric",
    timeZone: DISPLAY_TIME_ZONE,
  }).format(new Date(`${day}T12:00:00Z`));
}

// Accepted (USD): "1234", "1234.5", "1234.56", "1,234.56", "1234,56" (comma decimal).
// Anything else — including "10.999" or "1.234" — is rejected instead of silently
// becoming a 1000x larger amount.
const AMOUNT_PATTERNS: { re: RegExp; normalize: (s: string) => string }[] = [
  { re: /^\d+(\.\d{1,2})?$/, normalize: (s) => s },
  { re: /^\d{1,3}(,\d{3})+(\.\d{1,2})?$/, normalize: (s) => s.replace(/,/g, "") },
  { re: /^\d+,\d{1,2}$/, normalize: (s) => s.replace(",", ".") },
];

/** Parses the typed amount into integer cents; null if invalid or not positive. */
export function parseAmountToCents(raw: string): number | null {
  const input = raw.trim().replace(/^\$\s*/, "");
  const pattern = AMOUNT_PATTERNS.find((p) => p.re.test(input));
  if (!pattern) return null;
  const [int, dec = ""] = pattern.normalize(input).split(".");
  const cents = Number(int) * 100 + Number(dec.padEnd(2, "0"));
  return Number.isSafeInteger(cents) && cents > 0 ? cents : null;
}

/** Month (YYYY-MM) in the display zone. */
export function monthKey(date: Date) {
  return date.toISOString().slice(0, 7); // DISPLAY_TIME_ZONE is UTC
}

export function shiftMonth(key: string, delta: number) {
  const [y, m] = key.split("-").map(Number);
  return monthKey(new Date(Date.UTC(y, m - 1 + delta, 1)));
}

/** "November 2026" */
export function monthLabel(key: string) {
  const [y, m] = key.split("-").map(Number);
  return new Intl.DateTimeFormat(LOCALE, { month: "long", year: "numeric", timeZone: DISPLAY_TIME_ZONE }).format(
    new Date(Date.UTC(y, m - 1, 15)),
  );
}
