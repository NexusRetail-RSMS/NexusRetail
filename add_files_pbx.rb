require 'xcodeproj'

project_path = 'NexusRetail.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

group = project.main_group.find_subpath('NexusRetail/Features/Manager/InventoryDashboard', true)
files_to_add = [
    'NexusRetail/Features/Manager/InventoryDashboard/InventoryDashboardModels.swift',
    'NexusRetail/Features/Manager/InventoryDashboard/RequestStockSheet.swift'
]

files_to_add.each do |file_path|
    unless group.files.any? { |f| f.path == file_path.split('/').last }
        file_ref = group.new_reference(file_path.split('/').last)
        target.add_file_references([file_ref])
        puts "Added #{file_path}"
    end
end

project.save
