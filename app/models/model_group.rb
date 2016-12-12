class ModelGroup < ActiveRecord::Base
  include Search::Name
  audited

  attr_accessor :current_parent_id

  has_many :model_links, inverse_of: :model_group, dependent: :delete_all
  has_many :models, -> { uniq }, through: :model_links
  has_many :items, -> { uniq }, through: :models

  # has_many :all_model_links,
  #          :class_name => "ModelLink",
  #          :finder_sql => \
  #            proc { ModelLink.where(["model_group_id IN (?)",
  #                   descendant_ids]).to_sql }
  # has_many :all_models,
  #          -> { uniq },
  #          :class_name => "Model",
  #          :through => :all_model_links,
  #          :source => :model

  has_and_belongs_to_many :inventory_pools

  validates_presence_of :name

  accepts_nested_attributes_for :model_links, allow_destroy: true

  ##################################################

  # has_dag_links link_class_name: 'ModelGroupLink'

  has_many :parent_links,
           class_name: ::ModelGroupLink,
           foreign_key: :child_id

  has_many :child_links,
           class_name: ::ModelGroupLink,
           foreign_key: :parent_id

  has_and_belongs_to_many \
    :children,
    join_table: :model_group_links, class_name: 'ModelGroup',
    foreign_key: :parent_id, association_foreign_key: :child_id

  has_and_belongs_to_many \
    :parents,
    join_table: :model_group_links, class_name: 'ModelGroup',
    foreign_key: :child_id, association_foreign_key: :parent_id

  # p = FactoryGirl.create :model_group, name: 'Parent', type: 'ModelGroup'
  # c = FactoryGirl.create :model_group, name: 'Child', type: 'ModelGroup'
  # ModelGroupLink.create parent: p, child: c

  def descendants(found = [])
    more = Set.new(self.children) + found.map(&:children).flatten
    more == Set.new(found) ? found : descendants(more).to_a
  end

  def self_and_descendants
    descendants + [self]
  end

  def links_as_child
    ModelGroupLink.where(child_id: self.id)
  end

  # NOTE it's now chainable for scopes
  def all_models
    Model
      .joins(:model_links)
      .where(model_links: { model_group_id: self_and_descendants.map(&:id) })
      .uniq
  end

  def image
    self.images.first || all_models.detect { |m| not m.image.blank? }.try(:image)
  end

  scope :roots, (lambda do
    joins('LEFT JOIN model_group_links AS mgl ' \
          'ON mgl.child_id = model_groups.id')
      .where('mgl.child_id IS NULL')
  end)

  # scope :accessible_roots, lambda do |user_id|
  # end

  ################################################
  # Edge Label

  def label(parent_id = nil)
    if parent_id
      ModelGroupLink.where(child_id: self.id, parent_id: parent_id) \
        .first.try(:label) || name
    else
      name
    end
  end

  def set_parent_with_label(parent, label)
    ModelGroupLink.create_edge(parent, self)
    l = links_as_child.find_by(parent_id: parent.id)
    l.update_attributes(label: label) if l
  end

  ################################################

  def to_s
    name
  end

  # compares two objects in order to sort them
  def <=>(other)
    self.name.downcase <=> other.name.downcase
  end

end
