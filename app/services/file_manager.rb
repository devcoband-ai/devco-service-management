class FileManager
  DATA_DIR = Rails.root.join("data")
  PROJECTS_DIR = DATA_DIR.join("projects")
  ISSUES_DIR = DATA_DIR.join("issues")
  BOARDS_DIR = DATA_DIR.join("boards")

  class << self
    def ensure_directories!
      [PROJECTS_DIR, ISSUES_DIR, BOARDS_DIR].each { |d| FileUtils.mkdir_p(d) }
    end

    # --- Project files ---

    def write_project(project_data)
      ensure_directories!
      path = PROJECTS_DIR.join("#{project_data[:key]}.json")
      write_json(path, project_data)
      path.to_s
    end

    def read_project(key)
      path = PROJECTS_DIR.join("#{key}.json")
      return nil unless path.exist?
      read_json(path)
    end

    def delete_project_file(key)
      path = PROJECTS_DIR.join("#{key}.json")
      File.delete(path) if path.exist?
    end

    def all_project_files
      Dir.glob(PROJECTS_DIR.join("*.json")).map { |f| read_json(f) }
    end

    # --- Issue files ---

    def write_issue(issue_data)
      ensure_directories!
      path = ISSUES_DIR.join("#{issue_data[:tracking_id]}.json")
      write_json(path, issue_data)
      path.to_s
    end

    def read_issue(tracking_id)
      path = ISSUES_DIR.join("#{tracking_id}.json")
      return nil unless path.exist?
      read_json(path)
    end

    def delete_issue_file(tracking_id)
      path = ISSUES_DIR.join("#{tracking_id}.json")
      File.delete(path) if path.exist?
    end

    def all_issue_files
      Dir.glob(ISSUES_DIR.join("*.json")).map { |f| read_json(f) }
    end

    def issues_for_project(project_key)
      all_issue_files.select { |i| i["project"] == project_key }
    end

    # --- Board files ---

    def write_board(board_data)
      ensure_directories!
      path = BOARDS_DIR.join("#{board_data[:project]}-board.json")
      write_json(path, board_data)
      path.to_s
    end

    def read_board(project_key)
      path = BOARDS_DIR.join("#{project_key}-board.json")
      return nil unless path.exist?
      read_json(path)
    end

    def all_board_files
      Dir.glob(BOARDS_DIR.join("*.json")).map { |f| read_json(f) }
    end

    private

    def write_json(path, data)
      # Set flag to skip file watcher re-sync
      Thread.current[:skip_file_sync] = true
      File.write(path, JSON.pretty_generate(data) + "\n")
    ensure
      Thread.current[:skip_file_sync] = false
    end

    def read_json(path)
      JSON.parse(File.read(path))
    rescue JSON::ParserError => e
      Rails.logger.error("Failed to parse #{path}: #{e.message}")
      nil
    end
  end
end
