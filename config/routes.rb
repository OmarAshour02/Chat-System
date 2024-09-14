Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :applications, param: :token, only: [:create, :show, :update] do
        resources :chats, param: :number, only: [:create, :index, :show] do
          resources :messages, only: [:create, :index] do
            collection do
              get 'search'
            end
          end
        end
      end
    end
  end
end