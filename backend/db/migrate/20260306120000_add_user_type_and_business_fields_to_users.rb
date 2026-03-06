class AddUserTypeAndBusinessFieldsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :user_type, :string, null: false, default: 'individual'
    add_column :users, :business_name, :string
    add_column :users, :business_sector, :string

    add_index :users, :user_type
    add_index :users, :business_sector
  end
end
