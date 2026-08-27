# Idempotent seed data for local development and demos.

def upsert_user!(attrs)
  email = attrs.fetch(:email)
  user = User.find_or_initialize_by(email: email)
  user.assign_attributes(attrs)
  user.save!
  user
end

seed_password = 'password123'

upsert_user!(
  email: 'admin@kinko.com',
  full_name: 'Kinko Admin',
  user_type: 'individual',
  document_number: '12345678900',
  phone_number: '11999999999',
  address_number: '123',
  address_street: 'Main Street',
  address_neighborhood: 'Downtown',
  address_city: 'Sao Paulo',
  address_state: 'SP',
  address_zip_code: '01001000',
  password: seed_password,
  password_confirmation: seed_password
)

upsert_user!(
  email: 'procurement@kinko.com',
  full_name: 'Kinko Procurement',
  user_type: 'individual',
  document_number: '98765432100',
  phone_number: '11988887777',
  address_number: '500',
  address_street: 'Paulista Avenue',
  address_neighborhood: 'Business District',
  address_city: 'Sao Paulo',
  address_state: 'SP',
  address_zip_code: '01311000',
  password: seed_password,
  password_confirmation: seed_password
)

adjectives = [
  'Amber', 'Atlas', 'Aurora', 'Blue', 'Bold', 'Bright', 'Cedar', 'Central', 'Classic', 'Coastal',
  'Copper', 'Crown', 'Crystal', 'Delta', 'Eagle', 'East', 'Emerald', 'Evergreen', 'First', 'Golden',
  'Grand', 'Green', 'Harbor', 'Highland', 'Horizon', 'Imperial', 'Iron', 'Ivory', 'Jade', 'Liberty',
  'Lighthouse', 'Lucky', 'Maple', 'Metro', 'Modern', 'Noble', 'North', 'Nova', 'Oak', 'Pacific',
  'Peak', 'Pioneer', 'Prime', 'River', 'Royal', 'Silver', 'Sky', 'South', 'Summit', 'Sunrise',
  'Sunset', 'Swift', 'Urban', 'Valley', 'Velvet', 'Victory', 'West', 'White', 'Willow', 'Zenith'
]

sector_kinds = {
  'Food & Beverage' => [
    'Bakery', 'Coffee House', 'Cafe', 'Pizzeria', 'Burger Shop', 'Sandwich Bar', 'Pastry Shop',
    'Juice Bar', 'Tea House', 'Brunch Spot', 'Steakhouse', 'Seafood Grill', 'Bistro', 'Deli',
    'Butcher Shop', 'Produce Market', 'Organic Market', 'Snack Bar', 'Ice Cream Shop', 'Food Market'
  ],
  'Retail' => [
    'Supermarket', 'Grocery Store', 'Neighborhood Grocery', 'Convenience Store', 'Beverage Store',
    'Wine Shop', 'Liquor Store', 'Household Shop', 'General Store', 'Farmers Market'
  ],
  'Automotive' => [
    'Auto Garage', 'Car Wash', 'Tire Center', 'Auto Parts', 'Body Shop', 'Car Detailing',
    'Auto Electric', 'Car Dealer', 'Motor Service', 'Quick Lube'
  ],
  'Logistics' => [
    'Delivery Hub', 'Freight Service', 'Courier Center', 'Cold Chain Logistics', 'Cargo Solutions'
  ],
  'Technology' => [
    'Software Studio', 'Cloud Systems', 'IT Services', 'Digital Solutions', 'Data Labs'
  ],
  'Healthcare' => [
    'Medical Clinic', 'Dental Care', 'Lab Services', 'Pharmacy', 'Health Center'
  ],
  'Professional Services' => [
    'Accounting Group', 'Legal Advisory', 'HR Solutions', 'Business Consulting', 'Audit Partners'
  ],
  'Hospitality' => [
    'Hotel', 'Hostel', 'Inn', 'Event Hall', 'Travel Lodge'
  ],
  'Education' => [
    'Learning Center', 'Language School', 'Training Institute', 'Tutoring Hub', 'Music School'
  ],
  'Construction' => [
    'Builders', 'Engineering Works', 'Concrete Services', 'Renovation Co', 'Steel Structures'
  ]
}

target_partners = 200
ordered_sectors = [
  'Food & Beverage', 'Retail', 'Food & Beverage', 'Retail', 'Food & Beverage',
  'Automotive', 'Food & Beverage', 'Retail', 'Technology', 'Logistics',
  'Healthcare', 'Professional Services', 'Hospitality', 'Education', 'Construction'
]

target_partners.times do |index|
  sector = ordered_sectors[index % ordered_sectors.size]
  kinds = sector_kinds.fetch(sector)
  adjective = adjectives[index % adjectives.size]
  kind = kinds[(index / 2) % kinds.size]
  company_id = index + 1
  name = "#{adjective} #{kind} #{format('%03d', company_id)}"

  upsert_user!(
    email: format('partner%03d@kinko-partners.com', company_id),
    full_name: "Owner #{name}",
    user_type: 'business',
    business_name: name,
    business_sector: sector,
    document_number: format('%014d', 55_000_111_000_100 + company_id),
    phone_number: format('119700%05d', company_id),
    address_number: (100 + company_id).to_s,
    address_street: 'Enterprise Avenue',
    address_neighborhood: 'Commercial Center',
    address_city: 'Sao Paulo',
    address_state: 'SP',
    address_zip_code: format('04567%03d', index % 999),
    password: seed_password,
    password_confirmation: seed_password
  )

  puts "Partners processed: #{company_id}/#{target_partners}" if (company_id % 25).zero?
end

GOALS = [
  { key: "save_more_money",             name_pt: "Economizar mais dinheiro todo mês",           name_en: "Save more money each month",            icon: "piggy-bank" },
  { key: "cut_recurring_subscriptions", name_pt: "Parar de pagar assinaturas que não uso",      name_en: "Cut recurring subscriptions I don't use", icon: "repeat" },
  { key: "reduce_impulse_spending",     name_pt: "Reduzir compras por impulso",                 name_en: "Reduce impulse spending",               icon: "zap-off" },
  { key: "build_emergency_fund",        name_pt: "Criar uma reserva de emergência",             name_en: "Build an emergency fund",               icon: "shield" },
  { key: "pay_off_debt",                name_pt: "Quitar dívidas mais rápido",                  name_en: "Pay off debt faster",                   icon: "trending-down" },
  { key: "maximize_investments",        name_pt: "Investir mais / maximizar retorno",           name_en: "Maximize investments",                  icon: "trending-up" },
  { key: "reduce_dining_delivery",      name_pt: "Gastar menos com delivery/restaurante",       name_en: "Reduce dining out & delivery spending", icon: "coffee" },
  { key: "plan_big_purchase",           name_pt: "Planejar e guardar para uma compra grande",   name_en: "Plan and save for a big purchase",      icon: "target" },
  { key: "spending_awareness",          name_pt: "Só quero entender pra onde vai meu dinheiro", name_en: "Gain overall spending awareness",       icon: "eye" },
  { key: "increase_savings_rate",       name_pt: "Aumentar o percentual que guardo da renda",   name_en: "Increase my savings rate",              icon: "percent" }
].freeze

GOALS.each_with_index do |attrs, index|
  FinancialGoal.find_or_create_by!(key: attrs[:key]) do |goal|
    goal.name_pt = attrs[:name_pt]
    goal.name_en = attrs[:name_en]
    goal.icon = attrs[:icon]
    goal.position = index
    goal.active = true
  end
end

puts "Seed completed: #{User.count} users and #{Account.count} accounts."
puts "Business partners created/updated: #{target_partners}."
