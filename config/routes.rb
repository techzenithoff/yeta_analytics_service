# config/routes.rb
Rails.application.routes.draw do

    get '/health', to: proc { [200, {}, ['ok']] }

    
    namespace :api do
        namespace :v1 do
            resources :analytics , only: [] do

                collection do
                    get :summary
                    get :clients_by_country
                    get :content_breakdown
                    get :demographics
                    get :circuit_breaker_status
                end
            end
        end
    end
end