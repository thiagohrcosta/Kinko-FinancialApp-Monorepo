import { getTransactions } from "@/lib/kinko";
import { formatCurrency, formatDate } from "@/lib/format";

export async function RecentTransactions() {
  const transactions = (await getTransactions()).slice(0, 8);

  return (
    <div className="card p-6">
      <h2 className="font-semibold">Movimentações do mês</h2>

      {transactions.length === 0 ? (
        <p className="mt-6 text-center text-sm text-slate-500">Nenhuma movimentação neste mês.</p>
      ) : (
        <ul className="mt-4 divide-y divide-slate-100">
          {transactions.map((tx) => {
            const isCredit = tx.entry_type === "credit";
            const amount = tx.amount_cents / 100;
            return (
              <li key={tx.id} className="flex items-center justify-between gap-3 py-3">
                <div className="min-w-0">
                  <p className="truncate text-sm font-medium text-slate-900">{tx.description}</p>
                  <p className="text-xs text-slate-500">
                    {formatDate(tx.created_at)}
                    {tx.counterparty_sector ? ` · ${tx.counterparty_sector}` : ""}
                  </p>
                </div>
                <span
                  className={`shrink-0 text-sm font-semibold tabular-nums ${
                    isCredit ? "text-emerald-600" : "text-slate-900"
                  }`}
                >
                  {isCredit ? "+" : "−"}
                  {formatCurrency(amount, tx.currency || "USD")}
                </span>
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}
