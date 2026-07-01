//
//  AssociateAppointment.swift
//  NexusRetail
//
//  Model for a clienteling appointment and its related enums.
//

import Foundation

enum AppointmentMode: String, CaseIterable, Identifiable {
    case inStore
    case video

    var id: String { rawValue }
    var title: String { self == .inStore ? "In-store" : "Video" }
    var icon: String  { self == .inStore ? "bag.fill"  : "video.fill" }
}

struct AssociateAppointment: Identifiable {
    let id:         UUID = UUID()
    let clientName: String
    let date:       Date
    let mode:       AppointmentMode

    var time: String { date.formatted(date: .abbreviated, time: .shortened) }
}

// MARK: - Sample Data

extension SalesAssociateSampleData {
    static let appointments: [AssociateAppointment] = [
        AssociateAppointment(
            clientName: "Ananya Rao",
            date: Calendar.current.date(bySettingHour: 16, minute: 30, second: 0, of: .now) ?? .now,
            mode: .inStore
        ),
        AssociateAppointment(
            clientName: "Kabir Mehta",
            date: Calendar.current.date(byAdding: .day, value: 1,
                  to: Calendar.current.date(bySettingHour: 11, minute: 0, second: 0, of: .now) ?? .now) ?? .now,
            mode: .video
        ),
        AssociateAppointment(
            clientName: "Mira Kapoor",
            date: Calendar.current.date(byAdding: .day, value: 3,
                  to: Calendar.current.date(bySettingHour: 14, minute: 15, second: 0, of: .now) ?? .now) ?? .now,
            mode: .inStore
        ),
        AssociateAppointment(
            clientName: "Rhea Sethi",
            date: Calendar.current.date(byAdding: .day, value: 5,
                  to: Calendar.current.date(bySettingHour: 12, minute: 30, second: 0, of: .now) ?? .now) ?? .now,
            mode: .video
        )
    ]
}
