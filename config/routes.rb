Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  devise_for :users, path: '', path_names: {
      sign_in: 'login',
      sign_out: 'logout',
      registration: 'signup'
    },
    controllers: {
      sessions: 'users/sessions',
      registrations: 'users/registrations'
    }

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :user_relay_registrations, only: [ :index, :show, :update, :create, :destroy ]
      resources :users, only: [ :index, :show, :update, :create, :destroy ]
    end
  end
end
