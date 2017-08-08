module Concerns
  module ScopeIfPresence
    extend ActiveSupport::Concern

    # Calls block on current scope if arg.presence, otherwise returns
    # current scope.
    #################################################################
    # Instead of:
    #################################################################
    # audits = Audit.all
    #
    # if auditable_type
    #   audits = audits.where(auditable_type: auditable_type)
    # end
    #
    # if auditable_id
    #   audits = audits.where(auditable_id: auditable_id)
    # end
    #
    # if start_date
    #   audits = audits.filter_since_start_date(start_date)
    # end
    #
    #################################################################
    # You can write in in functional style:
    #################################################################
    # Audit
    #   .scope_if_presence(auditable_type) do |audits, auditable_type|
    #     audits.where(auditable_type: auditable_type)
    #   end
    #   .scope_if_presence(auditable_id) do |audits, auditable_id|
    #     audits.where(auditable_id: auditable_id)
    #   end
    #   .scope_if_presence(start_date) do |audits, start_date|
    #     audits.filter_since_start_date(start_date)
    #   end
    #   ...
    #
    module ClassMethods
      def scope_if_presence(arg)
        if arg.presence
          yield(all, arg)
        else
          all
        end
      end
    end
  end
end
