"use client";

import { useActionState, useState } from "react";
import { register, type RegisterState } from "./actions";

const initialState: RegisterState = {};

function Field({
  name,
  label,
  className = "",
  ...props
}: { name: string; label: string; className?: string } & React.InputHTMLAttributes<HTMLInputElement>) {
  return (
    <div className={className}>
      <label htmlFor={name} className="field-label">
        {label}
      </label>
      <input id={name} name={name} className="field" {...props} />
    </div>
  );
}

export function RegisterForm() {
  const [state, formAction, pending] = useActionState(register, initialState);
  const v = state.values ?? {};
  const [userType, setUserType] = useState(v.user_type || "individual");

  return (
    <form action={formAction} className="space-y-6">
      <fieldset>
        <legend className="sr-only">Tipo de conta</legend>
        <div className="grid grid-cols-2 gap-1 rounded-full bg-chip p-1 text-sm font-semibold">
          {[
            { value: "individual", label: "Pessoa física" },
            { value: "business", label: "Empresa" },
          ].map((opt) => (
            <label
              key={opt.value}
              className={`cursor-pointer rounded-full py-2 text-center transition has-focus-visible:ring-2 has-focus-visible:ring-kinko-accent ${
                userType === opt.value ? "bg-kinko-accent text-white" : "text-[#333]"
              }`}
            >
              <input
                type="radio"
                name="user_type"
                value={opt.value}
                checked={userType === opt.value}
                onChange={() => setUserType(opt.value)}
                className="sr-only"
              />
              {opt.label}
            </label>
          ))}
        </div>
      </fieldset>

      <section className="grid gap-4 sm:grid-cols-2">
        <h2 className="text-sm font-bold text-kinko sm:col-span-2">Seus dados</h2>
        <Field name="full_name" label="Nome completo" required defaultValue={v.full_name} autoComplete="name" className="sm:col-span-2" />
        <Field name="email" label="E-mail" type="email" required defaultValue={v.email} autoComplete="email" className="sm:col-span-2" />
        <Field name="document_number" label={userType === "business" ? "CNPJ" : "CPF"} defaultValue={v.document_number} inputMode="numeric" />
        <Field name="phone_number" label="Telefone" type="tel" defaultValue={v.phone_number} autoComplete="tel" />
        {userType === "business" && (
          <>
            <Field name="business_name" label="Nome da empresa" required defaultValue={v.business_name} autoComplete="organization" />
            <Field name="business_sector" label="Setor" required defaultValue={v.business_sector} placeholder="Ex.: Retail" />
          </>
        )}
      </section>

      <section className="grid gap-4 sm:grid-cols-6">
        <h2 className="text-sm font-bold text-kinko sm:col-span-6">Endereço</h2>
        <Field name="address_zip_code" label="CEP" required defaultValue={v.address_zip_code} autoComplete="postal-code" className="sm:col-span-2" />
        <Field name="address_street" label="Rua" required defaultValue={v.address_street} autoComplete="address-line1" className="sm:col-span-4" />
        <Field name="address_number" label="Número" required defaultValue={v.address_number} className="sm:col-span-2" />
        <Field name="address_complement" label="Complemento" defaultValue={v.address_complement} autoComplete="address-line2" className="sm:col-span-4" />
        <Field name="address_neighborhood" label="Bairro" required defaultValue={v.address_neighborhood} className="sm:col-span-2" />
        <Field name="address_city" label="Cidade" required defaultValue={v.address_city} autoComplete="address-level2" className="sm:col-span-3" />
        <Field name="address_state" label="UF" required maxLength={2} defaultValue={v.address_state} autoComplete="address-level1" className="sm:col-span-1" />
      </section>

      <section className="grid gap-4 sm:grid-cols-2">
        <h2 className="text-sm font-bold text-kinko sm:col-span-2">Acesso</h2>
        <Field name="password" label="Senha" type="password" required minLength={6} autoComplete="new-password" />
        <Field name="password_confirmation" label="Confirmar senha" type="password" required minLength={6} autoComplete="new-password" />
      </section>

      {state.errors && state.errors.length > 0 && (
        <ul role="alert" className="space-y-1 rounded-xl bg-[#FFF5F5] px-4 py-3 text-sm text-kinko">
          {state.errors.map((e) => (
            <li key={e}>{e}</li>
          ))}
        </ul>
      )}

      <button type="submit" disabled={pending} className="btn-kinko w-full">
        {pending ? "Criando conta…" : "Criar conta"}
      </button>
    </form>
  );
}
