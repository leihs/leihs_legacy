module Dataset
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

  def restore_random_dump(dataset)
    use_test_datetime
    PgTasks.truncate_tables
    PgTasks.data_restore dump_file_name(dataset)
    ActiveRecord::Base.connection.execute 'UPDATE settings SET logo_url = NULL;'
  end

  def use_test_datetime(reset: false, freeze: false)
    if freeze
      ENV['TIMECOP_MODE'] = 'freeze'
      Timecop.return
    end

    get_test_datetime(reset)

    test_datetime = ENV['TEST_DATETIME'].gsub(/\D/, '').to_i
    srand(test_datetime)

    back_to_date(Time.parse(ENV['TEST_DATETIME']))
    puts "\n        ------------------------- TEST_DATETIME=#{ENV['TEST_DATETIME']} -------------------------"
  end

  def dump_file_name(dataset)
    s = case dataset
        when 'minimal'
          'minimal.pgbin'
        when 'normal'
          get_test_datetime
          "normal_#{ENV['TEST_DATETIME']}.pgbin"
        when 'huge'
          get_test_datetime
          "huge_#{ENV['TEST_DATETIME']}.pgbin"
        else
          raise
        end
    File.join(Rails.root, 'features/personas/dumps', s)
  end

  private

  def get_test_datetime(reset = false)
    ENV['TEST_DATETIME'] = if not ENV['TEST_DATETIME'].blank? and not reset
                             ENV['TEST_DATETIME']
                           else
                             '2018-06-27T13:10:15+02:00'
                           end
  end

end
