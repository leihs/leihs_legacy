require_dependency 'procurement/application_controller'

module Procurement
  class SettingsController < ApplicationController

    before_action do
      unless procurement_admin?
        raise Errors::ForbiddenError
      end
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
      settings.update_attributes!(coerce_values(attrs))
      settings.errors.full_messages.flatten.compact
    end

    def coerce_values(attrs)
      attrs.map do |key, val|
        coerced_val = \
          case key
          when 'inspection_comments'
            val.split("\n").map(&:strip).map(&:presence).compact
          end
        [key, coerced_val || val]
      end.to_h
    end

  end
end
