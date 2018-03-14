LeihsAdmin::Engine.routes.draw do

  root to: redirect('/admin/inventory_pools')

  resources :authentication_systems, only: :index
  resources :buildings,       except: :show
  resources :inventory_pools, except: :show
  resources :locations,       only: :destroy
  resources :rooms,           except: :show
  resources :statistics,      only: [:index, :show]
  resources :suppliers,       except: []
  resources :users,           except: :show

  # Audits
  get 'audits',           to: 'audits#index'
  get ':type/:id/audits', to: 'audits#index', as: 'individual_audits'

  # Export inventory of all inventory pools
  get 'inventory/csv',              :to => 'inventory#csv_export',  :as => 'global_inventory_csv_export'
  get 'inventory/excel',            :to => 'inventory#excel_export',  :as => 'global_inventory_excel_export'

  # Fields
  get 'fields', to: 'fields#index'
  post 'batch_update_fields', to: 'fields#batch_update'

  get 'fields_editor', to: 'fields_editor#edit_react'
  delete 'fields_editor/:id', to: 'fields_editor#destroy'
  get 'fields_editor/all_fields', to: 'fields_editor#all_fields'
  get 'fields_editor/groups', to: 'fields_editor#groups'
  get 'fields_editor/single_field/(:id)', to: 'fields_editor#single_field', :as => 'fields_editor_single_field'
  get 'fields_editor/edit_react', to: 'fields_editor#edit_react'
  put 'fields_editor/new_react', to: 'fields_editor#new_react'
  post 'fields_editor/update_react', to: 'fields_editor#update_react'

  # Administrate settings
  get 'settings', to: 'settings#edit'
  put 'settings', to: 'settings#update'

  # Mail templates
  get 'mail_templates', to: 'mail_templates#index'
  get 'mail_templates/:dir/:name', to: 'mail_templates#edit'
  put 'mail_templates/:dir/:name', to: 'mail_templates#update'

  # Languages
  get 'languages',           to: 'languages#index'
end
