import formatCurrency from "@/app/utils/currency-formatter"
import MaterialIcons from "@expo/vector-icons/MaterialIcons"
import { ActivityIndicator, StyleSheet, Text, View } from "react-native"

type BalanceCardProps = {
  kind: "Income" | "Expenses"
  balance?: number
  loading?: boolean
}

export default function BalanceCard({
  kind,
  balance,
  loading = false,
}: BalanceCardProps) {
  const isIncome = kind === "Income"

  return (
    <View style={styles.container}>
      <View style={styles.iconContainer}>
        <MaterialIcons
          name={isIncome ? "arrow-upward" : "arrow-downward"}
          size={24}
          color={isIncome ? "#16a34a" : "#dc2626"}
        />
        <Text style={styles.kindText}>{kind}</Text>
      </View>

      {loading ? (
        <ActivityIndicator size="small" />
      ) : (
        <Text style={styles.balanceText}>
          {balance !== undefined
            ? formatCurrency(balance)
            : formatCurrency(0)}
        </Text>
      )}
    </View>
  )
}

const styles = StyleSheet.create({
  container: {
    width: "48%",
    borderRadius: 12,
    backgroundColor: "#fff",
    padding: 20,
    marginBottom: 20,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.08,
    shadowRadius: 6,
    elevation: 3,
  },
  iconContainer: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
  },
  kindText: {
    fontSize: 14,
    fontWeight: "600",
  },
  balanceText: {
    marginTop: 12,
    fontSize: 22,
    fontWeight: "bold",
  },
})