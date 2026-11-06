"use server";

import { redirect } from "next/navigation";
import { ApiError } from "@/lib/api";
import { login as apiLogin } from "@/lib/kinko";
import { createSession, deleteSession } from "@/lib/session";

export type LoginState = { error?: string; email?: string };

export async function login(_prev: LoginState, formData: FormData): Promise<LoginState> {
  const email = String(formData.get("email") ?? "").trim().toLowerCase();
  const password = String(formData.get("password") ?? "");

  if (!email || !password) {
    return { error: "Informe e-mail e senha.", email };
  }

  try {
    const { token, user } = await apiLogin(email, password);
    await createSession(token, { id: user.id, email: user.email, fullName: user.full_name });
  } catch (err) {
    if (err instanceof ApiError && err.status === 401) {
      return { error: "E-mail ou senha inválidos.", email };
    }
    console.error("Login failed:", err);
    return { error: "Não foi possível conectar ao servidor. Tente novamente.", email };
  }

  redirect("/dashboard");
}

export async function logout() {
  await deleteSession();
  redirect("/login");
}
