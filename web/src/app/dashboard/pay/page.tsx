import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";
import { ApiError } from "@/lib/api";
import { formatCurrency } from "@/lib/format";
import { getPaymentPreview, type PaymentPreview } from "@/lib/kinko";
import { formatPaymentCode, normalizePaymentCode } from "@/lib/payment-code";
import { CardSkeleton } from "../_components/skeleton";
import { PayConfirm } from "./pay-confirm";

export const metadata: Metadata = { title: "Pay · Kinko" };

const DATE_TIME = new Intl.DateTimeFormat("en-US", { dateStyle: "medium", timeStyle: "short", timeZone: "UTC" });

function CodeForm({ defaultValue, error }: { defaultValue?: string; error?: string }) {
  // GET form: the code ends up in the URL (?code=…), so a link or QR can open this screen directly.
  return (
    <form method="get" className="card space-y-4 p-5">
      <div>
        <label htmlFor="code" className="field-label">
          Payment code
        </label>
        <textarea
          id="code"
          name="code"
          required
          rows={2}
          defaultValue={defaultValue}
          placeholder="KNK1 XXXX XXXX XXXX XXXX XXXX XXXX"
          autoComplete="off"
          spellCheck={false}
          className="field resize-none font-mono uppercase"
        />
        <p className="mt-1 text-xs text-subtle">Paste the code the merchant sent you. Spaces and dashes are ignored.</p>
      </div>
      {error && (
        <p role="alert" className="rounded-xl bg-[#FFF5F5] px-3 py-2 text-sm text-kinko">
          {error}
        </p>
      )}
      <button type="submit" className="btn-kinko w-full">
        Continue
      </button>
    </form>
  );
}

function Row({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className="flex items-start justify-between gap-4 py-2 text-sm">
      <dt className="text-muted">{label}</dt>
      <dd className="min-w-0 text-right font-medium break-all">{children}</dd>
    </div>
  );
}

function blocker(p: PaymentPreview): string | null {
  if (p.payer.already_paid_by_you) return "You already paid this charge.";
  if (p.status === "paid") return "This charge has already been paid.";
  if (p.status === "canceled") return "The merchant canceled this charge.";
  if (p.status === "expired") return "This charge has expired. Ask the merchant for a new code.";
  if (p.payer.is_merchant) return "This is your own charge.";
  if (!p.payer.sufficient_funds) return "You don't have enough balance to pay this charge.";
  return null;
}

async function Preview({ code }: { code: string }) {
  let preview: PaymentPreview;
  try {
    preview = await getPaymentPreview(code);
  } catch (err) {
    if (err instanceof ApiError && (err.status === 404 || err.status === 422)) {
      const error = err.status === 404 ? "We couldn't find a charge for this code." : "This payment code is not valid.";
      return <CodeForm defaultValue={formatPaymentCode(code)} error={error} />;
    }
    throw err;
  }

  const reason = blocker(preview);
  const amount = formatCurrency(preview.amount_cents / 100, preview.currency);

  return (
    <div className="card space-y-4 p-5">
      <div className="text-center">
        <p className="text-sm text-muted">You are paying</p>
        <p className="mt-1 text-3xl font-bold tabular-nums">{amount}</p>
        <p className="mt-1 text-sm font-semibold">{preview.merchant.name}</p>
        {preview.merchant.sector && <p className="text-xs capitalize text-subtle">{preview.merchant.sector}</p>}
      </div>
      <dl className="divide-y divide-black/5 border-y border-black/5">
        <Row label="Description">{preview.description}</Row>
        <Row label="Payee account">
          <span className="font-mono text-xs">{preview.merchant.account_uuid}</span>
        </Row>
        <Row label="Debited from">
          <span className="font-mono text-xs">{preview.payer.account_uuid}</span>
        </Row>
        <Row label="Your balance">{formatCurrency(preview.payer.balance_cents / 100, preview.currency)}</Row>
        <Row label="Expires">{DATE_TIME.format(new Date(preview.expires_at))} UTC</Row>
        <Row label="Code">
          <span className="font-mono text-xs">{formatPaymentCode(preview.code)}</span>
        </Row>
      </dl>
      {reason && (
        <p role="status" className="rounded-xl bg-chip px-3 py-2 text-sm text-muted">
          {reason}
        </p>
      )}
      <PayConfirm code={preview.code} disabled={reason !== null} label={`Pay ${amount}`} />
      <Link href="/dashboard/pay" className="btn-ghost block text-center">
        Use a different code
      </Link>
    </div>
  );
}

async function PayContent({ searchParams }: { searchParams: PageProps<"/dashboard/pay">["searchParams"] }) {
  const raw = (await searchParams).code;
  const input = typeof raw === "string" ? raw : "";
  const code = input ? normalizePaymentCode(input) : null;

  if (!code) return <CodeForm defaultValue={input} error={input ? "This payment code is not valid." : undefined} />;
  return <Preview code={code} />;
}

export default function PayPage({ searchParams }: PageProps<"/dashboard/pay">) {
  return (
    <div className="mx-auto grid max-w-4xl gap-6 md:grid-cols-5">
      <div className="min-w-0 space-y-4 md:col-span-2">
        <h1 className="text-xl font-bold">Pay</h1>
        <p className="text-sm text-muted">
          Pay a merchant with your Kinko balance. Paste the payment code (or scan its QR code), check who gets paid and
          how much, then confirm.
        </p>
        <p className="text-xs text-subtle">
          The code only points to the charge stored at Kinko: the amount and the payee always come from the server, so
          an edited code can&apos;t change them.
        </p>
      </div>
      <div className="min-w-0 md:col-span-3 md:pt-11">
        <Suspense fallback={<CardSkeleton className="h-96" />}>
          <PayContent searchParams={searchParams} />
        </Suspense>
      </div>
    </div>
  );
}
