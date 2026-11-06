import Link from "next/link";
import { getInsights, type InsightRange } from "@/lib/kinko";
import { formatCurrency, formatDate } from "@/lib/format";

const RANGES: InsightRange[] = [7, 14, 30];
const W = 600;
const H = 220;
const PAD_X = 8;
const PAD_Y = 16;

function parseRange(value: string | string[] | undefined): InsightRange {
  const n = Number(Array.isArray(value) ? value[0] : value);
  return (RANGES as number[]).includes(n) ? (n as InsightRange) : 7;
}

function compact(value: number) {
  if (value >= 1_000_000) return `$${(value / 1_000_000).toFixed(1)}M`;
  if (value >= 1000) return `$${(value / 1000).toFixed(1)}k`;
  return `$${Math.round(value)}`;
}

/** Smooth Catmull-Rom curve (like d3.curveCatmullRom in the app), converted to Bézier. */
function smoothPath(points: [number, number][]) {
  if (points.length === 0) return "";
  let d = `M${points[0][0]},${points[0][1]}`;
  for (let i = 0; i < points.length - 1; i++) {
    const p0 = points[i - 1] ?? points[i];
    const p1 = points[i];
    const p2 = points[i + 1];
    const p3 = points[i + 2] ?? p2;
    const c1x = p1[0] + (p2[0] - p0[0]) / 6;
    const c1y = Math.min(H - PAD_Y, p1[1] + (p2[1] - p0[1]) / 6);
    const c2x = p2[0] - (p3[0] - p1[0]) / 6;
    const c2y = Math.min(H - PAD_Y, p2[1] - (p3[1] - p1[1]) / 6);
    d += ` C${c1x},${c1y} ${c2x},${c2y} ${p2[0]},${p2[1]}`;
  }
  return d;
}

export async function InsightsChart({
  searchParams,
}: {
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}) {
  const range = parseRange((await searchParams).range);
  const data = await getInsights(range);

  const n = data.dates.length;
  const max = Math.max(1, ...data.income, ...data.expenses) * 1.1;
  const x = (i: number) => PAD_X + (n > 1 ? (i * (W - PAD_X * 2)) / (n - 1) : 0);
  const y = (v: number) => H - PAD_Y - (v / max) * (H - PAD_Y * 2);
  const ticks = [0, 1, 2, 3].map((t) => (max / 3) * t);

  const series = (values: number[]) => {
    const pts = values.map((v, i) => [x(i), y(v)] as [number, number]);
    const line = smoothPath(pts);
    const area = `${line} L${x(n - 1)},${H - PAD_Y} L${x(0)},${H - PAD_Y} Z`;
    return { line, area };
  };
  const income = series(data.income);
  const expenses = series(data.expenses);

  return (
    <div className="card p-5">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h2 className="text-lg font-bold">Insight Dashboard</h2>
        <nav className="flex gap-1.5" aria-label="Range">
          {RANGES.map((r) => (
            <Link
              key={r}
              href={`/dashboard?range=${r}`}
              scroll={false}
              className={`rounded-full px-3 py-1 text-xs font-semibold transition ${
                r === range ? "bg-kinko-accent text-white" : "bg-chip text-[#333] hover:bg-[#e2e2e2]"
              }`}
              aria-current={r === range ? "page" : undefined}
            >
              {r}D
            </Link>
          ))}
        </nav>
      </div>

      <div className="mt-2 flex gap-4 text-sm">
        <span className="text-income">● Income</span>
        <span className="text-expense">● Expenses</span>
      </div>

      <div className="mt-4 flex gap-2">
        {/* Y axis */}
        <div className="flex h-[220px] flex-col-reverse justify-between py-3 text-right text-[10px] text-muted">
          {ticks.map((t) => (
            <span key={t}>{compact(t)}</span>
          ))}
        </div>

        <div className="relative h-[220px] flex-1">
          <svg viewBox={`0 0 ${W} ${H}`} preserveAspectRatio="none" className="absolute inset-0 size-full" aria-hidden>
            {ticks.map((t) => (
              <line key={t} x1={0} x2={W} y1={y(t)} y2={y(t)} stroke="rgba(0,0,0,0.06)" vectorEffect="non-scaling-stroke" />
            ))}
            <path d={income.area} fill="rgba(31,182,69,0.12)" />
            <path d={expenses.area} fill="rgba(242,1,1,0.12)" />
            <path d={income.line} fill="none" stroke="#57A773" strokeWidth={3} vectorEffect="non-scaling-stroke" strokeLinecap="round" />
            <path d={expenses.line} fill="none" stroke="#FF3B30" strokeWidth={3} vectorEffect="non-scaling-stroke" strokeLinecap="round" />
          </svg>

          {/* Hover columns with a per-day tooltip */}
          <div className="absolute inset-0 flex" role="list" aria-label={`Income and expenses for the last ${range} days`}>
            {data.dates.map((date, i) => (
              <div key={date} role="listitem" className="group relative flex-1">
                <div className="absolute inset-y-0 left-1/2 hidden w-px bg-black/20 group-hover:block" />
                <div
                  className={`pointer-events-none absolute top-0 z-10 hidden min-w-32 rounded-lg bg-white p-2 text-xs shadow-[0_2px_8px_rgba(0,0,0,0.15)] group-hover:block ${
                    i > n / 2 ? "right-1/2 mr-1" : "left-1/2 ml-1"
                  }`}
                >
                  <p className="font-semibold text-ink">{formatDate(date)}</p>
                  <p className="text-income">Income: {formatCurrency(data.income[i])}</p>
                  <p className="text-expense">Expenses: {formatCurrency(data.expenses[i])}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      <div className="mt-2 flex justify-between pl-10 text-[10px] text-muted">
        <span>{data.dates[0] && formatDate(data.dates[0])}</span>
        <span>{data.dates.at(-1) && formatDate(data.dates.at(-1)!)}</span>
      </div>
    </div>
  );
}
