import AsyncStorage from '@react-native-async-storage/async-storage';
import axios from 'axios';

const API_BASE_URL = process.env.EXPO_PUBLIC_API_URL || 'http://localhost:3000';

export type Transaction = {
  id: number;
  amount_cents: number;
  entry_type: 'credit' | 'debit';
  description: string;
  counterparty_name?: string | null;
  counterparty_type?: 'individual' | 'business' | null;
  counterparty_sector?: string | null;
  created_at: string;
  currency: string;
};

type TransactionsResponse = Transaction[];

export async function getTransactions(monthOffset: number = 0): Promise<Transaction[]> {
  const token = await AsyncStorage.getItem('authToken');

  if (!token) {
    throw new Error('No authentication token found');
  }

  const now = new Date();
  const targetDate = new Date(now.getFullYear(), now.getMonth() + monthOffset, 1);
  const monthStr = targetDate.toISOString().slice(0, 7);

  const response = await axios.get<TransactionsResponse>(
    `${API_BASE_URL}/api/v1/accounts/transactions`,
    {
      headers: {
        Authorization: `Bearer ${token}`,
      },
      params: {
        month: monthStr,
      },
    }
  );

  return response.data;
}
