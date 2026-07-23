Rails.application.routes.draw do


    get '/health', to: proc { [200, {}, ['ok']] }

    namespace :api do 
        namespace :v1 do
            resources :ratings, only: [:create] do
                collection do
                    get :summary
                end
            end
        end
    end
  
end
