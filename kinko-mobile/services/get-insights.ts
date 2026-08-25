import AsyncStorage from '@react-native-async-storage/async-storage';
import axios from 'axios';

const API_BASE_URL = process.env.EXPO_PUBLIC_API_URL || 'http://localhost:3000';

export type InsightRange = '7D' | '14D' | '30D';

export type InsightsResponse = {
  range: InsightRange;
  dates: string[];
  income: number[];
  expenses: number[];
};

export async function getInsights(range: InsightRange): Promise<InsightsResponse> {
  const token = await AsyncStorage.getItem('authToken');

  if (!token) {
    throw new Error('No authentication token found');
  }

  const days = range.replace('D', '');

  const response = await axios.get<InsightsResponse>(
    `${API_BASE_URL}/api/v1/accounts/insights`,
    {
      headers: {
        Authorization: `Bearer ${token}`,
      },
      params: { range: days },
      timeout: 10000,
    }
  );

  return response.data;
}
