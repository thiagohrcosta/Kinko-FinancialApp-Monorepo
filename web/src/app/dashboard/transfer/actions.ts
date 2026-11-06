"use server";

import { refresh } from "next/cache";
import { ApiError } from "@/lib/api";
import { createTransfer } from "@/lib/kinko";
import { parseAmountToCents } from "@/lib/format";

export type TransferState =
  | { status: "idle" }
  | { status: "error"; error: string; values: { destination: string; amount: string; description: string } }
  | { status: "success"; amountCents: number; destination: string; transactionId: string };

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const ERRORS: Record<string, string> = {
  "Insufficient funds": "Saldo insuficiente para esta transferência.",
  "Cannot transfer to the same account": "Você não pode transferir para a sua própria conta.",
  "Invalid amount": "Valor inválido.",
  "Account not found": "Conta de destino não encontrada.",
};

export async function transfer(_prev: TransferState, formData: FormData): Promise<TransferState> {
  const values = {
    destination: String(formData.get("destination") ?? "").trim(),
    amount: String(formData.get("amount") ?? "").trim(),
    description: String(formData.get("description") ?? "").trim(),
  };

  if (!UUID.test(values.destination)) {
    return { status: "error", error: "Informe um número de conta (UUID) válido.", values };
  }
  const amountCents = parseAmountToCents(values.amount);
  if (!amountCents) {
    return { status: "error", error: "Informe um valor maior que zero.", values };
  }

  try {
    const res = await createTransfer({
      destination_account_uuid: values.destination,
      amount_cents: amountCents,
      ...(values.description ? { description: values.description } : {}),
    });
    refresh(); // saldo e extrato atualizados ao navegar de volta
    return { status: "success", amountCents, destination: values.destination, transactionId: res.transaction_id };
  } catch (err) {
    if (err instanceof ApiError && ERRORS[err.message]) {
      return { status: "error", error: ERRORS[err.message], values };
    }
    console.error("Transfer failed:", err);
    return { status: "error", error: "Não foi possível concluir a transferência. Tente novamente.", values };
  }
}
