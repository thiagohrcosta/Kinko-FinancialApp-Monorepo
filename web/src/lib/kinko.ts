import "server-only";
import { authFetch, publicFetch } from "./api";

export type LoginResponse = {
  token: string;
  user: { id: number; email: string; full_name: string };
};

export type Balance = {
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
