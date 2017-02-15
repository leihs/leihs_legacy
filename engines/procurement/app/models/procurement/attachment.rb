module Procurement
  class Attachment < ActiveRecord::Base

    belongs_to :request, inverse_of: :attachments

    validates_presence_of :content
    validates_presence_of :request
  end
end
