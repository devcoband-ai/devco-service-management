module Api
  module V1
    class BoardsController < BaseController
      def show
        board = SmBoard.includes(project: { issues: [:assignee, :reporter] }).find(params[:id])
        render json: board_json(board)
      rescue ActiveRecord::RecordNotFound
        render_error("Board not found", status: :not_found)
      end

      def by_project
        project = SmProject.find_by!(key: params[:project_key]&.upcase || params[:project_key])
        board = project.boards.first

        unless board
          # Auto-create default board
          board = project.boards.create!(
            name: "#{project.name} Board",
            columns: SmBoard::DEFAULT_COLUMNS
          )
          FileManager.write_board(board.to_json_file)
        end

        render json: board_json(board)
      rescue ActiveRecord::RecordNotFound
        render_error("Project not found", status: :not_found)
      end

      def update
        board = SmBoard.find(params[:id])

        board.name = params[:name] if params[:name].present?
        board.columns = params[:columns] if params[:columns].present?
        board.save!

        # Update file
        FileManager.write_board(board.to_json_file)

        render json: board_json(board)
      rescue ActiveRecord::RecordNotFound
        render_error("Board not found", status: :not_found)
      rescue => e
        render_error(e.message)
      end

      private

      def board_json(board)
        issues = board.project.issues.includes(:assignee, :reporter).order(:tracking_id)

        {
          id: board.id,
          project_key: board.project.key,
          name: board.name,
          columns: board.columns,
          issues: issues.map { |i|
            {
              id: i.id,
              tracking_id: i.tracking_id,
              title: i.title,
              issue_type: i.issue_type,
              status: i.status,
              priority: i.priority,
              assignee: i.assignee ? { id: i.assignee.id, email: i.assignee.email, name: i.assignee.display_name } : nil,
              labels: i.labels,
              story_points: i.story_points
            }
          }
        }
      end
    end
  end
end
