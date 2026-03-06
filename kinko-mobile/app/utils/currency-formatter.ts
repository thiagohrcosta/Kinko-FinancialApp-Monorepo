export default function formatCurrency(value: number): string {
  return new Intl.NumberFormat('us', {
    style: 'currency',
    currency: 'USD',
  }).format(value);
}