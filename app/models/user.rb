# References the existing users table from devco-platform
# No migration needed — table already exists
class User < ApplicationRecord
  self.table_name = "users"

  has_many :led_projects, class_name: "SmProject", foreign_key: :lead_id
  has_many :assigned_issues, class_name: "SmIssue", foreign_key: :assignee_id
  has_many :reported_issues, class_name: "SmIssue", foreign_key: :reporter_id
  has_many :comments, class_name: "SmComment", foreign_key: :author_id
  has_many :transitions, class_name: "SmTransition", foreign_key: :transitioned_by_id

  def display_name
    [first_name, last_name].compact.join(" ").presence || email
  end
end
