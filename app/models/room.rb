class Room < ApplicationRecord
  include DefaultPagination

  SEARCHABLE_FIELDS = %w(name)

  belongs_to :building
  has_many :items, dependent: :restrict_with_exception

  validates_presence_of :name, :building_id
  validates_uniqueness_of :name, scope: :building_id, case_sensitive: false

  scope :general, -> { where(general: true) }

  def self.general_general
    find_by!(building_id: Leihs::Constants::GENERAL_BUILDING_UUID,
             general: true)
  end

  def self.search(search_term)
    return none if search_term.blank?

    term = "%#{sanitize_sql_like(search_term.to_s)}%"
    joins('INNER JOIN buildings ON buildings.id = rooms.building_id')
      .where(
        'rooms.name ILIKE :term OR buildings.name ILIKE :term OR buildings.code ILIKE :term',
        term: term
      )
  end

  def to_s
    if description.presence
      "#{name} (#{description})"
    else
      name
    end
  end

end
