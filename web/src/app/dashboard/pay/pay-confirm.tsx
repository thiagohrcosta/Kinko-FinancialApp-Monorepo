"use client";

import Link from "next/link";
import { useActionState } from "react";
import { formatCurrency } from "@/lib/format";
import { pay, type PayState } from "./actions";

const initialState: PayState = { status: "idle" };

export function PayConfirm({ code, disabled, label }: { code: string; disabled: boolean; label: string }) {
  const [state, formAction, pending] = useActionState(pay.bind(null, code), initialState);

  if (state.status === "success") {
    const { result } = state;
    return (
      <div className="card p-6 text-center">
        <span className="mx-auto grid size-14 place-items-center rounded-full bg-credit/12 text-2xl text-credit" aria-hidden>
          ✓
        </span>
        <h2 className="mt-3 text-lg font-bold">Payment complete</h2>
        <p className="mt-1 text-2xl font-bold tabular-nums">{formatCurrency(result.amount_cents / 100, result.currency)}</p>
        <p className="mt-1 text-sm text-muted">to {result.merchant.name}</p>
        <p className="mt-3 break-all text-[11px] text-subtle">Transaction ID: {result.transaction_id}</p>
        <div className="mt-5 flex flex-col gap-2 sm:flex-row sm:justify-center">
          <Link href="/dashboard/statement" className="btn-outline">
            View in statement
          </Link>
          <Link href="/dashboard/pay" className="btn-outline">
            Pay another code
          </Link>
        </div>
      </div>
    );
  }

  return (
    <form action={formAction} className="space-y-3">
      {state.status === "error" && (
        <p role="alert" className="rounded-xl bg-[#FFF5F5] px-3 py-2 text-sm text-kinko">
          {state.error}
        </p>
      )}
      <button type="submit" disabled={disabled || pending} className="btn-kinko w-full">
        {pending ? "Paying…" : label}
      </button>
    </form>
  );
}
