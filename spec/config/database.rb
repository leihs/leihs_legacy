module Config
  module Database
    extend self

    def dbname
      ENV['LEIHS_DATABASE_NAME'].presence or 'leihs_test'
    end

    def restore_seeds
      system("LEIHS_DATABASE_NAME=#{dbname} ./database/scripts/restore-seeds")
    end
  end
end
