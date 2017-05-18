Rails.application.routes.draw do
  devise_for :users,
            :controllers => {
              :registrations => "user/registrations",
              :sessions => "user/sessions",
            }
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root 'products#index'

  namespace :admin do
    resources :products
    resources :orders do
      member do
        post :cancel
        post :ship
        post :shipped
        post :return
      end
    end
  end


  resources :products do
    member do
      post :add_to_cart
    end
  end

  resources :carts do
    collection do
      delete :clean
        post :checkout
    end
  end

  resources :cart_items

  resources :orders do
    member do
    post :pay_with_wechat
    post :pay_with_alipay
    post :apply_to_cancel
  end
  end

  namespace :account do
    resources :orders
  end

  resources :payments, only: [:index] do
    collection do
      get :generate_pay
      get :pay_return
      get :pay_notify
      get :success
      get :failed
    end
end

  resources :cellphone_tokens, only: [:create]

end
