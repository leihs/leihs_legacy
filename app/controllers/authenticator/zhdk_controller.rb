require 'net/http'
require 'net/https'
require 'cgi'

# Server instances which don't rely on ZHdK login (e.g. demo) don't setup
# this file during deployment proces.
agw_info_path = File.join(Rails.root,
                          'app',
                          'controllers',
                          'authenticator',
                          'agw_info.rb')
if File.exists?(agw_info_path)
  require agw_info_path
end

class Authenticator::ZhdkController < Authenticator::AuthenticatorController
  # Server instances which don't rely on ZHdK login (e.g. demo) don't setup
  # the respective file and thus don't have this module defined.
  if defined?(AGWInfo)
    include AGWInfo
  end

  SUPER_USERS = ['e157339|zhdk',
                 'e159123|zhdk',
                 'e10262|zhdk',
                 'e162205|zhdk',
                 'e171014|zhdk'] # Jerome, Franco, Ramon, Tomáš
  AUTHENTICATION_SYSTEM_CLASS_NAME = 'Zhdk'

  def login_form_path
    '/authenticator/zhdk/login'
  end

  def login
    super
    redirect_to target
  end

  def target
    Rails.logger.info \
      "Setting.external_base_url: #{app_settings.external_base_url}"

    unless defined? AUTHENTICATION_URL
      throw 'Missing AUTHENTICATION_URL. Check agw_info_template.rb!'
    end

    AUTHENTICATION_URL \
      + '&url_postlogin=' \
      + CGI::escape("#{app_settings.external_base_url}/" \
                    "#{url_for('authenticator/zhdk/login_successful/%s')}")
  end

  def login_successful(session_id = params[:id])
    response = fetch("#{AUTHENTICATION_URL}/response" \
                     "&agw_sess_id=#{session_id}" \
                     "&app_ident=#{APPLICATION_IDENT}")
    if Integer(response.code) == 200
      xml = Hash.from_xml(response.body)
      # old# uid = xml["authresponse"]["person"]["uniqueid"]
      self.current_user = create_or_update_user(xml)
      redirect_back_or_default('/') # TODO: #working here#24
    else
      render plain: 'Authentication Failure. HTTP connection failed ' \
                    "- response was #{response.code}"
    end
  end

  def create_or_update_user(xml)
    return false unless xml['authresponse']['person']
    uid = xml['authresponse']['person']['uniqueid']
    email = xml['authresponse']['person']['email'] || uid + '@leihs.zhdk.ch'
    phone = "#{xml['authresponse']['person']['phone_mobile']}"
    phone = "#{xml['authresponse']['person']['phone_business']}" if phone.blank?
    phone = "#{xml['authresponse']['person']['phone_private']}" if phone.blank?
    user = \
      User.where(org_id: uid).first \
      || User.where(email: email).first \
      || User.new
    user.org_id = uid
    user.email = email
    user.phone = phone
    user.firstname = "#{xml['authresponse']['person']['firstname']}"
    user.lastname = "#{xml['authresponse']['person']['lastname']}"
    user.login = "#{user.firstname} #{user.lastname}"
    user.address = "#{xml['authresponse']['person']['address1']}, " \
                   "#{xml['authresponse']['person']['address2']}"
    user.zip = "#{xml['authresponse']['person']['countrycode']}-" \
               "#{xml['authresponse']['person']['zip']}"
    user.country = "#{xml['authresponse']['person']['country_de']}"
    user.city = "#{xml['authresponse']['person']['place']}"
    user.authentication_system = \
      AuthenticationSystem
        .where(class_name: AUTHENTICATION_SYSTEM_CLASS_NAME)
        .first
    user.extended_info = xml['authresponse']['person']
    user.save

    if SUPER_USERS.include?(user.org_id)
      user.update_attributes!(is_admin: true)
    end
    user
  end

  private

  def fetch(uri_str, limit = 10)
     raise ArgumentError, 'HTTP redirect too deep' if limit == 0

     uri = URI.parse(uri_str)
     http = Net::HTTP.new(uri.host, uri.port)
     http.use_ssl = true if uri.port == 443
     response = http.get(uri.path + '?' + uri.query)
     case response
     when Net::HTTPSuccess     then response
     when Net::HTTPRedirection then fetch(response['location'], limit - 1)
     else
       response.error!
     end
  end

end
