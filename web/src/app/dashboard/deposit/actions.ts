"use server";

import { ApiError } from "@/lib/api";
import { createDeposit } from "@/lib/kinko";
import { validateDepositAmount } from "@/lib/deposit-rules";

export type StartDepositResult =
  | { ok: true; clientSecret: string; amountCents: number }
  | { ok: false; error: string };

export async function startDeposit(rawAmount: string): Promise<StartDepositResult> {
  const validation = validateDepositAmount(rawAmount);
  if ("error" in validation) return { ok: false, error: validation.error };
  const amountCents = validation.cents;

  try {
    const { client_secret } = await createDeposit(amountCents);
    return { ok: true, clientSecret: client_secret, amountCents };
  } catch (err) {
    if (err instanceof ApiError && err.status === 502) {
      return { ok: false, error: "O provedor de pagamentos está indisponível no momento. Tente novamente mais tarde." };
    }
    console.error("Deposit failed:", err);
    return { ok: false, error: "Não foi possível iniciar o depósito. Tente novamente." };
  }
}
