require "sidekiq/web"
Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  mount Sidekiq::Web => "/sidekiq"

  # Defines the root path route ("/")
  root "hospitals#index"
  resources :hospitals do
    resources :imports, only: [:new, :create, :index] do
    end
  end

  resources :imports, only: [:index] do
    member do
      get :errors
    end
  end

  post 'imports/uploaded', to: 'imports#uploaded', as: 'import_uploaded'

  get 'patients/:id', to: 'patients#show', as: 'patient'

  get '/imports/sample-yaml', to: 'imports#sample_yaml', as: 'sample_yaml_imports'
  get '/imports/:id/yaml-download', to: 'imports#download_yaml', as: 'yaml_import_download'
end
