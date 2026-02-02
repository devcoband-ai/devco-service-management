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

        if old_status == "deleted"
          return render_error("Cannot transition a deleted issue. Use the recover endpoint instead.")
        end

        now = Time.current

        # Update file first
        file_data = FileManager.read_issue_any(issue.tracking_id)
        if file_data
          file_data["status"] = new_status
          file_data["updated_at"] = now.iso8601
        end

        # Handle file moves for archive/delete transitions
        if new_status == "archived"
          if file_data
            # Write updated content to archive location
            FileManager.write_issue(file_data.deep_symbolize_keys) unless FileManager.read_issue(issue.tracking_id)
          end
          FileManager.archive_issue(issue.tracking_id)
          issue.update!(status: new_status, archived_at: now)
        elsif new_status == "deleted"
          if file_data
            # Ensure file is in a known location before moving
            source_path = FileManager::ISSUES_DIR.join("#{issue.tracking_id}.json")
            archive_path = FileManager::ARCHIVE_ISSUES_DIR.join("#{issue.tracking_id}.json")
            unless source_path.exist? || archive_path.exist?
              FileManager.write_issue(file_data.deep_symbolize_keys)
            end
          end
          FileManager.delete_issue(issue.tracking_id)
          issue.update!(status: new_status, deleted_at: now)
        else
          # Normal transition — if coming from archived, move file back
          if old_status == "archived"
            FileManager.recover_issue(issue.tracking_id) if FileManager::ARCHIVE_ISSUES_DIR.join("#{issue.tracking_id}.json").exist?
            # Write to active dir if recovery moved it, update content
            if file_data
              FileManager.write_issue(file_data.deep_symbolize_keys)
            end
            issue.update!(status: new_status, archived_at: nil)
          else
            if file_data
              FileManager.write_issue(file_data.deep_symbolize_keys)
            end
            issue.update!(status: new_status)
          end
        end

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
