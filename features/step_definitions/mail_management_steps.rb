Given "{string}'s email address is {string}" do |name, email|
  u = User.find_by_login(name)
  u.update(email: email)
  #u.language = Language.default_language.id # should run with default lang...
  u.save
end

Then '{string} receives an email' do |email|
  expect(ActionMailer::Base.deliveries.size).to eq 1
  @mail = ActionMailer::Base.deliveries[0]  
  # ActiveMailer upcases the first letter?!
  expect(@mail.to[0].downcase).to eq email.downcase
  ActionMailer::Base.deliveries.clear
end

Then "its subject is {string}" do |subject|
  expect(@mail.subject).to eq subject
end

Then "it contains information {string}" do |line|
  expect(@mail.body).to match(Regexp.new(line))
end
