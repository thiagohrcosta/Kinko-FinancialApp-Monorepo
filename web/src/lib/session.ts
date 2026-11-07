import "server-only";
import { cookies } from "next/headers";

export const TOKEN_COOKIE = "kinko_token";
export const USER_COOKIE = "kinko_user";

/** The Rails-issued JWT expires after 24h (JsonWebToken.encode). */
export const SESSION_MAX_AGE = 60 * 60 * 24;

export type SessionUser = {
  id: number;
  email: string;
  fullName: string;
  /** Absent in sessions created before the merchant area existed: treated as individual. */
  userType?: "individual" | "business";
};

const cookieOptions = {
  httpOnly: true,
  secure: process.env.NODE_ENV === "production",
  sameSite: "lax" as const,
  path: "/",
  maxAge: SESSION_MAX_AGE,
};

export async function createSession(token: string, user: SessionUser) {
  const store = await cookies();
  store.set(TOKEN_COOKIE, token, cookieOptions);
  store.set(USER_COOKIE, JSON.stringify(user), cookieOptions);
}

export async function deleteSession() {
  const store = await cookies();
  store.delete(TOKEN_COOKIE);
  store.delete(USER_COOKIE);
}

export async function getToken(): Promise<string | null> {
  return (await cookies()).get(TOKEN_COOKIE)?.value ?? null;
}

export async function getSessionUser(): Promise<SessionUser | null> {
  const raw = (await cookies()).get(USER_COOKIE)?.value;
  if (!raw) return null;
  try {
    return JSON.parse(raw) as SessionUser;
  } catch {
    return null;
  }
}
