import { StyleSheet, Text, View } from "react-native";

export default function InsightDashboard() {
  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>Insight Dashboard</Text>
        <View style={styles.timeFilters}>
          <Text style={styles.timeFilter}>7D</Text>
          <Text style={styles.timeFilter}>30D</Text>
          <Text style={styles.timeFilter}>All</Text>
        </View>
      </View>
    </View>
  )
}

const styles = StyleSheet.create({
  container: {
    marginHorizontal: 20,
    marginTop: 10,
    backgroundColor: '#fff',
    borderRadius: 10,
    padding: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 5,
    elevation: 3,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center'
  },
  title: {
    fontSize: 18,
    fontWeight: 'bold',
  },
  timeFilters: {
    flexDirection: 'row',
    gap: 10,
    marginTop: 10,
  },
  timeFilter: {
    paddingVertical: 4,
    paddingHorizontal: 12,
    borderRadius: 20,
    backgroundColor: '#eee',
    fontSize: 14,
  }
})