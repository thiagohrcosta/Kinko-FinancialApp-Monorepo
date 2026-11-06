"use client";

import Link from "next/link";
import { useState, useTransition } from "react";
import { loadStripe, type Appearance, type Stripe } from "@stripe/stripe-js";
import { Elements, PaymentElement, useElements, useStripe } from "@stripe/react-stripe-js";
import { formatCurrency } from "@/lib/format";
import { validateDepositAmount } from "@/lib/deposit-rules";
import { startDeposit } from "./actions";

// Payment Element styled with the Kinko brand
const appearance: Appearance = {
  theme: "stripe",
  variables: {
    colorPrimary: "#d01c1c",
    colorDanger: "#dc2626",
    colorText: "#1f212a",
    fontFamily: "Roboto, system-ui, sans-serif",
    borderRadius: "12px",
  },
};

const PRESETS = ["25", "50", "100", "250"];

export function DepositFlow({ publishableKey }: { publishableKey: string }) {
  const [amount, setAmount] = useState("");
  const [stripe, setStripe] = useState<Stripe | null>(null);
  const [intent, setIntent] = useState<{ clientSecret: string; amountCents: number } | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [done, setDone] = useState<number | null>(null);
  const [pending, startTransition] = useTransition();

  if (done !== null) return <DepositSuccess amountCents={done} />;

  if (intent) {
    return (
      <div className="card space-y-4 p-5">
        <div className="flex items-center justify-between">
          <p className="text-sm text-muted">Deposit amount</p>
          <p className="text-xl font-bold tabular-nums">{formatCurrency(intent.amountCents / 100)}</p>
        </div>
        <Elements stripe={stripe} options={{ clientSecret: intent.clientSecret, appearance }}>
          <PaymentStep
            amountCents={intent.amountCents}
            onSuccess={() => setDone(intent.amountCents)}
            onCancel={() => setIntent(null)}
          />
        </Elements>
      </div>
    );
  }

  return (
    <form
      className="card space-y-4 p-5"
      onSubmit={(e) => {
        e.preventDefault();
        setError(null);
        const validation = validateDepositAmount(amount);
        if ("error" in validation) {
          setError(validation.error);
          return;
        }
        startTransition(async () => {
          // Load Stripe.js on demand and before creating the PaymentIntent, so a blocked
          // script doesn't leave orphaned payments behind.
          let instance = stripe;
          if (!instance) {
            try {
              instance = await loadStripe(publishableKey);
            } catch {
              instance = null;
            }
            if (!instance) {
              setError("We couldn't load Stripe. Check your connection or ad blocker.");
              return;
            }
            setStripe(instance);
          }

          const res = await startDeposit(amount);
          if (res.ok) setIntent({ clientSecret: res.clientSecret, amountCents: res.amountCents });
          else setError(res.error);
        });
      }}
    >
      <div>
        <label htmlFor="amount" className="field-label">
          How much do you want to deposit? (USD)
        </label>
        <div className="relative">
          <span className="pointer-events-none absolute inset-y-0 left-3 grid place-items-center text-muted">$</span>
          <input
            id="amount"
            required
            inputMode="decimal"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            placeholder="0.00"
            className="field pl-7 text-2xl font-bold tabular-nums"
          />
        </div>
      </div>
      <div className="flex flex-wrap gap-2">
        {PRESETS.map((p) => (
          <button
            key={p}
            type="button"
            onClick={() => setAmount(p)}
            className={`rounded-full px-4 py-1.5 text-sm font-semibold transition ${
              amount === p ? "bg-kinko-accent text-white" : "bg-chip text-[#333] hover:bg-[#e2e2e2]"
            }`}
          >
            ${p}
          </button>
        ))}
      </div>

      {error && (
        <p role="alert" className="rounded-xl bg-[#FFF5F5] px-3 py-2 text-sm text-kinko">
          {error}
        </p>
      )}

      <button type="submit" disabled={pending} className="btn-kinko w-full">
        {pending ? "Preparing payment…" : "Continue to payment"}
      </button>
    </form>
  );
}

function PaymentStep({
  amountCents,
  onSuccess,
  onCancel,
}: {
  amountCents: number;
  onSuccess: () => void;
  onCancel: () => void;
}) {
  const stripe = useStripe();
  const elements = useElements();
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!stripe || !elements) return;
    setSubmitting(true);
    setError(null);

    const { error, paymentIntent } = await stripe.confirmPayment({
      elements,
      // Only redirects when the method requires it (e.g. 3D Secure); returns to this page.
      redirect: "if_required",
      confirmParams: { return_url: `${window.location.origin}/dashboard/deposit` },
    });

    if (error) {
      setError(error.message ?? "Payment was not approved.");
      setSubmitting(false);
    } else if (paymentIntent?.status === "succeeded" || paymentIntent?.status === "processing") {
      onSuccess();
    } else {
      setError("Payment was not completed. Please try again.");
      setSubmitting(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <PaymentElement />
      {error && (
        <p role="alert" className="rounded-xl bg-[#FFF5F5] px-3 py-2 text-sm text-kinko">
          {error}
        </p>
      )}
      <button type="submit" disabled={!stripe || submitting} className="btn-kinko w-full">
        {submitting ? "Processing…" : `Pay ${formatCurrency(amountCents / 100)}`}
      </button>
      <button type="button" onClick={onCancel} disabled={submitting} className="btn-ghost w-full">
        Change amount
      </button>
    </form>
  );
}

export function DepositSuccess({ amountCents }: { amountCents?: number }) {
  return (
    <div className="card p-6 text-center">
      <span className="mx-auto grid size-14 place-items-center rounded-full bg-credit/12 text-2xl text-credit" aria-hidden>
        ✓
      </span>
      <h2 className="mt-3 text-lg font-bold">Payment approved</h2>
      {amountCents !== undefined && (
        <p className="mt-1 text-2xl font-bold tabular-nums">{formatCurrency(amountCents / 100)}</p>
      )}
      <p className="mx-auto mt-2 max-w-sm text-sm text-muted">
        The amount is added to your balance as soon as Stripe confirms the payment (usually within a few seconds).
      </p>
      <Link href="/dashboard" className="btn-outline mt-5">
        Back to overview
      </Link>
    </div>
  );
}
