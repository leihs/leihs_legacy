module LeihsAdmin
  class LanguagesController < AdminController
    def index
      @languages = Language.all
    end
  end
end
