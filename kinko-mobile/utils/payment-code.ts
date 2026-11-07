// The copy-and-paste payment code ("KNK1" + 24 chars, Crockford base32).
// Only the shape is checked here: the checksum is keyed with a server secret,
// so the backend is the authority on whether a code is real.

export const PAYMENT_CODE_PREFIX = 'KNK1';
export const PAYMENT_CODE_LENGTH = 28;
const BODY = /^[0-9A-HJKMNP-TV-Z]{24}$/;

/** Canonical form (upper case, no spaces/dashes, O→0, I/L→1), or null if the shape is wrong. */
export function normalizePaymentCode(raw: string): string | null {
  const code = raw.toUpperCase().replace(/[\s-]/g, '').replace(/O/g, '0').replace(/[IL]/g, '1');
  if (code.length !== PAYMENT_CODE_LENGTH || !code.startsWith(PAYMENT_CODE_PREFIX)) return null;
  return BODY.test(code.slice(PAYMENT_CODE_PREFIX.length)) ? code : null;
}

/** "KNK1 89Z1 N3XG …" — easier to read and compare. */
export function formatPaymentCode(code: string): string {
  return code.match(/.{1,4}/g)?.join(' ') ?? code;
}
