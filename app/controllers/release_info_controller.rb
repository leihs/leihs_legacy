class ReleaseInfoController < ActionController::Base
  include AppSettings

  layout 'splash'

  def index
    @get = RELEASE_INFO
  end

end
