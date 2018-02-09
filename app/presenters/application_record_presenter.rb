class ApplicationRecordPresenter < ApplicationPresenter
  attr_accessor :record, :user
  private :record, :user

  def initialize(record, user: nil)
    fail 'TypeError!' unless record.is_a?(ActiveRecord::Base)
    @record = record
    @user = user
  end

  # common helpers for ActiveModels
  def __type
    record.class.name or super
  end

  def id
    record.try(:id)
  end

  def created_at
    record.try(:created_at)
  end

  def updated_at
    record.try(:updated_at)
  end

  # helpers to be used in ApplicationRecordPresenters
  def self.delegate_to_record(*args)
    delegate_to :record, *args
  end

  def self.delegate_to(inst_var, *args)
    args.each { |m| delegate m, to: inst_var }
  end

  # pundit helpers (if library is used)
  if defined? Pundit
    include Pundit

    def policy_for(user)
      raise TypeError, 'Not a User!' unless (user.nil? or user.is_a?(User))
      auth_policy(user, record)
    end
  end
end
