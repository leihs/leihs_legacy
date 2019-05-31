class UserSession < ApplicationRecord
  belongs_to :user
  belongs_to :delegation, foreign_key: :delegation_id, class_name: 'User'
  belongs_to :authentication_system

  def self.find_by_token_base(token)
    where(<<-SQL.strip_heredoc, token)
      user_sessions.token_hash = encode(digest(?, 'sha256'), 'hex')
    SQL
      .joins(:user)
      .where(users: { account_enabled: true })
  end

  def self.find_by_token(token)
    find_by_token_base(token)
      .joins(<<-SQL.strip_heredoc)
        INNER JOIN settings
        ON settings.id = 0
      SQL
      .where(<<-SQL.strip_heredoc)
        now() <
          user_sessions.created_at +
          settings.sessions_max_lifetime_secs * interval '1 second'
      SQL
      .first
  end
end
