import type { Metadata } from "next";
import { Suspense } from "react";
import { getSessionUser } from "@/lib/session";
import { BalanceSummary } from "./_components/balance-summary";
import { InsightsChart } from "./_components/insights-chart";
import { RecentTransactions } from "./_components/recent-transactions";
import { CardSkeleton } from "./_components/skeleton";

export const metadata: Metadata = { title: "Dashboard · Kinko" };

async function Welcome() {
  const user = await getSessionUser();
  return <h1 className="text-xl font-bold">Bem-vindo de volta, {user?.fullName ?? "usuário"}</h1>;
}

export default function DashboardPage({ searchParams }: PageProps<"/dashboard">) {
  return (
    <div className="space-y-6">
      <Suspense fallback={<div className="h-7 w-64 animate-pulse rounded bg-chip" />}>
        <Welcome />
      </Suspense>

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
        <section className="min-w-0 lg:col-span-3">
          <Suspense fallback={<CardSkeleton className="h-80" />}>
            <InsightsChart searchParams={searchParams} />
          </Suspense>
        </section>
        <section className="min-w-0 lg:col-span-2">
          <Suspense fallback={<CardSkeleton className="h-80" />}>
            <RecentTransactions />
          </Suspense>
        </section>
      </div>
    </div>
  );
}
