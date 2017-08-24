require_relative '../../../../spec/steps/shared/login_steps'
require_relative 'shared/personas_dump_steps'

# rubocop:disable Metrics/ModuleLength
module LeihsAdmin
  module Spec
    module StatisticsSteps
      include ::LeihsAdmin::Spec::PersonasDumpSteps
      include ::Spec::LoginSteps

      step 'I am in the admin section' do
        visit admin.root_path
      end

      step 'I can choose to switch to the statistics section' do
        find("a[href='#{admin.statistics_path}']", match: :first)
      end

      step 'I am in the statistics section' do
        visit('/admin/statistics')
      end

      step "the page title is 'Statistics'" do
        find('h2', text: _('Statistics'))
      end

      step 'I select the statistics subsection ' \
           ':subsection_title' do |subsection_title|
        click_link(subsection_title)
      end

      step 'I see by default the last ' \
           ':number_of_days days\' statistics' do |number_of_days|
        from_date = Date.parse(all('input.datepicker').first.value)
        to_date = Date.parse(all('input.datepicker')[1].value)
        expect((to_date - from_date).days).to eq(Integer(number_of_days).days)
      end

      step 'I set the time frame to ' \
           ':from_day/:from_month - :to_day/:to_month ' \
           'of the current year' do |from_day, from_month, to_day, to_month|
        start_date = \
          Date.parse("#{from_day}/#{from_month}/#{Date.today.strftime('%Y')}")
        end_date = \
          Date.parse("#{to_day}/#{to_month}/#{Date.today.strftime('%Y')}")
        all('input.datepicker').first.set start_date
        all('input.datepicker')[1].set end_date
      end

      step 'I see the busiest inventory pools' do
        @date1 = 1.month.ago.to_formatted_s(:db)
        @date2 = Date.today.to_formatted_s(:db)
        sql = <<-SQL
          SELECT inventory_pools.id,
                 SUM(reservations.quantity) AS quantity,
                 inventory_pools.name AS label
          FROM "inventory_pools"
          INNER JOIN "reservations"
          ON "reservations"."inventory_pool_id" = "inventory_pools"."id"
          WHERE ("reservations"."type" = 'ItemLine'
                 AND "reservations"."item_id" IS NOT NULL
                 AND "reservations"."returned_date" IS NOT NULL)
            AND ("reservations"."start_date" >= '#{@date1}')
            AND ("reservations"."returned_date" <= '#{@date2}')
          GROUP BY inventory_pools.id
          ORDER BY quantity DESC LIMIT 10
        SQL
        @inventory_pools = ActiveRecord::Base.connection.exec_query(sql).to_hash
        within '.list-of-lines' do
          @inventory_pools.each do |ip|
            expect(page).to have_content ip['label']
          end
        end
      end

      step 'I expand an inventory pool' do
        @inventory_pool = @inventory_pools.first
        within('.list-of-lines .row',
               text: @inventory_pool['name'],
               match: :first) do
          find('.toggle').click
        end
      end

      step 'I see all models which this inventory pool is responsible for' do
        sql = <<-SQL
          SELECT models.id,
                 SUM(reservations.quantity) AS quantity,
                 CONCAT_WS(' ',
                           models.manufacturer,
                           models.product,
                           models.version) AS label
          FROM "models"
          INNER JOIN "reservations" ON "reservations"."model_id" = "models"."id"
          WHERE ("reservations"."type" = 'ItemLine'
                 AND "reservations"."item_id" IS NOT NULL
                 AND "reservations"."returned_date" IS NOT NULL)
            AND "reservations"."inventory_pool_id" = '#{@inventory_pool['id']}'
            AND ("reservations"."start_date" >= '#{@date1}')
            AND ("reservations"."returned_date" <= '#{@date2}')
          GROUP BY models.id,
                   reservations.model_id
          ORDER BY quantity DESC LIMIT 10
        SQL

        @models = ActiveRecord::Base.connection.exec_query(sql).to_hash

        within '.list-of-lines .children' do
          @models.each do |model|
            find('.row', text: model['name'], match: :first)
          end
        end
      end

      step 'I see the number of lends for each model' do
        within '.list-of-lines .children' do
          @models.each do |model|
            within('.row', text: model['label'], match: :first) do
              expect(page).to have_content "#{model['quantity']} lends"
            end
          end
        end
      end

      step 'I see users with most lends' do
        @date1 = 1.month.ago.to_formatted_s(:db)
        @date2 = Date.today.to_formatted_s(:db)

        sql = <<-SQL
          SELECT users.id,
                 SUM(reservations.quantity) AS quantity,
                 CONCAT_WS(' ', users.firstname, users.lastname) AS label
          FROM "users"
          INNER JOIN "reservations" ON "reservations"."user_id" = "users"."id"
          WHERE ("reservations"."type" = 'ItemLine'
                 AND "reservations"."item_id" IS NOT NULL
                 AND "reservations"."returned_date" IS NOT NULL)
            AND ("reservations"."start_date" >= '#{@date1}')
            AND ("reservations"."returned_date" <= '#{@date2}')
          GROUP BY users.id,
                   reservations.user_id
          ORDER BY quantity DESC LIMIT 10
        SQL

        @users = ActiveRecord::Base.connection.exec_query(sql).to_hash
        within '.list-of-lines' do
          @users.each do |user|
            expect(page).to have_content user['label']
          end
        end
      end

      step 'I expand the first user' do
        @user = @users.first
        within('.list-of-lines .row',
               text: @user['name'],
               match: :first) do
          find('.toggle').click
        end
      end

      step 'I see all models which the users has borrowed' do
        sql = <<-SQL
          SELECT models.id,
                 SUM(reservations.quantity) AS quantity,
                 CONCAT_WS(' ',
                           models.manufacturer,
                           models.product,
                           models.version) AS label
          FROM "models"
          INNER JOIN "reservations" ON "reservations"."model_id" = "models"."id"
          WHERE ("reservations"."type" = 'ItemLine'
                 AND "reservations"."item_id" IS NOT NULL
                 AND "reservations"."returned_date" IS NOT NULL)
            AND "reservations"."user_id" = '#{@user['id']}'
            AND ("reservations"."start_date" >= '#{@date1}')
            AND ("reservations"."returned_date" <= '#{@date2}')
          GROUP BY models.id,
                   reservations.model_id
          ORDER BY quantity DESC LIMIT 10
        SQL

        @models = ActiveRecord::Base.connection.exec_query(sql).to_hash

        within '.list-of-lines .children' do
          @models.each do |model|
            find('.row', text: model['name'], match: :first)
          end
        end
      end

      step 'I see all models for which this inventory pool owns items' do
        sql = <<-SQL
          SELECT models.id,
                 COUNT(items.id) AS quantity,
                 SUM(items.price) AS price,
                 models.product AS label
          FROM "models"
          INNER JOIN "items" ON "items"."model_id" = "models"."id"
          WHERE ("items"."price" > 0)
            AND "items"."owner_id" = '#{@inventory_pool['id']}'
            AND ("items"."created_at" >= '#{@date1}')
            AND ("items"."created_at" <= '#{@date2}')
          GROUP BY items.model_id,
                   models.id
          ORDER BY price DESC LIMIT 10
        SQL

        @models = ActiveRecord::Base.connection.exec_query(sql).to_hash

        within '.list-of-lines .children' do
          @models.each do |model|
            find('.row', text: model['name'], match: :first)
          end
        end
      end

      step 'for each model a sum of the purchase price of all matching items ' \
           'in this inventory pool' do
        within '.list-of-lines .children' do
          @models.each do |model|
            within('.row', text: model['label'], match: :first) do
              p = model['price'].to_i
              n = ActionController::Base.helpers.number_with_delimiter(p)
              expect(page).to have_content "#{n}"
            end
          end
        end
      end

      step 'I see inventory pools which bought the most items' do
        @date1 = 1.month.ago.to_formatted_s(:db)
        @date2 = Date.today.to_formatted_s(:db)
        sql = <<-SQL
          SELECT inventory_pools.id,
                 COUNT(items.id) AS quantity,
                 SUM(items.price) AS price,
                 inventory_pools.name AS label
          FROM "inventory_pools"
          INNER JOIN "items" ON "items"."owner_id" = "inventory_pools"."id"
          WHERE ("items"."price" > 0)
            AND ("items"."created_at" >= '#{@date1}')
            AND ("items"."created_at" <= '#{@date2}')
          GROUP BY items.owner_id,
                   inventory_pools.id
          ORDER BY price DESC LIMIT 10
        SQL
        @inventory_pools = ActiveRecord::Base.connection.exec_query(sql).to_hash
        within '.list-of-lines' do
          @inventory_pools.each do |ip|
            expect(page).to have_content ip['label']
          end
        end
      end

      step 'for each model the number of items ' \
           'of this model in that inventory pool' do
        within '.list-of-lines .children' do
          @models.each do |model|
            within('.row', text: model['label'], match: :first) do
              expect(page).to have_content "#{model['quantity']}x"
            end
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/ModuleLength

RSpec.configure do |config|
  config.include LeihsAdmin::Spec::StatisticsSteps, leihs_admin_statistics: true
end
