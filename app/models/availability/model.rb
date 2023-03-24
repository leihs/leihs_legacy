module Availability
  module Model

    def availability_in(inventory_pool, exclude_reservations: [], sanitize_invalid_entitled_quantity: false)
      Availability::Main.new(model: self,
                             inventory_pool: inventory_pool,
                             exclude_reservations: exclude_reservations,
                             sanitize_invalid_entitled_quantity: sanitize_invalid_entitled_quantity)
    end

    def being_maintained_until(pool, date = Time.zone.today)
      maintenance_period.to_i.times do
        date = pool.next_open_date(date + 1.day)
      end

      date
    end

  end
end
