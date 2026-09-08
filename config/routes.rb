# config/routes.rb
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      namespace :analytics do
        get :summary
        get :clients_by_country
        get :content_breakdown
        get :demographics
        get :circuit_breaker_status
      end
    end
  end
end