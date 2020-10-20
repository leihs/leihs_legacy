class Category < ModelGroup

  has_many :templates, -> { distinct }, through: :models

  has_many :images,
           -> { where(thumbnail: false) },
           as: :target,
           dependent: :destroy
  accepts_nested_attributes_for :images, allow_destroy: true

  def used?
    not (models.empty? and children.empty?)
  end

  default_scope do
    order(:name, :created_at, :id)
  end

  def self.filter(params, _inventory_pool = nil)
    categories = all
    categories = categories.search(params[:search_term]) if params[:search_term]
    categories = categories.order('name ASC')
    categories
  end

  def children_with_reservable_models(user_id, parent_id)
    qo =
      ::QueryObjects::CategoryChildrenWithReservableItems
      .new(user_id: user_id, parent_id: parent_id)
    self.class.find_by_sql(qo.query)
  end

  def self.parents_of_multiple(cats)
    joins('INNER JOIN model_group_links ' \
          'ON model_groups.id = model_group_links.parent_id')
      .where(model_group_links: \
             { child_id: cats.pluck(:id) })
      .distinct
  end

  def self.ancestors_of_multiple(cats, result = [])
    pars = parents_of_multiple(cats)
    if pars.empty?
      result
    else
      ancestors_of_multiple(pars, result.concat(pars).uniq)
    end
  end
end
