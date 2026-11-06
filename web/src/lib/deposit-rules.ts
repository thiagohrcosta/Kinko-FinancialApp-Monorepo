import { parseAmountToCents } from "./format";

export const MIN_DEPOSIT_CENTS = 100; // Stripe exige ≥ US$ 0,50; usamos US$ 1,00
export const MAX_DEPOSIT_CENTS = 10_000_00;

/** Validação compartilhada entre cliente (feedback imediato) e servidor (fonte da verdade). */
export function validateDepositAmount(raw: string): { cents: number } | { error: string } {
  const cents = parseAmountToCents(raw);
  if (!cents || cents < MIN_DEPOSIT_CENTS) return { error: "O valor mínimo é $1.00." };
  if (cents > MAX_DEPOSIT_CENTS) return { error: "O valor máximo por depósito é $10,000.00." };
  return { cents };
}
