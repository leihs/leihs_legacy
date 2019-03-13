module Delegation::User

  # rubocop:disable Metrics/MethodLength
  def self.included(base)
    base.class_eval do

      belongs_to :delegator_user, class_name: 'User'

      # NOTE this method is called from a normal user perspective
      has_and_belongs_to_many :delegations,
                              class_name: 'User',
                              join_table: 'delegations_users',
                              foreign_key: 'user_id',
                              association_foreign_key: 'delegation_id'

      # NOTE this method is called from a delegation perspective
      has_and_belongs_to_many :delegated_users,
                              class_name: 'User',
                              join_table: 'delegations_users',
                              foreign_key: 'delegation_id',
                              association_foreign_key: 'user_id'

      scope :as_delegations, -> { where.not(delegator_user_id: nil) }
      scope :not_as_delegations, -> { where(delegator_user_id: nil) }

      #############################################################################
      # HANDLING OF REMOVED MEMBERS ###############################################
      #############################################################################
      attr_reader :old_delegated_user_ids
      after_initialize do
        if delegation?
          @old_delegated_user_ids = \
            ::DelegationUser.where(delegation_id: id).map(&:user_id)
        end
      end

      before_update do
        if delegation?
          # fallback to [] because of factory
          removed_user_ids = (old_delegated_user_ids or []) - delegated_user_ids
          unless removed_user_ids.empty?
            #######################################################################
            # Raise if one tries to remove a delegation member, who still has open
            # reservations done in the name of this delegation.
            user_ids_with_open_reservations = []

            removed_user_ids.each do |user_id|
              open_reservations_of_user = \
                ::Reservation
                .where(user_id: self.id, delegated_user_id: user_id)
                .where(status: [:submitted, :approved, :signed])

              if open_reservations_of_user.exists?
                user_ids_with_open_reservations.push(user_id)
              end
            end

            unless user_ids_with_open_reservations.empty?
              users_with_open_reservations = \
                ::User.find(user_ids_with_open_reservations)
              raise \
                [_('There are open reservations for delegated users: '),
                 users_with_open_reservations.map(&:name).join(', '),
                 '.'].join
            end
            #######################################################################

            removed_user_ids.each do |user_id|
              # destroy sessions
              ::UserSession
                .where(delegation_id: self.id, user_id: user_id)
                .each(&:destroy!)

              # destroy unsubmitted reservations
              ::Reservation
                .where(user_id: self.id, delegated_user_id: user_id)
                .where(status: :unsubmitted)
                .each(&:destroy!)
            end
          end
        end
      end
      #############################################################################
      #############################################################################

      before_validation do
        if delegation?
          unless delegated_users.include? delegator_user
            delegated_users << delegator_user
          end
        end
      end

      validate do
        if delegation?
          unless delegated_users.include? delegator_user
            errors.add \
              :base,
              _('The responsible user has to be member of the delegation')
          end
        end
      end

    end
  end
  # rubocop:enable Metrics/MethodLength

  def delegation?
    not delegator_user_id.nil?
  end

end
