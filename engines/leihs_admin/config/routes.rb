LeihsAdmin::Engine.routes.draw do

  root to: redirect('/admin/top')
  
  unless Rails.env.production?
    get 'top', to: 'admin#top'
  end

  # Audits
  get 'audits',           to: 'audits#index'
  get ':type/:id/audits', to: 'audits#index', as: 'individual_audits'

end
