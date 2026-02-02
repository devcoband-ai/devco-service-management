class CreateSmIssues < ActiveRecord::Migration[8.0]
  def change
    create_table :sm_issues do |t|
      t.string :tracking_id, null: false
      t.references :project, foreign_key: { to_table: :sm_projects }, null: false
      t.string :issue_type, null: false
      t.string :title, null: false
      t.text :description
      t.string :status, default: "backlog", null: false
      t.string :priority, default: "medium", null: false
      t.references :assignee, foreign_key: { to_table: :users }, null: true
      t.references :reporter, foreign_key: { to_table: :users }, null: true
      t.jsonb :labels, default: []
      t.integer :story_points
      t.string :sprint
      t.date :due_date
      t.string :file_path

      t.timestamps
    end

    add_index :sm_issues, :tracking_id, unique: true
    add_index :sm_issues, :status
    add_index :sm_issues, :issue_type
    add_index :sm_issues, :priority
  end
end
