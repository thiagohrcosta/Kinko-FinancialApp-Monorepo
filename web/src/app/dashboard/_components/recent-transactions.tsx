import { getTransactions } from "@/lib/kinko";
import { formatCurrency, formatDate } from "@/lib/format";
import { ArrowDownward, ArrowUpward, ReceiptLong } from "@/components/icons";

export async function RecentTransactions() {
  const transactions = (await getTransactions()).slice(0, 8);

  return (
    <div className="card p-5">
      <h2 className="text-lg font-bold">Movimentações do mês</h2>

      {transactions.length === 0 ? (
        <div className="flex flex-col items-center gap-2 py-10 text-subtle">
          <ReceiptLong className="size-12 text-[#ccc]" />
          <p className="text-sm">Nenhuma movimentação neste mês.</p>
        </div>
      ) : (
        <ul className="mt-3 divide-y divide-[#eee]">
          {transactions.map((tx) => {
            const isCredit = tx.entry_type === "credit";
            const Icon = isCredit ? ArrowDownward : ArrowUpward;
            return (
              <li key={tx.id} className="flex items-center gap-3 py-3">
                {/* Mesmo padrão do extrato do app: círculo com a cor a 12% */}
                <span
                  className={`grid size-11 shrink-0 place-items-center rounded-full ${
                    isCredit ? "bg-credit/12 text-credit" : "bg-debit/12 text-debit"
                  }`}
                >
                  <Icon className="size-5" />
                </span>
                <div className="min-w-0 flex-1">
                  <p className="truncate text-[15px] font-semibold text-black">{tx.description}</p>
                  <p className="text-xs text-subtle">
                    {formatDate(tx.created_at)}
                    {tx.counterparty_sector ? ` · ${tx.counterparty_sector}` : ""}
                  </p>
                </div>
                <span className={`shrink-0 text-[15px] font-bold tabular-nums ${isCredit ? "text-credit" : "text-debit"}`}>
                  {isCredit ? "+" : "−"}
                  {formatCurrency(tx.amount_cents / 100, tx.currency || "USD")}
                </span>
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}
