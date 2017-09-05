#!/usr/bin/env ruby

require 'net/http'
require 'json'

r = Net::HTTP.get(URI('https://api.github.com/repos/rails/rails/issues/25198'))
j = JSON.parse(r)

if j['state'] == 'closed'
  exit 1
else
  exit 0
end
