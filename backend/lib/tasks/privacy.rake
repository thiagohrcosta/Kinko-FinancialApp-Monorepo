namespace :privacy do
  desc "Regenerate docs/privacy/data-inventory.md from config/personal_data.yml"
  task inventory: :environment do
    PersonalData.write_doc!
    puts "Updated #{PersonalData::DOC_PATH.cleanpath}"
  end
end
