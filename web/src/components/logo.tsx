export function Logo({ compact = false }: { compact?: boolean }) {
  return (
    <span className="inline-flex items-center gap-2">
      <span className="grid size-9 place-items-center rounded-xl bg-emerald-600 text-lg font-bold text-white shadow-sm">
        K
      </span>
      {!compact && <span className="text-lg font-semibold tracking-tight text-slate-900">Kinko</span>}
    </span>
  );
}
