import { StyleSheet, Text, View, ScrollView, TouchableOpacity } from 'react-native';
import MaterialIcons from '@expo/vector-icons/MaterialIcons';
import Header from '../components/header';
import BalanceCard from '../components/cards/balance-card';
import HomeGraphicChart from '../components/dashboards/home-graphic-chart';
import InsightCard from '../components/cards/insight-card';
import { useCallback, useEffect, useState } from 'react';
import getUserBalance from '@/services/get-user-balance';
import { useAuth } from '@/context/auth-context';
import { useBalanceWebSocket } from '@/hooks/use-balance-websocket';
import { useRouter } from 'expo-router';

export default function HomeScreen() {
  const router = useRouter();
  const { token, user } = useAuth();
  const [balance, setBalanceState] = useState<{
    income: number
    expenses: number
  } | null>(null)

  const [loading, setLoading] = useState(true)

  const fetchBalance = useCallback(async () => {
    try {
      const response = await getUserBalance()

      setBalanceState({
        income: response.income,
        expenses: response.expenses
      })
    } catch (error) {
      console.log("Erro ao buscar balance", error)
    } finally {
      setLoading(false)
    }
  }, [])

  const handleBalanceUpdate = useCallback((notification: {
    type: string;
    account_uuid: string;
    amount_cents: number;
    timestamp: string;
  }) => {
    if (notification.type === 'balance_updated') {
      console.log('Balance updated via WebSocket, refetching...');
      fetchBalance();
    }
  }, [fetchBalance]);

  useBalanceWebSocket(token, handleBalanceUpdate);

  useEffect(() => {
    fetchBalance()
  }, [fetchBalance])

  return (
    <View style={{ flex: 1 }}>
      <Header />
      <ScrollView style={styles.container} showsVerticalScrollIndicator={false}>
        <View style={styles.welcomeContainer}>
          <Text style={styles.welcomeText}>Welcome back {user?.full_name || 'User'}</Text>
        </View>
        {balance && (
          <View style={styles.balanceContainer}>
            <BalanceCard
              kind="Income"
              balance={balance?.income}
              loading={loading}
            />
            <BalanceCard
              kind="Expenses"
              balance={balance?.expenses}
              loading={loading}
            />
          </View>
        )}
        <HomeGraphicChart />
        <InsightCard />

        {/* View Statement Button */}
        <TouchableOpacity
          style={styles.statementButton}
          onPress={() => router.push('/(tabs)/transactions')}
        >
          <MaterialIcons name="receipt-long" size={20} color="#fff" />
          <Text style={styles.statementButtonText}>View Financial Statement</Text>
          <MaterialIcons name="chevron-right" size={20} color="#fff" />
        </TouchableOpacity>

        <View style={styles.bottomPadding} />
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    marginTop: 20,
    flex: 1,
    paddingBottom: 20,
  },
  welcomeContainer: {
    alignItems: 'flex-start',
    paddingHorizontal: 20,
  },
  welcomeText: {
    fontSize: 20,
    fontWeight: 'bold',
  },
  balanceContainer: {
    marginTop: 20,
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingHorizontal: 20,
  },
  statementButton: {
    marginHorizontal: 20,
    marginTop: 24,
    flexDirection: 'row',
    backgroundColor: '#d01c1c',
    paddingVertical: 14,
    paddingHorizontal: 16,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
  },
  statementButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
    flex: 1,
    textAlign: 'center',
  },
  bottomPadding: {
    height: 20,
  },
})
