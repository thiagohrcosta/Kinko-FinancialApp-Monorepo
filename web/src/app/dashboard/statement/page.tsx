import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";
import { getTransactions, type Transaction } from "@/lib/kinko";
import { dayKey, formatCurrency, formatDayHeading, formatTime, monthKey, monthLabel, shiftMonth } from "@/lib/format";
import { ReceiptLong } from "@/components/icons";
import { TransactionRow } from "@/components/transaction-row";
import { CardSkeleton } from "../_components/skeleton";

export const metadata: Metadata = { title: "Statement · Kinko" };

function parseMonth(value: string | string[] | undefined, current: string) {
  const v = Array.isArray(value) ? value[0] : value;
  if (!v || !/^\d{4}-(0[1-9]|1[0-2])$/.test(v) || v > current) return current;
  return v;
}

function groupByDay(transactions: Transaction[]) {
  const groups = new Map<string, Transaction[]>();
  for (const tx of transactions) {
    const key = dayKey(tx.created_at);
    groups.set(key, [...(groups.get(key) ?? []), tx]);
  }
  return [...groups.entries()].map(([day, items]) => ({ day, label: formatDayHeading(day), items }));
}

async function Statement({ searchParams }: { searchParams: PageProps<"/dashboard/statement">["searchParams"] }) {
  const params = await searchParams; // dynamic access before reading the clock
  const current = monthKey(new Date());
  const month = parseMonth(params.month, current);
  const transactions = await getTransactions(month);

  const credits = transactions.filter((t) => t.entry_type === "credit").reduce((s, t) => s + t.amount_cents, 0) / 100;
  const debits = transactions.filter((t) => t.entry_type === "debit").reduce((s, t) => s + t.amount_cents, 0) / 100;
  const isCurrent = month === current;

  return (
    <>
      {/* Month navigation, as in the app statement */}
      <div className="card flex items-center justify-between px-2 py-2">
        <Link
          href={`/dashboard/statement?month=${shiftMonth(month, -1)}`}
          className="grid size-10 place-items-center rounded-full text-2xl text-[#666] hover:bg-chip"
          aria-label="Previous month"
        >
          ‹
        </Link>
        <p className="font-bold text-kinko">{monthLabel(month)}</p>
        {isCurrent ? (
          <span className="grid size-10 place-items-center text-2xl text-[#ccc]" aria-hidden>
            ›
          </span>
        ) : (
          <Link
            href={`/dashboard/statement?month=${shiftMonth(month, 1)}`}
            className="grid size-10 place-items-center rounded-full text-2xl text-[#666] hover:bg-chip"
            aria-label="Next month"
          >
            ›
          </Link>
        )}
      </div>

      <div className="grid gap-4 sm:grid-cols-3">
        <div className="card p-4">
          <p className="text-xs font-semibold text-subtle">Income</p>
          <p className="mt-1 text-xl font-bold text-credit tabular-nums">{formatCurrency(credits)}</p>
        </div>
        <div className="card p-4">
          <p className="text-xs font-semibold text-subtle">Expenses</p>
          <p className="mt-1 text-xl font-bold text-debit tabular-nums">{formatCurrency(debits)}</p>
        </div>
        <div className="card p-4">
          <p className="text-xs font-semibold text-subtle">Net for the month</p>
          <p className="mt-1 text-xl font-bold tabular-nums">{formatCurrency(credits - debits)}</p>
        </div>
      </div>

      <p className="text-right text-[11px] text-subtle">Times shown in UTC</p>

      {transactions.length === 0 ? (
        <div className="card flex flex-col items-center gap-2 py-14 text-subtle">
          <ReceiptLong className="size-12 text-[#ccc]" />
          <p className="text-sm">No transactions in {monthLabel(month)}.</p>
        </div>
      ) : (
        <div className="space-y-4">
          {groupByDay(transactions).map((group) => (
            <section key={group.day} className="card px-5 py-2">
              <h2 className="pt-3 text-xs font-semibold tracking-wide text-subtle uppercase">{group.label}</h2>
              <ul className="divide-y divide-[#eee]">
                {group.items.map((tx) => (
                  <TransactionRow key={tx.id} tx={tx} meta={formatTime(tx.created_at)} />
                ))}
              </ul>
            </section>
          ))}
        </div>
      )}
    </>
  );
}

export default function StatementPage({ searchParams }: PageProps<"/dashboard/statement">) {
  return (
    <div className="mx-auto max-w-3xl space-y-4">
      <h1 className="text-xl font-bold">Financial Statement</h1>
      <Suspense
        fallback={
          <>
            <CardSkeleton className="h-14" />
            <CardSkeleton className="h-64" />
          </>
        }
      >
        <Statement searchParams={searchParams} />
      </Suspense>
    </div>
  );
}
