class SmComment < ApplicationRecord
  self.table_name = "sm_comments"

  belongs_to :issue, class_name: "SmIssue"
  belongs_to :author, class_name: "User", optional: true

  validates :body, presence: true
end
