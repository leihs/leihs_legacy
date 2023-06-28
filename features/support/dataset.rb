require_relative '../../database/spec/config/database'

module Dataset
  ###########################################
  # NOTE: don't change! this was used while
  # creating the personas dump
  TEST_DATETIME = '2018-06-27T13:10:15+02:00'
  ###########################################

  extend self

  def back_to_date(datetime = nil)
    if datetime
      mode = ENV['TIMECOP_MODE'] || :travel
      Timecop.send(mode, datetime)
    else
      if ENV['TEST_DATETIME']
        back_to_date(Time.parse(ENV['TEST_DATETIME']))
      else
        Timecop.return
      end
    end
  end

  def restore_dump
    use_test_datetime
    db_clean
    db_restore_data personas_sql
    ApplicationRecord.connection.execute 'UPDATE settings SET logo_url = NULL;'
    ApplicationRecord.connection.execute 'UPDATE smtp_settings SET enabled = TRUE;'
    ApplicationRecord.connection.execute 'ALTER TABLE emails DISABLE TRIGGER delete_old_emails_t;'
  end

  def use_test_datetime
    ENV['TEST_DATETIME'] = TEST_DATETIME

    test_datetime = TEST_DATETIME.gsub(/\D/, '').to_i
    srand(test_datetime)

    back_to_date(Time.parse(TEST_DATETIME))
    puts "\n        ------------------------- TEST_DATETIME=#{TEST_DATETIME} -------------------------"
  end
end
