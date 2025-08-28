class Template < ModelGroup
  include DefaultPagination

  # TODO: 12** belongs_to :inventory_pool through
  # TODO 12** validates belongs_to 1 and only 1 inventory pool
  # TODO 12** validates all models are present to current inventory_pool
  # TODO 12** has_many :models through

  default_scope { order(:name) }

  after_save do
    raise _('Template must have at least one model') if model_links.blank?
  end

  def self.filter(params, inventory_pool)
    templates = inventory_pool.templates
    unless params[:search_term].blank?
      templates = templates.search(params[:search_term])
    end
    templates = \
      templates.order("#{params[:sort] || 'name'} #{params[:order] || 'ASC'}")
    templates = templates.default_paginate params
    templates
  end

  ################################################################################

  # returns an array of reservations
  def add_to_contract(contract,
                      user,
                      _quantity = nil,
                      start_date = nil,
                      end_date = nil,
                      delegated_user_id = nil)
    model_links.flat_map do |ml|
      ml.model.add_to_contract(contract,
                               user,
                               ml.quantity,
                               start_date,
                               end_date,
                               delegated_user_id)
    end
  end

  def total_quantity
    model_links.sum(:quantity)
  end

  def accomplishable?(user = nil)
    unaccomplishable_models(user).empty?
  end

  def unaccomplishable_models(user = nil, quantity = nil)
    models.to_a.keep_if do |model|
      q = quantity || model_links.detect { |l| l.model_id == model.id }.quantity
      not inventory_pools.any? do |ip|
        if user
          model.total_borrowable_items_for_user_and_pool(user, ip) >= q
        else
          model.borrowable_items.where(inventory_pool_id: ip).count >= q
        end
      end
    end
  end
end
