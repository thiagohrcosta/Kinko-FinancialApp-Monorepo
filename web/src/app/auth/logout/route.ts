import { NextResponse, type NextRequest } from "next/server";
import { TOKEN_COOKIE, USER_COOKIE } from "@/lib/session";

/**
 * Usado quando o backend rejeita o token (401) durante a renderização:
 * Server Components não podem alterar cookies, então limpamos aqui.
 */
export function GET(request: NextRequest) {
  const url = new URL("/login", request.url);
  if (request.nextUrl.searchParams.has("expired")) url.searchParams.set("expired", "1");

  const res = NextResponse.redirect(url);
  res.cookies.delete(TOKEN_COOKIE);
  res.cookies.delete(USER_COOKIE);
  return res;
}
