module GatewayHelpers
  def jwt_headers(user)
    { "Authorization" => "Bearer #{JsonWebToken.encode(user_id: user.id)}" }
  end

  def api_key_headers(key)
    { "Authorization" => "Bearer #{key.plain_token}" }
  end

  def fund(user, cents)
    create(:ledger_entry_record, account_record: user.primary_account, amount_cents: cents)
  end

  def balance_of(user)
    AccountRepository.load(user.primary_account.uuid).balance
  end

  def json
    JSON.parse(response.body)
  end
end

RSpec.configure do |config|
  config.include GatewayHelpers
  config.include ActiveJob::TestHelper
end
