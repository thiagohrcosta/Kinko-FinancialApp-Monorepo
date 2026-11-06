import { NextResponse, type NextRequest } from "next/server";
import { TOKEN_COOKIE, USER_COOKIE } from "@/lib/session";

/**
 * Used when the backend rejects the token (401) during rendering:
 * Server Components can't modify cookies, so they are cleared here.
 */
export function GET(request: NextRequest) {
  const url = new URL("/login", request.url);
  if (request.nextUrl.searchParams.has("expired")) url.searchParams.set("expired", "1");

  const res = NextResponse.redirect(url);
  res.cookies.delete(TOKEN_COOKIE);
  res.cookies.delete(USER_COOKIE);
  return res;
}
