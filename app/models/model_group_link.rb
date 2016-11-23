# -*- encoding : utf-8 -*-
class ModelGroupLink < ActiveRecord::Base
  audited

  belongs_to :child, class_name: 'ModelGroup'

  belongs_to :parent, class_name: 'ModelGroup'


end
