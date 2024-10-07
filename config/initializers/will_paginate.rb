# https://github.com/mislav/will_paginate/wiki/Troubleshooting

require 'will_paginate/array'
require File.join(Rails.root, 'app/models/concerns/default_pagination')

class Array
  include DefaultPagination::Collection
end
