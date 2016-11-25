if Rails.env.development? and ENV['TEST_DATETIME']
  require File.join(Rails.root, 'features/support/dataset.rb')
  PgTasks.truncate_tables()
  Dataset.restore_random_dump('normal')
end
