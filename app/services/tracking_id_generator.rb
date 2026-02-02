class TrackingIdGenerator
  def self.next_id(project_key)
    existing = Dir.glob(FileManager::ISSUES_DIR.join("#{project_key}-*.json"))
    numbers = existing.map { |f|
      File.basename(f, ".json").split("-").last.to_i
    }.compact
    next_num = (numbers.max || 0) + 1
    "#{project_key}-#{next_num}"
  end
end
