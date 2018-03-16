Given(/^(?:the )database is empty$/) do
  PgTasks.truncate_tables
end

Given(/^settings exist$/) do
  unless Setting.first
    FactoryGirl.create(:setting)
  end
  unless SystemSetting.first
     FactoryGirl.create(:system_setting)
  end
end
