import type { Metadata } from "next";
import { Suspense } from "react";
import { ApiError } from "@/lib/api";
import { formatDate, formatTime } from "@/lib/format";
import { getWebhookEndpoint, listApiKeys, type ApiKey } from "@/lib/kinko";
import { CardSkeleton } from "../../_components/skeleton";
import { BusinessOnly, MerchantTabs, StatusBadge } from "../_components";
import { redeliverWebhookAction, revokeApiKeyAction, rotateSecretAction } from "../actions";
import { NewApiKeyForm, WebhookUrlForm } from "./forms";

export const metadata: Metadata = { title: "API keys & webhooks · Kinko" };

function when(iso: string | null) {
  return iso ? `${formatDate(iso)} ${formatTime(iso)}` : "never";
}

function KeyRow({ apiKey }: { apiKey: ApiKey }) {
  return (
    <li className="flex flex-wrap items-center justify-between gap-3 py-3">
      <div className="min-w-0">
        <p className="text-sm font-semibold">{apiKey.name}</p>
        <p className="font-mono text-xs text-subtle">{apiKey.masked_key}</p>
        <p className="text-xs text-subtle">
          Created {when(apiKey.created_at)} · last used {when(apiKey.last_used_at)}
        </p>
      </div>
      {apiKey.revoked_at ? (
        <StatusBadge status="revoked" />
      ) : (
        <form action={revokeApiKeyAction.bind(null, apiKey.id)}>
          <button type="submit" className="btn-ghost text-xs text-kinko">
            Revoke
          </button>
        </form>
      )}
    </li>
  );
}

async function Developers() {
  let keys: ApiKey[];
  let webhook: Awaited<ReturnType<typeof getWebhookEndpoint>>;
  try {
    [keys, webhook] = await Promise.all([listApiKeys(), getWebhookEndpoint()]);
  } catch (err) {
    if (err instanceof ApiError && err.status === 403) return <BusinessOnly />;
    throw err;
  }
  const { endpoint, deliveries } = webhook;

  return (
    <div className="grid gap-6 md:grid-cols-2">
      <section className="card min-w-0 space-y-4 p-5">
        <div>
          <h2 className="font-bold">API keys</h2>
          <p className="mt-1 text-sm text-muted">
            Send <code className="rounded bg-chip px-1">Authorization: Bearer kinko_sk_…</code> from your server to create and
            read charges. Keys can&apos;t manage other keys or webhooks.
          </p>
        </div>
        <NewApiKeyForm />
        {keys.length > 0 && (
          <ul className="divide-y divide-black/5">
            {keys.map((k) => (
              <KeyRow key={k.id} apiKey={k} />
            ))}
          </ul>
        )}
      </section>

      <section className="card min-w-0 space-y-4 p-5">
        <div>
          <h2 className="font-bold">Webhook</h2>
          <p className="mt-1 text-sm text-muted">
            Kinko POSTs <code className="rounded bg-chip px-1">payment_request.paid</code>,{" "}
            <code className="rounded bg-chip px-1">.canceled</code> and <code className="rounded bg-chip px-1">.expired</code>{" "}
            events, signed with the <code className="rounded bg-chip px-1">Kinko-Signature</code> header.
          </p>
        </div>
        <WebhookUrlForm current={endpoint?.url} />
        {endpoint && (
          <div className="space-y-2">
            <p className="field-label">Signing secret</p>
            <p className="select-all break-all rounded-lg bg-chip px-2 py-1 font-mono text-xs">{endpoint.signing_secret}</p>
            {!endpoint.active && <p className="text-xs text-kinko">Delivery is disabled. Save the URL to enable it again.</p>}
            <form action={rotateSecretAction}>
              <button type="submit" className="btn-outline text-xs">
                Rotate secret
              </button>
            </form>
          </div>
        )}
        {deliveries.length > 0 && (
          <div>
            <p className="field-label">Recent deliveries</p>
            <ul className="divide-y divide-black/5">
              {deliveries.map((d) => (
                <li key={d.id} className="flex items-center justify-between gap-3 py-2 text-xs">
                  <div className="min-w-0">
                    <p className="font-mono">{d.event_type}</p>
                    <p className="text-subtle">
                      {when(d.created_at)} · {d.attempts} attempt{d.attempts === 1 ? "" : "s"}
                      {d.last_error && <> · {d.last_error}</>}
                    </p>
                  </div>
                  <div className="flex shrink-0 items-center gap-2">
                    <StatusBadge status={d.status} />
                    {d.status !== "pending" && endpoint?.active && (
                      <form action={redeliverWebhookAction.bind(null, d.id)}>
                        <button type="submit" className="btn-ghost px-2 py-1 text-xs" aria-label={`Resend ${d.event_type}`}>
                          Resend
                        </button>
                      </form>
                    )}
                  </div>
                </li>
              ))}
            </ul>
          </div>
        )}
      </section>
    </div>
  );
}

export default function DevelopersPage() {
  return (
    <div className="mx-auto max-w-5xl space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-xl font-bold">Merchant</h1>
        <MerchantTabs active="developers" />
      </div>
      <Suspense fallback={<CardSkeleton className="h-96" />}>
        <Developers />
      </Suspense>
    </div>
  );
}
