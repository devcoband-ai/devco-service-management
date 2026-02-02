class SmBoard < ApplicationRecord
  self.table_name = "sm_boards"

  DEFAULT_COLUMNS = [
    { name: "Backlog", status_mapping: "backlog", wip_limit: nil },
    { name: "To Do", status_mapping: "todo", wip_limit: nil },
    { name: "In Progress", status_mapping: "in_progress", wip_limit: 5 },
    { name: "In Review", status_mapping: "in_review", wip_limit: 3 },
    { name: "Done", status_mapping: "done", wip_limit: nil }
  ].freeze

  belongs_to :project, class_name: "SmProject"

  validates :name, presence: true

  def file_path_on_disk
    Rails.root.join("data", "boards", "#{project.key}-board.json").to_s
  end

  def to_json_file
    {
      project: project.key,
      name: name,
      columns: columns,
      created_at: created_at&.iso8601,
      updated_at: updated_at&.iso8601
    }
  end
end
