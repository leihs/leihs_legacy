require_dependency 'procurement/application_controller'

module Procurement
  class SettingsController < ApplicationController

    before_action do
      authorize Procurement::Setting
    end

    def edit
      @settings = Procurement::Setting.all_as_hash
    end

    def create
      errors = update_settings

      if errors.empty?
        flash[:success] = _('Saved')
        head :ok
      else
        render json: errors, status: :internal_server_error
      end
    end

    private

    def update_settings
      settings = Procurement::Setting.first || Procurement::Setting.new
      setting_keys = Procurement::Setting.all_as_hash.keys
      attrs = params.permit(settings: setting_keys).require(:settings).to_h
      settings.update_attributes!(attrs)
      settings.errors.full_messages.flatten.compact
    end
  end
end
