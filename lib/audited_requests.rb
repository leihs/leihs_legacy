# make this class in lib/transactional_requests.rb, and load it on start
require 'active_record'

class AuditedRequests
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)

    ActiveRecord::Base.transaction do
      persist_request(request)
      @app.call(env)
    end
  end
   
  private

  def db_conn
    ActiveRecord::Base.connection
  end

  def persist_request(request)
    user_id = "'#{session_user(request.cookies).try(:id)}'" || "NULL"

    db_conn.execute <<-SQL
      INSERT INTO audited_requests (
        txid,
        http_uid,
        url,
        user_id,
        method
      )
      VALUES (
        '#{txid}',
        '#{env["HTTP_HTTP_UID"]}',
        '#{env["REQUEST_URI"]}',
        #{user_id},
        '#{env["REQUEST_METHOD"].downcase}'
      )
    SQL
  end

  def session_user(cookies)
    token = cookies['leihs-user-session']
    user_session = UserSession.find_by_token(token)
    user_session.try { |us| us.delegation or us.user }
  end
end
