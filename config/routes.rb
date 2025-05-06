Rails.application.routes.draw do
  devise_for :users

  resources :apartments do
    collection do
      get 'search'
    end
    member do
      post 'favorite'
      delete 'unfavorite'
    end
  end

  resources :users, only: [:show, :edit, :update]

  namespace :admin do
    resources :apartments
    resources :users
    root to: 'dashboard#index'
  end

  root 'apartments#index'
end