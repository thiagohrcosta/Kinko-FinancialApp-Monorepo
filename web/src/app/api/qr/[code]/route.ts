import { API_BASE_URL } from "@/lib/api";
import { normalizePaymentCode } from "@/lib/payment-code";

// Rails is only reachable server-side (compose network), so the browser gets
// the QR SVG through here. The QR only encodes the code, which is not secret.
export async function GET(_req: Request, ctx: RouteContext<"/api/qr/[code]">) {
  const code = normalizePaymentCode((await ctx.params).code);
  if (!code) return new Response("Invalid payment code", { status: 422 });

  const res = await fetch(`${API_BASE_URL}/api/v1/payment_requests/${code}/qr`, { cache: "no-store" });
  if (!res.ok) return new Response("QR unavailable", { status: res.status });

  return new Response(await res.text(), {
    headers: { "Content-Type": "image/svg+xml", "Cache-Control": "public, max-age=86400" },
  });
}
