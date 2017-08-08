# class ApplicationRecord gives problems and this method seems
# not always be defined, that's why defined on ActiveRecord::Base
class ActiveRecord::Base
  def can_destroy?
    self.class.reflect_on_all_associations.all? do |assoc|
      assoc.options[:dependent] != :restrict_with_exception ||
        (assoc.macro == :has_one && self.send(assoc.name).nil?) ||
        (assoc.macro == :has_many && self.send(assoc.name).empty?)
    end
  end
end
