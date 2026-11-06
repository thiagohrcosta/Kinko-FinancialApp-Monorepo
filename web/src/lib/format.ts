export function formatCurrency(value: number, currency = "USD") {
  return new Intl.NumberFormat("en-US", { style: "currency", currency }).format(value);
}

export function formatDate(iso: string) {
  return new Intl.DateTimeFormat("en-US", { month: "short", day: "numeric" }).format(new Date(iso));
}

export function formatTime(iso: string) {
  return new Intl.DateTimeFormat("pt-BR", { hour: "2-digit", minute: "2-digit" }).format(new Date(iso));
}

/** "12,50" ou "12.50" ou "1,234.56" → centavos inteiros; null se inválido. */
export function parseAmountToCents(raw: string): number | null {
  const cleaned = raw.trim().replace(/[^\d.,]/g, "");
  if (!cleaned) return null;
  const lastSep = Math.max(cleaned.lastIndexOf(","), cleaned.lastIndexOf("."));
  const hasDecimals = lastSep !== -1 && cleaned.length - lastSep - 1 <= 2;
  const integer = (hasDecimals ? cleaned.slice(0, lastSep) : cleaned).replace(/[.,]/g, "");
  const decimals = hasDecimals ? cleaned.slice(lastSep + 1).padEnd(2, "0") : "00";
  const cents = Number(integer || "0") * 100 + Number(decimals);
  return Number.isFinite(cents) && cents > 0 ? cents : null;
}

/** Mês corrente/selecionado no formato YYYY-MM (horário local do servidor). */
export function monthKey(date: Date) {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}`;
}

export function shiftMonth(key: string, delta: number) {
  const [y, m] = key.split("-").map(Number);
  return monthKey(new Date(y, m - 1 + delta, 1));
}

export function monthLabel(key: string) {
  const [y, m] = key.split("-").map(Number);
  const label = new Intl.DateTimeFormat("pt-BR", { month: "long", year: "numeric" }).format(new Date(y, m - 1, 1));
  return label.charAt(0).toUpperCase() + label.slice(1);
}
