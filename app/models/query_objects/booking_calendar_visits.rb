class QueryObjects::BookingCalendarVisits
  attr_reader :query

  def self.cast_date(value)
    value.is_a?(Date) ? value : Date.parse(value.to_s)
  end

  def initialize(inventory_pool_id:, start_date:, end_date:)
    pool_id = UUIDTools::UUID.parse(inventory_pool_id).to_s
    start_d = self.class.cast_date(start_date)
    end_d = self.class.cast_date(end_date)
    @query = ApplicationRecord.sanitize_sql_array(
      [<<~SQL,
         WITH dates AS
           (SELECT d::date
            FROM generate_series(?::date,
                                 ?::date,
                                 '1 day'::interval) AS d)
         SELECT dates.d,
           (SELECT count(hand_overs.*)
            FROM
              (SELECT dates.d,
                      reservations.user_id,
                      reservations.start_date
               FROM reservations
               WHERE inventory_pool_id = ?
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
               WHERE inventory_pool_id = ?
                 AND status = 'signed'
                 AND end_date = dates.d
               GROUP BY user_id,
                        end_date) AS take_backs) AS visits_count
         FROM dates
       SQL
       start_d, end_d, pool_id, pool_id]
    )
  end

  def run
    ApplicationRecord.connection.exec_query(@query).to_a
  end
end
