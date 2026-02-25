import { StyleSheet, Text, View } from 'react-native';

import Header from '../components/header';
import BalanceCard from '../components/cards/balance-card';
import HomeGraphicChart from '../components/dashboards/home-graphic-chart';
import InsightCard from '../components/cards/insight-card';
import { useEffect, useState } from 'react';
import getUserBalance from '../services/get-user-balance';

export default function HomeScreen() {
  const [balance, setBalanceState] = useState<{
    income: number
    expenses: number
  } | null>(null)

  const [loading, setLoading] = useState(true)

  async function fetchBalance() {
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
  }

  useEffect(() => {
    fetchBalance()
  }, [])

  return (
    <View style={{ flex: 1 }}>
      <Header />
      <View style={styles.container}>
        <View style={styles.welcomeContainer}>
          <Text style={styles.welcomeText}>Welcome back John Doe</Text>
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
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    marginTop: 20,
    flex: 1,
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
  }
})
