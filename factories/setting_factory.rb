# coding: UTF-8

FactoryGirl.define do

  factory :setting do
    local_currency_string { 'CHF' }
    contract_lending_party_string { "Your\nAddress\nHere" }
    email_signature { 'Das PZ-leihs Team' }
    deliver_received_order_notifications { false }
    user_image_url do
      'http://www.zhdk.ch/?person/foto&width=100&compressionlevel=0&id={:id}'
    end
    logo_url { '/assets/image-logo-zhdk.png' }
  end

end
