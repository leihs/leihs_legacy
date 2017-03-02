module Statistics
  class Base
    class << self

      def hand_overs(klasses, options = {})
        options.symbolize_keys!
        options[:limit] ||= 10

        if klasses.is_a? Array
          raise 'limit is required' if options[:limit].nil?
          raise 'max accepted limit is 20' if options[:limit] > 20
        end

        klasses = Array(klasses)
        klass = klasses.first
        klasses = klasses.drop(1)

        reservations = Reservation.arel_table
        query = get_query_for_hand_overs(klass, reservations, options)

        query.map do |x|
          h = { type: 'statistic',
                object: klass.name,
                id: x.id,
                label: x.label,
                quantity: Integer(x.quantity),
                unit: _('lends') }
          unless klasses.empty?
            h[:children] = \
              hand_overs(klasses,
                         options.merge(klass.name.foreign_key.to_sym => x.id))
          end
          h
        end
      end

      def contracts(klasses, options = {})
        options.symbolize_keys!
        options[:limit] ||= 10

        if klasses.is_a? Array
          raise 'limit is required' if options[:limit].nil?
          raise 'max accepted limit is 20' if options[:limit] > 20
        end

        klasses = Array(klasses)
        klass = klasses.first
        klasses = klasses.drop(1)

        reservations = Reservation.arel_table
        query = get_query_for_contracts(klass, reservations, options)

        query.map do |x|
          h = { type: 'statistic',
                object: klass.name,
                id: x.id,
                label: x.label,
                quantity: Integer(x.quantity),
                unit: _('contracts') }
          unless klasses.empty?
            h[:children] = \
              contracts(klasses,
                        options.merge(klass.name.foreign_key.to_sym => x.id))
          end
          h
        end
      end

      def item_values(klasses, options = {})
        options.symbolize_keys!
        options[:limit] ||= 10

        if klasses.is_a? Array
          raise 'limit is required' if options[:limit].nil?
          raise 'max accepted limit is 20' if options[:limit] > 20
        end

        klasses = Array(klasses)
        klass = klasses.first
        klasses = klasses.drop(1)

        items = Item.arel_table

        query = prepare_query_for_item_values(klass, items, options)
        query.map do |x|
          h = { type: 'statistic',
                object: klass.name,
                id: x.id,
                label: "#{x.quantity}x #{x.label}",
                quantity: Integer(x.price),
                unit: _('CHF') }
          unless klasses.empty?
            h[:children] = \
              item_values(klasses,
                          options.merge(klass.name.foreign_key.to_sym => x.id))
          end
          h
        end
      end

      private

      def prepare_query_for_item_values(klass, items, options)
        query = klass.unscoped
          .select("#{klass.name.tableize}.id, " \
                  'COUNT(items.id) AS quantity, ' \
                  'SUM(items.price) AS price')
          .where(items[:price].gt(0))
          .order('price DESC')
          .limit(options[:limit])

        query = case klass.name
                when 'InventoryPool'
                  query.joins(:own_items)
                    .group('items.owner_id')
                    .group('inventory_pools.id')
                    .select('inventory_pools.name AS label')
                when 'Model'
                  query.joins(:items)
                    .group("items.#{klass.name.foreign_key}")
                    .group('models.id')
                    .select('models.product AS label')
                else
                  raise "#{klass} not supported"
                end

        unless options[:inventory_pool_id].blank?
          query = query.where(items: { owner_id: options[:inventory_pool_id] })
        end
        unless options[:model_id].blank?
          query = query.where(items: { model_id: options[:model_id] })
        end
        unless options[:start_date].blank?
          query = \
            query.where \
              items[:created_at].gteq \
                Date.parse(options[:start_date]).to_s(:db)
        end
        unless options[:end_date].blank?
          query = query.where \
            items[:created_at].lteq \
              Date.parse(options[:end_date]).to_s(:db)
        end
        query
      end

      def get_query_for_contracts(klass, reservations, options)
        query = klass.unscoped
          .select("#{klass.name.tableize}.id, " \
                  'COUNT(DISTINCT contracts.id) AS quantity')
          .where(reservations: { status: [:signed, :closed] })
          .order('quantity DESC')
          .limit(options[:limit])

        query = case klass.name
                when 'User'
                  query.joins(reservations: :contract)
                    .group("reservations.#{klass.name.foreign_key}")
                    .group('users.id')
                    .select(<<~SQL)
                      CONCAT_WS(' ',
                                users.firstname,
                                users.lastname) AS label
                    SQL
                when 'InventoryPool'
                  query.joins(reservations: :contract)
                    .group('inventory_pools.id')
                    .select('inventory_pools.name AS label')
                else
                  raise "#{klass} not supported"
                end

        unless options[:user_id].blank?
          query = query.where(reservations: { user_id: options[:user_id] })
        end
        unless options[:inventory_pool_id].blank?
          query = \
            query.where(reservations: \
                        { inventory_pool_id: options[:inventory_pool_id] })
        end
        unless options[:model_id].blank?
          query = query.where(reservations: { model_id: options[:model_id] })
        end
        unless options[:item_id].blank?
          query = query.where(reservations: { item_id: options[:item_id] })
        end
        unless options[:start_date].blank?
          query = \
            query.where \
              reservations[:start_date].gteq \
                Date.parse(options[:start_date]).to_s(:db)
        end
        unless options[:end_date].blank?
          query.where \
            reservations[:returned_date].lteq \
              Date.parse(options[:end_date]).to_s(:db)
        end
      end

      def get_initial_query_for_hand_overs(klass, reservations, options)
        klass.unscoped
          .select("#{klass.name.tableize}.id, " \
                  'SUM(reservations.quantity) AS quantity')
          .where(reservations[:type].eq('ItemLine')
                 .and(reservations[:item_id].not_eq(nil))
                 .and(reservations[:returned_date].not_eq(nil)))
          .order('quantity DESC')
          .limit(options[:limit])
      end

      def get_query_for_hand_overs(klass, reservations, options)
        query = get_initial_query_for_hand_overs(klass, reservations, options)
        query = extend_query_for_hand_overs(query, klass)

        unless options[:user_id].blank?
          query = query.where(reservations: { user_id: options[:user_id] })
        end
        unless options[:inventory_pool_id].blank?
          query = \
            query
              .where(reservations: \
                     { inventory_pool_id: options[:inventory_pool_id] })
        end
        unless options[:model_id].blank?
          query = query.where(reservations: { model_id: options[:model_id] })
        end
        unless options[:item_id].blank?
          query = query.where(reservations: { item_id: options[:item_id] })
        end
        unless options[:start_date].blank?
          query = \
            query.where \
              reservations[:start_date].gteq \
                Date.parse(options[:start_date]).to_s(:db)
        end
        unless options[:end_date].blank?
          query.where \
            reservations[:returned_date].lteq \
              Date.parse(options[:end_date]).to_s(:db)
        end
      end

      def extend_query_for_hand_overs(query, klass)
        case klass.name
        when 'User'
          query.joins(:reservations)
            .group('users.id')
            .group("reservations.#{klass.name.foreign_key}")
            .select("CONCAT_WS(' ', " \
                    'users.firstname, ' \
                    'users.lastname) AS label')
        when 'InventoryPool'
          query.joins(:reservations)
            .group('inventory_pools.id')
            .select('inventory_pools.name AS label')
        when 'Model'
          query.joins(:reservations)
            .group('models.id')
            .group("reservations.#{klass.name.foreign_key}")
            .select("CONCAT_WS(' ', " \
                    'models.manufacturer, ' \
                    'models.product, ' \
                    'models.version) AS label')
        when 'Item'
          query.joins(item_lines: :model)
            .group('items.id')
            .group("reservations.#{klass.name.foreign_key}")
            .group('models.manufacturer')
            .group('models.product')
            .group('models.version')
            .select("CONCAT_WS(' ', " \
                    'items.inventory_code, ' \
                    'models.manufacturer, ' \
                    'models.product, ' \
                    'models.version) AS label')
        else
          raise "#{klass} not supported"
        end
      end
    end
  end
end
