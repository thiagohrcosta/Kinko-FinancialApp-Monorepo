import "server-only";
import { redirect } from "next/navigation";
import { getToken } from "./session";

export const API_BASE_URL = process.env.API_BASE_URL ?? "http://localhost:3000";

export class ApiError extends Error {
  constructor(
    message: string,
    public status: number,
    /** Mensagens individuais de validação do Rails (`errors: [...]`), quando houver. */
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
    // corpo não-JSON
  }
  return new ApiError(`Request failed with status ${res.status}`, res.status);
}

/** Chamada sem autenticação (login, registro). */
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
 * Chamada autenticada ao Rails usando o JWT guardado no cookie httpOnly.
 * Se o token estiver ausente/expirado, encerra a sessão e manda para o login.
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

  // Componentes de servidor não podem apagar cookies; o route handler faz isso.
  if (res.status === 401) redirect("/auth/logout?expired=1");
  if (!res.ok) throw await toApiError(res);
  return res.json() as Promise<T>;
}
