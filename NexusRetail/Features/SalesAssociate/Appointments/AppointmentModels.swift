import SwiftUI

struct AssociateAppointment: Identifiable {
    let id = UUID()
    var clientName: String
    var clientEmail: String
    var clientPhone: String
    var date: Date
    var mode: AppointmentMode
    var productOrNote: String

    var time: String {
        date.formatted(date: .omitted, time: .shortened)
    }
}

enum AppointmentMode: String, CaseIterable, Identifiable {
    case inStore, video
    var id: String { rawValue }
    var title: String { self == .inStore ? "In Store" : "Video Consultation" }
    var shortTitle: String { self == .inStore ? "In Store" : "Video" }
    var icon: String { self == .inStore ? "bag.fill" : "video.fill" }
    var rowIcon: String { self == .inStore ? "mappin.and.ellipse" : "video.fill" }
}
