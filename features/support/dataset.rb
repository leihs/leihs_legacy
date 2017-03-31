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
    PgTasks.truncate_tables
    dump_file = File.join(Rails.root, 'features/personas/personas.pgbin')
    PgTasks.data_restore dump_file
    ActiveRecord::Base.connection.execute 'UPDATE settings SET logo_url = NULL;'
  end

  def use_test_datetime
    ENV['TEST_DATETIME'] = TEST_DATETIME

    test_datetime = TEST_DATETIME.gsub(/\D/, '').to_i
    srand(test_datetime)

    back_to_date(Time.parse(TEST_DATETIME))
    puts "\n        ------------------------- TEST_DATETIME=#{TEST_DATETIME} -------------------------"
  end
end
