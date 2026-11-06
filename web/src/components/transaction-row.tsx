import type { Transaction } from "@/lib/kinko";
import { formatCurrency } from "@/lib/format";
import { ArrowDownward, ArrowUpward } from "./icons";

/** Linha do extrato no padrão do app: círculo com a cor a 12%, verde crédito / vermelho débito. */
export function TransactionRow({ tx, meta }: { tx: Transaction; meta: string }) {
  const isCredit = tx.entry_type === "credit";
  const Icon = isCredit ? ArrowDownward : ArrowUpward;
  return (
    <li className="flex items-center gap-3 py-3">
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
          {meta}
          {tx.counterparty_sector ? ` · ${tx.counterparty_sector}` : ""}
        </p>
      </div>
      <span className={`shrink-0 text-[15px] font-bold tabular-nums ${isCredit ? "text-credit" : "text-debit"}`}>
        {isCredit ? "+" : "−"}
        {formatCurrency(tx.amount_cents / 100, tx.currency || "USD")}
      </span>
    </li>
  );
}
