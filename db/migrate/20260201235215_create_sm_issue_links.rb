class CreateSmIssueLinks < ActiveRecord::Migration[8.0]
  def change
    create_table :sm_issue_links do |t|
      t.references :source_issue, foreign_key: { to_table: :sm_issues }, null: false
      t.references :target_issue, foreign_key: { to_table: :sm_issues }, null: false
      t.string :link_type, null: false

      t.datetime :created_at, null: false
    end

    add_index :sm_issue_links, [:source_issue_id, :target_issue_id, :link_type], unique: true, name: "idx_sm_issue_links_unique"
  end
end
