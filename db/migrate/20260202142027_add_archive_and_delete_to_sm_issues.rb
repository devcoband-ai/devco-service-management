class AddArchiveAndDeleteToSmIssues < ActiveRecord::Migration[8.1]
  def change
    add_column :sm_issues, :archived_at, :datetime
    add_column :sm_issues, :deleted_at, :datetime
  end
end
