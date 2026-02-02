module Api
  module V1
    class BaseController < ApplicationController
      before_action :set_current_user

      private

      def set_current_user
        # Simple token auth via X-Api-Token header, or fall back to first user for dev
        token = request.headers["X-Api-Token"]
        if token.present?
          @current_user = User.find_by(email: token)
        end

        # Dev fallback: use first active user
        @current_user ||= User.find_by(active: true) || User.first
      end

      def current_user
        @current_user
      end

      def render_error(message, status: :unprocessable_entity)
        render json: { error: message }, status: status
      end

      def render_errors(errors, status: :unprocessable_entity)
        render json: { errors: errors }, status: status
      end
    end
  end
end
