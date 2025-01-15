Rails.application.routes.draw do

  if Rails.env.test?
    # NOTE: needed because of some assertions in tests
    get 'borrow', to: 'application#borrow'
  end

  if Rails.env.development? or Rails.env.test?
    root to: 'application#root'

    # NOTE: for prod path helper is added as application helper custom method
    post '/sign-in', to: 'application#sign_in'
    post '/sign-out', to: 'application#sign_out'
    # fake a my page so redirects dont look like errors to the Devs
    get '/my/auth-info', to: -> (hash) { [200, {}, ["<h1>Hello Dev! In prod, this would show <code>/my/auth-info</code>. Maybe try <a href='http://localhost:3240/my/auth-info'><code>http://localhost:3240/my/auth-info</code></a>?</h1>"]] }
  end

  get :status, controller: :application, action: :status

  # Categories
  get "category_links",       to: "category_links#index", as: "category_links"

  # Styleguide
  get "styleguide",           to: "styleguide#show"
  get "styleguide/:section",  to: "styleguide#show"

  # Models
  get "models/:id/image",       to: "models#image", as: "model_image"
  get "models/:id/image_thumb", to: "models#image", as: "model_image_thumb", size: :thumb

  # Properties
  get "properties", to: "properties#index", as: "properties"

  # Images
  get 'images/:id', to: 'images#show', as: 'get_image'
  get 'images/:id/thumbnail', to: 'images#thumbnail', as: 'get_image_thumbnail'

  # Attachments
  get 'attachments/:id', to: 'attachments#show', as: 'get_attachment'

  get 'release', to: 'release_info#index', as: 'release_info'

  # Old Admin Section
  namespace :admin do
    # Export inventory of all inventory pools
    get 'inventory/csv',          :to => 'inventory#csv_export',          :as => 'global_inventory_csv_export'
    get 'inventory/excel',        :to => 'inventory#excel_export',        :as => 'global_inventory_excel_export'
    get 'inventory/quick_csv',    :to => 'inventory#quick_csv_export',    :as => 'global_inventory_quick_csv_export'
    get 'inventory/quick_excel',  :to => 'inventory#quick_excel_export',  :as => 'global_inventory_quick_excel_export'
  end

  # Manage Section
  namespace :manage do
    root to: "application#root"

    # Users
    post 'users/:id/set_start_screen', to: 'users#set_start_screen'

    # Rooms
    get     'rooms',              to: 'rooms#index'

    get 'rooms_diff', to: 'rooms#get_rooms_diff'
    post 'rooms_diff', to: 'rooms#post_rooms_diff'

    scope ":inventory_pool_id/" do

      # maintenance
      get 'maintenance', to: 'application#maintenance'

      ## Availability
      get 'availabilities',           to: 'availability#index', as: 'inventory_pool_availabilities'
      get 'availabilities/in_stock',  to: 'availability#in_stock'

      ## Daily
      get 'daily', to: "inventory_pools#daily", as: "daily_view"

      ## Contracts
      get   'orders',                  to: "orders#index",      as: "orders"
      ###############################################################################
      # NOTE: query string length of GET is not enough for hand over dialog
      post  'orders',                  to: "orders#index",      as: "orders_via_post"
      ###############################################################################
      post  "orders/:id/approve",      to: "orders#approve",    as: "approve_order"
      post  "orders/:id/reject",       to: "orders#reject"
      put   "orders/:id",              to: "orders#update"
      post  'orders/:id/swap_user',    to: "orders#swap_user"
      get   'orders/:id/edit',         to: "orders#edit",       as: "edit_order"

      ## Contracts
      get   'contracts',                  to: "contracts#index",      as: "contracts"
      post  'contracts',                  to: "contracts#create",     as: "create_contract"
      get   "contracts/:id",              to: "contracts#show",       as: "contract"
      get   "contracts/:id/value_list",   to: "contracts#value_list", as: "value_list"
      get   "contracts/:id/picking_list", to: "contracts#picking_list", as: "picking_list"

      ## Visits
      delete  'visits/:visit_id',        to: 'visits#destroy'
      post    'visits/:visit_id/remind', to: 'visits#remind'
      get     'visits/hand_overs',       to: 'visits#index',     status: "approved"
      get     'visits/take_backs',       to: 'visits#index',     status: "signed"
      get     'visits',                  to: "visits#index",     as: "inventory_pool_visits"

      ## Workload
      get 'workload', to: 'inventory_pools#workload'

      ## Latest Reminder
      get 'latest_reminder', to: 'inventory_pools#latest_reminder'

      ## Workdays
      get 'workdays', to: "workdays#index"

      ## Holidays
      get 'holidays', to: "holidays#index"

      ## Reservations
      get     "reservations",                        to: "reservations#index"
      post    "reservations",                        to: "reservations#create"
      delete  "reservations",                        to: "reservations#destroy"
      post    "reservations/swap_user",              to: "reservations#swap_user"
      post    "reservations/swap_model",             to: "reservations#swap_model"
      post    "reservations/edit_purpose",           to: "reservations#edit_purpose"
      post    "reservations/assign_or_create",       to: "reservations#assign_or_create"
      post    "reservations/change_time_range",      to: "reservations#change_time_range"
      post    "reservations/for_template",           to: "reservations#create_for_template"
      post    "reservations/:id/assign",             to: "reservations#assign"
      post    "reservations/:id/remove_assignment",  to: "reservations#remove_assignment"
      put     "reservations/:line_id",               to: "reservations#update"
      delete  "reservations/:line_id",               to: "reservations#destroy"
      post    "reservations/take_back",              to: "reservations#take_back"
      post    "reservations/print",                  to: "reservations#print", as: "print_reservations"

      # Inventory
      get  'inventory',                  :to => "inventory#index",         :as => "inventory"
      get  'inventory/expert/index',     :to => "expert#index"
      get  'inventory/csv',              :to => "inventory#csv_export",    :as => "inventory_csv_export"
      get  'inventory/excel',            :to => "inventory#excel_export",  :as => "inventory_excel_export"
      get  'inventory/csv/expert',       :to => "expert#csv_export",       :as => "inventory_csv_export_expert"
      get  'inventory/excel/expert',     :to => "expert#excel_export",     :as => "inventory_excel_export_expert"
      get  'inventory/csv_import',       :to => "inventory#csv_import"
      post 'inventory/csv_import',       :to => "inventory#csv_import"
      get  'inventory/helper',           :to => "inventory#helper",        :as => "inventory_helper"
      get  'inventory/helper_react',     :to => "inventory#helper_react",  :as => "inventory_helper_react"
      get  'inventory/expert',           :to => "inventory#expert",        :as => "inventory_expert"
      get  'inventory/find',             :to => "inventory#find"

      # Models
      get     'models',                          to: "models#index",                    as: "models"
      post    'models',                          to: "models#create",                   as: "create_model"
      get     'models/new_old',                  to: "models#new_old",                  as: "new_model_old"
      get     'models/new',                      to: "models#new",                      as: "new_model"
      post    'models/store_attachment_react',   to: "models#store_attachment_react",   as: "model_store_attachment_react"
      post    'models/store_image_react',        to: "models#store_image_react",        as: "model_store_image_react"
      get     'models/:id/timeline',             to: "models#timeline"
      get     'models/:id/old_timeline',         to: "models#old_timeline"
      put     'models/:id',                      to: "models#update"
      get     'models/:id',                      to: "models#show"
      delete  'models/:id',                      to: "models#destroy"
      get     'models/:id/edit',                 to: "models#edit",                     as: "edit_model"
      get     'models/:id/edit_old',             to: "models#edit_old",                 as: "edit_old_model"
      post    'models/:id/upload/image',         to: "models#upload",                   type: "image"
      post    'models/:id/upload/attachment',    to: "models#upload",                   type: "attachment"

      # Categories
      get     'categories',                       to: 'categories#index',           as: 'categories'

      # Options
      get   'options',            to: "options#index"
      post  'options',            to: "options#create",     as: "create_option"
      get   'options/new',        to: "options#new",        as: "new_option"
      get   'options/:id/edit',   to: "options#edit",       as: "edit_option"
      put   'options/:id',        to: "options#update",     as: "update_option"

      # Items
      get    'items',                          to: "items#index"
      post   'items',                          to: "items#create",                  as: "create_item"
      post   'items/create_multiple',          to: "items#create_multiple",         as: "create_multiple_items"
      get    'items/create_multiple/result',   to: "items#create_multiple_result",  as: "create_multiple_items_result"
      post   'items/create_package',           to: "items#create_package",          as: "create_package"
      get    'items/new',                      to: "items#new",                     as: "new_item"
      post   'items/store_attachment_react',   to: "items#store_attachment_react",  as: "item_store_attachment_react"
      get    'items/current_locations',        to: "items#current_locations"
      get    'items/:id',                      to: "items#show"
      put    'items/:id',                      to: "items#update",                  as: "update_item"
      get    'items/:id/edit',                 to: "items#edit",                    as: "edit_item"
      get    'items/:id/copy',                 to: "items#copy",                    as: "copy_item"
      post   'items/:id/inspect',              to: "items#inspect"
      post   'items/:id/upload/attachment',    to: "items#upload",                  type: "attachment"

      # Partitions
      get 'partitions', to: "partitions#index"

      # Entitlement Groups
      get     'groups',           to: "entitlement_groups#index",      as: "inventory_pool_groups"
      get     'groups/:id/edit',  to: "entitlement_groups#edit",       as: "edit_inventory_pool_group"
      get     'groups/new',       to: "entitlement_groups#new",        as: "new_inventory_pool_group"
      post    'groups',           to: "entitlement_groups#create"
      put     'groups/:id',       to: "entitlement_groups#update",     as: "update_inventory_pool_group"
      delete  'groups/:id',       to: "entitlement_groups#destroy",    as: "delete_inventory_pool_group"


      get     'user_groups',      to: "user_groups#index",             as: "inventory_pool_user_groups"

      # ModelLinks
      get 'model_links', to: "model_links#index"

      # Templates
      get     'templates',              to: "templates#index",        as: "templates"
      post    'templates',              to: "templates#create"
      get     'templates/new',          to: "templates#new",          as: "new_template"
      get     'templates/:id/edit',     to: "templates#edit",         as: "edit_template"
      put     'templates/:id',          to: "templates#update",       as: "update_template"
      delete  'templates/:id',          to: "templates#destroy",      as: "delete_template"

      # Users
      get      "users",               to: "users#index",     as: "inventory_pool_users"
      get      'users/:id/hand_over', to: "users#hand_over", as: "hand_over"
      get      'users/:id/take_back', to: "users#take_back", as: "take_back"

      # Access rights
      get "access_rights", to: "access_rights#index"

      # Fields
      get 'fields', to: 'fields#index', as: 'fields'
      # Search
      post 'search',               to: 'search#search',        as: "search"
      get  'search',               to: 'search#results',       as: "search_results"
      get  'search/models',        to: "search#models",        as: "search_models"
      get  'search/software',      to: "search#software",      as: "search_software"
      get  'search/items',         to: "search#items",         as: "search_items"
      get  'search/licenses',      to: "search#licenses",      as: "search_licenses"
      get  'search/users',         to: "search#users",         as: "search_users"
      get  'search/contracts',     to: "search#contracts",     as: "search_contracts"
      get  'search/orders',        to: "search#orders",        as: "search_orders"
      get  'search/options',       to: "search#options",       as: "search_options"

    end

  end

end
