module Payments
  # One-off correction for #12. Before the fix, every card deposit credited the
  # system account instead of debiting it, so its balance grew by twice each
  # deposit in the wrong direction. The ledger is append-only, so each wrong leg
  # is corrected with a new entry: a debit of twice its amount (reverses the
  # credit and posts the debit it should have been).
  #
  # Idempotent: a leg already corrected has an entry with reference
  # "fix-12:<original reference>", and that reference is unique per account.
  #
  #   bin/rails ledger:correct_deposit_legs           # dry run: what would change
  #   APPLY=1 bin/rails ledger:correct_deposit_legs   # write the corrections
  class CorrectDepositLegs
    WRONG_DESCRIPTION = "Card Payment Processed".freeze
    REFERENCE_PREFIX = "fix-12:".freeze

    Result = Struct.new(:legs, :amount_cents, keyword_init: true)

    def call(apply: false)
      AccountRepository.with_locked(DepositService::SYSTEM_ACCOUNT_UUID) do |system_account|
        legs = uncorrected_legs
        if apply
          legs.each do |leg|
            system_account.debit!(Accounts::Money.new(leg.amount_cents * 2, leg.currency),
                                  description: "Correction (#12): card deposit was credited instead of debited",
                                  reference: "#{REFERENCE_PREFIX}#{leg.reference}", allow_negative: true)
          end
        end

        Result.new(legs: legs.size, amount_cents: legs.sum(&:amount_cents))
      end
    end

    private
      def uncorrected_legs
        entries = ::Account.find_by!(uuid: DepositService::SYSTEM_ACCOUNT_UUID).ledger_entries
        wrong = entries.where(entry_type: "credit", description: WRONG_DESCRIPTION).where.not(reference: nil).order(:id).to_a
        corrected = entries.where(reference: wrong.map { |leg| "#{REFERENCE_PREFIX}#{leg.reference}" }).pluck(:reference)

        wrong.reject { |leg| corrected.include?("#{REFERENCE_PREFIX}#{leg.reference}") }
      end
  end
end
