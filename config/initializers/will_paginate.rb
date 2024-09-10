# https://github.com/mislav/will_paginate/wiki/Troubleshooting

require 'will_paginate/array'
require 'default_pagination'

class Array
  include DefaultPagination::Collection
end
