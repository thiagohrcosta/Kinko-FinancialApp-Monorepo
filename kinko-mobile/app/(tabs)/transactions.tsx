import { StyleSheet, Text, View, ScrollView, TouchableOpacity, ActivityIndicator, FlatList } from 'react-native';
import { useState, useEffect } from 'react';
import MaterialIcons from '@expo/vector-icons/MaterialIcons';
import { getTransactions, Transaction } from '@/services/get-transactions';
import formatCurrency from '@/app/utils/currency-formatter';

type FilterType = 'all' | 'income' | 'expenses';

const iconMap: { [key: string]: string } = {
  // Transfer and payment related
  'transferred to': 'send',
  'sent to': 'send',
  'transfer to': 'send',
  'received from': 'call-received',
  'received': 'call-received',
  'deposit from': 'account-balance-wallet',
  'card payment': 'credit-card',
  'transfer': 'swap-horiz',
  'sent': 'send',
  'payment': 'credit-card',
  'withdrawal': 'money-off',

  // Entertainment
  netflix: 'play-circle',
  spotify: 'music-note',
  hulu: 'play-circle',
  disney: 'play-circle',

  // Food & Dining
  coffee: 'local-cafe',
  cafe: 'local-cafe',
  bartender: 'local-cafe',
  restaurant: 'restaurant',
  food: 'fastfood',
  pizza: 'fastfood',
  burger: 'fastfood',
  sushi: 'restaurant',

  // Transportation
  uber: 'directions-car',
  lyft: 'directions-car',
  taxi: 'directions-car',
  gas: 'local-gas-station',
  parking: 'local-parking',
  bus: 'directions-bus',

  // Shopping
  amazon: 'shopping-bag',
  apple: 'shopping-bag',
  target: 'shopping-bag',
  grocery: 'shopping-cart',
  supermarket: 'shopping-cart',
  walmart: 'shopping-cart',
  costco: 'shopping-cart',

  // Utilities
  salary: 'attach-money',
  income: 'attach-money',
  deposit: 'account-balance-wallet',
  bill: 'receipt',
  rent: 'apartment',
  phone: 'phone',
  internet: 'router',
  electricity: 'flash-on',
  water: 'opacity',

  // Health & Fitness
  gym: 'fitness-center',
  peloton: 'fitness-center',
  hospital: 'local-hospital',
  pharmacy: 'local-pharmacy',
  doctor: 'local-hospital',

  // Education
  education: 'school',
  tuition: 'school',
  course: 'school',
};

const sectorIconMap: { [key: string]: string } = {
  'food & beverage': 'restaurant',
  retail: 'storefront',
  automotive: 'directions-car',
  logistics: 'local-shipping',
  technology: 'memory',
  healthcare: 'local-hospital',
  'professional services': 'business-center',
  hospitality: 'hotel',
  education: 'school',
  construction: 'construction',
};

function getIconForDescription(description: string): string {
  const lowercase = description.toLowerCase();

  // Verificar primeiro as chaves mais específicas (multi-word)
  const multiWordKeys = Object.keys(iconMap).filter(k => k.includes(' '));
  for (const keyword of multiWordKeys.sort((a, b) => b.length - a.length)) {
    if (lowercase.includes(keyword)) {
      return iconMap[keyword];
    }
  }

  // Depois verificar as chaves de uma palavra
  for (const [keyword, icon] of Object.entries(iconMap)) {
    if (!keyword.includes(' ') && lowercase.includes(keyword)) {
      return icon;
    }
  }

  return 'receipt-long';
}

function getIconForTransaction(txn: Transaction): string {
  if (txn.counterparty_type === 'individual') {
    return 'person';
  }

  if (txn.counterparty_type === 'business') {
    const sector = txn.counterparty_sector?.toLowerCase() || '';
    if (sectorIconMap[sector]) {
      return sectorIconMap[sector];
    }
  }

  return getIconForDescription(txn.description);
}

function getTransactionTitle(txn: Transaction): string {
  if (txn.counterparty_name) {
    if (txn.entry_type === 'credit') {
      return `Received from ${txn.counterparty_name}`;
    }
    return `Transfer to ${txn.counterparty_name}`;
  }

  return txn.description;
}

function truncateText(value: string, maxLength = 34): string {
  if (value.length <= maxLength) {
    return value;
  }

  return `${value.slice(0, maxLength - 1)}...`;
}

export default function TransactionsScreen() {
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [monthOffset, setMonthOffset] = useState(0);
  const [filter, setFilter] = useState<FilterType>('all');

  const currentMonth = new Date();
  const displayMonth = new Date(currentMonth.getFullYear(), currentMonth.getMonth() + monthOffset, 1);
  const monthLabel = displayMonth.toLocaleString('en-US', { month: 'long', year: 'numeric' });

  async function fetchTransactions() {
    try {
      setLoading(true);
      setError(null);
      const data = await getTransactions(monthOffset);
      setTransactions(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Error loading transactions');
      console.error('Error fetching transactions:', err);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    fetchTransactions();
  }, [monthOffset]);

  const filteredTransactions = transactions.filter((txn) => {
    if (filter === 'income') return txn.entry_type === 'credit';
    if (filter === 'expenses') return txn.entry_type === 'debit';
    return true;
  });

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    const today = new Date();
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);

    if (
      date.getDate() === today.getDate() &&
      date.getMonth() === today.getMonth() &&
      date.getFullYear() === today.getFullYear()
    ) {
      return 'Today';
    }

    if (
      date.getDate() === yesterday.getDate() &&
      date.getMonth() === yesterday.getMonth() &&
      date.getFullYear() === yesterday.getFullYear()
    ) {
      return 'Yesterday';
    }

    return date.toLocaleDateString('en-US', { weekday: 'long', month: 'short', day: 'numeric' });
  };

  const groupTransactionsByDate = (txns: Transaction[]) => {
    const grouped: { [key: string]: Transaction[] } = {};

    txns.forEach((txn) => {
      const label = formatDate(txn.created_at);
      if (!grouped[label]) {
        grouped[label] = [];
      }
      grouped[label].push(txn);
    });

    return grouped;
  };

  const groupedTransactions = groupTransactionsByDate(filteredTransactions);
  const dates = Object.keys(groupedTransactions);

  const renderTransaction = (txn: Transaction) => {
    const isCredit = txn.entry_type === 'credit';
    const color = isCredit ? '#16a34a' : '#dc2626';
    const sign = isCredit ? '+' : '-';
    const icon = getIconForTransaction(txn);
    const title = truncateText(getTransactionTitle(txn));

    return (
      <View key={txn.id} style={styles.transactionItem}>
        <View style={styles.transactionLeft}>
          <View style={[styles.iconCircle, { backgroundColor: `${color}20` }]}>
            <MaterialIcons
              name={icon as any}
              size={22}
              color={color}
            />
          </View>
          <View>
            <Text style={styles.transactionName} numberOfLines={1} ellipsizeMode="tail">{title}</Text>
            <Text style={styles.transactionDate}>
              {new Date(txn.created_at).toLocaleTimeString('en-US', {
                hour: '2-digit',
                minute: '2-digit',
                hour12: true,
              })}
            </Text>
          </View>
        </View>
        <Text style={[styles.transactionAmount, { color }]}>
          {sign}{formatCurrency(txn.amount_cents / 100)}
        </Text>
      </View>
    );
  };

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Statement</Text>
      </View>

      {/* Filter Tabs */}
      <View style={styles.filterTabs}>
        <TouchableOpacity
          style={[styles.filterTab, filter === 'all' && styles.filterTabActive]}
          onPress={() => setFilter('all')}
        >
          <Text style={[styles.filterTabText, filter === 'all' && styles.filterTabTextActive]}>
            All
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.filterTab, filter === 'income' && styles.filterTabActive]}
          onPress={() => setFilter('income')}
        >
          <Text style={[styles.filterTabText, filter === 'income' && styles.filterTabTextActive]}>
            Income
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.filterTab, filter === 'expenses' && styles.filterTabActive]}
          onPress={() => setFilter('expenses')}
        >
          <Text style={[styles.filterTabText, filter === 'expenses' && styles.filterTabTextActive]}>
            Expenses
          </Text>
        </TouchableOpacity>
      </View>

      {/* Month Navigation */}
      <View style={styles.monthNavigation}>
        <TouchableOpacity
          onPress={() => setMonthOffset(monthOffset - 1)}
          style={styles.navButton}
        >
          <MaterialIcons name="chevron-left" size={24} color="#666" />
        </TouchableOpacity>

        <Text style={styles.monthLabel}>{monthLabel}</Text>

        <TouchableOpacity
          onPress={() => setMonthOffset(monthOffset + 1)}
          disabled={monthOffset >= 0}
          style={[styles.navButton, monthOffset >= 0 && styles.navButtonDisabled]}
        >
          <MaterialIcons
            name="chevron-right"
            size={24}
            color={monthOffset >= 0 ? '#ccc' : '#666'}
          />
        </TouchableOpacity>
      </View>

      {/* Transactions List */}
      {loading ? (
        <View style={styles.centerContainer}>
          <ActivityIndicator size="large" color="#d01c1c" />
        </View>
      ) : error ? (
        <View style={styles.centerContainer}>
          <MaterialIcons name="error-outline" size={48} color="#dc2626" />
          <Text style={styles.errorText}>{error}</Text>
        </View>
      ) : filteredTransactions.length === 0 ? (
        <View style={styles.centerContainer}>
          <MaterialIcons name="receipt-long" size={48} color="#ccc" />
          <Text style={styles.emptyText}>No transactions this month</Text>
        </View>
      ) : filteredTransactions.length === 0 ? (
        <View style={styles.centerContainer}>
          <MaterialIcons name="receipt-long" size={48} color="#ccc" />
          <Text style={styles.emptyText}>No transactions this month</Text>
        </View>
      ) : (
        <ScrollView style={styles.transactionsList} showsVerticalScrollIndicator={false}>
          {dates.map((date) => (
            <View key={date}>
              <Text style={styles.dateLabel}>{date}</Text>
              {groupedTransactions[date].map(renderTransaction)}
            </View>
          ))}
          <View style={styles.bottomPadding} />
        </ScrollView>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  header: {
    paddingHorizontal: 20,
    paddingVertical: 16,
    backgroundColor: '#fff',
    borderBottomWidth: 1,
    borderBottomColor: '#eee',
  },
  headerTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#000',
  },
  filterTabs: {
    flexDirection: 'row',
    backgroundColor: '#fff',
    borderBottomWidth: 1,
    borderBottomColor: '#eee',
  },
  filterTab: {
    flex: 1,
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderBottomWidth: 3,
    borderBottomColor: 'transparent',
    alignItems: 'center',
  },
  filterTabActive: {
    borderBottomColor: '#d01c1c',
  },
  filterTabText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#999',
  },
  filterTabTextActive: {
    color: '#d01c1c',
  },
  monthNavigation: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingVertical: 12,
    backgroundColor: '#fff',
    marginBottom: 8,
  },
  navButton: {
    padding: 8,
  },
  navButtonDisabled: {
    opacity: 0.5,
  },
  monthLabel: {
    fontSize: 16,
    fontWeight: '600',
    color: '#000',
  },
  transactionsList: {
    flex: 1,
    paddingHorizontal: 16,
    paddingTop: 8,
  },
  dateLabel: {
    fontSize: 13,
    fontWeight: '600',
    color: '#999',
    marginTop: 16,
    marginBottom: 12,
    textTransform: 'uppercase',
  },
  transactionItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    backgroundColor: '#fff',
    paddingHorizontal: 16,
    paddingVertical: 12,
    marginBottom: 8,
    borderRadius: 12,
  },
  transactionLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
    gap: 12,
  },
  iconCircle: {
    width: 44,
    height: 44,
    borderRadius: 22,
    justifyContent: 'center',
    alignItems: 'center',
  },
  transactionName: {
    fontSize: 14,
    fontWeight: '600',
    color: '#000',
    maxWidth: 210,
  },
  transactionDate: {
    fontSize: 12,
    color: '#999',
    marginTop: 2,
  },
  transactionAmount: {
    fontSize: 14,
    fontWeight: '700',
  },
  centerContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  errorText: {
    fontSize: 14,
    color: '#dc2626',
    marginTop: 8,
  },
  emptyText: {
    fontSize: 14,
    color: '#999',
    marginTop: 8,
  },
  bottomPadding: {
    height: 20,
  },
});
