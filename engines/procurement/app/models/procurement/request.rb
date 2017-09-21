require_dependency 'procurement/concerns/csv'
require_dependency 'procurement/concerns/request_filters'

module Procurement
  class Request < ApplicationRecord
    include Csv
    include RequestFilters

    belongs_to :budget_period
    belongs_to :category
    belongs_to :organization
    belongs_to :template
    belongs_to :user      # from parent application
    belongs_to :model     # from parent application
    belongs_to :supplier  # from parent application
    belongs_to :room # from parent application

    has_many :attachments, dependent: :destroy, inverse_of: :request
    accepts_nested_attributes_for :attachments, reject_if: :all_blank

    monetize :price_cents, allow_nil: true

    REQUESTER_NEW_KEYS = [:requested_quantity, :priority, :replacement]
    REQUESTER_EDIT_KEYS = [:article_name, :model_id, :article_number, :price,
                           :supplier_name, :supplier_id, :motivation, :receiver,
                           :room_id, :template_id,
                           attachments_attributes: [:content,
                                                    :filename,
                                                    :size,
                                                    :metadata,
                                                    :content_type]]
    INSPECTOR_KEYS = [:requested_quantity,
                      :approved_quantity,
                      :order_quantity,
                      :inspection_comment,
                      :inspector_priority,
                      :replacement,
                      :accounting_type,
                      :internal_order_number]

    ACCOUNTING_TYPES = ['aquisition', 'investment']

    #################################################################

    # NOTE not executing on unchanged existing records
    before_validation on: [:create, :update] do
      self.price ||= 0

      self.order_quantity ||= approved_quantity
      self.approved_quantity ||= order_quantity

      validates_budget_period
    end

    before_validation on: :create do
      access = Access.requesters.find_by(user_id: user_id)
      if access
        self.organization_id ||= access.organization_id
      else
        errors.add(:user, _('must be a requester'))
      end
    end

    validates_presence_of :user, :category, :organization,
                          :article_name, :motivation
    validates_presence_of :inspection_comment, if: :not_completely_approved?
    validates_presence_of :internal_order_number, if: :investment?
    validates :requested_quantity,
              presence: true,
              numericality: { greater_than: 0 }

    before_destroy do
      validates_budget_period
      throw :abort unless errors.empty?
    end

    def validates_budget_period
      errors.add(:budget_period, _('is over')) if budget_period.past?
    end

    #################################################################

    def requested_by?(u)
      user == u
    end

    def editable?(user)
      Access.requesters.find_by(user_id: user_id) and
        (
         (category.inspectable_by?(user) and not budget_period.past?) or
         (requested_by?(user) and budget_period.in_requesting_phase?)
        )
    end

    # NOTE keep this order for the sorting
    STATES = [:new, :in_inspection, :approved, :partially_approved, :denied]

    # rubocop:disable Metrics/PerceivedComplexity
    def state(user)
      if budget_period.past? or
          Procurement::Category.inspector_of_any_category?(user) or
          Procurement::Access.admin?(user)
        if approved_quantity.nil?
          :new
        elsif approved_quantity == 0
          :denied
        elsif 0 < approved_quantity and approved_quantity < requested_quantity
          :partially_approved
        elsif approved_quantity >= requested_quantity
          :approved
        else
          raise
        end
      elsif budget_period.in_inspection_phase?
        :in_inspection
      else
        :new
      end
    end
    # rubocop:enable Metrics/PerceivedComplexity

    def total_price(current_user)
      quantity = \
        if (not budget_period.in_requesting_phase?) or
          Procurement::Category.inspector_of_any_category?(current_user) or
          Procurement::Access.admin?(current_user)
          order_quantity || approved_quantity || requested_quantity
        else
          requested_quantity
        end
      price * quantity
    end

    def investment?
      accounting_type == 'investment'
    end

    private

    def not_completely_approved?
      approved_quantity and approved_quantity < requested_quantity
    end

  end
end
