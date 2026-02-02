module Api
  module V1
    class IssuesController < BaseController
      before_action :find_project, only: [:index, :create]
      before_action :find_issue, only: [:show, :update, :destroy]

      def index
        issues = @project.issues.includes(:assignee, :reporter, :project)

        # Filter archived and deleted by default
        unless params[:include_deleted] == "true"
          issues = issues.where.not(status: "deleted")
        end
        unless params[:include_archived] == "true"
          issues = issues.where.not(status: "archived")
        end

        issues = issues.by_status(params[:status]) if params[:status].present?
        issues = issues.where(issue_type: params[:type]) if params[:type].present?
        issues = issues.order(:tracking_id)

        render json: issues.map { |i| issue_json(i) }
      end

      def show
        render json: issue_json(@issue, detail: true)
      end

      def create
        now = Time.current.iso8601
        tracking_id = TrackingIdGenerator.next_id(@project.key)

        file_data = {
          tracking_id: tracking_id,
          project: @project.key,
          type: params[:issue_type] || params[:type] || "task",
          title: params[:title],
          description: params[:description],
          status: params[:status] || "backlog",
          priority: params[:priority] || "medium",
          assignee: params[:assignee],
          reporter: current_user&.email,
          labels: params[:labels] || [],
          story_points: params[:story_points],
          sprint: params[:sprint],
          due_date: params[:due_date],
          links: params[:links] || [],
          comments: [],
          created_at: now,
          updated_at: now
        }

        # Validate links
        errors = IntegrityChecker.validate_links(file_data)
        return render_errors(errors) if errors.any?

        # File first
        FileManager.write_issue(file_data)

        # Then DB
        issue = RepairService.sync_issue_from_file(file_data.stringify_keys.transform_keys(&:to_s))
        RepairService.sync_issue_links(file_data.stringify_keys.transform_keys(&:to_s))

        render json: issue_json(issue.reload), status: :created
      rescue => e
        render_error(e.message)
      end

      def update
        now = Time.current.iso8601

        file_data = FileManager.read_issue(@issue.tracking_id) || {}
        updatable = %w[title description priority assignee labels story_points sprint due_date]
        updatable.each do |field|
          file_data[field] = params[field] if params.key?(field)
        end
        file_data["type"] = params[:issue_type] || params[:type] if params.key?(:issue_type) || params.key?(:type)
        file_data["links"] = params[:links].map { |l| l.is_a?(Hash) ? l : l.to_unsafe_h } if params.key?(:links)
        file_data["updated_at"] = now

        # Validate links if changed
        if params.key?(:links)
          errors = IntegrityChecker.validate_links(file_data)
          return render_errors(errors) if errors.any?
        end

        FileManager.write_issue(file_data.deep_symbolize_keys)
        RepairService.sync_issue_from_file(file_data.stringify_keys)
        if params.key?(:links)
          @issue.outgoing_links.destroy_all
          RepairService.sync_issue_links(file_data.stringify_keys)
        end

        @issue.reload
        render json: issue_json(@issue, detail: true)
      rescue => e
        render_error(e.message)
      end

      def destroy
        tracking_id = @issue.tracking_id
        now = Time.current
        old_status = @issue.status

        # Soft delete: move file to deleted directory
        file_data = FileManager.read_issue_any(tracking_id)
        if file_data
          file_data["status"] = "deleted"
          file_data["updated_at"] = now.iso8601
          # Ensure file exists in a movable location
          source = FileManager::ISSUES_DIR.join("#{tracking_id}.json")
          archive_source = FileManager::ARCHIVE_ISSUES_DIR.join("#{tracking_id}.json")
          unless source.exist? || archive_source.exist?
            FileManager.write_issue(file_data.deep_symbolize_keys)
          end
        end

        FileManager.delete_issue(tracking_id)

        # Update DB (soft delete)
        @issue.update!(status: "deleted", deleted_at: now)

        # Record transition
        SmTransition.create!(
          issue: @issue,
          from_status: old_status,
          to_status: "deleted",
          transitioned_by: current_user,
          transitioned_at: now
        )

        render json: { message: "Issue #{tracking_id} soft-deleted", deleted_at: now }
      rescue => e
        render_error(e.message)
      end

      def recover
        issue = SmIssue.find_by!(tracking_id: params[:tracking_id] || params[:issue_tracking_id])

        unless issue.status == "deleted"
          return render_error("Issue is not deleted, cannot recover")
        end

        now = Time.current

        # Read file from deleted dir and update status
        file_data = FileManager.read_deleted_issue(issue.tracking_id)
        if file_data
          file_data["status"] = "backlog"
          file_data["updated_at"] = now.iso8601
        end

        # Move file back to active
        FileManager.recover_issue(issue.tracking_id)

        # Write updated content
        if file_data
          FileManager.write_issue(file_data.deep_symbolize_keys)
        end

        # Update DB
        issue.update!(status: "backlog", deleted_at: nil, archived_at: nil)

        # Record transition
        SmTransition.create!(
          issue: issue,
          from_status: "deleted",
          to_status: "backlog",
          transitioned_by: current_user,
          transitioned_at: now
        )

        render json: { message: "Issue #{issue.tracking_id} recovered to backlog", tracking_id: issue.tracking_id }
      rescue ActiveRecord::RecordNotFound
        render_error("Issue not found", status: :not_found)
      rescue => e
        render_error(e.message)
      end

      def bulk_archive
        results = bulk_transition(params[:tracking_ids], "archived")
        render json: results
      end

      def bulk_delete
        results = bulk_transition(params[:tracking_ids], "deleted")
        render json: results
      end

      def bulk_recover
        tracking_ids = params[:tracking_ids] || []
        results = { succeeded: [], failed: [] }

        tracking_ids.each do |tid|
          issue = SmIssue.find_by(tracking_id: tid)
          unless issue&.status == "deleted"
            results[:failed] << { tracking_id: tid, error: "Not found or not deleted" }
            next
          end

          now = Time.current
          file_data = FileManager.read_deleted_issue(tid)
          if file_data
            file_data["status"] = "backlog"
            file_data["updated_at"] = now.iso8601
          end

          FileManager.recover_issue(tid)
          FileManager.write_issue(file_data.deep_symbolize_keys) if file_data

          issue.update!(status: "backlog", deleted_at: nil, archived_at: nil)
          SmTransition.create!(
            issue: issue,
            from_status: "deleted",
            to_status: "backlog",
            transitioned_by: current_user,
            transitioned_at: now
          )
          results[:succeeded] << tid
        rescue => e
          results[:failed] << { tracking_id: tid, error: e.message }
        end

        render json: results
      end

      private

      def bulk_transition(tracking_ids, target_status)
        tracking_ids ||= []
        results = { succeeded: [], failed: [] }

        tracking_ids.each do |tid|
          issue = SmIssue.find_by(tracking_id: tid)
          unless issue
            results[:failed] << { tracking_id: tid, error: "Not found" }
            next
          end

          if issue.status == target_status
            results[:failed] << { tracking_id: tid, error: "Already #{target_status}" }
            next
          end

          if issue.status == "deleted" && target_status != "deleted"
            results[:failed] << { tracking_id: tid, error: "Cannot transition deleted issue" }
            next
          end

          now = Time.current
          old_status = issue.status
          file_data = FileManager.read_issue_any(tid)
          if file_data
            file_data["status"] = target_status
            file_data["updated_at"] = now.iso8601
          end

          if target_status == "archived"
            # Ensure file is in active dir for archiving
            unless FileManager::ISSUES_DIR.join("#{tid}.json").exist?
              FileManager.write_issue(file_data.deep_symbolize_keys) if file_data
            end
            FileManager.archive_issue(tid)
            issue.update!(status: "archived", archived_at: now)
          elsif target_status == "deleted"
            source = FileManager::ISSUES_DIR.join("#{tid}.json")
            archive_source = FileManager::ARCHIVE_ISSUES_DIR.join("#{tid}.json")
            unless source.exist? || archive_source.exist?
              FileManager.write_issue(file_data.deep_symbolize_keys) if file_data
            end
            FileManager.delete_issue(tid)
            issue.update!(status: "deleted", deleted_at: now)
          end

          SmTransition.create!(
            issue: issue,
            from_status: old_status,
            to_status: target_status,
            transitioned_by: current_user,
            transitioned_at: now
          )
          results[:succeeded] << tid
        rescue => e
          results[:failed] << { tracking_id: tid, error: e.message }
        end

        results
      end

      def find_project
        @project = SmProject.find_by!(key: params[:project_key]&.upcase || params[:project_key])
      rescue ActiveRecord::RecordNotFound
        render_error("Project not found", status: :not_found)
      end

      def find_issue
        @issue = SmIssue.includes(:assignee, :reporter, :project, :comments, :outgoing_links, :incoming_links)
                        .find_by!(tracking_id: params[:tracking_id] || params[:id])
      rescue ActiveRecord::RecordNotFound
        render_error("Issue not found", status: :not_found)
      end

      def issue_json(issue, detail: false)
        json = {
          id: issue.id,
          tracking_id: issue.tracking_id,
          project_key: issue.project.key,
          issue_type: issue.issue_type,
          title: issue.title,
          status: issue.status,
          priority: issue.priority,
          assignee: issue.assignee ? { id: issue.assignee.id, email: issue.assignee.email, name: issue.assignee.display_name } : nil,
          reporter: issue.reporter ? { id: issue.reporter.id, email: issue.reporter.email, name: issue.reporter.display_name } : nil,
          labels: issue.labels,
          story_points: issue.story_points,
          sprint: issue.sprint,
          due_date: issue.due_date,
          archived_at: issue.archived_at,
          deleted_at: issue.deleted_at,
          created_at: issue.created_at,
          updated_at: issue.updated_at
        }

        if detail
          json[:description] = issue.description
          json[:comments] = issue.comments.order(:created_at).map { |c|
            {
              id: c.id,
              author: c.author ? { id: c.author.id, email: c.author.email, name: c.author.display_name } : nil,
              body: c.body,
              created_at: c.created_at
            }
          }
          json[:links] = issue.outgoing_links.includes(:target_issue).map { |l|
            { type: l.link_type, ref: l.target_issue.tracking_id }
          } + issue.incoming_links.includes(:source_issue).map { |l|
            { type: SmIssueLink.reverse_type(l.link_type), ref: l.source_issue.tracking_id }
          }
          json[:transitions] = issue.transitions.order(:transitioned_at).map { |t|
            {
              from_status: t.from_status,
              to_status: t.to_status,
              transitioned_by: t.transitioned_by&.display_name,
              transitioned_at: t.transitioned_at
            }
          }
        end

        json
      end
    end
  end
end
