import "server-only";
import { authFetch, publicFetch } from "./api";

export type LoginResponse = {
  token: string;
  user: { id: number; email: string; full_name: string; user_type: "individual" | "business" };
};

export type Balance = {
  account_uuid: string;
  balance: string;
  income: number;
  expenses: number;
  period: string;
};

export type Transaction = {
  id: number;
  amount_cents: number;
  entry_type: "credit" | "debit";
  description: string;
  counterparty_name: string | null;
  counterparty_type: "individual" | "business" | null;
  counterparty_sector: string | null;
  created_at: string;
  currency: string;
};

export type InsightRange = 7 | 14 | 30;

export type Insights = {
  range: string;
  dates: string[];
  income: number[];
  expenses: number[];
};

export function login(email: string, password: string) {
  return publicFetch<LoginResponse>("/api/v1/auth/login", {
    method: "POST",
    body: JSON.stringify({ email, password }),
  });
}

export function getBalance() {
  return authFetch<Balance>("/api/v1/accounts/balance");
}

/** month as YYYY-MM; the backend defaults to the current month. */
export function getTransactions(month?: string) {
  const qs = month ? `?month=${encodeURIComponent(month)}` : "";
  return authFetch<Transaction[]>(`/api/v1/accounts/transactions${qs}`);
}

export function getInsights(range: InsightRange) {
  return authFetch<Insights>(`/api/v1/accounts/insights?range=${range}`);
}


export type RegisterPayload = {
  email: string;
  password: string;
  password_confirmation: string;
  full_name: string;
  user_type: "individual" | "business";
  business_name?: string;
  business_sector?: string;
  document_number?: string;
  phone_number?: string;
  address_zip_code: string;
  address_street: string;
  address_number: string;
  address_complement?: string;
  address_neighborhood: string;
  address_city: string;
  address_state: string;
};

export function register(payload: RegisterPayload) {
  return publicFetch<LoginResponse>("/api/v1/auth/register", {
    method: "POST",
    body: JSON.stringify(payload),
  });
}

export function createTransfer(input: { destination_account_uuid: string; amount_cents: number; description?: string }) {
  return authFetch<{ message: string; transaction_id: string }>("/api/v1/transfers", {
    method: "POST",
    body: JSON.stringify(input),
  });
}

export function createDeposit(amount_cents: number) {
  return authFetch<{ payment_intent_id: string; client_secret: string }>("/api/v1/deposits", {
    method: "POST",
    body: JSON.stringify({ amount_cents }),
  });
}

// ---- Payment gateway: payer side -------------------------------------------

export type PaymentRequestStatus = "pending" | "paid" | "canceled" | "expired";

export type MerchantSummary = { name: string; sector: string | null; account_uuid: string };

export type PaymentPreview = {
  code: string;
  status: PaymentRequestStatus;
  amount_cents: number;
  currency: string;
  description: string;
  expires_at: string;
  paid_at: string | null;
  merchant: MerchantSummary;
  payer: {
    account_uuid: string;
    balance_cents: number;
    sufficient_funds: boolean;
    is_merchant: boolean;
    already_paid_by_you: boolean;
  };
};

export type PaymentResult = {
  status: "paid";
  transaction_id: string;
  amount_cents: number;
  currency: string;
  paid_at: string;
  merchant: MerchantSummary;
};

export function getPaymentPreview(code: string) {
  return authFetch<PaymentPreview>(`/api/v1/payment_requests/${encodeURIComponent(code)}`);
}

export function payPaymentRequest(code: string) {
  return authFetch<PaymentResult>(`/api/v1/payment_requests/${encodeURIComponent(code)}/pay`, { method: "POST" });
}

// ---- Payment gateway: merchant side ----------------------------------------

export type Charge = {
  id: string;
  object: "payment_request";
  code: string;
  status: PaymentRequestStatus;
  amount_cents: number;
  fee_cents: number;
  currency: string;
  description: string;
  external_reference: string | null;
  metadata: Record<string, string>;
  expires_at: string;
  paid_at: string | null;
  canceled_at: string | null;
  payer: { account_uuid: string; name: string } | null;
  created_at: string;
};

export type ApiKey = {
  id: number;
  name: string;
  masked_key: string;
  created_at: string;
  last_used_at: string | null;
  revoked_at: string | null;
};

export type WebhookEndpoint = {
  url: string;
  active: boolean;
  /** e.g. kinko_whsec_…abcd */
  masked_secret: string;
  /** Only in the response that creates the endpoint or rotates the secret. */
  signing_secret?: string;
  updated_at: string;
};

export type WebhookDeliveryRow = {
  id: string;
  event_type: string;
  status: "pending" | "succeeded" | "failed";
  attempts: number;
  last_response_code: number | null;
  last_error: string | null;
  created_at: string;
  delivered_at: string | null;
};

export function listCharges(status?: PaymentRequestStatus) {
  const qs = status ? `?status=${status}` : "";
  return authFetch<{ data: Charge[]; limit: number; offset: number }>(`/api/v1/merchant/payment_requests${qs}`);
}

export function createCharge(input: { amount_cents: number; description: string; external_reference?: string; expires_in?: number }) {
  return authFetch<Charge>("/api/v1/merchant/payment_requests", {
    method: "POST",
    body: JSON.stringify(input),
    // A double submit of the same form returns the same charge.
    headers: { "Idempotency-Key": crypto.randomUUID() },
  });
}

export function cancelCharge(id: string) {
  return authFetch<Charge>(`/api/v1/merchant/payment_requests/${encodeURIComponent(id)}/cancel`, { method: "POST" });
}

export function listApiKeys() {
  return authFetch<ApiKey[]>("/api/v1/merchant/api_keys");
}

export function createApiKey(name: string) {
  return authFetch<ApiKey & { secret: string }>("/api/v1/merchant/api_keys", {
    method: "POST",
    body: JSON.stringify({ name }),
  });
}

export function revokeApiKey(id: number) {
  return authFetch<ApiKey>(`/api/v1/merchant/api_keys/${id}`, { method: "DELETE" });
}

export function getWebhookEndpoint() {
  return authFetch<{ endpoint: WebhookEndpoint | null; deliveries: WebhookDeliveryRow[] }>("/api/v1/merchant/webhook_endpoint");
}

export function saveWebhookEndpoint(url: string) {
  return authFetch<{ endpoint: WebhookEndpoint }>("/api/v1/merchant/webhook_endpoint", {
    method: "PUT",
    body: JSON.stringify({ url }),
  });
}

export function rotateWebhookSecret() {
  return authFetch<{ endpoint: WebhookEndpoint }>("/api/v1/merchant/webhook_endpoint/rotate_secret", { method: "POST" });
}
