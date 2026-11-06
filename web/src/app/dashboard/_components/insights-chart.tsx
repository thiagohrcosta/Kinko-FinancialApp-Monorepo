import Link from "next/link";
import { getInsights, type InsightRange } from "@/lib/kinko";
import { formatCurrency, formatDate } from "@/lib/format";

const RANGES: InsightRange[] = [7, 14, 30];

function parseRange(value: string | string[] | undefined): InsightRange {
  const n = Number(Array.isArray(value) ? value[0] : value);
  return (RANGES as number[]).includes(n) ? (n as InsightRange) : 7;
}

export async function InsightsChart({
  searchParams,
}: {
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}) {
  const range = parseRange((await searchParams).range);
  const data = await getInsights(range);

  const max = Math.max(1, ...data.income, ...data.expenses);
  const totalIn = data.income.reduce((a, b) => a + b, 0);
  const totalOut = data.expenses.reduce((a, b) => a + b, 0);

  return (
    <div className="card p-6">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h2 className="font-semibold">Entradas x Saídas</h2>
          <p className="text-xs text-slate-500">
            <span className="text-emerald-600">{formatCurrency(totalIn)}</span> em entradas ·{" "}
            <span className="text-red-600">{formatCurrency(totalOut)}</span> em saídas
          </p>
        </div>
        <nav className="flex rounded-lg bg-slate-100 p-1 text-xs font-medium" aria-label="Período">
          {RANGES.map((r) => (
            <Link
              key={r}
              href={`/dashboard?range=${r}`}
              scroll={false}
              className={`rounded-md px-3 py-1 ${
                r === range ? "bg-white text-slate-900 shadow-sm" : "text-slate-500 hover:text-slate-900"
              }`}
              aria-current={r === range ? "page" : undefined}
            >
              {r}D
            </Link>
          ))}
        </nav>
      </div>

      <div className="mt-6 flex h-48 items-end gap-1" role="img" aria-label={`Gráfico dos últimos ${range} dias`}>
        {data.dates.map((date, i) => (
          <div key={date} className="group relative flex h-full flex-1 items-end justify-center gap-0.5">
            <div
              className="w-full max-w-3 rounded-t bg-emerald-500"
              style={{ height: `${(data.income[i] / max) * 100}%` }}
            />
            <div
              className="w-full max-w-3 rounded-t bg-red-400"
              style={{ height: `${(data.expenses[i] / max) * 100}%` }}
            />
            <div className="pointer-events-none absolute bottom-full z-10 mb-2 hidden whitespace-nowrap rounded-md bg-slate-900 px-2 py-1 text-xs text-white group-hover:block">
              {formatDate(date)}: +{formatCurrency(data.income[i])} / −{formatCurrency(data.expenses[i])}
            </div>
          </div>
        ))}
      </div>
      <div className="mt-2 flex justify-between text-xs text-slate-400">
        <span>{data.dates[0] && formatDate(data.dates[0])}</span>
        <span>{data.dates.at(-1) && formatDate(data.dates.at(-1)!)}</span>
      </div>

      <div className="mt-4 flex gap-4 text-xs text-slate-500">
        <span className="flex items-center gap-1.5">
          <span className="size-2.5 rounded-sm bg-emerald-500" /> Entradas
        </span>
        <span className="flex items-center gap-1.5">
          <span className="size-2.5 rounded-sm bg-red-400" /> Saídas
        </span>
      </div>
    </div>
  );
}
