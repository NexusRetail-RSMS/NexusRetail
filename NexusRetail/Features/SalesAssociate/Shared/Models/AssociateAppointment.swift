//
//  AssociateAppointment.swift
//  NexusRetail
//
//  Model for a clienteling appointment and its related enums.
//

import Foundation

// MARK: - Sample Data

extension SalesAssociateSampleData {
    static let appointments: [AssociateAppointment] = [
        AssociateAppointment(
            clientName: "Ananya Rao",
            clientEmail: "ananya@example.com",
            clientPhone: "1234567890",
            date: Calendar.current.date(bySettingHour: 16, minute: 30, second: 0, of: .now) ?? .now,
            mode: .inStore,
            productOrNote: "Note"
        ),
        AssociateAppointment(
            clientName: "Kabir Mehta",
            clientEmail: "kabir@example.com",
            clientPhone: "1234567890",
            date: Calendar.current.date(byAdding: .day, value: 1,
                  to: Calendar.current.date(bySettingHour: 11, minute: 0, second: 0, of: .now) ?? .now) ?? .now,
            mode: .video,
            productOrNote: "Note"
        ),
        AssociateAppointment(
            clientName: "Mira Kapoor",
            clientEmail: "mira@example.com",
            clientPhone: "1234567890",
            date: Calendar.current.date(byAdding: .day, value: 3,
                  to: Calendar.current.date(bySettingHour: 14, minute: 15, second: 0, of: .now) ?? .now) ?? .now,
            mode: .inStore,
            productOrNote: "Note"
        ),
        AssociateAppointment(
            clientName: "Rhea Sethi",
            clientEmail: "rhea@example.com",
            clientPhone: "1234567890",
            date: Calendar.current.date(byAdding: .day, value: 5,
                  to: Calendar.current.date(bySettingHour: 12, minute: 30, second: 0, of: .now) ?? .now) ?? .now,
            mode: .video,
            productOrNote: "Note"
        )
    ]
}
