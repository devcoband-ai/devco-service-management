class SmIssue < ApplicationRecord
  self.table_name = "sm_issues"

  TYPES = %w[epic story task bug spike decision].freeze
  STATUSES = %w[backlog todo in_progress in_review done cancelled archived deleted].freeze
  PRIORITIES = %w[critical high medium low].freeze

  belongs_to :project, class_name: "SmProject"
  belongs_to :assignee, class_name: "User", optional: true
  belongs_to :reporter, class_name: "User", optional: true
  has_many :comments, class_name: "SmComment", foreign_key: :issue_id, dependent: :destroy
  has_many :transitions, class_name: "SmTransition", foreign_key: :issue_id, dependent: :destroy
  has_many :outgoing_links, class_name: "SmIssueLink", foreign_key: :source_issue_id, dependent: :destroy
  has_many :incoming_links, class_name: "SmIssueLink", foreign_key: :target_issue_id, dependent: :destroy

  validates :tracking_id, presence: true, uniqueness: true
  validates :title, presence: true
  validates :issue_type, inclusion: { in: TYPES }
  validates :status, inclusion: { in: STATUSES }
  validates :priority, inclusion: { in: PRIORITIES }

  scope :by_status, ->(status) { where(status: status) }
  scope :by_project, ->(project_key) { joins(:project).where(sm_projects: { key: project_key }) }
  scope :active, -> { where(status: STATUSES - %w[archived deleted]) }
  scope :not_deleted, -> { where.not(status: "deleted") }
  scope :archived_only, -> { where(status: "archived") }
  scope :deleted_only, -> { where(status: "deleted") }

  def file_path_on_disk
    case status
    when "archived"
      Rails.root.join("data", "archive", "issues", "#{tracking_id}.json").to_s
    when "deleted"
      Rails.root.join("data", "deleted", "issues", "#{tracking_id}.json").to_s
    else
      Rails.root.join("data", "issues", "#{tracking_id}.json").to_s
    end
  end

  def all_links
    outgoing_links + incoming_links
  end

  def to_json_file
    {
      tracking_id: tracking_id,
      project: project.key,
      type: issue_type,
      title: title,
      description: description,
      status: status,
      priority: priority,
      assignee: assignee&.email,
      reporter: reporter&.email,
      labels: labels || [],
      story_points: story_points,
      sprint: sprint,
      due_date: due_date&.iso8601,
      links: build_links_json,
      comments: comments.order(:created_at).map { |c|
        { author: c.author&.email, body: c.body, at: c.created_at.iso8601 }
      },
      created_at: created_at&.iso8601,
      updated_at: updated_at&.iso8601
    }
  end

  private

  def build_links_json
    links_json = []
    outgoing_links.includes(:target_issue).each do |link|
      links_json << { type: link.link_type, ref: link.target_issue.tracking_id }
    end
    incoming_links.includes(:source_issue).each do |link|
      reverse_type = SmIssueLink.reverse_type(link.link_type)
      links_json << { type: reverse_type, ref: link.source_issue.tracking_id }
    end
    links_json
  end
end
