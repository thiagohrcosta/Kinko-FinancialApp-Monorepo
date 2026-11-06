import { parseAmountToCents } from "./format";

export const MIN_DEPOSIT_CENTS = 100; // Stripe requires ≥ $0.50; we use $1.00
export const MAX_DEPOSIT_CENTS = 10_000_00;

/** Shared between the client (instant feedback) and the server (source of truth). */
export function validateDepositAmount(raw: string): { cents: number } | { error: string } {
  const cents = parseAmountToCents(raw);
  if (!cents) return { error: "Enter a valid amount (e.g. 25.50)." };
  if (cents < MIN_DEPOSIT_CENTS) return { error: "The minimum deposit is $1.00." };
  if (cents > MAX_DEPOSIT_CENTS) return { error: "The maximum deposit is $10,000.00." };
  return { cents };
}
