import AsyncStorage from '@react-native-async-storage/async-storage';
import axios, { AxiosError, AxiosHeaders } from 'axios';

import {
  getPaymentPreview,
  PaymentError,
  payPaymentRequest,
  paymentBlocker,
} from '@/services/payment-requests';
import { CODE, preview, RESULT } from './fixtures';

function backendError(status: number, error: string) {
  const config = { headers: new AxiosHeaders() };
  return new AxiosError('Request failed', 'ERR_BAD_RESPONSE', config, null, {
    status,
    statusText: '',
    headers: {},
    config,
    data: { error },
  });
}

beforeEach(async () => {
  jest.restoreAllMocks();
  await AsyncStorage.setItem('authToken', 'jwt-123');
});

describe('getPaymentPreview', () => {
  it('sends the JWT and returns the preview', async () => {
    const get = jest.spyOn(axios, 'get').mockResolvedValue({ data: preview() });

    await expect(getPaymentPreview(CODE)).resolves.toMatchObject({ code: CODE, amount_cents: 4990 });
    expect(get).toHaveBeenCalledWith(
      expect.stringMatching(new RegExp(`/api/v1/payment_requests/${CODE}$`)),
      expect.objectContaining({ headers: { Authorization: 'Bearer jwt-123' } })
    );
  });

  it('maps backend errors to payer-friendly messages', async () => {
    jest.spyOn(axios, 'get').mockRejectedValue(backendError(404, 'Payment request not found'));

    await expect(getPaymentPreview(CODE)).rejects.toEqual(new PaymentError("We couldn't find a charge for this code.", 404));
  });

  it('reports a network failure', async () => {
    const config = { headers: new AxiosHeaders() };
    jest.spyOn(axios, 'get').mockRejectedValue(new AxiosError('Network Error', 'ERR_NETWORK', config));

    await expect(getPaymentPreview(CODE)).rejects.toThrow('Could not reach the server. Check your connection.');
  });

  it('fails without calling the API when there is no session', async () => {
    await AsyncStorage.removeItem('authToken');
    const get = jest.spyOn(axios, 'get');

    await expect(getPaymentPreview(CODE)).rejects.toThrow('Your session has expired');
    expect(get).not.toHaveBeenCalled();
  });
});

describe('payPaymentRequest', () => {
  it('POSTs to /pay and returns the result', async () => {
    const post = jest.spyOn(axios, 'post').mockResolvedValue({ data: RESULT });

    await expect(payPaymentRequest(CODE)).resolves.toEqual(RESULT);
    expect(post).toHaveBeenCalledWith(
      expect.stringMatching(new RegExp(`/api/v1/payment_requests/${CODE}/pay$`)),
      null,
      expect.objectContaining({ headers: { Authorization: 'Bearer jwt-123' } })
    );
  });

  it.each([
    [422, 'Insufficient funds', "You don't have enough balance to pay this charge."],
    [409, 'Payment request already paid', 'This charge has already been paid.'],
    [422, 'Payment request expired', 'This charge has expired. Ask the merchant for a new code.'],
    [422, 'Payment request canceled', 'The merchant canceled this charge.'],
    [422, 'Cannot pay your own payment request', "You can't pay your own charge."],
    [500, 'Internal error', "We couldn't complete the payment. Please try again."],
  ])('maps %i %s', async (status, backend, shown) => {
    jest.spyOn(axios, 'post').mockRejectedValue(backendError(status, backend));

    await expect(payPaymentRequest(CODE)).rejects.toThrow(shown);
  });
});

describe('paymentBlocker', () => {
  it('allows a pending charge with enough balance', () => {
    expect(paymentBlocker(preview())).toBeNull();
  });

  it.each([
    [preview({}, { already_paid_by_you: true }), 'You already paid this charge.'],
    [preview({ status: 'paid' }), 'This charge has already been paid.'],
    [preview({ status: 'canceled' }), 'The merchant canceled this charge.'],
    [preview({ status: 'expired' }), 'This charge has expired. Ask the merchant for a new code.'],
    [preview({}, { is_merchant: true }), 'This is your own charge.'],
    [preview({}, { sufficient_funds: false }), "You don't have enough balance to pay this charge."],
  ])('blocks %#', (p, reason) => {
    expect(paymentBlocker(p)).toBe(reason);
  });
});
