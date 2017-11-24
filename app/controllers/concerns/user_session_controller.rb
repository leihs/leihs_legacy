require 'cider_ci/open_session/encryptor'

# Note about `secure` cookies:  cookies can be set to secure via settings,
# the default is false because:
# - it could break existing leihs instances, and the easiest way to fix it
#     would be via the database
# - it is very obscure when this causes problems

# UserSessionController instead of the more appropriate UserSession
# to avoid conflicts with the UserSession model
module Concerns
  module UserSessionController
    extend ActiveSupport::Concern

    attr_accessor :user_session

    USER_SESSION_COOKIE_NAME = 'leihs-user-session'.freeze

    def delete_user_session_cookie
      cookies.delete USER_SESSION_COOKIE_NAME
    end

    def user_by_session
      if user_session_cookie = cookies[USER_SESSION_COOKIE_NAME].presence
        begin
          session_object = CiderCi::OpenSession::Encryptor.decrypt(
            secret_key_base, user_session_cookie
          ).deep_symbolize_keys
          @user_session = UserSession.find_by! \
            token_hash: Digest::SHA256.hexdigest(session_object[:token])
          validate_lifetime!(@user_session)
          @user_session.delegation || @user_session.user
        rescue Exception => e
          Rails.logger.warn e
          reset_session
          delete_user_session_cookie
          nil
        end
      end
    end

    def create_user_session(user)
      token = SecureRandom.uuid
      token_hash = Digest::SHA256.hexdigest token
      value = CiderCi::OpenSession::Encryptor.encrypt(
        secret_key_base, user_id: user.id,
                         token: token
      )
      cookies[USER_SESSION_COOKIE_NAME] = {
        expires: 10.years.from_now,
        value: value,
        httponly: true,
        secure: Setting.first.try(:sessions_force_secure)
      }
      if Setting.first.try(:sessions_force_uniqueness) && !user.delegation?
        UserSession.destroy_all(user_id: user.id)
      end
      @user_session = UserSession.create user_id: user.id, token_hash: token_hash
    end

    private

    def secret_key_base
      Rails.application.secrets.secret_key_base.presence \
        || raise('secret_key_base is missing')
    end

    def validate_lifetime_duration!(lifetime, max_lifetime)
      if lifetime > max_lifetime
        raise 'The session has expired!'
      end
    end

    def validate_lifetime!(user_session)
      lifetime = Time.zone.now - user_session.created_at
      if lifetime >
        (Setting.first.try(:sessions_max_lifetime_secs) || (5 * 24 * 60 * 60))
        raise 'The session has expired!'
      end
    end

  end
end
