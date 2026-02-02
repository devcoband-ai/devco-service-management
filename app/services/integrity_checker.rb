class IntegrityChecker
  # Validates that all link references in an issue's links array point to existing issues
  def self.validate_links(issue_data)
    errors = []
    links = issue_data["links"] || issue_data[:links] || []

    links.each do |link|
      ref = link["ref"] || link[:ref]
      next if ref.blank?

      unless FileManager.read_issue(ref)
        errors << "Referenced issue #{ref} does not exist"
      end
    end

    errors
  end

  # Check if any other issues reference this tracking_id
  def self.find_references_to(tracking_id)
    references = []

    FileManager.all_issue_files.each do |issue_data|
      next if issue_data.nil?
      next if issue_data["tracking_id"] == tracking_id

      links = issue_data["links"] || []
      links.each do |link|
        if link["ref"] == tracking_id
          references << {
            issue: issue_data["tracking_id"],
            link_type: link["type"]
          }
        end
      end
    end

    references
  end

  # Remove all references to a tracking_id from other issue files
  def self.remove_references_to(tracking_id)
    references = find_references_to(tracking_id)

    references.each do |ref|
      issue_data = FileManager.read_issue(ref[:issue])
      next unless issue_data

      issue_data["links"].reject! { |l| l["ref"] == tracking_id }
      issue_data["updated_at"] = Time.current.iso8601
      FileManager.write_issue(issue_data.deep_symbolize_keys)
    end

    references
  end
end
