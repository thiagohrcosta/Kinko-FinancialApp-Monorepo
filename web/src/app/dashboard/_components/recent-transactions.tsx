import Link from "next/link";
import { getTransactions } from "@/lib/kinko";
import { formatDate } from "@/lib/format";
import { ReceiptLong } from "@/components/icons";
import { TransactionRow } from "@/components/transaction-row";

export async function RecentTransactions() {
  const transactions = (await getTransactions()).slice(0, 6);

  return (
    <div className="card p-5">
      <h2 className="text-lg font-bold">This month</h2>

      {transactions.length === 0 ? (
        <div className="flex flex-col items-center gap-2 py-10 text-subtle">
          <ReceiptLong className="size-12 text-[#ccc]" />
          <p className="text-sm">No transactions this month.</p>
        </div>
      ) : (
        <ul className="mt-3 divide-y divide-[#eee]">
          {transactions.map((tx) => (
            <TransactionRow key={tx.id} tx={tx} meta={formatDate(tx.created_at)} />
          ))}
        </ul>
      )}

      {/* Same "View Financial Statement" button as the app */}
      <Link
        href="/dashboard/statement"
        className="mt-4 flex items-center gap-2 rounded-xl bg-kinko px-4 py-3.5 text-white transition hover:bg-kinko-dark"
      >
        <ReceiptLong className="size-5" />
        <span className="flex-1 text-center font-semibold">View Financial Statement</span>
        <span aria-hidden className="text-lg">›</span>
      </Link>
    </div>
  );
}
