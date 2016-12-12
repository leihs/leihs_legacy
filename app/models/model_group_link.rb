# -*- encoding : utf-8 -*-
class ModelGroupLink < ActiveRecord::Base
  audited

  belongs_to :child, class_name: 'ModelGroup'

  belongs_to :parent, class_name: 'ModelGroup'

  def self.find_edge(mg1, mg2)
    where(parent_id: mg1.id, child_id: mg2.id).first \
    || where(child_id: mg1.id, parent_id: mg2.id).first
  end

  def self.create_edge(parent, child)
    create!(parent_id: parent.id, child_id: child.id)
  end

end
