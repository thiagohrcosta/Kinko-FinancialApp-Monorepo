namespace :ledger do
  desc "Correct card deposits that credited the system account instead of debiting it (#12). APPLY=1 to write."
  task correct_deposit_legs: :environment do
    apply = ENV["APPLY"] == "1"
    result = Payments::CorrectDepositLegs.new.call(apply: apply)
    amount = format("%.2f", result.amount_cents / 100.0)

    if apply
      puts "Corrected #{result.legs} deposit legs (#{amount} deposited)."
    else
      puts "Dry run: #{result.legs} deposit legs to correct (#{amount} deposited). Run with APPLY=1 to write."
    end
  end
end
