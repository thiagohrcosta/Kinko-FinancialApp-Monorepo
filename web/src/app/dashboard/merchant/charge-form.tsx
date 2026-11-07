"use client";

import { useActionState, useState } from "react";
import { formatCurrency } from "@/lib/format";
import { formatPaymentCode } from "@/lib/payment-code";
import { createChargeAction, type CreateChargeState } from "./actions";

const initialState: CreateChargeState = { status: "idle" };

export function ChargeForm() {
  const [round, setRound] = useState(0);
  return <ChargeFormInner key={round} onReset={() => setRound((r) => r + 1)} />;
}

function CopyText({ value, label }: { value: string; label: string }) {
  const [copied, setCopied] = useState(false);
  return (
    <button
      type="button"
      className="btn-outline"
      onClick={async () => {
        try {
          await navigator.clipboard.writeText(value);
          setCopied(true);
          setTimeout(() => setCopied(false), 1500);
        } catch {
          // Clipboard unavailable: the code can still be selected
        }
      }}
    >
      {copied ? "Copied!" : label}
    </button>
  );
}

function ChargeFormInner({ onReset }: { onReset: () => void }) {
  const [state, formAction, pending] = useActionState(createChargeAction, initialState);

  if (state.status === "success") {
    const { charge } = state;
    return (
      <div className="card space-y-4 p-5 text-center">
        <h2 className="text-lg font-bold">Charge created</h2>
        <p className="text-2xl font-bold tabular-nums">{formatCurrency(charge.amount_cents / 100, charge.currency)}</p>
        <p className="text-sm text-muted">{charge.description}</p>
        {/* eslint-disable-next-line @next/next/no-img-element -- dynamic SVG from our own route */}
        <img src={`/api/qr/${charge.code}`} alt={`QR code for ${charge.code}`} className="mx-auto size-48" />
        <p className="select-all break-all rounded-xl bg-chip px-3 py-2 font-mono text-sm">{formatPaymentCode(charge.code)}</p>
        <div className="flex flex-col gap-2 sm:flex-row sm:justify-center">
          <CopyText value={charge.code} label="Copy code" />
          <button type="button" onClick={onReset} className="btn-outline">
            New charge
          </button>
        </div>
      </div>
    );
  }

  const v = state.status === "error" ? state.values : undefined;
  return (
    <form action={formAction} className="card space-y-4 p-5">
      <h2 className="font-bold">New charge</h2>
      <div>
        <label htmlFor="amount" className="field-label">
          Amount (USD)
        </label>
        <input id="amount" name="amount" required inputMode="decimal" defaultValue={v?.amount} placeholder="0.00" className="field tabular-nums" />
      </div>
      <div>
        <label htmlFor="description" className="field-label">
          Description
        </label>
        <input id="description" name="description" required maxLength={140} defaultValue={v?.description} placeholder="e.g. Order #1001" className="field" />
      </div>
      <div className="grid gap-4 sm:grid-cols-2">
        <div>
          <label htmlFor="reference" className="field-label">
            Your reference <span className="font-normal text-subtle">(optional)</span>
          </label>
          <input id="reference" name="reference" maxLength={100} defaultValue={v?.reference} className="field" />
        </div>
        <div>
          <label htmlFor="expires" className="field-label">
            Expires in
          </label>
          <select id="expires" name="expires" defaultValue={v?.expires ?? "86400"} className="field">
            <option value="900">15 minutes</option>
            <option value="3600">1 hour</option>
            <option value="86400">24 hours</option>
            <option value="604800">7 days</option>
          </select>
        </div>
      </div>
      {state.status === "error" && (
        <p role="alert" className="rounded-xl bg-[#FFF5F5] px-3 py-2 text-sm text-kinko">
          {state.error}
        </p>
      )}
      <button type="submit" disabled={pending} className="btn-kinko w-full">
        {pending ? "Creating…" : "Create charge"}
      </button>
    </form>
  );
}
