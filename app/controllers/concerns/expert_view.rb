# rubocop:disable Metrics/ModuleLength
module ExpertView
  extend ActiveSupport::Concern

  include ExpertFilter

  included do

    private

    def matching_items(inventory_pool, params)
      items = inventory_items(params, inventory_pool)

      items_directly_matching = \
        items.select(:id).where(parent_id: nil)

      parent_items_containing_matching_child = \
        items.select(:parent_id).where.not(parent_id: nil)

      Item.distinct.where(
        <<-SQL
          items.id IN (#{items_directly_matching.to_sql})
          or items.id IN (#{parent_items_containing_matching_child.to_sql})
        SQL
      )
    end

    # rubocop:disable Metrics/MethodLength
    def items_for_view(inventory_pool, params)
      reduced = matching_items(inventory_pool, params)

      query = <<-SQL

        select
          *
        from
        (
          (
            select
              'model' as type,
              models.type as model_type,
              models.id as id,
              trim(models.product) as product,
              trim(models.version) as version,
              null as option_price,
              null as option_inventory_code,
              models.is_package as model_is_package
            from
              models
            where
              models.id IN (#{reduced.select(:model_id).to_sql})
          )
          union
          (
            select
              'option' as type,
              null as model_type,
              options.id as id,
              options.product as product,
              options.version as version,
              options.price as option_price,
              options.inventory_code as option_inventory_code,
              null as model_is_package
            from
              options
            where
              true = false
          )
          order by
            product, version
        ) as merged
      SQL

      page_size = (params[:page_size] || 20).to_i
      start_index = (params[:start_index] || 0).to_i

      result_models = InventoryPool.connection.exec_query(
        query + " limit #{page_size + 1} offset #{start_index}").to_hash

      items_in_model_page = reduced.where(
        <<-SQL
          items.model_id IN (
            select id from (#{query} limit #{page_size} offset #{start_index}
          ) as merged)
        SQL
      )
      items_for_model = Item.distinct.where(
        <<-SQL
          items.id in (
            #{items_in_model_page.select(:id).to_sql}
          )
          or items.parent_id in (
            #{items_in_model_page.select(:id).to_sql}
          )
        SQL
      )

      result_items = items_for_model.map do |item|
        {
          id: item.id,
          model_id: item.model_id,
          inventory_code: item.inventory_code,
          current_location: item.current_location,
          is_borrowable: item.is_borrowable,
          is_broken: item.is_broken,
          retired: item.retired,
          parent_id: item.parent_id,
          to_s: item.to_s,
          is_incomplete: item.is_incomplete
        }
      end

      has_more = result_models.length > page_size

      {
        data: result_models.slice(0, page_size),
        items: result_items,
        has_more: has_more,
        page_size: page_size,
        start_index: start_index
      }
    end
    # rubocop:enable Metrics/MethodLength

  end
end
# rubocop:enable Metrics/ModuleLength
