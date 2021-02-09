module Concerns
  module InventoryCode
    extend ActiveSupport::Concern

    ####################################################################

    def lowest_proposed_inventory_code
      Item.proposed_inventory_code(owner, :lowest)
    end

    def highest_proposed_inventory_code
      Item.proposed_inventory_code(owner, :highest)
    end

    ####################################################################

    module ClassMethods

      def prefix_number(pool, num)
        "#{pool.shortname}#{num}"
      end

      # extract *last* number sequence in string
      def last_number(inventory_code)
        inventory_code ||= ''
        inventory_code.reverse.sub(/[^\d]*/, '').sub(/[^\d]+.*/, '').reverse.to_i
      end

      # proposes the next available number based on the owner inventory_pool
      # tries to take the next free inventory code
      # after the previously created Item
      def proposed_inventory_code(inventory_pool, type = :last)
        latest_inventory_code = \
          Item
          .where(owner_id: inventory_pool)
          .order('created_at DESC')
          .first
          .try(:inventory_code)

        next_num = case type
                   when :lowest
                     free_inventory_code_ranges(from: 0).first.first
                   when :highest
                     free_inventory_code_ranges(from: 0).last.first
                   else # :last
                     latest_number = last_number(latest_inventory_code)
                     free_inventory_code_ranges(from: latest_number)
                       .first
                       .first
                   end

        prefix_number(inventory_pool, next_num)
      end

      # if argument is false returns { 1 => 3, 2 => 1, 77 => 1, 79 => 2, ... }
      # the key is the allocated inventory_code_number
      # the value is the count of the allocated items
      # if the value is larger than 1, then there is a allocation conflict
      #
      # if argument is true returns
      # { 1 => ["AVZ1", "ITZ1", "VMK1"],
      #   2 => "AVZ2",
      #   77 => "AVZ77",
      #   79 => ["AVZ79", "ITZ79"], ... }
      # the key is the allocated inventory_code_number
      # the value is/are the inventory_code/s of the allocated items
      # if the value is an Array, then there is a allocation conflict
      #
      def allocated_inventory_code_numbers(with_allocated_codes = false)
        h = {}
        inventory_codes = \
          ApplicationRecord
          .connection
          .select_values('SELECT inventory_code FROM items')
        inventory_codes.each do |code|
          num = last_number(code)
          h[num] = if with_allocated_codes
                     (h[num].nil? ? code : Array(h[num]) << code)
                   else
                     Integer(h[num].presence || 0) + 1
                   end
        end
        h
      end

      # returns [ [1, 2], [5, 23], [28, 29], ... [9990, Infinity] ]
      # all displayed numbers [from, to] included are available
      #
      # Attention: params could be negative!
      #
      def free_inventory_code_ranges(params = {})
        infinity = 1 / 0.0
        default_params = { from: 1, to: infinity, min_gap: 1 }
        params.reverse_merge!(default_params)

        from = [Integer(params[:from].presence || 0), 1].max
        if params[:to] == infinity
          to = infinity
        else
          to = [[Integer(params[:to].presence || 0), from].max, infinity].min
        end
        min_gap = [[Integer(params[:min_gap].presence || 0), 1].max, to].min

        ranges = []
        last_n = from - 1

        sorted_numbers = \
          allocated_inventory_code_numbers
          .keys
          .select { |n| n >= from and n <= to }
          .sort
        sorted_numbers.each do |n|
          if n - 1 != last_n and (n - 1 - last_n >= min_gap)
            ranges << [last_n + 1, n - 1]
          end
          last_n = n
        end
        ranges << [last_n + 1, to] if last_n + 1 <= to and (to - last_n >= min_gap)

        ranges
      end

      def free_consecutive_code_numbers(quantity = 1)
        r =
          free_inventory_code_ranges
          .find { |r| quantity <= r.second - r.first + 1 }

        Range.new(*r).take(quantity)
      end

      def free_consecutive_inventory_codes(pool, quantity = 1)
        free_consecutive_code_numbers(quantity).map { |n| prefix_number(pool, n) }
      end
    end
  end
end
