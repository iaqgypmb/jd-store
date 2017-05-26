Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root 'welcome#index'

  get "welcome" => "welcome#index"
  get "test" => "welcome#test"

  # 用户注册和登录登出
  resources :users
  resources :sessions
  delete '/logout' => 'sessions#destroy', as: :logout
  resources :cellphone_tokens, only: [:create]
  # mount RuCaptcha::Engine => "/rucaptcha"

  namespace :admin do
    resources :slider_photos do
      member do
      post :hide
      post :public
      end
    end
    resources :categories
    resources :products do
      resources :subproducts
      resources :product_params
      resources :product_photos
    end
    resources :orders do
      member do
        post :cancel
        post :ship
        post :shipped
        post :return
      end
    end
  end



  resources :categories

  resources :products do
    member do
      post :add_to_cart
    end

    resources :evaluations do
      resources :evaluation_photos
    end
  end

  resources :carts do
    collection do
      delete :clean
        post :checkout
    end
  end

  resources :addresses do
    member do
      put :set_default_address
    end
  end

  resources :cart_items

  resources :orders do
    collection do
      post :build_order
      post :order_create
    end
    member do
    post :pay_with_wechat
    post :pay_with_alipay
    post :apply_to_cancel
    post :order_create

  end
  end

  namespace :account do
    resources :orders
  end

  resources :evaluations do
    resources :evaluation_photos
  end

  resources :payments, only: [:index] do
    member do
      post :create_payment
      get :create_payment
      post :get_payment_status
    end
    collection do
      get :generate_pay
      post :pay_return
      post :pay_notify
      get :pay_notify
      get :pay_return
      post :test
      get :success
      get :failed
    end
  end



end
