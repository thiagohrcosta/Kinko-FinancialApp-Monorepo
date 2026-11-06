"use server";

import { redirect, unstable_rethrow } from "next/navigation";
import { ApiError } from "@/lib/api";
import { register as apiRegister, type RegisterPayload } from "@/lib/kinko";
import { createSession } from "@/lib/session";

export type RegisterState = { errors?: string[]; values?: Record<string, string> };

const FIELDS = [
  "full_name", "email", "password", "password_confirmation", "user_type", "business_name", "business_sector",
  "document_number", "phone_number", "address_zip_code", "address_street", "address_number",
  "address_complement", "address_neighborhood", "address_city", "address_state",
] as const;

export async function register(_prev: RegisterState, formData: FormData): Promise<RegisterState> {
  const values = Object.fromEntries(
    FIELDS.map((f) => [f, String(formData.get(f) ?? "").trim()]),
  ) as Record<(typeof FIELDS)[number], string>;
  values.email = values.email.toLowerCase();
  // Never echo passwords back into the form
  const echo = { ...values, password: "", password_confirmation: "" };

  const errors: string[] = [];
  if (values.password.length < 6) errors.push("Password must be at least 6 characters.");
  if (values.password !== values.password_confirmation) errors.push("Password confirmation doesn't match.");
  if (values.user_type === "business" && (!values.business_name || !values.business_sector)) {
    errors.push("Enter the business name and industry.");
  }
  if (errors.length) return { errors, values: echo };

  const payload: RegisterPayload = {
    ...values,
    user_type: values.user_type === "business" ? "business" : "individual",
  };
  if (payload.user_type === "individual") {
    delete payload.business_name;
    delete payload.business_sector;
  }

  try {
    const { token, user } = await apiRegister(payload);
    await createSession(token, { id: user.id, email: user.email, fullName: user.full_name });
  } catch (err) {
    unstable_rethrow(err);
    if (err instanceof ApiError && err.status === 422) {
      // Rails validation messages are already user-facing English sentences
      return { errors: err.errors.length ? err.errors : [err.message], values: echo };
    }
    console.error("Register failed:", err);
    return { errors: ["We couldn't reach the server. Please try again."], values: echo };
  }

  redirect("/dashboard");
}
