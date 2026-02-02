class SmIssueLink < ApplicationRecord
  self.table_name = "sm_issue_links"

  LINK_TYPES = %w[blocks blocked_by parent child relates_to duplicates].freeze
  REVERSE_MAP = {
    "blocks" => "blocked_by",
    "blocked_by" => "blocks",
    "parent" => "child",
    "child" => "parent",
    "relates_to" => "relates_to",
    "duplicates" => "duplicates"
  }.freeze

  belongs_to :source_issue, class_name: "SmIssue"
  belongs_to :target_issue, class_name: "SmIssue"

  validates :link_type, inclusion: { in: LINK_TYPES }

  def self.reverse_type(type)
    REVERSE_MAP[type] || type
  end
end
