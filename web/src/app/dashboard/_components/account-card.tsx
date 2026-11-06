import { getPrimaryAccount } from "@/lib/kinko";
import { formatCurrency } from "@/lib/format";
import { AccountBalanceWallet } from "@/components/icons";
import { CopyButton } from "@/components/copy-button";

/** Saldo + número da conta (UUID) para receber transferências. */
export async function AccountCard() {
  const account = await getPrimaryAccount();
  if (!account) return null;

  return (
    <div className="rounded-xl bg-gradient-to-r from-kinko-light to-kinko-dark p-5 text-white shadow-[0_2px_6px_rgba(0,0,0,0.08)]">
      <div className="flex items-center gap-2">
        <AccountBalanceWallet className="size-6" />
        <p className="text-sm font-semibold">Saldo disponível</p>
      </div>
      <p className="mt-2 text-[28px] font-bold tabular-nums">{formatCurrency(account.balance / 100)}</p>
      <div className="mt-3 flex items-center gap-2 rounded-lg bg-black/15 px-3 py-2">
        <div className="min-w-0 flex-1">
          <p className="text-[10px] font-semibold tracking-wide text-white/75 uppercase">Sua conta</p>
          <p className="truncate font-mono text-xs">{account.uuid}</p>
        </div>
        <CopyButton value={account.uuid} />
      </div>
    </div>
  );
}
