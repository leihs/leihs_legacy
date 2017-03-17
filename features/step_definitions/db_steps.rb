Given(/^(?:the )database is empty$/) do
  PgTasks.truncate_tables
end

Given(/^settings exist$/) do
  unless Setting.first
    FactoryGirl.create(:setting)
  end
end
