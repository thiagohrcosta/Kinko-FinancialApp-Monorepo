import type { Metadata } from "next";
import { Suspense } from "react";
import { CardSkeleton } from "../_components/skeleton";
import { DepositFlow, DepositSuccess } from "./deposit-flow";

export const metadata: Metadata = { title: "Depositar · Kinko" };

async function DepositContent({ searchParams }: { searchParams: PageProps<"/dashboard/deposit">["searchParams"] }) {
  const params = await searchParams;

  // Retorno de um redirect do Stripe (ex.: 3D Secure)
  if (params.redirect_status === "succeeded") return <DepositSuccess />;

  // Lida em tempo de requisição (depois do await acima), não no build.
  const publishableKey = process.env.STRIPE_PUBLISHABLE_KEY;
  if (!publishableKey) {
    return (
      <div className="card p-5 text-sm">
        <p className="font-bold text-kinko">Depósito com cartão não configurado</p>
        <p className="mt-1 text-muted">
          Defina <code className="rounded bg-chip px-1">STRIPE_PUBLISHABLE_KEY</code> no ambiente do frontend (a mesma
          conta Stripe do <code className="rounded bg-chip px-1">STRIPE_SECRET_KEY</code> do backend).
        </p>
      </div>
    );
  }

  return (
    <>
      {params.redirect_status === "failed" && (
        <p role="alert" className="mb-4 rounded-xl bg-[#FFF5F5] px-3 py-2 text-sm text-kinko">
          O pagamento não foi aprovado. Tente novamente.
        </p>
      )}
      <DepositFlow publishableKey={publishableKey} />
    </>
  );
}

export default function DepositPage({ searchParams }: PageProps<"/dashboard/deposit">) {
  return (
    <div className="mx-auto grid max-w-4xl gap-6 md:grid-cols-5">
      <div className="min-w-0 space-y-3 md:col-span-2">
        <h1 className="text-xl font-bold">Depositar</h1>
        <p className="text-sm text-muted">
          Adicione saldo com cartão via Stripe. O Kinko só registra o crédito no ledger depois que o Stripe confirma o
          pagamento pelo webhook — nunca a partir do navegador.
        </p>
        <p className="text-xs text-subtle">
          Em modo de teste, use o cartão <span className="font-mono">4242 4242 4242 4242</span>, qualquer data futura e
          qualquer CVC.
        </p>
      </div>
      <div className="min-w-0 md:col-span-3 md:pt-11">
        <Suspense fallback={<CardSkeleton className="h-56" />}>
          <DepositContent searchParams={searchParams} />
        </Suspense>
      </div>
    </div>
  );
}
