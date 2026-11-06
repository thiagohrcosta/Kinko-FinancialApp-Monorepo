import "server-only";
import { authFetch, publicFetch } from "./api";

export type LoginResponse = {
  token: string;
  user: { id: number; email: string; full_name: string };
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

/** month no formato YYYY-MM; o backend usa o mês atual por padrão. */
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
