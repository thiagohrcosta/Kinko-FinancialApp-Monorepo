import type { Metadata } from "next";
import { Suspense } from "react";
import { BalanceSummary } from "./_components/balance-summary";
import { InsightsChart } from "./_components/insights-chart";
import { RecentTransactions } from "./_components/recent-transactions";
import { CardSkeleton } from "./_components/skeleton";

export const metadata: Metadata = { title: "Dashboard · Kinko" };

export default function DashboardPage({ searchParams }: PageProps<"/dashboard">) {
  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight">Visão geral</h1>
        <p className="text-sm text-slate-500">Saldo derivado do ledger e movimentações dos últimos 30 dias.</p>
      </div>

      <Suspense
        fallback={
          <div className="grid gap-4 md:grid-cols-3">
            <CardSkeleton className="h-32" />
            <CardSkeleton className="h-32" />
            <CardSkeleton className="h-32" />
          </div>
        }
      >
        <BalanceSummary />
      </Suspense>

      <div className="grid gap-6 lg:grid-cols-5">
        <section className="lg:col-span-3">
          <Suspense fallback={<CardSkeleton className="h-80" />}>
            <InsightsChart searchParams={searchParams} />
          </Suspense>
        </section>
        <section className="lg:col-span-2">
          <Suspense fallback={<CardSkeleton className="h-80" />}>
            <RecentTransactions />
          </Suspense>
        </section>
      </div>
    </div>
  );
}
