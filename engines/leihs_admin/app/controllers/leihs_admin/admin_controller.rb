module LeihsAdmin
  class AdminController < ApplicationController
    layout 'leihs_admin/admin'

    before_action do
      not_authorized!(redirect_path: main_app.root_path) unless admin?
    end

    unless Rails.env.production?
      def top
        routes = Engine.routes.routes
        @index_names =
          routes
          .select do |r|
            begin
              r.path.spec.left.memo.defaults[:action] == 'index'
            rescue
              nil
            end
          end
          .map(&:name)
          .reject { |n| ['individual_audits', 'users'].include? n }
          .push('settings', 'fields_editor')
          .sort

        render 'leihs_admin/top'
      end
    end
  end
end
