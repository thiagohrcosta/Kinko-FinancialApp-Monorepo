import { getBalance } from "@/lib/kinko";
import { formatCurrency } from "@/lib/format";
import { AccountBalanceWallet, ArrowDownward, ArrowUpward } from "@/components/icons";
import Link from "next/link";

export async function BalanceSummary() {
  const { balance, income, expenses } = await getBalance();

  return (
    <div className="grid gap-4 md:grid-cols-3">
      {/* Balance on the brand gradient (same as the app's login button) */}
      <div className="rounded-xl bg-gradient-to-r from-kinko-light to-kinko-dark p-5 text-white shadow-[0_2px_6px_rgba(0,0,0,0.08)]">
        <div className="flex items-center gap-2">
          <AccountBalanceWallet className="size-6" />
          <p className="text-sm font-semibold">Balance</p>
        </div>
        <p className="mt-3 text-[28px] font-bold tabular-nums">{formatCurrency(Number(balance))}</p>
        <div className="mt-3 flex gap-2">
          <Link href="/dashboard/deposit" className="rounded-full bg-white px-3 py-1 text-xs font-semibold text-kinko hover:bg-white/90">
            Deposit
          </Link>
          <Link href="/dashboard/transfer" className="rounded-full bg-white/20 px-3 py-1 text-xs font-semibold text-white hover:bg-white/30">
            Transfer
          </Link>
        </div>
      </div>

      {/* Same pattern as the app's BalanceCard */}
      <div className="card p-5">
        <div className="flex items-center gap-2">
          <ArrowDownward className="size-6 text-credit" />
          <p className="text-sm font-semibold">Income</p>
        </div>
        <p className="mt-3 text-[22px] font-bold tabular-nums">{formatCurrency(income)}</p>
        <p className="text-xs text-subtle">Last 30 days</p>
      </div>

      <div className="card p-5">
        <div className="flex items-center gap-2">
          <ArrowUpward className="size-6 text-debit" />
          <p className="text-sm font-semibold">Expenses</p>
        </div>
        <p className="mt-3 text-[22px] font-bold tabular-nums">{formatCurrency(expenses)}</p>
        <p className="text-xs text-subtle">Last 30 days</p>
      </div>
    </div>
  );
}
