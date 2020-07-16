module Availability
  module Model

    def availability_in(inventory_pool, exclude_reservations: [])
      Availability::Main.new(model: self,
                             inventory_pool: inventory_pool,
                             exclude_reservations: exclude_reservations)
    end

    def being_maintained_until(pool, date = Time.zone.today)
      maintenance_period.to_i.times do
        date = pool.next_open_date(date + 1.day)
      end

      date
    end

  end
end
