import { NextResponse, type NextRequest } from "next/server";

// Checagem otimista (só presença do cookie). A validação real do token
// acontece no Rails a cada chamada feita por src/lib/api.ts.
const TOKEN_COOKIE = "kinko_token";

export function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl;
  const hasSession = request.cookies.has(TOKEN_COOKIE);

  if (pathname.startsWith("/dashboard") && !hasSession) {
    return NextResponse.redirect(new URL("/login", request.url));
  }

  if ((pathname === "/login" || pathname === "/") && hasSession) {
    return NextResponse.redirect(new URL("/dashboard", request.url));
  }

  if (pathname === "/" && !hasSession) {
    return NextResponse.redirect(new URL("/login", request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/", "/login", "/dashboard/:path*"],
};
