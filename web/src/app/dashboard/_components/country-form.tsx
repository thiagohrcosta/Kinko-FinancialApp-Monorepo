"use client";

import { useActionState } from "react";
import { CountrySelect } from "@/components/country-select";
import { saveCountry, type CountryState } from "../profile-actions";

const initialState: CountryState = {};

export function CountryForm({ state: currentState }: { state: string }) {
  const [state, formAction, pending] = useActionState(saveCountry, initialState);

  return (
    <form action={formAction} className="mt-4 grid gap-3 sm:grid-cols-[2fr_1fr_auto] sm:items-end">
      <CountrySelect defaultValue={state.values?.address_country} />
      <div>
        <label htmlFor="address_state" className="field-label">
          State / province
        </label>
        <input id="address_state" name="address_state" required defaultValue={state.values?.address_state ?? currentState} className="field" />
      </div>
      <button type="submit" disabled={pending} className="btn-kinko">
        {pending ? "Saving…" : "Save"}
      </button>
      {state.errors && state.errors.length > 0 && (
        <ul role="alert" className="space-y-1 text-sm text-kinko sm:col-span-3">
          {state.errors.map((e) => (
            <li key={e}>{e}</li>
          ))}
        </ul>
      )}
    </form>
  );
}
