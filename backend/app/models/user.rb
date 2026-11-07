class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :accounts, dependent: :destroy
  has_many :merchant_api_keys, dependent: :destroy
  has_one :webhook_endpoint, dependent: :destroy

  USER_TYPES = %w[individual business].freeze

  validates :email, presence: true, uniqueness: true
  validates :password, presence: true, length: { minimum: 6 }, if: :password_required?

  validates :full_name, presence: true
  validates :user_type, presence: true, inclusion: { in: USER_TYPES }
  validates :business_name, presence: true, if: :business?
  validates :business_sector, presence: true, if: :business?
  validates :address_street, presence: true
  validates :address_number, presence: true
  # Sign-up only: legacy users may have no neighborhood and must still be
  # saveable (e.g. Devise password reset).
  validates :address_neighborhood, presence: true, on: :create
  validates :address_city, presence: true
  validates :address_state, presence: true
  validates :address_zip_code, presence: true

  after_create :create_default_account

  def business?
    user_type == "business"
  end

  def primary_account
    accounts.order(:id).first
  end

  def display_name
    business? && business_name.present? ? business_name : full_name
  end

  private

  def password_required?
    new_record? || password.present? || password_confirmation.present?
  end

  def create_default_account
    Accounts::CreateAccount.new.call(user: self)
  end
end
