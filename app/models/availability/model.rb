module Availability
  module Model

    def availability_in(inventory_pool, exclude_reservations: [])
      Availability::Main.new(model: self,
                             inventory_pool: inventory_pool,
                             exclude_reservations: exclude_reservations)
    end

  end
end
