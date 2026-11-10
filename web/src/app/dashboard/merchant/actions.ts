"use server";

import { revalidatePath } from "next/cache";
import { unstable_rethrow } from "next/navigation";
import { ApiError } from "@/lib/api";
import { parseAmountToCents } from "@/lib/format";
import {
  cancelCharge,
  createApiKey,
  createCharge,
  revokeApiKey,
  rotateWebhookSecret,
  saveWebhookEndpoint,
  type Charge,
} from "@/lib/kinko";

export type CreateChargeState =
  | { status: "idle" }
  | { status: "error"; error: string; values: { amount: string; description: string; reference: string; expires: string } }
  | { status: "success"; charge: Charge };

const EXPIRY_OPTIONS = new Set(["900", "3600", "86400", "604800"]);

function message(err: unknown, fallback: string) {
  unstable_rethrow(err);
  if (err instanceof ApiError && err.status < 500) return err.message;
  console.error(fallback, err);
  return fallback;
}

export async function createChargeAction(_prev: CreateChargeState, formData: FormData): Promise<CreateChargeState> {
  const values = {
    amount: String(formData.get("amount") ?? "").trim(),
    description: String(formData.get("description") ?? "").trim(),
    reference: String(formData.get("reference") ?? "").trim(),
    expires: String(formData.get("expires") ?? "86400"),
  };
  const amountCents = parseAmountToCents(values.amount);
  if (!amountCents) return { status: "error", error: "Enter a valid amount greater than zero (e.g. 25.50).", values };
  if (!values.description) return { status: "error", error: "Enter a description.", values };

  try {
    const charge = await createCharge({
      amount_cents: amountCents,
      description: values.description,
      ...(values.reference ? { external_reference: values.reference } : {}),
      expires_in: Number(EXPIRY_OPTIONS.has(values.expires) ? values.expires : "86400"),
    });
    revalidatePath("/dashboard/merchant");
    return { status: "success", charge };
  } catch (err) {
    return { status: "error", error: message(err, "We couldn't create the charge. Please try again."), values };
  }
}

export async function cancelChargeAction(id: string) {
  try {
    await cancelCharge(id);
  } catch (err) {
    message(err, "Cancel failed");
  }
  revalidatePath("/dashboard/merchant");
}

export type ApiKeyState = { status: "idle" } | { status: "error"; error: string } | { status: "created"; name: string; secret: string };

export async function createApiKeyAction(_prev: ApiKeyState, formData: FormData): Promise<ApiKeyState> {
  const name = String(formData.get("name") ?? "").trim();
  if (!name) return { status: "error", error: "Give the key a name (e.g. Production)." };
  try {
    const key = await createApiKey(name);
    revalidatePath("/dashboard/merchant/developers");
    return { status: "created", name: key.name, secret: key.secret };
  } catch (err) {
    return { status: "error", error: message(err, "We couldn't create the key. Please try again.") };
  }
}

export async function revokeApiKeyAction(id: number) {
  try {
    await revokeApiKey(id);
  } catch (err) {
    message(err, "Revoke failed");
  }
  revalidatePath("/dashboard/merchant/developers");
}

export type WebhookState = { status: "idle" } | { status: "error"; error: string; url: string } | { status: "saved" };

export async function saveWebhookAction(_prev: WebhookState, formData: FormData): Promise<WebhookState> {
  const url = String(formData.get("url") ?? "").trim();
  if (!url) return { status: "error", error: "Enter the URL that will receive the webhooks.", url };
  try {
    await saveWebhookEndpoint(url);
    revalidatePath("/dashboard/merchant/developers");
    return { status: "saved" };
  } catch (err) {
    return { status: "error", error: message(err, "We couldn't save the URL. Please try again."), url };
  }
}

export async function rotateSecretAction() {
  try {
    await rotateWebhookSecret();
  } catch (err) {
    message(err, "Rotate failed");
  }
  revalidatePath("/dashboard/merchant/developers");
}
