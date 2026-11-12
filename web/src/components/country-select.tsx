import { COUNTRY_OPTIONS } from "@/lib/countries";

export function CountrySelect({
  name = "address_country",
  defaultValue,
  className = "",
}: {
  name?: string;
  defaultValue?: string;
  className?: string;
}) {
  return (
    <div className={className}>
      <label htmlFor={name} className="field-label">
        Country
      </label>
      {/* `key`: React resets forms after a server action, and a <select> resets to the option it had when it
          mounted, so remount it when the value echoed back changes. */}
      <select
        key={defaultValue ?? ""}
        id={name}
        name={name}
        required
        defaultValue={defaultValue ?? ""}
        autoComplete="country"
        className="field"
      >
        <option value="" disabled>
          Select your country
        </option>
        {COUNTRY_OPTIONS.map((c) => (
          <option key={c.code} value={c.code}>
            {c.name}
          </option>
        ))}
      </select>
    </div>
  );
}
