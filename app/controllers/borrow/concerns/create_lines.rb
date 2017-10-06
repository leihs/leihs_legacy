module Borrow
  module Concerns
    module CreateLines
      def create_lines(model:,
                       status:,
                       quantity:,
                       inventory_pool:,
                       start_date: nil,
                       end_date: nil,
                       delegated_user_id: nil)
        if end_date and start_date and end_date < start_date
          end_date = start_date
        end

        attrs = { inventory_pool: inventory_pool,
                  status: status,
                  quantity: 1,
                  model: model,
                  start_date: start_date || time_window_min,
                  end_date: end_date || next_open_date(time_window_max),
                  delegated_user_id: delegated_user_id }

        new_lines = Integer(quantity).times.map do
          current_user.item_lines.create(attrs)
        end

        new_lines
      end
    end
  end
end
