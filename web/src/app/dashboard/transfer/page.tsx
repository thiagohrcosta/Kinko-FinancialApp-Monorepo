import type { Metadata } from "next";
import { Suspense } from "react";
import { AccountCard } from "../_components/account-card";
import { CardSkeleton } from "../_components/skeleton";
import { TransferForm } from "./transfer-form";

export const metadata: Metadata = { title: "Transfer · Kinko" };

export default function TransferPage() {
  return (
    <div className="mx-auto grid max-w-4xl gap-6 md:grid-cols-5">
      <div className="min-w-0 space-y-4 md:col-span-2">
        <h1 className="text-xl font-bold">Transfer</h1>
        <p className="text-sm text-muted">
          Send money to another Kinko account using its account number. Both legs of the transfer are recorded in
          the ledger under the same transaction ID.
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
