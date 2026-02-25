import { useAuth } from "@/context/auth-context";
import AsyncStorage from "@react-native-async-storage/async-storage";
import axios from "axios";

const API_BASE_URL = process.env.EXPO_PUBLIC_API_URL || 'http://localhost:3000';

type UserBalanceResponse = {
  userId: string;
  balance: number;
  income: number;
  expenses: number;
}

export default async function getUserBalance(): Promise<UserBalanceResponse> {
  const token = await AsyncStorage.getItem('authToken');

  const response = await axios.get<UserBalanceResponse>(`${API_BASE_URL}/api/v1/accounts/balance`, {
    headers: {
      Authorization: `Bearer ${token}`,
    },
  });

  return response.data;
}