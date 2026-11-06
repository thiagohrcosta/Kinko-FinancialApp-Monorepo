import type { Metadata } from "next";
import { Suspense } from "react";
import { CardSkeleton } from "../_components/skeleton";
import { DepositFlow, DepositSuccess } from "./deposit-flow";

export const metadata: Metadata = { title: "Deposit · Kinko" };

async function DepositContent({ searchParams }: { searchParams: PageProps<"/dashboard/deposit">["searchParams"] }) {
  const params = await searchParams;

  // Return from a Stripe redirect (e.g. 3D Secure)
  if (params.redirect_status === "succeeded") return <DepositSuccess />;

  // Read at request time (after the await above), not at build time.
  const publishableKey = process.env.STRIPE_PUBLISHABLE_KEY;
  if (!publishableKey) {
    return (
      <div className="card p-5 text-sm">
        <p className="font-bold text-kinko">Card deposits are not configured</p>
        <p className="mt-1 text-muted">
          Set <code className="rounded bg-chip px-1">STRIPE_PUBLISHABLE_KEY</code> in the frontend environment (same
          Stripe account as the backend&apos;s <code className="rounded bg-chip px-1">STRIPE_SECRET_KEY</code>).
        </p>
      </div>
    );
  }

  return (
    <>
      {params.redirect_status === "failed" && (
        <p role="alert" className="mb-4 rounded-xl bg-[#FFF5F5] px-3 py-2 text-sm text-kinko">
          The payment was not approved. Please try again.
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
        <h1 className="text-xl font-bold">Deposit</h1>
        <p className="text-sm text-muted">
          Add funds with a card through Stripe. Kinko only credits the ledger after Stripe confirms the payment via
          webhook — never from the browser.
        </p>
        <p className="text-xs text-subtle">
          In test mode, use card <span className="font-mono">4242 4242 4242 4242</span> with any future date and any
          CVC.
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
