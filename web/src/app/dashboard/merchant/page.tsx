import type { Metadata } from "next";
import { Suspense } from "react";
import { ApiError } from "@/lib/api";
import { formatCurrency, formatDate, formatTime } from "@/lib/format";
import { listCharges, type Charge } from "@/lib/kinko";
import { formatPaymentCode } from "@/lib/payment-code";
import { CardSkeleton } from "../_components/skeleton";
import { BusinessOnly, MerchantTabs, StatusBadge } from "./_components";
import { cancelChargeAction } from "./actions";
import { ChargeForm } from "./charge-form";

export const metadata: Metadata = { title: "Charges · Kinko" };

function ChargeRow({ charge }: { charge: Charge }) {
  return (
    <li className="flex flex-wrap items-center justify-between gap-3 py-3">
      <div className="min-w-0">
        <p className="truncate text-sm font-semibold">{charge.description}</p>
        <p className="text-xs text-subtle">
          {formatDate(charge.created_at)} · {formatTime(charge.created_at)}
          {charge.external_reference && <> · ref {charge.external_reference}</>}
          {charge.payer && <> · paid by {charge.payer.name}</>}
        </p>
        <p className="mt-0.5 break-all font-mono text-[11px] text-subtle">{formatPaymentCode(charge.code)}</p>
      </div>
      <div className="flex items-center gap-3">
        <StatusBadge status={charge.status} />
        <span className="text-sm font-bold tabular-nums">{formatCurrency(charge.amount_cents / 100, charge.currency)}</span>
        {charge.status === "pending" && (
          <form action={cancelChargeAction.bind(null, charge.id)}>
            <button type="submit" className="btn-ghost text-xs">
              Cancel
            </button>
          </form>
        )}
      </div>
    </li>
  );
}

async function Charges() {
  let charges: Charge[];
  try {
    charges = (await listCharges()).data;
  } catch (err) {
    if (err instanceof ApiError && err.status === 403) return <BusinessOnly />;
    throw err;
  }

  return (
    <div className="grid gap-6 md:grid-cols-5">
      <div className="min-w-0 md:col-span-2">
        <ChargeForm />
      </div>
      <div className="card min-w-0 p-5 md:col-span-3">
        <h2 className="font-bold">Recent charges</h2>
        {charges.length === 0 ? (
          <p className="mt-3 text-sm text-muted">No charges yet. Create one, or use the API with a Kinko API key.</p>
        ) : (
          <ul className="mt-2 divide-y divide-black/5">
            {charges.map((c) => (
              <ChargeRow key={c.id} charge={c} />
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}

export default function MerchantPage() {
  return (
    <div className="mx-auto max-w-5xl space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-xl font-bold">Merchant</h1>
        <MerchantTabs active="charges" />
      </div>
      <Suspense fallback={<CardSkeleton className="h-96" />}>
        <Charges />
      </Suspense>
    </div>
  );
}
