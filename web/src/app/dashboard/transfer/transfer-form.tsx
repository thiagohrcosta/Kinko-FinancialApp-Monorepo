"use client";

import Link from "next/link";
import { useActionState, useState } from "react";
import { formatCurrency } from "@/lib/format";
import { transfer, type TransferState } from "./actions";

const initialState: TransferState = { status: "idle" };

export function TransferForm() {
  // Changing the key remounts the form with a clean state ("New transfer")
  const [round, setRound] = useState(0);
  return <TransferFormInner key={round} onReset={() => setRound((r) => r + 1)} />;
}

function TransferFormInner({ onReset }: { onReset: () => void }) {
  const [state, formAction, pending] = useActionState(transfer, initialState);

  if (state.status === "success") {
    return (
      <div className="card p-6 text-center">
        <span className="mx-auto grid size-14 place-items-center rounded-full bg-credit/12 text-2xl text-credit" aria-hidden>
          ✓
        </span>
        <h2 className="mt-3 text-lg font-bold">Transfer complete</h2>
        <p className="mt-1 text-2xl font-bold tabular-nums">{formatCurrency(state.amountCents / 100)}</p>
        <p className="mt-1 break-all text-xs text-subtle">to {state.destination}</p>
        <p className="mt-3 break-all text-[11px] text-subtle">Transaction ID: {state.transactionId}</p>
        <div className="mt-5 flex flex-col gap-2 sm:flex-row sm:justify-center">
          <Link href="/dashboard/statement" className="btn-outline">
            View in statement
          </Link>
          <button type="button" onClick={onReset} className="btn-outline">
            New transfer
          </button>
        </div>
      </div>
    );
  }

  const v = state.status === "error" ? state.values : undefined;

  return (
    <form action={formAction} className="card space-y-4 p-5">
      <div>
        <label htmlFor="destination" className="field-label">
          Destination account
        </label>
        <input
          id="destination"
          name="destination"
          required
          defaultValue={v?.destination}
          placeholder="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
          autoComplete="off"
          spellCheck={false}
          className="field font-mono"
        />
      </div>
      <div>
        <label htmlFor="amount" className="field-label">
          Amount (USD)
        </label>
        <div className="relative">
          <span className="pointer-events-none absolute inset-y-0 left-3 grid place-items-center text-sm text-muted">$</span>
          <input
            id="amount"
            name="amount"
            required
            inputMode="decimal"
            defaultValue={v?.amount}
            placeholder="0.00"
            className="field pl-7 text-lg font-bold tabular-nums"
          />
        </div>
      </div>
      <div>
        <label htmlFor="description" className="field-label">
          Description <span className="font-normal text-subtle">(optional)</span>
        </label>
        <input id="description" name="description" maxLength={80} defaultValue={v?.description} placeholder="e.g. Dinner" className="field" />
      </div>

      {state.status === "error" && (
        <p role="alert" className="rounded-xl bg-[#FFF5F5] px-3 py-2 text-sm text-kinko">
          {state.error}
        </p>
      )}

      <button type="submit" disabled={pending} className="btn-kinko w-full">
        {pending ? "Sending…" : "Send transfer"}
      </button>
    </form>
  );
}
