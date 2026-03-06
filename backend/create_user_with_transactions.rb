#!/usr/bin/env rails runner

# Script para criar usuário de teste com transações
user = User.find_or_create_by!(email: 'test_with_balance@kinko.com') do |u|
  u.full_name = 'Test User With Balance'
  u.document_number = '98765432199'
  u.phone_number = '11987654321'
  u.address_number = '999'
  u.address_street = 'Test Avenue'
  u.address_city = 'São Paulo'
  u.address_state = 'SP'
  u.address_zip_code = '01310-100'
  u.password = 'password123'
  u.password_confirmation = 'password123'
end

# Criar conta para o usuário
account = user.accounts.first_or_create!(
  uuid: SecureRandom.uuid,
  status: 'active'
)

puts "═" * 60
puts "✓ User created/updated:"
puts "  Email: #{user.email}"
puts "  ID: #{user.id}"
puts "  Name: #{user.full_name}"
puts "  Account UUID: #{account.uuid}"
puts ""

# Adicionar transações de exemplo dos últimos 30 dias
# Renda: 5 transações de crédito
puts "Adding income transactions (credit entries)..."
5.times do |i|
  amount = (100 + (i * 50)) * 100  # em centavos
  date = (25 - i).days.ago

  LedgerEntry.create!(
    account: account,
    amount_cents: amount,
    entry_type: :credit,
    description: "Salary deposit #{i + 1}",
    created_at: date,
    updated_at: date
  )

  puts "  ✓ Added R$ #{amount / 100.0} income"
end

# Despesas: 3 transações de débito
puts ""
puts "Adding expense transactions (debit entries)..."
3.times do |i|
  amount = (50 + (i * 25)) * 100  # em centavos
  date = (20 - i).days.ago

  LedgerEntry.create!(
    account: account,
    amount_cents: amount,
    entry_type: :debit,
    description: "Purchase #{i + 1}",
    created_at: date,
    updated_at: date
  )

  puts "  ✓ Added R$ #{amount / 100.0} expense"
end

puts ""
puts "═" * 60
puts "✓ Test user fully set up!"
puts ""
puts "LOGIN CREDENTIALS:"
puts "  Email:    test_with_balance@kinko.com"
puts "  Password: password123"
puts ""
puts "EXPECTED BALANCE (last 30 days):"
income_total = (100 + 150 + 200 + 250 + 300) / 100.0
expense_total = (50 + 75 + 100) / 100.0
balance_total = income_total - expense_total
puts "  Income:    R$ #{income_total}"
puts "  Expenses:  R$ #{expense_total}"
puts "  Balance:   R$ #{balance_total}"
puts ""
puts "═" * 60
