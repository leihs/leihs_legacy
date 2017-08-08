module Procurement
  class Attachment < ApplicationRecord

    belongs_to :request, inverse_of: :attachments

    validates_presence_of :content
    validates_presence_of :request
  end
end
