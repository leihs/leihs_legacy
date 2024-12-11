module ProcurementAccess
  extend ActiveSupport::Concern

  def procurement_access?
    uuid = UUIDTools::UUID.parse(id)
    rows = ApplicationRecord.connection.exec_query <<-SQL
      SELECT (
        EXISTS (
          SELECT TRUE
          FROM procurement_requesters_organizations
          WHERE user_id = '#{uuid}'
        ) OR
        EXISTS (
          SELECT TRUE
          FROM procurement_category_viewers
          WHERE user_id = '#{uuid}'
        ) OR
        EXISTS (
          SELECT TRUE
          FROM procurement_category_inspectors
          WHERE user_id = '#{uuid}'
        ) OR
        EXISTS (
          SELECT TRUE
          FROM procurement_admins
          WHERE user_id = '#{uuid}'
        )
      ) as result
    SQL
    rows.first['result']
  end
end
