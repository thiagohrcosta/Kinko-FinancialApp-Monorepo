module Payments
  class DepositService
    SYSTEM_ACCOUNT_UUID = ENV.fetch("SYSTEM_ACCOUNT_UUID")

    def initialize(account_repository:)
      @account_repository = account_repository
    end

    def call(account_uuid:, amount_cents:)
      user_account   = @account_repository.load(account_uuid)
      system_account = @account_repository.load(SYSTEM_ACCOUNT_UUID)

      money = Accounts::Money.new(amount_cents, "USD")

      # Usar descrições mais amigáveis
      user_description = "Deposit from Card Payment"
      system_description = "Card Payment Processed"

      user_account.credit!(money, description: user_description)
      system_account.credit!(money, description: system_description)

      ActiveRecord::Base.transaction do
        @account_repository.save(user_account)
        @account_repository.save(system_account)
      end

      # Notificar o usuário em tempo real via WebSocket
      notify_deposit(account_uuid, amount_cents)
    end

    private

    def notify_deposit(account_uuid, amount_cents)
      # Encontrar o usuário que possui essa conta
      user = Account.find_by!(uuid: account_uuid).user

      # Enviar notificação via ActionCable
      ActionCable.server.broadcast(
        "notifications:user:#{user.id}",
        {
          type: "balance_updated",
          account_uuid: account_uuid,
          amount_cents: amount_cents,
          timestamp: Time.current.iso8601
        }
      )

      Rails.logger.info("✓ Deposit notification sent to user:#{user.id}")
    rescue => e
      Rails.logger.error("Failed to send deposit notification: #{e.message}")
      # Não falha o depósito se a notificação falhar
    end
  end
end
