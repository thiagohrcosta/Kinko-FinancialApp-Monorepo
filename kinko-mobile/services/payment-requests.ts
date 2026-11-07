import AsyncStorage from '@react-native-async-storage/async-storage';
import axios, { isAxiosError } from 'axios';

const API_BASE_URL = process.env.EXPO_PUBLIC_API_URL || 'http://localhost:3000';

export type PaymentRequestStatus = 'pending' | 'paid' | 'canceled' | 'expired';

export type MerchantSummary = { name: string; sector: string | null; account_uuid: string };

export type PaymentPreview = {
  code: string;
  status: PaymentRequestStatus;
  amount_cents: number;
  currency: string;
  description: string;
  expires_at: string;
  paid_at: string | null;
  merchant: MerchantSummary;
  payer: {
    account_uuid: string;
    balance_cents: number;
    sufficient_funds: boolean;
    is_merchant: boolean;
    already_paid_by_you: boolean;
  };
};

export type PaymentResult = {
  status: 'paid';
  transaction_id: string;
  amount_cents: number;
  currency: string;
  paid_at: string;
  merchant: MerchantSummary;
};

// Backend error → message shown to the payer
const MESSAGES: Record<string, string> = {
  'Insufficient funds': "You don't have enough balance to pay this charge.",
  'Payment request already paid': 'This charge has already been paid.',
  'Payment request expired': 'This charge has expired. Ask the merchant for a new code.',
  'Payment request canceled': 'The merchant canceled this charge.',
  'Cannot pay your own payment request': "You can't pay your own charge.",
  'Invalid payment code': 'This payment code is not valid.',
  'Payment request not found': "We couldn't find a charge for this code.",
};

export class PaymentError extends Error {
  constructor(message: string, public status?: number) {
    super(message);
    this.name = 'PaymentError';
  }
}

function toPaymentError(error: unknown, fallback: string): PaymentError {
  if (isAxiosError(error)) {
    if (!error.response) return new PaymentError('Could not reach the server. Check your connection.');
    const backend = error.response.data?.error;
    return new PaymentError(MESSAGES[backend] ?? fallback, error.response.status);
  }
  return new PaymentError(fallback);
}

async function authHeaders() {
  const token = await AsyncStorage.getItem('authToken');
  if (!token) throw new PaymentError('Your session has expired. Please log in again.', 401);
  return { Authorization: `Bearer ${token}` };
}

export async function getPaymentPreview(code: string): Promise<PaymentPreview> {
  const headers = await authHeaders();
  try {
    const response = await axios.get<PaymentPreview>(
      `${API_BASE_URL}/api/v1/payment_requests/${encodeURIComponent(code)}`,
      { headers, timeout: 10000 }
    );
    return response.data;
  } catch (error) {
    throw toPaymentError(error, "We couldn't load this charge. Please try again.");
  }
}

export async function payPaymentRequest(code: string): Promise<PaymentResult> {
  const headers = await authHeaders();
  try {
    const response = await axios.post<PaymentResult>(
      `${API_BASE_URL}/api/v1/payment_requests/${encodeURIComponent(code)}/pay`,
      null,
      { headers, timeout: 15000 }
    );
    return response.data;
  } catch (error) {
    throw toPaymentError(error, "We couldn't complete the payment. Please try again.");
  }
}

/** Why the payer can't pay this charge, or null when it can be paid. */
export function paymentBlocker(p: PaymentPreview): string | null {
  if (p.payer.already_paid_by_you) return 'You already paid this charge.';
  if (p.status === 'paid') return 'This charge has already been paid.';
  if (p.status === 'canceled') return 'The merchant canceled this charge.';
  if (p.status === 'expired') return 'This charge has expired. Ask the merchant for a new code.';
  if (p.payer.is_merchant) return 'This is your own charge.';
  if (!p.payer.sufficient_funds) return "You don't have enough balance to pay this charge.";
  return null;
}
