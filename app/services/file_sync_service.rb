class FileSyncService
  def self.start!
    return if @listener

    FileManager.ensure_directories!

    @listener = Listen.to(
      FileManager::PROJECTS_DIR.to_s,
      FileManager::ISSUES_DIR.to_s,
      FileManager::BOARDS_DIR.to_s,
      only: /\.json$/
    ) do |modified, added, removed|
      next if Thread.current[:skip_file_sync]

      (modified + added).each { |path| sync_file(path) }
      removed.each { |path| handle_removal(path) }
    end

    @listener.start
    Rails.logger.info("[FileSyncService] Watching data/ directory for changes")
  end

  def self.stop!
    @listener&.stop
    @listener = nil
  end

  def self.sync_file(path)
    Rails.logger.info("[FileSyncService] Syncing: #{path}")
    data = JSON.parse(File.read(path))

    if path.include?("/projects/")
      RepairService.sync_project_from_file(data)
    elsif path.include?("/issues/")
      RepairService.sync_issue_from_file(data)
      RepairService.sync_issue_links(data)
    elsif path.include?("/boards/")
      RepairService.sync_board_from_file(data)
    end
  rescue => e
    Rails.logger.error("[FileSyncService] Error syncing #{path}: #{e.message}")
  end

  def self.handle_removal(path)
    Rails.logger.info("[FileSyncService] File removed: #{path}")
    basename = File.basename(path, ".json")

    if path.include?("/projects/")
      SmProject.find_by(key: basename)&.destroy
    elsif path.include?("/issues/")
      SmIssue.find_by(tracking_id: basename)&.destroy
    elsif path.include?("/boards/")
      # boards are project-key-board.json
      project_key = basename.sub(/-board$/, "")
      project = SmProject.find_by(key: project_key)
      SmBoard.where(project: project).destroy_all if project
    end
  rescue => e
    Rails.logger.error("[FileSyncService] Error handling removal #{path}: #{e.message}")
  end
end
