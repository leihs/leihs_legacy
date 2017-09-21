module Procurement
  module RequestFilters
    extend ActiveSupport::Concern
    included do

      scope :search, lambda { |query|
        sql = all
        return sql if query.blank?

        query.split.each do |q|
          next if q.blank?
          q = "%#{q}%"
          sql = sql.where(arel_table[:article_name].matches(q)
                            .or(arel_table[:article_number].matches(q))
                            .or(arel_table[:supplier_name].matches(q))
                            .or(arel_table[:receiver].matches(q))
                            .or(Building.arel_table[:name].matches(q))
                            .or(Room.arel_table[:name].matches(q))
                            .or(arel_table[:motivation].matches(q))
                            .or(arel_table[:inspection_comment].matches(q))
                            .or(User.arel_table[:firstname].matches(q))
                            .or(User.arel_table[:lastname].matches(q))
                         )
        end
        sql
        .joins(:user)
        .joins(:room)
        .joins('INNER JOIN buildings ON buildings.id = rooms.building_id')
      }

    end
  end
end
