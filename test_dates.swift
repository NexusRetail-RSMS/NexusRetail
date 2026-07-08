import Foundation

let calendar = Calendar.current
let now = Date()

// Yesterday
let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
// 31 days ago
let oldDate = calendar.date(byAdding: .day, value: -31, to: now)!

print("Yesterday diff:", calendar.dateComponents([.day], from: yesterday, to: now).day!)
print("Old diff:", calendar.dateComponents([.day], from: oldDate, to: now).day!)

