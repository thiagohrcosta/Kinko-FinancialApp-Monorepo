import { getBalance } from "@/lib/kinko";
import { formatCurrency } from "@/lib/format";
import { AccountBalanceWallet, ArrowDownward, ArrowUpward } from "@/components/icons";

export async function BalanceSummary() {
  const { balance, income, expenses } = await getBalance();

  return (
    <div className="grid gap-4 md:grid-cols-3">
      {/* Saldo com o gradiente da marca (mesmo do botão de login do app) */}
      <div className="rounded-xl bg-gradient-to-r from-kinko-light to-kinko-dark p-5 text-white shadow-[0_2px_6px_rgba(0,0,0,0.08)]">
        <div className="flex items-center gap-2">
          <AccountBalanceWallet className="size-6" />
          <p className="text-sm font-semibold">Saldo</p>
        </div>
        <p className="mt-3 text-[28px] font-bold tabular-nums">{formatCurrency(Number(balance))}</p>
        <p className="text-xs text-white/75">Calculado a partir do ledger</p>
      </div>

      {/* Mesmo padrão do BalanceCard do app */}
      <div className="card p-5">
        <div className="flex items-center gap-2">
          <ArrowDownward className="size-6 text-credit" />
          <p className="text-sm font-semibold">Entradas</p>
        </div>
        <p className="mt-3 text-[22px] font-bold tabular-nums">{formatCurrency(income)}</p>
        <p className="text-xs text-subtle">Últimos 30 dias</p>
      </div>

      <div className="card p-5">
        <div className="flex items-center gap-2">
          <ArrowUpward className="size-6 text-debit" />
          <p className="text-sm font-semibold">Saídas</p>
        </div>
        <p className="mt-3 text-[22px] font-bold tabular-nums">{formatCurrency(expenses)}</p>
        <p className="text-xs text-subtle">Últimos 30 dias</p>
      </div>
    </div>
  );
}
