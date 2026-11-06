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
        <legend className="sr-only">Account type</legend>
        <div className="grid grid-cols-2 gap-1 rounded-full bg-chip p-1 text-sm font-semibold">
          {[
            { value: "individual", label: "Personal" },
            { value: "business", label: "Business" },
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
        <h2 className="text-sm font-bold text-kinko sm:col-span-2">Your details</h2>
        <Field name="full_name" label="Full name" required defaultValue={v.full_name} autoComplete="name" className="sm:col-span-2" />
        <Field name="email" label="Email" type="email" required defaultValue={v.email} autoComplete="email" className="sm:col-span-2" />
        <Field name="document_number" label={userType === "business" ? "Tax ID (EIN)" : "SSN / Tax ID"} defaultValue={v.document_number} inputMode="numeric" />
        <Field name="phone_number" label="Phone" type="tel" defaultValue={v.phone_number} autoComplete="tel" />
        {userType === "business" && (
          <>
            <Field name="business_name" label="Business name" required defaultValue={v.business_name} autoComplete="organization" />
            <Field name="business_sector" label="Industry" required defaultValue={v.business_sector} placeholder="e.g. Retail" />
          </>
        )}
      </section>

      <section className="grid gap-4 sm:grid-cols-6">
        <h2 className="text-sm font-bold text-kinko sm:col-span-6">Address</h2>
        <Field name="address_number" label="Number" required defaultValue={v.address_number} className="sm:col-span-2" />
        <Field name="address_street" label="Street" required defaultValue={v.address_street} autoComplete="address-line1" className="sm:col-span-4" />
        <Field name="address_complement" label="Apt, suite, etc." defaultValue={v.address_complement} autoComplete="address-line2" className="sm:col-span-3" />
        <Field name="address_neighborhood" label="Neighborhood" required defaultValue={v.address_neighborhood} className="sm:col-span-3" />
        <Field name="address_city" label="City" required defaultValue={v.address_city} autoComplete="address-level2" className="sm:col-span-3" />
        <Field name="address_state" label="State" required maxLength={2} placeholder="NY" defaultValue={v.address_state} autoComplete="address-level1" className="sm:col-span-1" />
        <Field name="address_zip_code" label="ZIP code" required defaultValue={v.address_zip_code} autoComplete="postal-code" inputMode="numeric" className="sm:col-span-2" />
      </section>

      <section className="grid gap-4 sm:grid-cols-2">
        <h2 className="text-sm font-bold text-kinko sm:col-span-2">Security</h2>
        <Field name="password" label="Password" type="password" required minLength={6} autoComplete="new-password" />
        <Field name="password_confirmation" label="Confirm password" type="password" required minLength={6} autoComplete="new-password" />
      </section>

      {state.errors && state.errors.length > 0 && (
        <ul role="alert" className="space-y-1 rounded-xl bg-[#FFF5F5] px-4 py-3 text-sm text-kinko">
          {state.errors.map((e) => (
            <li key={e}>{e}</li>
          ))}
        </ul>
      )}

      <button type="submit" disabled={pending} className="btn-kinko w-full">
        {pending ? "Creating account…" : "Create account"}
      </button>
    </form>
  );
}
