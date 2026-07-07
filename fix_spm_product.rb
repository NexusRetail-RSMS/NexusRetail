require 'xcodeproj'

project_path = 'NexusRetail.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the Swift Package Product Dependency and change its name
pkg_dep = project.root_object.project_references.map { |pr| pr[:project_ref] }.compact.first
# Actually let's search all XCSwiftPackageProductDependency objects
dependencies = project.objects.select { |obj| obj.isa == 'XCSwiftPackageProductDependency' }

dependencies.each do |dep|
  if dep.product_name == 'Razorpay'
    dep.product_name = 'RazorpayCheckout'
    puts "Fixed product name to RazorpayCheckout"
  end
end

project.save
puts "Project saved."
