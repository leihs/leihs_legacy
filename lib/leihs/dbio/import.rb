module Leihs
  module DBIO
    module Import
      class << self

        LEIHS_UUID_NS = UUIDTools::UUID.sha1_create UUIDTools::UUID.parse_int(0), 'leihs'

        IGNORED_TABLES = %w(schema_migrations)

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

        NEW_TABLES = %w( procurement_images )

        (TABLES + NEW_TABLES).each do |tbl_name|
          class_name = "LeihsDBIOImport#{tbl_name.to_s.camelize}"
          klass = const_set(class_name, Class.new(ActiveRecord::Base))
          klass.table_name = tbl_name
          klass.inheritance_column = nil
        end

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
          procurement_images:
            parent_id: procurement_images
        YML
                                  ).with_indifferent_access

        def escape(file_path)
          Shellwords.escape file_path
        end

        def reload!
          load File.absolute_path(__FILE__)
        end

        def map_model_group_link(row)
          begin
            unless row['direct']
              nil
            else
              table_uuid_ns = UUIDTools::UUID.sha1_create LEIHS_UUID_NS, 'model_group_links'
              ref_table_uuid_ns = UUIDTools::UUID.sha1_create LEIHS_UUID_NS, 'model_groups'
              { id: UUIDTools::UUID.sha1_create(table_uuid_ns, row[:id].to_s),
                parent_id: UUIDTools::UUID.sha1_create(ref_table_uuid_ns, row[:ancestor_id].to_s),
                child_id: UUIDTools::UUID.sha1_create(ref_table_uuid_ns, row[:descendant_id].to_s),
                label: row[:label] }
            end
          rescue
            binding.pry
          end
        end

        def map_audit_row(row)
          ref_table = row[:auditable_type].pluralize.underscore
          ref_table_uuid_ns = UUIDTools::UUID.sha1_create LEIHS_UUID_NS, ref_table
          auditable_id = UUIDTools::UUID.sha1_create(ref_table_uuid_ns, row[:auditable_id].to_s)
          row.merge({ auditable_id: auditable_id })
        end

        def map_attachments_row(row)
          if ref_id = row[:model_id]
            ref_table = 'models'
            ref_klass = LeihsDBIOImportModels
          elsif ref_id = row[:item_id]
            ref_table = 'items'
            ref_klass = LeihsDBIOImportItems
          end

          ref_table_uuid_ns = UUIDTools::UUID.sha1_create LEIHS_UUID_NS, ref_table
          ref_uuid = UUIDTools::UUID.sha1_create(ref_table_uuid_ns, ref_id.to_s)

          file_path = "#{@v3_attachments_dir}/#{path_to_file(row[:id], row[:filename])}"
          row[:content] = read_and_encode_file(file_path)
          if row[:content] and ref_klass.find_by_id(ref_uuid)
            row[:content_type] = `file -b --mime-type #{escape file_path}`.sub("\n", '')
            row[:size] = File.open(file_path).size
            row.merge Hash["#{ref_table.singularize}_id", ref_uuid]
          else # row[:content].nil? and ref_klass.find_by_id(ref_uuid) and ENV['REPLACE_MISSING_IMAGES'].present?
            row[:content] = IMAGE_NOT_FOUND_PNG
            row[:content_type] = 'image/png'
            row[:size]= 2161
            row.merge Hash["#{ref_table.singularize}_id", ref_uuid]
          end
        end

        def map_procurement_attachments_row(row)
          file_path = "#{@v3_procurement_attachments_dir}/#{path_to_procurement_file(row[:id], row[:file_file_name])}"
          row[:content] = read_and_encode_file(file_path)

          ref_table_uuid_ns = UUIDTools::UUID.sha1_create LEIHS_UUID_NS, 'procurement_requests'
          ref_uuid = UUIDTools::UUID.sha1_create(ref_table_uuid_ns, row[:request_id].to_s)

          if row[:content] and LeihsDBIOImportProcurementRequests.find_by_id(ref_uuid)
            row.merge(request_id: ref_uuid)
          end
        end

        def map_procurement_main_categories_row(row)
          file_path = "#{@v3_procurement_images_dir}/#{path_to_procurement_image(row[:id], row[:image_file_name])}"
          content = read_and_encode_file(file_path)
          thumbnail_file_path = "#{@v3_procurement_images_dir}/#{path_to_procurement_image(row[:id], row[:image_file_name], 'normal')}"
          thumbnail_content = read_and_encode_file(thumbnail_file_path)
          begin
            if content and thumbnail_content
              thumbnail_file = File.open(thumbnail_file_path)
              row.merge \
                after_create: { table_name: 'procurement_main_categories',
                                data: [{ content_type: row[:image_content_type],
                                         content: content,
                                         filename: row[:image_file_name],
                                         size: row[:image_file_size] },
                                       { content_type: row[:image_content_type],
                                         content: thumbnail_content,
                                         filename: row[:image_file_name],
                                         size: thumbnail_file.size }] }
            else
              row
            end
          rescue => e
            Rails.logger.warn(e.message)
            nil
          end
        end

        def map_images_row(row)
          folder_id = row[:parent_id] || row[:id]
          filename = row[:filename]
          file_path = "#{@v3_images_dir}/#{path_to_file(folder_id, filename)}"
          if row[:content] = read_and_encode_file(file_path)
            row[:content_type] = `file -b --mime-type #{escape file_path}`.sub("\n", '')
          else # ENV['REPLACE_MISSING_IMAGES'].present?
            row[:content] = IMAGE_NOT_FOUND_PNG
            row[:content_type] = 'image/png'
            row[:size]= 2161
          end

          ref_table = row[:target_type].underscore.pluralize
          ref_table_uuid_ns = UUIDTools::UUID.sha1_create LEIHS_UUID_NS, ref_table
          target_id = UUIDTools::UUID.sha1_create(ref_table_uuid_ns, row[:target_id].to_s)
          row.merge!(target_id: target_id)

          if row[:content]
            if row[:thumbnail]
              row
            else
              [row, build_thumbnail_row(row.dup)]
            end
          end
        end

        def build_thumbnail_row(row)
          parent_file_path = "#{@v3_images_dir}/#{path_to_file(row[:id], row[:filename])}"
          extension = File.extname(parent_file_path)
          basename_without_extension = File.basename(parent_file_path, extension)
          thumbnail_filename = "#{basename_without_extension}_thumb#{extension}"
          thumbnail_file_path = "#{@v3_images_dir}/#{path_to_file(row[:id], thumbnail_filename)}"

          begin
            file = File.open(thumbnail_file_path)
            row.merge \
              id: nil,
              content: read_and_encode_file(thumbnail_file_path),
              filename: thumbnail_filename,
              size: file.size,
              parent_id: row[:id],
              thumbnail: :thumb
          rescue => e
            Rails.logger.warn(e.message)
            nil
          end
        end

        def read_and_encode_file(file_path)
          if File.exist?(file_path)
            file = File.open(file_path)
            Base64.encode64(file.read)
          else
            Rails.logger.warn "The file '#{file_path}' could not be found!"
            nil
          end
        end

        def path_to_file(folder_id, filename)
          folder = format('%08d', folder_id).scan(/..../).join('/')
          "#{folder}/#{filename}"
        end

        def path_to_procurement_file(folder_id, filename)
          folder = format('%09d', folder_id).scan(/.../).join('/')
          "#{folder}/original/#{filename}"
        end

        def path_to_procurement_image(folder_id, filename, size = 'original')
          folder = format('%09d', folder_id).scan(/.../).join('/')
          "#{folder}/#{size}/#{filename}"
        end

        def map_hiddden_field_row(row)
          unless LeihsDBIOImportFields.where(id: row[:field_id]).first
            Rails.logger.warn "Discarding hidden_filed #{row} because its field row does not exist"
            nil
          else
            row
          end
        end

        def add_position_to_partition row
          row.merge(position: row[:id])
        end

        def custom_pre_migrator(table_name, row)
          case table_name
          when 'model_group_links'
            map_model_group_link row
          when 'audits'
            map_audit_row row
          when 'images'
            map_images_row row
          when 'attachments'
            map_attachments_row row
          when 'procurement_attachments'
            map_procurement_attachments_row row
          when 'procurement_main_categories'
            map_procurement_main_categories_row row
          when 'hidden_fields'
            map_hiddden_field_row row
          when 'partitions'
            add_position_to_partition row
          else
            row
          end
        end

        def general_migrator(table_name, row)
          table_uuid_ns = UUIDTools::UUID.sha1_create LEIHS_UUID_NS, table_name.to_s
          row.map do |k, v|
            begin
              if k.to_s == 'id' and v.is_a? Integer
                [k, UUIDTools::UUID.sha1_create(table_uuid_ns, v.to_s)]
              elsif k.to_s =~ /_id$/ and v.is_a? Integer
                ref_table_name = FOREIGN_TABLE_RESOLVERS[table_name].try(:[], k) \
                  || k.gsub(/_id$/, '').pluralize
                ref_table_uuid_ns = UUIDTools::UUID.sha1_create LEIHS_UUID_NS, ref_table_name
                [k, UUIDTools::UUID.sha1_create(ref_table_uuid_ns, v.to_s)]
              else
                [k, v]
              end
            rescue
              binding.pry
            end
          end.to_h
        end

        def convert(table_name, rows)
          rows.map { |row| custom_pre_migrator(table_name, row) } \
            .flatten.compact.map { |row| general_migrator(table_name, row) }
        end

        def import_table_data(table_name, rows)
          Rails.logger.info "Importing #{table_name} with #{rows.count} rows..."
          class_name = singleton_class.const_get("LeihsDBIOImport#{table_name.to_s.camelize}")
          rows = convert(table_name, rows).map do |row|
            class_name.create! row.reject { |k, v| k == 'after_create' }
            if row.has_key?('after_create')
              custom_after_create! row
            end
          end
          Rails.logger.info "Imported #{table_name} with #{rows.count} rows."
        end

        def custom_after_create!(row)
          after_create = row['after_create']
          table_name = after_create['table_name']

          case table_name
          when 'procurement_main_categories'
            random_uuid = UUIDTools::UUID.sha1_create row['id'], 'procurement_images'
            original_row, thumbnail_row = after_create['data']
            LeihsDBIOImportProcurementImages.create! original_row.merge(id: random_uuid,
                                                                        main_category_id: row['id'])
            LeihsDBIOImportProcurementImages.create! thumbnail_row.merge(main_category_id: row['id'],
                                                                         parent_id: random_uuid)
          else
            raise "custom after create hook for #{table_name} not defined!"
          end
        end

        def unvalidated_import(data)
          ActiveRecord::Base.connection.execute 'SET session_replication_role = replica;'
          ActiveRecord::Base.record_timestamps = false
          data.reject { |tn, _| IGNORED_TABLES.include? tn }.each do |table_name, rows|
            if rows.presence && (not rows.empty?)
              import_table_data table_name, rows
            end
          end
          ActiveRecord::Base.connection.execute 'SET session_replication_role = DEFAULT;'
        end

        def validated_import(data)
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

          unmigrated_tables = \
            ActiveRecord::Base.connection.tables.reject { |tn| tn =~ /schema_migrations/ } \
            - TABLES \
            - NEW_TABLES
          Rails.logger.info "Yet unmigrated tables: #{unmigrated_tables.sort}."
        end

        def import_data(data, unvalidated_import = false)
          ActiveRecord::Base.connection.transaction do
            PgTasks.truncate_tables
            ActiveRecord::Base.record_timestamps = false
            if unvalidated_import
              unvalidated_import data
            else
              validated_import data
            end
            ActiveRecord::Base.record_timestamps = true
          end
        end

        def load_data(filename)
          Rails.logger.info "Loading data from #{filename} ..."
          data = YAML.load(::IO.read filename).with_indifferent_access
          Rails.logger.info 'Data loaded.'
          data
        end

        def import(filename = nil,
                   attachments_path: nil,
                   images_path: nil,
                   procurement_attachments_path: nil,
                   procurement_images_path: nil)
          filename ||= Rails.root.join('tmp', 'db_data.yml')
          @v3_attachments_dir = \
            attachments_path || "#{Rails.root}/public/attachments/"
          @v3_images_dir = \
            images_path || "#{Rails.root}/public/images/attachments/"
          @v3_procurement_attachments_dir = \
            procurement_attachments_path || "#{Rails.root}/public/system/procurement/attachments/files/"
          @v3_procurement_images_dir = \
            procurement_images_path || "#{Rails.root}/public/system/procurement/main_categories/images/"
          import_data load_data(filename)
          # PgTasks.structure_and_data_dump 'tmp/import_dump.pgbin'
          # `export RAILS_ENV=test && export FILE=tmp/import_dump.pgbin && bundle exec rake db:pg:truncate_tables db:pg:data:restore`
        end


        IMAGE_NOT_FOUND_PNG = <<-PNG.strip_heredoc
          iVBORw0KGgoAAAANSUhEUgAAAlgAAAGQBAMAAACAGwOrAAAAG1BMVEX/AAAA
          AAC/AACfAADfAAAfAAB/AABfAAA/AACZ3P73AAAACXBIWXMAAA7EAAAOxAGV
          Kw4bAAAH/ElEQVR4nO3azVvbRgLHccWSbY47SRx8tEnJ02ONu+keTSFtj6sm
          2XCMmgZ6xM0ucERtU/xnd941ejEma2PT8P08TwKyNOPRTy/MjBRFAAAAAAAA
          AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
          AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAn43nP99i5a3x5BZr/0QH
          F6+Pflquiulj/SMer6A5NW0xuI1q/y8doQyWqsOGtS8my7en5i6FNRVv3p3k
          g+Xq+NzCSsRl08exeKRWTpaq+76E1RZfLV+3D2v5quruUFj7vRXUfV/CGj1Z
          Qd33Jazs0Qrqvi9hTR+uoG7C+gT3JaycsBqsIawHtxlWcij/nVyZgdmzi7OB
          W996fj47fzfxiyezs6/lz0O7fHB+9cGvNA4nuorzYJCXPL+4Kuq4WVilMoe+
          sP5NtVY25apopvpG3fp1hNURg2QqB2Y/yt//KX/2TDOSX/RwTfRtqzqpWvqP
          7GybD9SmolfuS2Zyn9+rz1+6T+I8rONmYZXL5P9wn+swZGtNU/xXJ5lp2LrC
          2hVXF0J2oruif54L82d8JFtwNPsohOkCtVLx5vgkFz/asHZF70ou9idhjTKs
          XVnF/4Q4tTuSy80uUrtZW3hBsan/cLuhTENYsilX56ndWrVELsqGrSmsL9RZ
          1RGPo6lsoDzL9Mejnr7IWrkZiQzFb+rHe/FOr47F9kA39FVYY/ZQfi5Lfef2
          ZFe8nOhj/8p84U3CKpdpCGsk/qvXmwPSEn3ZwOS9eLuesHZ1K0fbsf7+jrlS
          ntv9icW/5f9JavvY074uNbIX47Qf1pg9HJqLeGhvh6k7WXqqttZ4PBYvx0pQ
          6KlczJ+oD/caytTD2tE3DBmSuXT3xVuz9sl6wkov1c8tsW+amT4ubTZ9pFea
          JskrVZVKbEvlYnjXyh6JPyJT52lULuWuy4X3rGqZWlgje31mprW5PYpyN2xY
          qxhn1viwzCGMbWhRVh6oDVWjhv4MSlUpv0eJPu+czFYlt9K7OCpKPXTbXzY1
          JQirWqYWlrvy28K02lU4FWsJy9zREzdTub9d2uyBan3RxdZXWDFLkIV/xzLh
          TkqzfXGOurAXh1UtUw9rYha7urlb/vbXXk9Y9uRI7Q5Vvq2tFlPf5AeqVHHy
          lZLN/EU5Ugeg5S4+tU/6uxaHVStTC8uNuWP9Zfv9ouRawrLNc1d/u3yH3FKL
          xT7qXcj94W+HTcv8wlDV1S2GCLG9bheGVStTC8td9y29OpivWM89y54O7lLb
          agrLH2+9N8WdqhtuXDnhgtRdSAvDqpWphfXWrz6NfE9UV3Jnwrp0iyqs4Frp
          hF2m4jDrsPaDfoW9jheGVStTC8v33HUjivuD75SuOayJ3eLpyez167R6GU78
          RRVFfvSjFWHpvwrD4H5mD/vCsGpl5oZl2hT8NbZhtTcSVuz61qUmqz5fXLQ4
          DjtalbDCyWJb+cKwamWuDyusb5NhxanonY33dnZVWEUMo21V5GhmfbxpWK5/
          ctnUlDlhqTJ/j7Cm4veJWZT/vXC9zUR1FTsiMD+scGY9u2FYtTLXhxXcPTcZ
          VtcMwWxYsR3HRC9U6zri7NgbFDWuP6zkboTlhmD2j2Nm5o9i3XON5zwTvbf3
          rNRNvtiwRO/DF99+k6rpkfCvYcndCKs0EbIq14ZV5KG7iS1xbu5Qv0dR+U4R
          uhNdh85ZY9uWdG1YXd/Z0vND8nAdXKS9N2Z2fc4uV8MKH8qLm3ZKq2WKsPKm
          sIrVYWd+9a4Nq+jGD9Vvw/Ljl6DfHKqEtZLhztR/VdoUVvDEMd9YWMVtctoQ
          1pyHopWwgplBN6S7wUC6UsafL2ZWoRpWcI8TmwvLHeFE9+CH5ZcRhs030UpY
          rSKZtruqS5OFXjhFUynjJ8y6jWEVI8F4c2H5AeKWDqvyAtWc57OVsPz8aDD/
          uSisWpmhO3WGjWEVZ6Kb/Pth1vQNy7o2LD8Vkh2Zv4a9s71D93zVPsWoqYY1
          coc98RE03+3CaeVKGXfHT0TjPauY187FGh7fN4fVslPdHfGN/vJd03M4sq9P
          543XYTUs/5zCz9nPudsFYVXLbNnm7fYbuw5RZlvS7eUbC0vGof5P8m07vffs
          o4nLDIJeuOFPMghqrIaVpGYYkBTZjhpTDsKqlmmZb4zFq+aw2qYl8jxcx4sh
          c8LaV886D6bi1M+FJt/uPHUPm5Nc6Gewz/Kwe1oNS2aqnsW2pi5a9aXqYe1e
          pSnh4/tqmakaNMTy2GWNYSWp+FlvPthgWK1U9FL11kJp4jj63j437grRm81S
          Ia4NSz1uPvKvACgtIfqztPpWZOldh0qZrlk8jZrDin4Q4rVc/4dZv5mwZCzm
          DY9yWO5hc/SdflGk92u4rh5WS08gvpkU23ypPqi+FVkKq1pGv4Iiz645YUX/
          ssOwWw1rkfj4+OuGT10bk/Hx8d5kYS1P5ValDw4WF6uUOSjNA9UdNDb0Tpgz
          1EGTWx2CfW5udXD/ueHM+gTcs24unjNLigYvmicc4CW+J5jUet+oSIR9tT3J
          5ky/w0vk8OOnwyh5lovtxVvfd2YkWHr/H3O1ftFx/TnZdEP+HpKd8c5k040A
          AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
          AAAAAAAAAAAAAAAAAAAAAAAAAAAAAACb9ReGvKegrI7sqgAAAABJRU5ErkJg
          gg==
        PNG
      end
    end
  end
end
