namespace :leihs do
  namespace :dbio do
    desc 'Export the database content into a RDBMS independent dump;' \
      ' FILE=tmp/db_data.yml'
    task export: :environment do
      Leihs::DBIO.export ENV['FILE'].presence
    end

    desc 'Import the RDBMS independent dump into PostgreSQL;' \
      ' FILE=tmp/db_data.yml'
    task import: :environment do
      Leihs::DBIO::Import.import ENV['FILE'].presence
    end

    desc 'Restore a legacy personas MySQL dump; DATASET=minimal|normal|huge'
    task restore_legacy: :environment do
      load 'features/support/dataset.rb'
      Dataset.restore_random_dump(ENV['DATASET'].presence || 'normal')
    end
  end
end
