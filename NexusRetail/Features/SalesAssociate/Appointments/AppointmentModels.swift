import SwiftUI

struct AssociateAppointment: Identifiable {
    let id = UUID()
    let clientName: String
    let date: Date
    let mode: AppointmentMode
    var time: String { date.formatted(date: .abbreviated, time: .shortened) }
}

enum AppointmentMode: String, CaseIterable, Identifiable {
    case inStore, video
    var id: String { rawValue }
    var title: String { self == .inStore ? "In-store" : "Video" }
    var icon: String { self == .inStore ? "bag.fill" : "video.fill" }
}
