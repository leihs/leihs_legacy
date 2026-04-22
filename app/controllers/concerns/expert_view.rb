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

    def items_for_view(inventory_pool, params)
      reduced = matching_items(inventory_pool, params)

      page_size = (params[:page_size] || 20).to_i
      start_index = (params[:start_index] || 0).to_i

      # Item-centric pagination ordered by inventory_code (same idea as Inventory GET /items).
      # Previously we paginated models by product/version then loaded their items, which
      # produced a different first page than a global code-sorted item list.
      # Wrap `reduced` in a subquery so ORDER BY is not combined with DISTINCT in one SELECT.
      item_page_scope = Item.from("(#{reduced.to_sql}) AS items")
                            .reorder(Arel.sql('items.inventory_code ASC'))
                            .limit(page_size + 1)
                            .offset(start_index)
      page_records = item_page_scope.to_a
      has_more = page_records.size > page_size
      page_records = page_records.first(page_size)

      result_items = page_records.map do |item|
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

      model_ids_ordered = page_records.map(&:model_id).uniq
      models_by_id = Model.where(id: model_ids_ordered).index_by(&:id)

      result_models = model_ids_ordered.filter_map do |mid|
        m = models_by_id[mid]
        next unless m

        {
          'type' => 'model',
          'model_type' => m.type,
          'id' => m.id,
          'product' => m.product.to_s.strip,
          'version' => m.version.to_s.strip,
          'option_price' => nil,
          'option_inventory_code' => nil,
          'model_is_package' => m.is_package
        }
      end

      {
        data: result_models,
        items: result_items,
        has_more: has_more,
        page_size: page_size,
        start_index: start_index
      }
    end

  end
end
