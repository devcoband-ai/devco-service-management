module Api
  module V1
    class IssuesController < BaseController
      before_action :find_project, only: [:index, :create]
      before_action :find_issue, only: [:show, :update, :destroy]

      def index
        issues = @project.issues.includes(:assignee, :reporter, :project)
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

        # Remove references from other files
        IntegrityChecker.remove_references_to(tracking_id)

        # Delete file
        FileManager.delete_issue_file(tracking_id)

        # Delete from DB
        @issue.destroy!

        render json: { message: "Issue #{tracking_id} deleted" }
      rescue => e
        render_error(e.message)
      end

      private

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
