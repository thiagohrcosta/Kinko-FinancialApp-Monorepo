"use server";

import { redirect, unstable_rethrow } from "next/navigation";
import { ApiError } from "@/lib/api";
import { login as apiLogin } from "@/lib/kinko";
import { createSession } from "@/lib/session";

export type LoginState = { error?: string; email?: string };

export async function login(_prev: LoginState, formData: FormData): Promise<LoginState> {
  const email = String(formData.get("email") ?? "").trim().toLowerCase();
  const password = String(formData.get("password") ?? "");

  if (!email || !password) {
    return { error: "Please enter both email and password.", email };
  }

  try {
    const { token, user } = await apiLogin(email, password);
    await createSession(token, { id: user.id, email: user.email, fullName: user.full_name });
  } catch (err) {
    unstable_rethrow(err);
    if (err instanceof ApiError && err.status === 401) {
      return { error: "Invalid email or password.", email };
    }
    console.error("Login failed:", err);
    return { error: "We couldn't reach the server. Please try again.", email };
  }

  redirect("/dashboard");
}
