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
      Leihs::DBIO::Import.import \
        ENV['FILE'].presence,
        attachments_path: ENV['ATTACHMENTS_PATH'].presence,
        images_path: ENV['IMAGES_PATH'].presence,
        procurement_attachments_path: ENV['PROCUREMENT_ATTACHMENTS_PATH'].presence,
        procurement_images_path: ENV['PROCUREMENT_IMAGES_PATH'].presence
    end

    desc 'Restore a legacy personas MySQL dump'
    task restore_legacy: :environment do
      load 'features/support/dataset.rb'
      Dataset.restore_dump
    end
  end
end
