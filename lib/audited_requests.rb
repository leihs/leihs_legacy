require 'active_record'

class AuditedRequests
  def initialize(app)
    @app = app
  end

  HTTP_UNSAFE_METHODS = ["DELETE", "PATCH", "POST", "PUT"]

  def call(env)
    if unsafe_method?(env["REQUEST_METHOD"])
      ActiveRecord::Base.transaction do
        txid = get_txid
        persist_request(txid, env)
        response = @app.call(env)
        persist_response(txid, response)
        response
      end
    else
      @app.call(env)
    end
  end
   
  private

  def unsafe_method?(m)
    HTTP_UNSAFE_METHODS.include?(m)
  end

  def db_conn
    ActiveRecord::Base.connection
  end

  def get_txid
    db_conn.execute("SELECT txid() AS txid").entries.first['txid']
  end

  def persist_request(txid, env)
    url = env["REQUEST_URI"]
    request = Rack::Request.new(env)
    user_id = session_user(request.cookies).try(:id)
    http_uid = env["HTTP_HTTP_UID"]
    method = env["REQUEST_METHOD"].downcase

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
        #{http_uid.presence ? "'#{http_uid}'" : "NULL"},
        #{url.presence ? "'#{url}'" : "NULL"},
        #{user_id.presence ? "'#{user_id}'" : "NULL"},
        #{method.presence ? "'#{method}'" : "NULL"}
      )
    SQL
  end

  def persist_response(txid, (status))
    db_conn.execute <<-SQL
      INSERT INTO audited_responses (txid, status)
      VALUES ('#{txid}', '#{status}')
    SQL
  end

  def session_user(cookies)
    token = cookies['leihs-user-session']
    user_session = UserSession.find_by_token(token)
    user_session.try { |us| us.delegation or us.user }
  end
end
