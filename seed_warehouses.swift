import Foundation

// Assuming we can parse Config.xcconfig for Supabase URL and Key
let configPath = "NexusRetail/Config.xcconfig"
let configContent = try! String(contentsOfFile: configPath)
var urlString = ""
var anonKey = ""
for line in configContent.components(separatedBy: "\n") {
    if line.hasPrefix("SUPABASE_URL") {
        urlString = line.components(separatedBy: "=")[1].trimmingCharacters(in: .whitespaces)
    }
    if line.hasPrefix("SUPABASE_ANON_KEY") {
        anonKey = line.components(separatedBy: "=")[1].trimmingCharacters(in: .whitespaces)
    }
}
print("URL: \(urlString)")
