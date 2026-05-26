Rails.application.routes.draw do

    get '/health', to: proc { [200, {}, ['ok']] }

  namespace :api do 
    namespace :v1 do
      resources :watch_histories
    end
  end
  
end
