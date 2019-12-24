Given(/^there are at least (\d+) users with late take backs from at least (\d+) inventory pools where automatic suspension is activated$/) do |users_n, ips_n|
  @reservations = Reservation.signed.where('end_date < ?', Date.today).distinct { |cl| cl.inventory_pool and cl.user }
  expect(@reservations.count).to be >= 2
end

When(/^the cronjob executes the rake task for reminding and suspending all late users$/) do
  User.remind_and_suspend_all
end

Then(/^every such user is suspended in the corresponding inventory pool$/) do
  @reservations.each do |c|
    ip = c.inventory_pool
    u = c.user
    suspension = Suspension.find_by(user: u, inventory_pool: ip)
    expect(suspension).to be
    expect(suspension.suspended_until).to be>= Date.today
  end
end

Then(/^the suspended reason is the one configured for the corresponding inventory pool$/) do
  @reservations.each do |c|
    ip = c.inventory_pool
    u = c.user
    ar = u.access_right_for(ip)
    ar.suspended_reason == ip.automatic_suspension_reason
  end
end


Then(/^a user with login "(.*?)" exists$/) do |arg1|
  @user = User.find_by(login: arg1)
  expect(@user).not_to be nil
end

Then(/^the login of this user is longer than (\d+) chars$/) do |arg1|
  expect(@user.login.size).to be > 40
end

Given(/^the following users exist$/) do |table|
  hashes_with_evaled_and_nilified_values(table).each do |hash_row|

    attrs = {language: Language.find_by_locale_name(hash_row['language']),
             firstname: hash_row['firstname'],
             lastname: hash_row['lastname'],
             login: hash_row['login'] || hash_row['firstname'].downcase,
             email: hash_row['email'],
             address: hash_row['address']}

    FactoryGirl.create(:user, attrs)
  end
end
