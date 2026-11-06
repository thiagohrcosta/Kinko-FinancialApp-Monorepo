#!/usr/bin/env rails runner
# Cria (ou recria) um usuário de teste com lançamentos nos últimos 30 dias.
# Uso: bin/rails runner create_user_with_transactions.rb

user = User.find_or_initialize_by(email: 'test_with_balance@kinko.com')
user.assign_attributes(
  full_name: 'Test User With Balance',
  user_type: 'individual',
  document_number: '98765432199',
  phone_number: '11987654321',
  address_street: 'Test Avenue',
  address_number: '999',
  address_neighborhood: 'Bela Vista',
  address_city: 'São Paulo',
  address_state: 'SP',
  address_zip_code: '01310-100',
  password: 'password123',
  password_confirmation: 'password123'
)
user.save!

# A conta padrão é criada no after_create do User
account = user.accounts.first || Accounts::CreateAccount.new.call(user: user)

# Recomeça do zero para o resultado ser previsível
LedgerEntry.where(account: account).delete_all

puts "═" * 60
puts "✓ User created/updated:"
puts "  Email: #{user.email}"
puts "  ID: #{user.id}"
puts "  Name: #{user.full_name}"
puts "  Account UUID: #{account.uuid}"
puts ""

# Renda: 5 lançamentos de crédito
puts "Adding income transactions (credit entries)..."
incomes = 5.times.map do |i|
  amount = (100 + (i * 50)) * 100 # em centavos
  date = (25 - i).days.ago

  LedgerEntry.create!(
    account: account,
    amount_cents: amount,
    currency: 'USD',
    entry_type: :credit,
    description: "Salary deposit #{i + 1}",
    created_at: date,
    updated_at: date
  )

  puts "  ✓ Added $#{amount / 100.0} income"
  amount
end

# Despesas: 3 lançamentos de débito
puts ""
puts "Adding expense transactions (debit entries)..."
expenses = 3.times.map do |i|
  amount = (50 + (i * 25)) * 100 # em centavos
  date = (20 - i).days.ago

  LedgerEntry.create!(
    account: account,
    amount_cents: amount,
    currency: 'USD',
    entry_type: :debit,
    description: "Purchase #{i + 1}",
    created_at: date,
    updated_at: date
  )

  puts "  ✓ Added $#{amount / 100.0} expense"
  amount
end

income_total = incomes.sum / 100.0
expense_total = expenses.sum / 100.0

puts ""
puts "═" * 60
puts "✓ Test user fully set up!"
puts ""
puts "LOGIN CREDENTIALS:"
puts "  Email:    test_with_balance@kinko.com"
puts "  Password: password123"
puts ""
puts "EXPECTED BALANCE (last 30 days):"
puts "  Income:    $#{income_total}"
puts "  Expenses:  $#{expense_total}"
puts "  Balance:   $#{income_total - expense_total}"
puts ""
puts "═" * 60
