module Api
  module V1
    class ProjectsController < BaseController
      before_action :find_project, only: [:show, :update, :destroy, :archive]

      def index
        projects = SmProject.includes(:lead).order(:key)
        unless params[:include_archived] == "true"
          projects = projects.where.not(status: "archived")
        end
        render json: projects.map { |p| project_json(p) }
      end

      def archive
        now = Time.current
        issues = @project.issues.where.not(status: %w[archived deleted])

        archived_count = 0
        issues.find_each do |issue|
          old_status = issue.status
          file_data = FileManager.read_issue_any(issue.tracking_id)
          if file_data
            file_data["status"] = "archived"
            file_data["updated_at"] = now.iso8601
            unless FileManager::ISSUES_DIR.join("#{issue.tracking_id}.json").exist?
              FileManager.write_issue(file_data.deep_symbolize_keys)
            end
          end

          FileManager.archive_issue(issue.tracking_id)
          issue.update!(status: "archived", archived_at: now)

          SmTransition.create!(
            issue: issue,
            from_status: old_status,
            to_status: "archived",
            transitioned_by: current_user,
            transitioned_at: now
          )
          archived_count += 1
        end

        # Archive project itself
        project_file = FileManager.read_project(@project.key) || {}
        project_file["status"] = "archived"
        project_file["updated_at"] = now.iso8601
        FileManager.write_project(project_file.symbolize_keys)
        @project.update!(status: "archived")

        render json: { message: "Project #{@project.key} archived", issues_archived: archived_count }
      rescue => e
        render_error(e.message)
      end

      def show
        render json: project_json(@project, include_stats: true)
      end

      def create
        now = Time.current.iso8601

        # Write file first
        file_data = {
          key: params[:key]&.upcase,
          name: params[:name],
          description: params[:description],
          lead: current_user&.email,
          status: "active",
          created_at: now,
          updated_at: now
        }

        FileManager.write_project(file_data)

        # Then sync to DB
        project = RepairService.sync_project_from_file(file_data.stringify_keys)

        # Create default board
        board_data = {
          project: project.key,
          name: "#{project.name} Board",
          columns: SmBoard::DEFAULT_COLUMNS,
          created_at: now,
          updated_at: now
        }
        FileManager.write_board(board_data)
        RepairService.sync_board_from_file(board_data.stringify_keys)

        render json: project_json(project), status: :created
      rescue => e
        render_error(e.message)
      end

      def update
        now = Time.current.iso8601

        file_data = FileManager.read_project(@project.key) || {}
        file_data.merge!(
          "name" => params[:name] || @project.name,
          "description" => params[:description] || @project.description,
          "status" => params[:status] || @project.status,
          "updated_at" => now
        )

        FileManager.write_project(file_data.symbolize_keys)
        RepairService.sync_project_from_file(file_data)

        @project.reload
        render json: project_json(@project)
      rescue => e
        render_error(e.message)
      end

      def destroy
        # Check for issues
        if @project.issues.any?
          return render_error("Cannot delete project with existing issues. Delete issues first.")
        end

        FileManager.delete_project_file(@project.key)
        @project.boards.destroy_all
        @project.destroy!

        render json: { message: "Project #{@project.key} deleted" }
      rescue => e
        render_error(e.message)
      end

      private

      def find_project
        @project = SmProject.find_by!(key: params[:key]&.upcase || params[:key])
      rescue ActiveRecord::RecordNotFound
        render_error("Project not found", status: :not_found)
      end

      def project_json(project, include_stats: false)
        json = {
          id: project.id,
          key: project.key,
          name: project.name,
          description: project.description,
          lead: project.lead ? { id: project.lead.id, email: project.lead.email, name: project.lead.display_name } : nil,
          status: project.status,
          created_at: project.created_at,
          updated_at: project.updated_at
        }

        if include_stats
          json[:issue_count] = project.issues.count
          json[:issues_by_status] = project.issues.group(:status).count
        end

        json
      end
    end
  end
end
