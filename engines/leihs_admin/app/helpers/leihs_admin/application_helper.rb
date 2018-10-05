module LeihsAdmin
  module ApplicationHelper
    include LinkifyHelper

    if Rails.env.production?
      def sign_in_path
        '/sign-in'
      end

      def sign_out_path
        '/sign-out'
      end
    end

  end
end
