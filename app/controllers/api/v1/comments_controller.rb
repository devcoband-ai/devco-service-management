module Api
  module V1
    class CommentsController < BaseController
      def create
        issue = SmIssue.find_by!(tracking_id: params[:tracking_id])
        now = Time.current

        # Update file first
        file_data = FileManager.read_issue(issue.tracking_id)
        if file_data
          file_data["comments"] ||= []
          file_data["comments"] << {
            "author" => current_user&.email,
            "body" => params[:body],
            "at" => now.iso8601
          }
          file_data["updated_at"] = now.iso8601
          FileManager.write_issue(file_data.deep_symbolize_keys)
        end

        # Create in DB
        comment = issue.comments.create!(
          author: current_user,
          body: params[:body],
          created_at: now
        )

        render json: {
          id: comment.id,
          author: current_user ? { id: current_user.id, email: current_user.email, name: current_user.display_name } : nil,
          body: comment.body,
          created_at: comment.created_at
        }, status: :created
      rescue ActiveRecord::RecordNotFound
        render_error("Issue not found", status: :not_found)
      rescue => e
        render_error(e.message)
      end
    end
  end
end
