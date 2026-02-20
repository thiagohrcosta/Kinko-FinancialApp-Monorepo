class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :accounts, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :password, presence: true, length: { minimum: 6 }, if: :password_required?

  validates :full_name, presence: true
  validates :address_street, presence: true
  validates :address_number, presence: true
  validates :address_city, presence: true
  validates :address_state, presence: true
  validates :address_neighborhood, presence: true
  validates :address_zip_code, presence: true

  after_create :create_default_account

  private

  def password_required?
    new_record? || password.present? || password_confirmation.present?
  end

  def create_default_account
    Accounts::CreateAccount.new.call(user: self)
  end

end