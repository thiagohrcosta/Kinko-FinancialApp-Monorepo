class WebhookEvent < ApplicationRecord
  validates :event_id, presence: true, uniqueness: true

  # Registra o evento e retorna true só na primeira vez que ele é visto.
  # `create!` é necessário: `create` engole a falha de unicidade (RecordInvalid
  # não é lançado) e faria um reenvio do Stripe creditar o depósito duas vezes.
  # RecordNotUnique cobre a corrida entre duas entregas simultâneas (índice único).
  def self.process_once(event_id)
    create!(event_id: event_id, status: "processing")
    true
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    false
  end
end
