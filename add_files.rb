require 'xcodeproj'
project_path = 'NexusRetail.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.first

# Helper to find or create groups
def ensure_group(project, path)
  group = project.main_group
  path.split('/').each do |name|
    group = group.groups.find { |g| g.display_name == name || g.path == name } || group.new_group(name, name)
  end
  group
end

dashboard_group = ensure_group(project, 'NexusRetail/Features/AfterSales/Dashboard')

['RepairOrderManager.swift', 'RepairCardView.swift', 'ActiveRepairsView.swift'].each do |filename|
  file_path = "NexusRetail/Features/AfterSales/Dashboard/#{filename}"
  
  # Check if already added
  unless dashboard_group.files.find { |f| f.path == filename }
    file_reference = dashboard_group.new_file(filename)
    target.add_file_references([file_reference])
    puts "Added #{filename}"
  end
end

project.save
