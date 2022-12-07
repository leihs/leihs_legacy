class QueryObjects::BookingCalendarVisits
  attr_reader :query

  def initialize(inventory_pool_id:, start_date:, end_date:)
    @query = \
      <<-SQL
        WITH dates AS
          (SELECT d::date
           FROM generate_series('#{start_date}'::date,
                                '#{end_date}'::date,
                                '1 day'::interval) AS d)
        SELECT dates.d,
          (SELECT count(hand_overs.*)
           FROM
             (SELECT dates.d,
                     reservations.user_id,
                     reservations.start_date
              FROM reservations
              WHERE inventory_pool_id = '#{inventory_pool_id}'
                AND status IN ('submitted', 'approved')
                AND start_date = dates.d
              GROUP BY user_id,
                       start_date) AS hand_overs) +
          (SELECT count(take_backs.*)
           FROM
             (SELECT dates.d,
                     reservations.user_id,
                     reservations.end_date
              FROM reservations
              WHERE inventory_pool_id = '#{UUIDTools::UUID.parse(inventory_pool_id)}'
                AND status = 'signed'
                AND end_date = dates.d
              GROUP BY user_id,
                       end_date) AS take_backs) AS visits_count
        FROM dates
      SQL
  end

  def run
    ApplicationRecord.connection.exec_query(@query).to_a
  end
end
