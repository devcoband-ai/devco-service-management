module Api
  module V1
    class MeController < BaseController
      def show
        if current_user
          render json: {
            id: current_user.id,
            email: current_user.email,
            name: current_user.display_name,
            first_name: current_user.first_name,
            last_name: current_user.last_name
          }
        else
          render_error("Not authenticated", status: :unauthorized)
        end
      end
    end
  end
end
