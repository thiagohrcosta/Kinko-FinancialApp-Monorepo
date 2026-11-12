"use server";

import { refresh } from "next/cache";
import { unstable_rethrow } from "next/navigation";
import { ApiError } from "@/lib/api";
import { updateProfileAddress } from "@/lib/kinko";

/** `values` refill the form: React resets it after every submission. */
export type CountryState = { errors?: string[]; saved?: boolean; values?: { address_country: string; address_state: string } };

export async function saveCountry(_prev: CountryState, formData: FormData): Promise<CountryState> {
  const address_country = String(formData.get("address_country") ?? "").trim();
  const address_state = String(formData.get("address_state") ?? "").trim();
  const values = { address_country, address_state };
  if (!address_country) return { errors: ["Select your country."], values };

  try {
    await updateProfileAddress({ address_country, address_state });
    refresh();
    return { saved: true };
  } catch (err) {
    unstable_rethrow(err);
    if (err instanceof ApiError && err.status === 422) return { errors: err.errors.length ? err.errors : [err.message], values };
    console.error("Saving the country failed:", err);
    return { errors: ["We couldn't save your country. Please try again."], values };
  }
}
