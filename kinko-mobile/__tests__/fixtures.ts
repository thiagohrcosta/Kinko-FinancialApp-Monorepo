import type { PaymentPreview, PaymentResult } from '@/services/payment-requests';

export const CODE = 'KNK189Z1N3XGHP23ADCXRXP4HP9G';

export function preview(overrides: Partial<PaymentPreview> = {}, payer: Partial<PaymentPreview['payer']> = {}): PaymentPreview {
  return {
    code: CODE,
    status: 'pending',
    amount_cents: 4990,
    currency: 'USD',
    description: 'Order #7',
    expires_at: '2026-11-08T01:40:00Z',
    paid_at: null,
    merchant: { name: 'Acme Motors', sector: 'automotive', account_uuid: 'merchant-uuid' },
    ...overrides,
    payer: {
      account_uuid: 'payer-uuid',
      balance_cents: 10000,
      sufficient_funds: true,
      is_merchant: false,
      already_paid_by_you: false,
      ...payer,
    },
  };
}

export const RESULT: PaymentResult = {
  status: 'paid',
  transaction_id: '37ec22c2-b97a-4adf-aaf0-64f69e473279',
  amount_cents: 4990,
  currency: 'USD',
  paid_at: '2026-11-07T01:40:23Z',
  merchant: { name: 'Acme Motors', sector: 'automotive', account_uuid: 'merchant-uuid' },
};
