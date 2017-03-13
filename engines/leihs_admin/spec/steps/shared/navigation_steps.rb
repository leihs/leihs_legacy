module LeihsAdmin
  module Spec
    module NavigationSteps
      step 'I visit :path' do |path|
        visit path
      end

      step 'I open the list of users' do
        visit admin.users_path
      end

      step 'I open the list of inventory pools' do
        visit admin.inventory_pools_path
      end
    end
  end
end
