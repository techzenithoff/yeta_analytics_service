require "rails_helper"

RSpec.describe WatchHistoriesController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/watch_histories").to route_to("watch_histories#index")
    end

    it "routes to #show" do
      expect(get: "/watch_histories/1").to route_to("watch_histories#show", id: "1")
    end


    it "routes to #create" do
      expect(post: "/watch_histories").to route_to("watch_histories#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/watch_histories/1").to route_to("watch_histories#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/watch_histories/1").to route_to("watch_histories#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/watch_histories/1").to route_to("watch_histories#destroy", id: "1")
    end
  end
end
