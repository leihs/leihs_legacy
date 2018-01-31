Given(/^a settings object$/) do
  @setting = Setting.first
  @setting ||= Setting.create({local_currency_string: 'GBP',
                               email_signature: 'kthxbye',
                               default_email: 'from@example.com'})
end

Given(/^the settings are existing$/) do
  FactoryGirl.create :setting unless Setting.first
end

When(/^the settings are not existing$/) do
  Setting.delete_all
  expect(Setting.count.zero?).to be true
end

Then(/^there is an error for the missing settings$/) do
  expect { step 'I go to the home page' }.to raise_error(RuntimeError)
end

