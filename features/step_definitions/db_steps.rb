require "./spec/config/database.rb"

Given(/^(?:the )database has only minimal seeds$/) do
  PgTasks.truncate_tables
  Config::Database.restore_seeds
end

Given(/^settings exist$/) do
  unless Setting.first
    FactoryBot.create(:setting)
  end
end
