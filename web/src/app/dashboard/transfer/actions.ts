"use server";

import { refresh } from "next/cache";
import { unstable_rethrow } from "next/navigation";
import { ApiError } from "@/lib/api";
import { createTransfer } from "@/lib/kinko";
import { parseAmountToCents } from "@/lib/format";

export type TransferState =
  | { status: "idle" }
  | { status: "error"; error: string; values: { destination: string; amount: string; description: string } }
  | { status: "success"; amountCents: number; destination: string; transactionId: string };

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// Backend error → message shown to the user
const ERRORS: Record<string, string> = {
  "Insufficient funds": "Insufficient funds for this transfer.",
  "Cannot transfer to the same account": "You can't transfer to your own account.",
  "Invalid amount": "Invalid amount.",
  "Account not found": "Destination account not found.",
};

export async function transfer(_prev: TransferState, formData: FormData): Promise<TransferState> {
  const values = {
    destination: String(formData.get("destination") ?? "").trim(),
    amount: String(formData.get("amount") ?? "").trim(),
    description: String(formData.get("description") ?? "").trim(),
  };

  if (!UUID.test(values.destination)) {
    return { status: "error", error: "Enter a valid account number (UUID).", values };
  }
  const amountCents = parseAmountToCents(values.amount);
  if (!amountCents) {
    return { status: "error", error: "Enter a valid amount greater than zero (e.g. 25.50).", values };
  }

  try {
    const res = await createTransfer({
      destination_account_uuid: values.destination,
      amount_cents: amountCents,
      ...(values.description ? { description: values.description } : {}),
    });
    refresh(); // balance and statement are fresh when navigating back
    return { status: "success", amountCents, destination: values.destination, transactionId: res.transaction_id };
  } catch (err) {
    unstable_rethrow(err); // e.g. redirect to /auth/logout when the token expired
    if (err instanceof ApiError && ERRORS[err.message]) {
      return { status: "error", error: ERRORS[err.message], values };
    }
    console.error("Transfer failed:", err);
    return { status: "error", error: "We couldn't complete the transfer. Please try again.", values };
  }
}
