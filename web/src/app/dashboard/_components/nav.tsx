"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const LINKS = [
  { href: "/dashboard", label: "Overview" },
  { href: "/dashboard/statement", label: "Statement" },
  { href: "/dashboard/transfer", label: "Transfer" },
  { href: "/dashboard/deposit", label: "Deposit" },
  { href: "/dashboard/pay", label: "Pay" },
] as const;

const MERCHANT_LINK = { href: "/dashboard/merchant", label: "Merchant" } as const;

export function DashboardNav({ isBusiness = false }: { isBusiness?: boolean }) {
  const pathname = usePathname();
  const links = isBusiness ? [...LINKS, MERCHANT_LINK] : LINKS;
  return (
    <nav aria-label="Main" className="-mb-px flex gap-1 overflow-x-auto">
      {links.map(({ href, label }) => {
        const active = href === "/dashboard" ? pathname === href : pathname.startsWith(href);
        return (
          <Link
            key={href}
            href={href}
            aria-current={active ? "page" : undefined}
            className={`shrink-0 border-b-2 px-3 py-3 text-sm font-semibold transition ${
              active ? "border-kinko text-kinko" : "border-transparent text-muted hover:text-ink"
            }`}
          >
            {label}
          </Link>
        );
      })}
    </nav>
  );
}
