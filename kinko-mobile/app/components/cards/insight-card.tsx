import MaterialIcons from "@expo/vector-icons/MaterialIcons";
import { View, Text, StyleSheet, Pressable } from "react-native";

export default function InsightCard() {
  return (
    <View style={styles.container}>
      <View style={styles.headerContainer}>
        <MaterialIcons name="lightbulb-outline" size={24} color="#ff0000" />
        <Text style={styles.headerText}>Insights</Text>
      </View>
      <Text style={{ marginTop: 8 }}>
        Get personalized insights based on your spending habits and financial goals. We analyze your transactions to provide you with actionable advice and tips to help you save money and make informed financial decisions.
      </Text>
      <Pressable style={styles.insightButton}>
        <Text style={styles.insightButtonText}>View Insights</Text>
      </Pressable>
    </View>
  )
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: "#fff",
    borderRadius: 8,
    padding: 16,
    margin:20,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 2,
  },
  headerContainer: {
    flexDirection: "row",
    alignItems: "center",
  },
  headerText: {
    fontSize: 18,
    fontWeight: "bold",
    marginLeft: 8,
  },
  insightButton: {
    marginTop: 12,
    backgroundColor: "#FF3B30",
    paddingVertical: 10,
    borderRadius: 20,
    alignItems: "center",
  },
  insightButtonText: {
    color: "#fff",
    fontSize: 14,
    fontWeight: "600",
  },
})