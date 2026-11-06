import type { Metadata } from "next";
import { Suspense } from "react";
import { AccountCard } from "../_components/account-card";
import { CardSkeleton } from "../_components/skeleton";
import { TransferForm } from "./transfer-form";

export const metadata: Metadata = { title: "Transferir · Kinko" };

export default function TransferPage() {
  return (
    <div className="mx-auto grid max-w-4xl gap-6 md:grid-cols-5">
      <div className="min-w-0 space-y-4 md:col-span-2">
        <h1 className="text-xl font-bold">Transferir</h1>
        <p className="text-sm text-muted">
          Envie dinheiro para outra conta Kinko usando o número da conta. As duas pernas da transferência são
          registradas no ledger com o mesmo ID de transação.
        </p>
        <Suspense fallback={<CardSkeleton className="h-40" />}>
          <AccountCard />
        </Suspense>
      </div>
      <div className="min-w-0 md:col-span-3 md:pt-11">
        <TransferForm />
      </div>
    </div>
  );
}
