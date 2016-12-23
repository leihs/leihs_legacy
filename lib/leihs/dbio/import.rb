module Leihs
  module DBIO
    module Import
      class << self

        LEIHS_UUID_NS = UUIDTools::UUID.sha1_create UUIDTools::UUID.parse_int(0), "leihs"

        IGNORED_TABLES = %w(audits schema_migrations)

        TABLES = %w(
          languages
          authentication_systems

          users
          delegations_users
          database_authentications

          fields
          hidden_fields

          addresses
          inventory_pools
          workdays
          options
          holidays
          access_rights

          models
          models_compatibles
          accessories
          accessories_inventory_pools
          properties
          suppliers
          buildings
          locations
          items
          groups
          groups_users
          model_groups
          inventory_pools_model_groups
          model_links
          model_group_links
          partitions

          purposes
          contracts
          reservations

          images
          mail_templates
          numerators
          settings
          attachments

          procurement_organizations
          procurement_main_categories
          procurement_accesses
          procurement_budget_periods
          procurement_budget_limits
          procurement_categories
          procurement_category_inspectors
          procurement_templates
          procurement_requests
          procurement_attachments
          procurement_settings

          notifications
          audits
        )

        FOREIGN_TABLE_RESOLVERS = (YAML.load <<-YML.strip_heredoc
          delegations_users:
            delegation_id: users
          items:
            owner_id: inventory_pools
            parent_id: items
          images:
            parent_id: images
          models_compatibles:
            compatible_id: models
          reservations:
            handed_over_by_user_id: users
            delegated_user_id: users
            returned_to_user_id: users
          users:
            delegator_user_id: users
          procurement_accesses:
            organization_id: procurement_organizations
          procurement_attachments:
            request_id: procurement_requests
          procurement_budget_limits:
            main_category_id: procurement_main_categories
            budget_period_id: procurement_budget_periods
          procurement_categories:
            main_category_id: procurement_main_categories
          procurement_category_inspectors:
            category_id: procurement_categories
          procurement_requests:
            organization_id: procurement_organizations
            budget_period_id: procurement_budget_periods
            category_id: procurement_categories
            template_id: procurement_templates
          procurement_templates:
            category_id: procurement_categories
          procurement_organizations:
            parent_id: procurement_organizations
        YML
        ).with_indifferent_access


        def reload!
          load File.absolute_path(__FILE__)
        end

        def map_model_group_link row
          begin
            unless row['direct']
              nil
            else
              table_uuid_ns = UUIDTools::UUID.sha1_create LEIHS_UUID_NS, 'model_group_links'
              ref_table_uuid_ns = UUIDTools::UUID.sha1_create LEIHS_UUID_NS, 'model_groups'
              {id: UUIDTools::UUID.sha1_create(table_uuid_ns, row[:id].to_s),
               parent_id: UUIDTools::UUID.sha1_create(ref_table_uuid_ns, row[:ancestor_id].to_s),
               child_id: UUIDTools::UUID.sha1_create(ref_table_uuid_ns, row[:descendant_id].to_s),
               label: row[:label]}
            end
          rescue
            binding.pry
          end
        end

        def map_audit_row row
          ref_table = row[:auditable_type].pluralize.underscore
          ref_table_uuid_ns = UUIDTools::UUID.sha1_create LEIHS_UUID_NS, ref_table
          auditable_id = UUIDTools::UUID.sha1_create(ref_table_uuid_ns, row[:auditable_id].to_s)
          row.merge({auditable_id: auditable_id})
        end

        def map_images_row row
          ref_table = row[:target_type].underscore.pluralize
          ref_table_uuid_ns = UUIDTools::UUID.sha1_create LEIHS_UUID_NS, ref_table
          target_id = UUIDTools::UUID.sha1_create(ref_table_uuid_ns, row[:target_id].to_s)
          row.merge({target_id: target_id})
        end

        def map_hiddden_field_row row
          unless LeihsDBIOImportFields.where(id: row[:field_id]).first
            Rails.logger.warn "Discarding hidden_filed #{row} because its field row does not exist"
            nil
          else
            row
          end
        end

        def add_position_to_partition row
          row.merge(position: row.id)
        end

        def custom_pre_migrator table_name, row
          case table_name
          when 'model_group_links'
            map_model_group_link row
          when 'audits'
            map_audit_row row
          when 'images'
            map_images_row row
          when 'hidden_fields'
            map_hiddden_field_row row
          when 'partitions'
            add_position_to_partition row
          else
            row
          end
        end

        def general_migrator table_name, row
          table_uuid_ns = UUIDTools::UUID.sha1_create LEIHS_UUID_NS, table_name.to_s

          row.map do|k,v|
            begin
              if k.to_s == 'id' and v.is_a? Integer
                [k, UUIDTools::UUID.sha1_create(table_uuid_ns, v.to_s)]
              elsif k.to_s =~ /_id$/ and v.is_a? Integer
                ref_table_name = FOREIGN_TABLE_RESOLVERS[table_name].try(:[],k) \
                  ||  k.gsub(/_id$/,'').pluralize
                ref_table_uuid_ns = UUIDTools::UUID.sha1_create LEIHS_UUID_NS, ref_table_name
                [k, UUIDTools::UUID.sha1_create(ref_table_uuid_ns, v.to_s)]
              else
                [k,v]
              end
            rescue
              binding.pry
            end
          end.to_h
        end

        def convert table_name, rows
          rows.map{|row| custom_pre_migrator(table_name, row)} \
            .compact.map{ |row| general_migrator(table_name, row) }
        end

        def import_table_data table_name, rows
          Rails.logger.info "Importing #{table_name} with #{rows.count} rows..."
          class_name = "LeihsDBIOImport#{table_name.to_s.camelize}"
          eval <<-RB.strip_heredoc
          class ::#{class_name} < ActiveRecord::Base
            self.table_name = '#{table_name}'
            self.inheritance_column = nil
          end
          RB
          rows = convert(table_name, rows).map do |row|
            class_name.constantize.create! row
          end
          Rails.logger.info "Imported #{table_name} with #{rows.count} rows."
        end

        def unvalidated_import data
          ActiveRecord::Base.connection.execute "SET session_replication_role = replica;"
          ActiveRecord::Base.record_timestamps = false
          data.reject{|tn,_| IGNORED_TABLES.include? tn}.each do |table_name, rows|
            if rows.presence && (not rows.empty?)
              import_table_data table_name, rows
            end
          end
          ActiveRecord::Base.connection.execute "SET session_replication_role = DEFAULT;"
        end

        def validated_import data
          ActiveRecord::Base.connection.execute <<-SQL.strip_heredoc
            ALTER TABLE ONLY users
              DROP CONSTRAINT fkey_users_delegators;
            ALTER TABLE ONLY items
              DROP CONSTRAINT fk_rails_ed5bf219ac;
            ALTER TABLE ONLY procurement_organizations
              DROP CONSTRAINT fk_rails_0731e8b712 ;
            ALTER TABLE ONLY images
              DROP CONSTRAINT fkey_images_images_parent_id;
          SQL
          TABLES.each do |table_name|
            import_table_data table_name, data[table_name]
          end

          ActiveRecord::Base.connection.execute <<-SQL.strip_heredoc
            UPDATE images SET parent_id = NULL
              WHERE (NOT EXISTS (SELECT 1 FROM images parents WHERE parents.id = images.parent_id))
          SQL

          ActiveRecord::Base.connection.execute <<-SQL.strip_heredoc
            ALTER TABLE ONLY users
                ADD CONSTRAINT fkey_users_delegators FOREIGN KEY (delegator_user_id) REFERENCES users(id);
            ALTER TABLE ONLY items
                ADD CONSTRAINT fk_rails_ed5bf219ac FOREIGN KEY (parent_id) REFERENCES items(id) ON DELETE SET NULL;
            ALTER TABLE ONLY procurement_organizations
                ADD CONSTRAINT fk_rails_0731e8b712 FOREIGN KEY (parent_id) REFERENCES procurement_organizations(id);
            ALTER TABLE ONLY images
              ADD CONSTRAINT fkey_images_images_parent_id FOREIGN KEY (parent_id) REFERENCES images(id);
          SQL

          Rails.logger.info "Yet unmigrated tables: #{(ActiveRecord::Base.connection.tables.reject{|tn| tn =~ /schema_migrations/} - TABLES).sort}."

        end


        def import_data data, unvalidated_import = false
          ActiveRecord::Base.connection.transaction do
            PgTasks.truncate_tables()
            ActiveRecord::Base.record_timestamps = false
            if unvalidated_import
              unvalidated_import data
            else
              validated_import data
            end
            ActiveRecord::Base.record_timestamps = true
          end
        end

        def load_data filename
          Rails.logger.info "Loading data from #{filename} ..."
          data = YAML.load(::IO.read filename).with_indifferent_access
          Rails.logger.info "Data loaded."
          data
        end

        def import(filename = nil)
          filename ||= Rails.root.join('tmp', 'db_data.yml')
          import_data load_data(filename)
          # PgTasks.structure_and_data_dump 'tmp/import_dump.pgbin'
          # `export RAILS_ENV=test && export FILE=tmp/import_dump.pgbin && bundle exec rake db:pg:truncate_tables db:pg:data:restore`
        end

      end
    end
  end
end
