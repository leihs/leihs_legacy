class Supplier < ApplicationRecord

  validates_presence_of :name
  validates_uniqueness_of :name, case_sensitive: false

  has_many :items, dependent: :restrict_with_exception

  def to_s
    name
  end

  def self.filter(search_term: nil, pool_id: nil)
    suppliers = search(search_term).order(:name)
    if pool_id.present?
      suppliers = suppliers.joins(:items)
        .where('items.inventory_pool_id': pool_id).distinct
    end
    # FIXME: not used?
    # suppliers = suppliers.where(id: params[:ids]) if params[:ids]
    suppliers
  end

  scope :search, lambda { |query|
                 sql = all
                 return sql if query.blank?

                 query.split.each do |q|
                   q = "%#{q}%"
                   sql = sql.where(arel_table[:name].matches(q))
                 end
                 sql
  }

end
