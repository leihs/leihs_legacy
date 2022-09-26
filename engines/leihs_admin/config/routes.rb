LeihsAdmin::Engine.routes.draw do

  root to: redirect('/admin/top')
  
  unless Rails.env.production?
    get 'top', to: 'admin#top'
  end

  resources :locations,       only: :destroy
  resources :users,           only: :index

  # Audits
  get 'audits',           to: 'audits#index'
  get ':type/:id/audits', to: 'audits#index', as: 'individual_audits'

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

  # Mail templates
  get 'mail_templates', to: 'mail_templates#index'
  get 'mail_templates/:dir/:name', to: 'mail_templates#edit'
  put 'mail_templates/:dir/:name', to: 'mail_templates#update'
end
