import SwiftUI

struct AssociateAppointment: Identifiable {
    var id: UUID = UUID()
    var clientName: String
    var clientEmail: String
    var clientPhone: String
    var date: Date
    var mode: AppointmentMode
    var status: AppointmentStatus
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

enum AppointmentStatus: String, CaseIterable, Identifiable {
    case confirmed, pending, cancelled
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var icon: String {
        switch self {
        case .confirmed: return "checkmark.circle.fill"
        case .pending: return "clock.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }
    var color: Color {
        switch self {
        case .confirmed: return RSMSColors.success
        case .pending: return RSMSColors.warning
        case .cancelled: return RSMSColors.error
        }
    }
}
