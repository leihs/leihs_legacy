class ReleaseInfoController < ActionController::Base

  layout 'splash'

  def index
    @get = RELEASE_INFO
  end

end
