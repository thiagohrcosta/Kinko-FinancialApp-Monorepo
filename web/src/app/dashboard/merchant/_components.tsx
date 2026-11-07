import Link from "next/link";

export function MerchantTabs({ active }: { active: "charges" | "developers" }) {
  const tabs = [
    { key: "charges", href: "/dashboard/merchant", label: "Charges" },
    { key: "developers", href: "/dashboard/merchant/developers", label: "API keys & webhooks" },
  ] as const;
  return (
    <div className="flex gap-2">
      {tabs.map((t) => (
        <Link
          key={t.key}
          href={t.href}
          aria-current={t.key === active ? "page" : undefined}
          className={`rounded-full px-3 py-1 text-sm font-semibold ${t.key === active ? "bg-ink text-white" : "bg-chip text-muted hover:text-ink"}`}
        >
          {t.label}
        </Link>
      ))}
    </div>
  );
}

export function BusinessOnly() {
  return (
    <div className="card mx-auto max-w-xl p-6 text-sm">
      <p className="font-bold text-kinko">Business account required</p>
      <p className="mt-1 text-muted">
        The merchant area (charges, API keys and webhooks) is available to business accounts. Create a business account
        to accept payments with Kinko.
      </p>
    </div>
  );
}

const STATUS_STYLES: Record<string, string> = {
  pending: "bg-amber-100 text-amber-800",
  paid: "bg-credit/12 text-credit",
  succeeded: "bg-credit/12 text-credit",
  canceled: "bg-chip text-muted",
  expired: "bg-chip text-muted",
  failed: "bg-[#FFF5F5] text-kinko",
};

export function StatusBadge({ status }: { status: string }) {
  return (
    <span className={`inline-block rounded-full px-2 py-0.5 text-[11px] font-semibold capitalize ${STATUS_STYLES[status] ?? "bg-chip"}`}>
      {status}
    </span>
  );
}
