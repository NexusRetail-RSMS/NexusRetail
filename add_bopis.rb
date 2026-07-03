require 'xcodeproj'
project_path = 'NexusRetail.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

sales_group = project.main_group.find_subpath(File.join('NexusRetail', 'Features', 'SalesAssociate'), false)

if sales_group
  # Find or create BOPIS group
  bopis_group = sales_group.children.find { |g| g.name == 'BOPIS' || g.path == 'BOPIS' }
  if bopis_group.nil?
    bopis_group = sales_group.new_group('BOPIS', 'BOPIS')
  end

  # Helper to recursively add files
  def add_files_to_group(group, target, path)
    Dir.foreach(path) do |file|
      next if file == '.' || file == '..'
      full_path = File.join(path, file)
      if File.directory?(full_path)
        subgroup = group.children.find { |g| g.name == file || g.path == file }
        if subgroup.nil?
          subgroup = group.new_group(file, file)
        end
        add_files_to_group(subgroup, target, full_path)
      elsif file.end_with?('.swift')
        # Check if already added
        existing = group.files.find { |f| f.path == file }
        if existing.nil?
          file_ref = group.new_file(file)
          target.add_file_references([file_ref])
          puts "Added #{file}"
        end
      end
    end
  end

  bopis_path = 'NexusRetail/Features/SalesAssociate/BOPIS'
  add_files_to_group(bopis_group, target, bopis_path)
  
  project.save
  puts "Project saved successfully"
else
  puts "SalesAssociate group not found"
end
