module Api
  module V1
    class TransitionsController < BaseController
      def create
        issue = SmIssue.find_by!(tracking_id: params[:tracking_id])
        new_status = params[:status]

        unless SmIssue::STATUSES.include?(new_status)
          return render_error("Invalid status: #{new_status}")
        end

        old_status = issue.status

        if old_status == new_status
          return render_error("Issue is already in #{new_status}")
        end

        now = Time.current

        # Update file first
        file_data = FileManager.read_issue(issue.tracking_id)
        if file_data
          file_data["status"] = new_status
          file_data["updated_at"] = now.iso8601
          FileManager.write_issue(file_data.deep_symbolize_keys)
        end

        # Update DB
        issue.update!(status: new_status)

        # Record transition
        SmTransition.create!(
          issue: issue,
          from_status: old_status,
          to_status: new_status,
          transitioned_by: current_user,
          transitioned_at: now
        )

        render json: {
          tracking_id: issue.tracking_id,
          from_status: old_status,
          to_status: new_status,
          transitioned_at: now
        }
      rescue ActiveRecord::RecordNotFound
        render_error("Issue not found", status: :not_found)
      rescue => e
        render_error(e.message)
      end
    end
  end
end
