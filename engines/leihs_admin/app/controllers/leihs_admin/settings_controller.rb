module LeihsAdmin
  class SettingsController < AdminController

    def edit
      @settings = Setting.first || Setting.new
    end

    def update
      @settings = Setting.first || Setting.new

      if @settings.update_attributes(params[:setting])
        flash[:notice] = _('Successfully set.')
        redirect_to admin.settings_path
      else
        flash.now[:error] = @settings.errors.full_messages.uniq.join(', ')
        render :edit
      end
    end

  end

end
