module LanguageFactory
  module_function

  def create
    languages = [{ name: 'Deutsch', locale: 'de-CH' },
                 { name: 'English (UK)', locale: 'en-GB' },
                 { name: 'English (US)', locale: 'en-US' }]
    languages.delete_if { |l| Language.find_by_locale(l[:locale]) }
    if languages.empty?
      Language.first
    else
      FactoryGirl.create(:language,
                         name: languages.first[:name],
                         locale: languages.first[:locale])
    end
  end

end

FactoryGirl.define do

  factory :language do
    active { true }
    name { Faker::Lorem.words(number: 1).join }
    locale{ name[0..1].downcase }
    default { Language.find_by_default(true).blank? }
  end

end
