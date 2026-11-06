"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const LINKS = [
  { href: "/dashboard", label: "Visão geral" },
  { href: "/dashboard/statement", label: "Extrato" },
  { href: "/dashboard/transfer", label: "Transferir" },
  { href: "/dashboard/deposit", label: "Depositar" },
] as const;

export function DashboardNav() {
  const pathname = usePathname();
  return (
    <nav aria-label="Principal" className="-mb-px flex gap-1 overflow-x-auto">
      {LINKS.map(({ href, label }) => {
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
