module Procurement
  module Errors
    class UnauthorizedError < StandardError
      # If the request requires a login, but user is not logged in.
    end

    class ForbiddenError < StandardError
      # If user is logged in, but access is denied.
    end
  end
end
