module Api
  module V1
    class RepairController < BaseController
      def create
        stats = RepairService.run!
        render json: { message: "Repair complete", stats: stats }
      rescue => e
        render_error("Repair failed: #{e.message}", status: :internal_server_error)
      end
    end
  end
end
