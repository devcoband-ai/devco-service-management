# Seed the database from JSON files (file-first approach)
puts "Seeding from JSON files..."
stats = RepairService.run!
puts "Seed complete: #{stats}"
