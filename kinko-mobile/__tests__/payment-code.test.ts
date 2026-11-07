import { formatPaymentCode, normalizePaymentCode } from '@/utils/payment-code';

const CODE = 'KNK189Z1N3XGHP23ADCXRXP4HP9G';

describe('normalizePaymentCode', () => {
  it('accepts pasted codes in any case, with spaces, dashes or line breaks', () => {
    expect(normalizePaymentCode(CODE)).toBe(CODE);
    expect(normalizePaymentCode(CODE.toLowerCase())).toBe(CODE);
    expect(normalizePaymentCode(` ${formatPaymentCode(CODE)}\n`)).toBe(CODE);
    expect(normalizePaymentCode(formatPaymentCode(CODE).replace(/ /g, '-'))).toBe(CODE);
  });

  it('maps the Crockford look-alikes O, I and L', () => {
    expect(normalizePaymentCode('KNK1OOOOOOOOOOIIIIILLLLL0000')).toBe('KNK1000000000011111111110000');
  });

  it.each(['', 'KNK1', CODE.slice(0, -1), `${CODE}0`, CODE.replace('KNK1', 'KNK2'), CODE.replace(/.$/, 'U'), CODE.replace(/.$/, '*')])(
    'rejects %j',
    (bad) => {
      expect(normalizePaymentCode(bad)).toBeNull();
    }
  );
});

describe('formatPaymentCode', () => {
  it('groups by 4', () => {
    expect(formatPaymentCode(CODE)).toBe('KNK1 89Z1 N3XG HP23 ADCX RXP4 HP9G');
  });
});
