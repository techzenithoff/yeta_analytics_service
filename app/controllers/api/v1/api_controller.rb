module Api::V1
	class ApiController < ApplicationController
		
		#include Pagy::Backend

		#before_action :authenticate_account!

        include Authenticatable

		
        def pagination_dict(pagy)
        {
            current_page: pagy.page,
            next_page:    pagy.next,
            prev_page:    pagy.prev,
            items_per_page:  pagy.items,
            total_pages:  pagy.pages,
            total_count:  pagy.count
        }
        end

        
	end
end