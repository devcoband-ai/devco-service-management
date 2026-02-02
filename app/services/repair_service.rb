class RepairService
  def self.run!
    Rails.logger.info("[RepairService] Starting full repair from JSON files...")

    # Wipe all SM tables
    ActiveRecord::Base.transaction do
      SmTransition.delete_all
      SmComment.delete_all
      SmIssueLink.delete_all
      SmIssue.delete_all
      SmBoard.delete_all
      SmProject.delete_all
    end

    stats = { projects: 0, issues: 0, links: 0, boards: 0, comments: 0 }

    # Rebuild projects
    FileManager.all_project_files.each do |data|
      next unless data
      sync_project_from_file(data)
      stats[:projects] += 1
    end

    # Rebuild issues (two passes: create issues, then resolve links)
    issues_data = FileManager.all_issue_files.compact
    issues_data.each do |data|
      sync_issue_from_file(data, skip_links: true)
      stats[:issues] += 1
    end

    # Second pass: resolve links
    issues_data.each do |data|
      count = sync_issue_links(data)
      stats[:links] += count
    end

    # Rebuild boards
    FileManager.all_board_files.each do |data|
      next unless data
      sync_board_from_file(data)
      stats[:boards] += 1
    end

    Rails.logger.info("[RepairService] Repair complete: #{stats}")
    stats
  end

  def self.sync_project_from_file(data)
    lead = User.find_by(email: data["lead"]) if data["lead"]
    SmProject.find_or_initialize_by(key: data["key"]).tap do |p|
      p.name = data["name"]
      p.description = data["description"]
      p.lead = lead
      p.status = data["status"] || "active"
      p.created_at = data["created_at"] if data["created_at"]
      p.updated_at = data["updated_at"] if data["updated_at"]
      p.save!
    end
  end

  def self.sync_issue_from_file(data, skip_links: false)
    project = SmProject.find_by!(key: data["project"])
    assignee = User.find_by(email: data["assignee"]) if data["assignee"]
    reporter = User.find_by(email: data["reporter"]) if data["reporter"]

    issue = SmIssue.find_or_initialize_by(tracking_id: data["tracking_id"])
    issue.assign_attributes(
      project: project,
      issue_type: data["type"],
      title: data["title"],
      description: data["description"],
      status: data["status"] || "backlog",
      priority: data["priority"] || "medium",
      assignee: assignee,
      reporter: reporter,
      labels: data["labels"] || [],
      story_points: data["story_points"],
      sprint: data["sprint"],
      due_date: data["due_date"],
      file_path: FileManager::ISSUES_DIR.join("#{data['tracking_id']}.json").to_s
    )
    issue.created_at = data["created_at"] if data["created_at"]
    issue.updated_at = data["updated_at"] if data["updated_at"]
    issue.save!

    # Sync comments
    (data["comments"] || []).each do |comment_data|
      author = User.find_by(email: comment_data["author"]) if comment_data["author"]
      issue.comments.find_or_create_by!(
        body: comment_data["body"],
        created_at: comment_data["at"]
      ) do |c|
        c.author = author
      end
    end

    issue
  end

  def self.sync_issue_links(data)
    source = SmIssue.find_by(tracking_id: data["tracking_id"])
    return 0 unless source

    count = 0
    (data["links"] || []).each do |link_data|
      target = SmIssue.find_by(tracking_id: link_data["ref"])
      next unless target

      # Only store "forward" links to avoid duplicates
      link_type = link_data["type"]
      next if %w[blocked_by child].include?(link_type) # these are reverse views

      SmIssueLink.find_or_create_by!(
        source_issue: source,
        target_issue: target,
        link_type: link_type
      )
      count += 1
    rescue ActiveRecord::RecordNotUnique
      # Already exists, skip
    end

    count
  end

  def self.sync_board_from_file(data)
    project = SmProject.find_by!(key: data["project"])
    board = SmBoard.find_or_initialize_by(project: project)
    board.name = data["name"]
    board.columns = data["columns"]
    board.created_at = data["created_at"] if data["created_at"]
    board.updated_at = data["updated_at"] if data["updated_at"]
    board.save!
  end
end
