"use server";

import { unstable_rethrow } from "next/navigation";
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
    unstable_rethrow(err); // e.g. redirect to /auth/logout when the token expired
    if (err instanceof ApiError && err.status === 502) {
      return { ok: false, error: "The payment provider is unavailable right now. Please try again later." };
    }
    console.error("Deposit failed:", err);
    return { ok: false, error: "We couldn't start the deposit. Please try again." };
  }
}
