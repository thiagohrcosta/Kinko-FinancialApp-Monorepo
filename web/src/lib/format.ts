// O backend agrupa e filtra por mês em UTC (Rails Time.zone padrão). Para que datas,
// cabeçalhos de dia e o "mês atual" batam com o que a API retorna, toda a formatação
// usa o mesmo fuso, independente do fuso do servidor Next.
export const DISPLAY_TIME_ZONE = "UTC";

export function formatCurrency(value: number, currency = "USD") {
  return new Intl.NumberFormat("en-US", { style: "currency", currency }).format(value);
}

export function formatDate(iso: string) {
  return new Intl.DateTimeFormat("en-US", { month: "short", day: "numeric", timeZone: DISPLAY_TIME_ZONE }).format(
    new Date(iso),
  );
}

export function formatTime(iso: string) {
  return new Intl.DateTimeFormat("pt-BR", { hour: "2-digit", minute: "2-digit", timeZone: DISPLAY_TIME_ZONE }).format(
    new Date(iso),
  );
}

/** Data (YYYY-MM-DD) do lançamento no fuso de exibição — usada para agrupar o extrato por dia. */
export function dayKey(iso: string) {
  return new Date(iso).toISOString().slice(0, 10); // DISPLAY_TIME_ZONE é UTC
}

export function formatDayHeading(day: string) {
  return new Intl.DateTimeFormat("pt-BR", {
    weekday: "long",
    day: "numeric",
    month: "long",
    timeZone: DISPLAY_TIME_ZONE,
  }).format(new Date(`${day}T12:00:00Z`));
}

// Formatos aceitos (USD): "1234", "1234.5", "1234.56", "1,234.56", "1234,56" (vírgula decimal).
// Qualquer outra coisa — inclusive "10.999" ou "1.234" — é rejeitada em vez de
// virar um valor 1000x maior por engano.
const AMOUNT_PATTERNS: { re: RegExp; normalize: (s: string) => string }[] = [
  { re: /^\d+(\.\d{1,2})?$/, normalize: (s) => s },
  { re: /^\d{1,3}(,\d{3})+(\.\d{1,2})?$/, normalize: (s) => s.replace(/,/g, "") },
  { re: /^\d+,\d{1,2}$/, normalize: (s) => s.replace(",", ".") },
];

/** Converte o valor digitado em centavos inteiros; null se inválido ou não positivo. */
export function parseAmountToCents(raw: string): number | null {
  const input = raw.trim().replace(/^\$\s*/, "");
  const pattern = AMOUNT_PATTERNS.find((p) => p.re.test(input));
  if (!pattern) return null;
  const [int, dec = ""] = pattern.normalize(input).split(".");
  const cents = Number(int) * 100 + Number(dec.padEnd(2, "0"));
  return Number.isSafeInteger(cents) && cents > 0 ? cents : null;
}

/** Mês (YYYY-MM) no fuso de exibição. */
export function monthKey(date: Date) {
  return date.toISOString().slice(0, 7); // DISPLAY_TIME_ZONE é UTC
}

export function shiftMonth(key: string, delta: number) {
  const [y, m] = key.split("-").map(Number);
  return monthKey(new Date(Date.UTC(y, m - 1 + delta, 1)));
}

export function monthLabel(key: string) {
  const [y, m] = key.split("-").map(Number);
  const label = new Intl.DateTimeFormat("pt-BR", { month: "long", year: "numeric", timeZone: DISPLAY_TIME_ZONE }).format(
    new Date(Date.UTC(y, m - 1, 15)),
  );
  return label.charAt(0).toUpperCase() + label.slice(1);
}
