Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get 'songs/search', to: 'songs#search'
    end

    namespace :v2 do
      get 'songs/search', to: 'songs#search'
    end
  end
end
