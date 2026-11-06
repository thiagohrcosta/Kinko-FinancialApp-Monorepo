import { getBalance } from "@/lib/kinko";
import { formatCurrency } from "@/lib/format";

export async function BalanceSummary() {
  const { balance, income, expenses } = await getBalance();
  const total = Number(balance);

  return (
    <div className="grid gap-4 md:grid-cols-3">
      <div className="card bg-gradient-to-br from-emerald-600 to-emerald-700 p-6 text-white md:col-span-1">
        <p className="text-sm font-medium text-emerald-100">Saldo disponível</p>
        <p className="mt-2 text-3xl font-semibold tabular-nums">{formatCurrency(total)}</p>
        <p className="mt-1 text-xs text-emerald-100">Calculado a partir do ledger</p>
      </div>
      <Stat label="Entradas (30 dias)" value={income} tone="income" />
      <Stat label="Saídas (30 dias)" value={expenses} tone="expense" />
    </div>
  );
}

function Stat({ label, value, tone }: { label: string; value: number; tone: "income" | "expense" }) {
  const isIncome = tone === "income";
  return (
    <div className="card p-6">
      <div className="flex items-center gap-2">
        <span
          className={`grid size-7 place-items-center rounded-full text-sm ${
            isIncome ? "bg-emerald-50 text-emerald-600" : "bg-red-50 text-red-600"
          }`}
          aria-hidden
        >
          {isIncome ? "↓" : "↑"}
        </span>
        <p className="text-sm font-medium text-slate-600">{label}</p>
      </div>
      <p className="mt-3 text-2xl font-semibold tabular-nums">{formatCurrency(value)}</p>
    </div>
  );
}
