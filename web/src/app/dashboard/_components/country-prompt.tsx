import { getProfile } from "@/lib/kinko";
import { CountryForm } from "./country-form";

/**
 * Users created before the country was asked at sign-up must add it: it decides
 * which privacy rules (deadlines, notices) apply to them.
 */
export async function CountryPrompt() {
  const profile = await getProfile().catch(() => null);
  if (!profile || profile.address_country) return null;

  return (
    <section className="mb-8 rounded-2xl border border-chip bg-white p-5 shadow-sm">
      <h2 className="text-base font-bold text-ink">Where do you live?</h2>
      <p className="mt-1 text-sm text-subtle">
        Add your country to keep your account up to date. It tells us which privacy rules protect your data.
      </p>
      <CountryForm state={profile.address_state} />
    </section>
  );
}
