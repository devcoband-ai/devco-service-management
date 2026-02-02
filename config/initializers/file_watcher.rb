# Start the file sync service in development
# Watches data/ directory and syncs changes to DB
if Rails.env.development? && !defined?(Rails::Console)
  Rails.application.config.after_initialize do
    # Only start if not running in a rake task
    unless File.basename($0) == 'rake'
      FileSyncService.start!
    end
  end
end
