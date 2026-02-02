class SmProject < ApplicationRecord
  self.table_name = "sm_projects"

  belongs_to :lead, class_name: "User", optional: true
  has_many :issues, class_name: "SmIssue", foreign_key: :project_id, dependent: :destroy
  has_many :boards, class_name: "SmBoard", foreign_key: :project_id, dependent: :destroy

  validates :key, presence: true, uniqueness: true, format: { with: /\A[A-Z][A-Z0-9]{1,9}\z/, message: "must be 2-10 uppercase alphanumeric characters starting with a letter" }
  validates :name, presence: true
  validates :status, inclusion: { in: %w[active archived] }

  scope :active, -> { where(status: "active") }

  def file_path
    Rails.root.join("data", "projects", "#{key}.json").to_s
  end

  def to_json_file
    {
      key: key,
      name: name,
      description: description,
      lead: lead&.email,
      status: status,
      created_at: created_at&.iso8601,
      updated_at: updated_at&.iso8601
    }
  end
end
