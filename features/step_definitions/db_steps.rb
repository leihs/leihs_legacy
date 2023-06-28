require_relative '../../database/spec/config/database'

Given(/^(?:the )database has only minimal seeds$/) do
  db_clean
  db_restore_data seeds_sql
end

Given(/^settings exist$/) do
  unless Setting.first
    FactoryBot.create(:setting)
  end
end
