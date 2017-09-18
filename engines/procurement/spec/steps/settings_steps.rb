require_relative 'shared/common_steps'
require_relative 'shared/navigation_steps'
require_relative 'shared/personas_steps'

steps_for :settings do
  include CommonSteps
  include NavigationSteps
  include PersonasSteps

  step 'a contact form exists' do
    @contact_url = Faker::Internet.url
  end

  step 'I enter the following settings' do |table|
    @settings_key_value = table.hashes.map { |h| [h['key'], h['value']] }.to_h
    within 'form table tbody' do
      @settings_key_value.each do |key, val|
        find("input[name=\"settings[#{key}]\"]").set val
      end
    end
  end

  # NOTE: could also be a generic form step
  step 'I enter the following text in the field :label_text' do |label_text, text|
    within 'form table tbody' do
      label = find('label', text: label_text)
      input = label.all('input, textarea').first || find('#' + label[:for])
      input.set text
    end
  end

  step 'the settings are saved successfully to the database' do
    expect(Procurement::Setting.count).to be 1

    setting = Procurement::Setting.first
    @settings_key_value.each_pair do |key, val|
      expect(setting[key]).to eq val
    end
  end

  step 'these settings are saved in the database as listed' do |table|
    settings = Procurement::Setting.first
    table.rows_hash.except('key').each do |key, val|
      expect(settings[key].to_json).to eq val
    end

  end

  step 'the contact link is visible' do
    within 'header ul.nav.h4' do
      link = find('a', text: _('Contact'))
      expect(link[:href]).to eq @settings_key_value['contact_url']
    end
  end

end
