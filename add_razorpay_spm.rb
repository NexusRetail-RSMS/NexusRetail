require 'xcodeproj'

project_path = 'NexusRetail.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Check if package already exists
package_url = 'https://github.com/razorpay/razorpay-pod.git'
existing_pkg = project.root_object.package_references.find { |pkg| pkg.repositoryURL == package_url }

if existing_pkg
  puts "Razorpay package already added."
else
  # Add Package Reference
  pkg_ref = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
  pkg_ref.repositoryURL = package_url
  pkg_ref.requirement = {
    "kind" => "upToNextMajorVersion",
    "minimumVersion" => "1.3.5"
  }
  project.root_object.package_references << pkg_ref

  # Add Product Dependency to the main target
  target = project.targets.find { |t| t.name == 'NexusRetail' }
  if target
    pkg_dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
    pkg_dep.package = pkg_ref
    pkg_dep.product_name = "Razorpay"
    
    build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
    build_file.product_ref = pkg_dep
    
    # Find Frameworks build phase
    frameworks_phase = target.frameworks_build_phase
    frameworks_phase.files << build_file
    
    puts "Added Razorpay package dependency to target #{target.name}"
  else
    puts "Could not find target NexusRetail"
  end

  project.save
  puts "Project saved."
end
