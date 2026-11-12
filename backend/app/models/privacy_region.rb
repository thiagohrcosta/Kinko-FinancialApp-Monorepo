# Which privacy rules apply to a person, from their country and US state.
#
# Everyone gets the same rights (one flow for all users); the region only
# changes deadlines, notices and a few extras. See #81.
#
#   :eu            EEA, UK (UK GDPR) and Switzerland (FADP): GDPR rules
#   :us_ca         California: CCPA as amended by CPRA
#   :us_state_law  US states with a comprehensive privacy law in force
#   :us_other      the rest of the US (GLBA and federal rules only)
#   :other         every other country
#   :unknown       no country on file yet (users created before it was asked)
module PrivacyRegion
  REGIONS = %i[eu us_ca us_state_law us_other other unknown].freeze

  EEA = %w[AT BE BG CY CZ DE DK EE ES FI FR GR HR HU IE IS IT LI LT LU LV MT NL NO PL PT RO SE SI SK].freeze
  EUROPE = (EEA + %w[GB CH]).freeze

  # State => date its comprehensive privacy law took effect. California has
  # its own region. New laws pass every year: review this list each quarter.
  US_STATE_LAWS = {
    "VA" => Date.new(2023, 1, 1),  "CO" => Date.new(2023, 7, 1),  "CT" => Date.new(2023, 7, 1),
    "UT" => Date.new(2023, 12, 31), "TX" => Date.new(2024, 7, 1), "OR" => Date.new(2024, 7, 1),
    "MT" => Date.new(2024, 10, 1), "IA" => Date.new(2025, 1, 1),  "DE" => Date.new(2025, 1, 1),
    "NH" => Date.new(2025, 1, 1),  "NE" => Date.new(2025, 1, 1),  "NJ" => Date.new(2025, 1, 15),
    "TN" => Date.new(2025, 7, 1),  "MN" => Date.new(2025, 7, 31), "MD" => Date.new(2025, 10, 1),
    "IN" => Date.new(2026, 1, 1),  "KY" => Date.new(2026, 1, 1),  "RI" => Date.new(2026, 1, 1)
  }.freeze

  module_function

  def for(country:, state: nil, on: Date.current)
    country = country.to_s.strip.upcase
    state = state.to_s.strip.upcase

    return :unknown if country.blank?
    return :eu if EUROPE.include?(country)
    return :other unless country == "US"
    return :us_ca if state == "CA"

    effective = US_STATE_LAWS[state]
    effective && effective <= on ? :us_state_law : :us_other
  end
end
