"use server";

import { refresh } from "next/cache";
import { unstable_rethrow } from "next/navigation";
import { ApiError } from "@/lib/api";
import { payPaymentRequest, type PaymentResult } from "@/lib/kinko";
import { normalizePaymentCode } from "@/lib/payment-code";

export type PayState = { status: "idle" } | { status: "error"; error: string } | { status: "success"; result: PaymentResult };

// Backend error → message shown to the payer
const ERRORS: Record<string, string> = {
  "Insufficient funds": "You don't have enough balance to pay this charge.",
  "Payment request already paid": "This charge has already been paid.",
  "Payment request expired": "This charge has expired. Ask the merchant for a new code.",
  "Payment request canceled": "The merchant canceled this charge.",
  "Cannot pay your own payment request": "You can't pay your own charge.",
  "Invalid payment code": "This payment code is not valid.",
  "Payment request not found": "We couldn't find a charge for this code.",
};

export async function pay(code: string): Promise<PayState> {
  const normalized = normalizePaymentCode(code);
  if (!normalized) return { status: "error", error: ERRORS["Invalid payment code"] };

  try {
    const result = await payPaymentRequest(normalized);
    refresh(); // balance and statement are fresh when navigating back
    return { status: "success", result };
  } catch (err) {
    unstable_rethrow(err);
    if (err instanceof ApiError && ERRORS[err.message]) return { status: "error", error: ERRORS[err.message] };
    console.error("Payment failed:", err);
    return { status: "error", error: "We couldn't complete the payment. Please try again." };
  }
}
