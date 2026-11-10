import MaterialIcons from '@expo/vector-icons/MaterialIcons';
import { useRouter } from 'expo-router';
import { useState } from 'react';
import { ActivityIndicator, ScrollView, StyleSheet, Text, TextInput, TouchableOpacity, View } from 'react-native';

import {
  getPaymentPreview,
  payPaymentRequest,
  paymentBlocker,
  type PaymentPreview,
  type PaymentResult,
} from '@/services/payment-requests';
import { formatPaymentCode, normalizePaymentCode } from '@/utils/payment-code';
import Header from '../components/header';

const KINKO_RED = '#d01c1c';

function money(cents: number, currency: string) {
  return new Intl.NumberFormat('en-US', { style: 'currency', currency }).format(cents / 100);
}

function expiry(iso: string) {
  return `${new Intl.DateTimeFormat('en-US', { dateStyle: 'medium', timeStyle: 'short', timeZone: 'UTC' }).format(new Date(iso))} UTC`;
}

type Step =
  | { kind: 'enter' }
  | { kind: 'preview'; preview: PaymentPreview }
  | { kind: 'paid'; result: PaymentResult };

function Row({ label, value, mono }: { label: string; value: string; mono?: boolean }) {
  return (
    <View style={styles.row}>
      <Text style={styles.rowLabel}>{label}</Text>
      <Text style={[styles.rowValue, mono && styles.mono]} selectable>
        {value}
      </Text>
    </View>
  );
}

export default function PayScreen() {
  const router = useRouter();
  const [input, setInput] = useState('');
  const [step, setStep] = useState<Step>({ kind: 'enter' });
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  function reset() {
    setInput('');
    setError(null);
    setStep({ kind: 'enter' });
  }

  async function loadPreview() {
    const code = normalizePaymentCode(input);
    if (!code) {
      setError('This payment code is not valid.');
      return;
    }
    setBusy(true);
    setError(null);
    try {
      setStep({ kind: 'preview', preview: await getPaymentPreview(code) });
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setBusy(false);
    }
  }

  async function confirm(preview: PaymentPreview) {
    setBusy(true);
    setError(null);
    try {
      setStep({ kind: 'paid', result: await payPaymentRequest(preview.code) });
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setBusy(false);
    }
  }

  let content: React.ReactNode;

  if (step.kind === 'paid') {
    const { result } = step;
    content = (
      <View style={[styles.card, styles.center]} testID="pay-success">
        <View style={styles.successIcon}>
          <MaterialIcons name="check" size={32} color="#15803d" />
        </View>
        <Text style={styles.title}>Payment complete</Text>
        <Text style={styles.amount}>{money(result.amount_cents, result.currency)}</Text>
        <Text style={styles.muted}>to {result.merchant.name}</Text>
        <Text style={styles.small} selectable>
          Transaction ID: {result.transaction_id}
        </Text>
        <TouchableOpacity style={styles.primary} onPress={() => router.push('/(tabs)/transactions')}>
          <Text style={styles.primaryText}>View in statement</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.secondary} onPress={reset}>
          <Text style={styles.secondaryText}>Pay another code</Text>
        </TouchableOpacity>
      </View>
    );
  } else if (step.kind === 'preview') {
    const { preview } = step;
    const blocker = paymentBlocker(preview);
    const amount = money(preview.amount_cents, preview.currency);
    content = (
      <View style={styles.card} testID="pay-preview">
        <View style={styles.center}>
          <Text style={styles.muted}>You are paying</Text>
          <Text style={styles.amount}>{amount}</Text>
          <Text style={styles.merchant}>{preview.merchant.name}</Text>
          {preview.merchant.sector ? <Text style={styles.sector}>{preview.merchant.sector}</Text> : null}
        </View>
        <View style={styles.rows}>
          <Row label="Description" value={preview.description} />
          <Row label="Payee account" value={preview.merchant.account_uuid} mono />
          <Row label="Debited from" value={preview.payer.account_uuid} mono />
          <Row label="Your balance" value={money(preview.payer.balance_cents, preview.currency)} />
          <Row label="Expires" value={expiry(preview.expires_at)} />
          <Row label="Code" value={formatPaymentCode(preview.code)} mono />
        </View>
        {blocker ? (
          <Text style={styles.notice} testID="pay-blocker">
            {blocker}
          </Text>
        ) : null}
        {error ? (
          <Text style={styles.error} accessibilityRole="alert">
            {error}
          </Text>
        ) : null}
        <TouchableOpacity
          style={[styles.primary, (blocker || busy) && styles.disabled]}
          disabled={!!blocker || busy}
          onPress={() => confirm(preview)}
          accessibilityRole="button"
          accessibilityState={{ disabled: !!blocker || busy }}
          testID="pay-confirm"
        >
          {busy ? <ActivityIndicator color="#fff" /> : <Text style={styles.primaryText}>Pay {amount}</Text>}
        </TouchableOpacity>
        <TouchableOpacity style={styles.secondary} onPress={reset}>
          <Text style={styles.secondaryText}>Use a different code</Text>
        </TouchableOpacity>
      </View>
    );
  } else {
    content = (
      <View style={styles.card}>
        <Text style={styles.label}>Payment code</Text>
        <TextInput
          value={input}
          onChangeText={setInput}
          placeholder="KNK1 XXXX XXXX XXXX XXXX XXXX XXXX"
          autoCapitalize="characters"
          autoCorrect={false}
          multiline
          style={styles.input}
          testID="pay-code-input"
        />
        <Text style={styles.hint}>Paste the code the merchant sent you. Spaces and dashes are ignored.</Text>
        {error ? (
          <Text style={styles.error} accessibilityRole="alert">
            {error}
          </Text>
        ) : null}
        <TouchableOpacity
          style={[styles.primary, busy && styles.disabled]}
          disabled={busy}
          onPress={loadPreview}
          accessibilityRole="button"
          testID="pay-continue"
        >
          {busy ? <ActivityIndicator color="#fff" /> : <Text style={styles.primaryText}>Continue</Text>}
        </TouchableOpacity>
      </View>
    );
  }

  return (
    <View style={{ flex: 1 }}>
      <Header />
      <ScrollView contentContainerStyle={styles.container} keyboardShouldPersistTaps="handled">
        <Text style={styles.heading}>Pay</Text>
        <Text style={styles.intro}>
          Pay a merchant with your Kinko balance. Paste the payment code, check who gets paid and how much, then confirm.
        </Text>
        {content}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { padding: 20, paddingBottom: 40 },
  heading: { fontSize: 20, fontWeight: 'bold' },
  intro: { marginTop: 6, marginBottom: 16, color: '#6b7280', fontSize: 14 },
  card: { backgroundColor: '#fff', borderRadius: 16, padding: 18, gap: 12, shadowColor: '#000', shadowOpacity: 0.06, shadowRadius: 8, elevation: 2 },
  center: { alignItems: 'center' },
  label: { fontWeight: '600', fontSize: 14 },
  input: { borderWidth: 1, borderColor: '#e5e7eb', borderRadius: 12, padding: 12, minHeight: 64, fontFamily: 'monospace', fontSize: 15 },
  hint: { color: '#9ca3af', fontSize: 12 },
  error: { backgroundColor: '#FFF5F5', color: KINKO_RED, padding: 10, borderRadius: 10, fontSize: 14 },
  notice: { backgroundColor: '#f3f4f6', color: '#4b5563', padding: 10, borderRadius: 10, fontSize: 14 },
  primary: { backgroundColor: KINKO_RED, borderRadius: 12, paddingVertical: 14, alignItems: 'center', alignSelf: 'stretch' },
  primaryText: { color: '#fff', fontSize: 16, fontWeight: '700' },
  disabled: { opacity: 0.5 },
  secondary: { paddingVertical: 10, alignItems: 'center', alignSelf: 'stretch' },
  secondaryText: { fontWeight: '600', color: '#111827' },
  muted: { color: '#6b7280', fontSize: 14 },
  amount: { fontSize: 32, fontWeight: 'bold', marginVertical: 4 },
  merchant: { fontWeight: '700', fontSize: 15 },
  sector: { color: '#9ca3af', fontSize: 12, textTransform: 'capitalize' },
  rows: { borderTopWidth: 1, borderTopColor: '#f3f4f6' },
  row: { flexDirection: 'row', justifyContent: 'space-between', gap: 12, paddingVertical: 9, borderBottomWidth: 1, borderBottomColor: '#f3f4f6' },
  rowLabel: { color: '#6b7280', fontSize: 13 },
  rowValue: { flex: 1, textAlign: 'right', fontSize: 13, fontWeight: '600' },
  mono: { fontFamily: 'monospace', fontWeight: '400', fontSize: 11 },
  title: { fontSize: 18, fontWeight: 'bold', marginTop: 8 },
  small: { fontSize: 11, color: '#9ca3af', marginVertical: 8, textAlign: 'center' },
  successIcon: { width: 56, height: 56, borderRadius: 28, backgroundColor: '#dcfce7', alignItems: 'center', justifyContent: 'center' },
});
