"use client";

import Link from "next/link";
import { useState, useTransition } from "react";
import { loadStripe, type Appearance, type Stripe } from "@stripe/stripe-js";
import { Elements, PaymentElement, useElements, useStripe } from "@stripe/react-stripe-js";
import { formatCurrency } from "@/lib/format";
import { validateDepositAmount } from "@/lib/deposit-rules";
import { startDeposit } from "./actions";

// Payment Element com a identidade do Kinko
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
          <p className="text-sm text-muted">Valor do depósito</p>
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
          // Carrega o Stripe.js só quando necessário e antes de criar o PaymentIntent,
          // para não deixar pagamentos órfãos se o script estiver bloqueado.
          let instance = stripe;
          if (!instance) {
            try {
              instance = await loadStripe(publishableKey);
            } catch {
              instance = null;
            }
            if (!instance) {
              setError("Não foi possível carregar o Stripe. Verifique sua conexão ou bloqueadores de anúncio.");
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
          Quanto você quer depositar? (USD)
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
        {pending ? "Preparando pagamento…" : "Continuar para o pagamento"}
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
      // Só redireciona quando o método exige (ex.: 3D Secure); volta para esta página.
      redirect: "if_required",
      confirmParams: { return_url: `${window.location.origin}/dashboard/deposit` },
    });

    if (error) {
      setError(error.message ?? "Pagamento não aprovado.");
      setSubmitting(false);
    } else if (paymentIntent?.status === "succeeded" || paymentIntent?.status === "processing") {
      onSuccess();
    } else {
      setError("Pagamento não concluído. Tente novamente.");
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
        {submitting ? "Processando…" : `Pagar ${formatCurrency(amountCents / 100)}`}
      </button>
      <button type="button" onClick={onCancel} disabled={submitting} className="btn-ghost w-full">
        Alterar valor
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
      <h2 className="mt-3 text-lg font-bold">Pagamento aprovado</h2>
      {amountCents !== undefined && (
        <p className="mt-1 text-2xl font-bold tabular-nums">{formatCurrency(amountCents / 100)}</p>
      )}
      <p className="mx-auto mt-2 max-w-sm text-sm text-muted">
        O valor é creditado no seu saldo assim que o Stripe confirmar o pagamento (normalmente em poucos segundos).
      </p>
      <Link href="/dashboard" className="btn-outline mt-5">
        Voltar para a visão geral
      </Link>
    </div>
  );
}
