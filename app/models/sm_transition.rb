class SmTransition < ApplicationRecord
  self.table_name = "sm_transitions"

  belongs_to :issue, class_name: "SmIssue"
  belongs_to :transitioned_by, class_name: "User", optional: true

  validates :from_status, :to_status, presence: true
  validates :transitioned_at, presence: true
end
