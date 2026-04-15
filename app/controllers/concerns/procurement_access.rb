module ProcurementAccess
  extend ActiveSupport::Concern

  def procurement_access?
    uuid = UUIDTools::UUID.parse(id).to_s
    sql = ApplicationRecord.sanitize_sql_array(
      [<<~SQL,
         SELECT (
           EXISTS (
             SELECT TRUE
             FROM procurement_requesters_organizations
             WHERE user_id = ?
           ) OR
           EXISTS (
             SELECT TRUE
             FROM procurement_category_viewers
             WHERE user_id = ?
           ) OR
           EXISTS (
             SELECT TRUE
             FROM procurement_category_inspectors
             WHERE user_id = ?
           ) OR
           EXISTS (
             SELECT TRUE
             FROM procurement_admins
             WHERE user_id = ?
           )
         ) as result
       SQL
       uuid, uuid, uuid, uuid]
    )
    rows = ApplicationRecord.connection.exec_query(sql)
    rows.first['result']
  end
end
