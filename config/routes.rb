Spree::Core::Engine.add_routes do
  resources :addresses

  namespace :api, defaults: { format: 'json' } do
    namespace :v1 do
      namespace :mine do
        resources :addresses, only: [:create, :index, :show, :update, :destroy] do
          member do
            put 'set_default'
            patch 'set_default'
          end
          collection do
            get 'countries'
          end
        end
      end
    end
  end

  if Rails.env.test?
    put '/cart', :to => 'orders#update', :as => :put_cart
  end
end