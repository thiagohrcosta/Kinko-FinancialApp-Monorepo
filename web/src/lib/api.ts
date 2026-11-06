import "server-only";
import { redirect } from "next/navigation";
import { getToken } from "./session";

export const API_BASE_URL = process.env.API_BASE_URL ?? "http://localhost:3000";

export class ApiError extends Error {
  constructor(
    message: string,
    public status: number,
    /** Individual Rails validation messages (`errors: [...]`), when present. */
    public errors: string[] = [],
  ) {
    super(message);
  }
}

async function toApiError(res: Response): Promise<ApiError> {
  try {
    const body = await res.json();
    if (typeof body?.error === "string") return new ApiError(body.error, res.status);
    if (Array.isArray(body?.errors)) {
      const errors = body.errors.map(String);
      return new ApiError(errors.join("; "), res.status, errors);
    }
  } catch {
    // non-JSON body
  }
  return new ApiError(`Request failed with status ${res.status}`, res.status);
}

/** Unauthenticated call (login, sign-up). */
export async function publicFetch<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(`${API_BASE_URL}${path}`, {
    ...init,
    headers: { "Content-Type": "application/json", Accept: "application/json", ...init?.headers },
    cache: "no-store",
  });
  if (!res.ok) throw await toApiError(res);
  return res.json() as Promise<T>;
}

/**
 * Authenticated call to Rails using the JWT stored in the httpOnly cookie.
 * A missing/expired token ends the session and sends the user to login.
 */
export async function authFetch<T>(path: string, init?: RequestInit): Promise<T> {
  const token = await getToken();
  if (!token) redirect("/login");

  const res = await fetch(`${API_BASE_URL}${path}`, {
    ...init,
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
      ...init?.headers,
    },
    cache: "no-store",
  });

  // Server Components can't delete cookies; the route handler does it.
  if (res.status === 401) redirect("/auth/logout?expired=1");
  if (!res.ok) throw await toApiError(res);
  return res.json() as Promise<T>;
}
