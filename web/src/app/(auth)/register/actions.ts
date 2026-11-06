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

// Traduz as mensagens mais comuns do Rails/Devise; as demais seguem como vieram.
const TRANSLATIONS: Record<string, string> = {
  "Email has already been taken": "Este e-mail já está cadastrado.",
  "Email is invalid": "E-mail inválido.",
  "Password is too short (minimum is 6 characters)": "A senha precisa ter pelo menos 6 caracteres.",
  "Password confirmation doesn't match Password": "A confirmação não confere com a senha.",
};

export async function register(_prev: RegisterState, formData: FormData): Promise<RegisterState> {
  const values = Object.fromEntries(
    FIELDS.map((f) => [f, String(formData.get(f) ?? "").trim()]),
  ) as Record<(typeof FIELDS)[number], string>;
  values.email = values.email.toLowerCase();
  // Não devolvemos senhas para o formulário
  const echo = { ...values, password: "", password_confirmation: "" };

  const errors: string[] = [];
  if (values.password.length < 6) errors.push(TRANSLATIONS["Password is too short (minimum is 6 characters)"]);
  if (values.password !== values.password_confirmation) errors.push(TRANSLATIONS["Password confirmation doesn't match Password"]);
  if (values.user_type === "business" && (!values.business_name || !values.business_sector)) {
    errors.push("Informe o nome e o setor da empresa.");
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
      const messages = err.errors.length ? err.errors : [err.message];
      return { errors: messages.map((m) => TRANSLATIONS[m] ?? m), values: echo };
    }
    console.error("Register failed:", err);
    return { errors: ["Não foi possível conectar ao servidor. Tente novamente."], values: echo };
  }

  redirect("/dashboard");
}
