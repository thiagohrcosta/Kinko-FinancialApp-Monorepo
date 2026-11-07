import { fireEvent, render, screen, waitFor } from '@testing-library/react-native';

import PayScreen from '@/app/(tabs)/pay';
import { getPaymentPreview, PaymentError, payPaymentRequest } from '@/services/payment-requests';
import { CODE, preview, RESULT } from './fixtures';

const mockPush = jest.fn();
jest.mock('expo-router', () => ({ useRouter: () => ({ push: mockPush }) }));
jest.mock('expo-image', () => ({ Image: () => null }));
jest.mock('@expo/vector-icons/MaterialIcons', () => () => null);
jest.mock('@/services/payment-requests', () => ({
  ...jest.requireActual('@/services/payment-requests'),
  getPaymentPreview: jest.fn(),
  payPaymentRequest: jest.fn(),
}));

const mockedPreview = getPaymentPreview as jest.MockedFunction<typeof getPaymentPreview>;
const mockedPay = payPaymentRequest as jest.MockedFunction<typeof payPaymentRequest>;

beforeEach(() => jest.clearAllMocks());

function enterCode(code: string) {
  fireEvent.changeText(screen.getByTestId('pay-code-input'), code);
  fireEvent.press(screen.getByTestId('pay-continue'));
}

it('rejects a malformed code without calling the API', () => {
  render(<PayScreen />);
  enterCode('KNK1 THIS IS WRONG');

  expect(screen.getByRole('alert')).toHaveTextContent('This payment code is not valid.');
  expect(mockedPreview).not.toHaveBeenCalled();
});

it('normalizes a pasted code and shows the preview', async () => {
  mockedPreview.mockResolvedValue(preview());
  render(<PayScreen />);
  enterCode(` ${CODE.toLowerCase().match(/.{1,4}/g)!.join(' ')} `);

  await screen.findByTestId('pay-preview');
  expect(mockedPreview).toHaveBeenCalledWith(CODE);
  expect(screen.getByText('$49.90')).toBeTruthy();
  expect(screen.getByText('Acme Motors')).toBeTruthy();
  expect(screen.getByText('Order #7')).toBeTruthy();
  expect(screen.getByText('payer-uuid')).toBeTruthy();
  expect(screen.getByText('$100.00')).toBeTruthy();
  expect(screen.getByText('Nov 8, 2026, 1:40 AM UTC')).toBeTruthy();
  expect(screen.getByTestId('pay-confirm')).toBeEnabled();
});

it('shows the API error when the code is unknown', async () => {
  mockedPreview.mockRejectedValue(new PaymentError("We couldn't find a charge for this code.", 404));
  render(<PayScreen />);
  enterCode(CODE);

  expect(await screen.findByRole('alert')).toHaveTextContent("We couldn't find a charge for this code.");
});

it.each([
  [{ status: 'expired' as const }, {}, 'This charge has expired. Ask the merchant for a new code.'],
  [{}, { sufficient_funds: false }, "You don't have enough balance to pay this charge."],
  [{}, { already_paid_by_you: true }, 'You already paid this charge.'],
])('disables payment with a reason (%#)', async (overrides, payer, reason) => {
  mockedPreview.mockResolvedValue(preview(overrides, payer));
  render(<PayScreen />);
  enterCode(CODE);

  expect(await screen.findByTestId('pay-blocker')).toHaveTextContent(reason);
  expect(screen.getByTestId('pay-confirm')).toBeDisabled();
  fireEvent.press(screen.getByTestId('pay-confirm'));
  expect(mockedPay).not.toHaveBeenCalled();
});

it('pays and shows the receipt', async () => {
  mockedPreview.mockResolvedValue(preview());
  mockedPay.mockResolvedValue(RESULT);
  render(<PayScreen />);
  enterCode(CODE);

  fireEvent.press(await screen.findByTestId('pay-confirm'));

  await screen.findByTestId('pay-success');
  expect(mockedPay).toHaveBeenCalledTimes(1);
  expect(mockedPay).toHaveBeenCalledWith(CODE);
  expect(screen.getByText('Payment complete')).toBeTruthy();
  expect(screen.getByText(`Transaction ID: ${RESULT.transaction_id}`)).toBeTruthy();

  fireEvent.press(screen.getByText('View in statement'));
  expect(mockPush).toHaveBeenCalledWith('/(tabs)/transactions');
});

it('keeps the preview and shows the error when payment fails', async () => {
  mockedPreview.mockResolvedValue(preview());
  mockedPay.mockRejectedValue(new PaymentError('This charge has already been paid.', 409));
  render(<PayScreen />);
  enterCode(CODE);

  fireEvent.press(await screen.findByTestId('pay-confirm'));

  expect(await screen.findByRole('alert')).toHaveTextContent('This charge has already been paid.');
  expect(screen.getByTestId('pay-preview')).toBeTruthy();
});

it('goes back to code entry with "Use a different code"', async () => {
  mockedPreview.mockResolvedValue(preview());
  render(<PayScreen />);
  enterCode(CODE);
  await screen.findByTestId('pay-preview');

  fireEvent.press(screen.getByText('Use a different code'));

  await waitFor(() => expect(screen.getByTestId('pay-code-input')).toHaveProp('value', ''));
});
