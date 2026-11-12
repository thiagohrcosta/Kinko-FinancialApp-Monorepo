class AddAddressCountryToUsers < ActiveRecord::Migration[8.1]
  def change
    # ISO 3166-1 alpha-2. Nullable: users created before this column are
    # asked for their country on their next visit.
    add_column :users, :address_country, :string, limit: 2
  end
end
