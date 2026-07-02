//
//  SalesSharedUI.swift
//  NexusRetail
//
//  Reusable view-returning free functions shared across SalesAssociate feature tabs.
//

import SwiftUI

// MARK: - Hero Banner

func salesHero(title: String, subtitle: String, systemImage: String) -> some View {
    HStack(alignment: .top, spacing: 16) {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(subtitle)
                .font(RSMSFonts.body)
                .foregroundStyle(.white.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)
        }
        Spacer()
        Image(systemName: systemImage)
            .font(.system(size: 24, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 48, height: 48)
            .background(.white.opacity(0.16))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    .padding(20)
    .background(
        LinearGradient(
            colors: [RSMSColors.burgundy, RSMSColors.darkBurgundy],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    .shadow(color: RSMSColors.burgundy.opacity(0.24), radius: 18, x: 0, y: 10)
}

// MARK: - Info Row (Client detail card)

func infoRow(title: String, value: String, icon: String) -> some View {
    HStack(alignment: .top, spacing: 14) {
        Image(systemName: icon)
            .foregroundStyle(RSMSColors.burgundy)
            .frame(width: 42, height: 42)
            .background(RSMSColors.burgundy.opacity(0.08))
            .clipShape(Circle())

        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(RSMSColors.primaryText)
            Text(value)
                .font(RSMSFonts.subheadline)
                .foregroundStyle(RSMSColors.secondaryText)
        }
        Spacer()
    }
    .padding(18)
    .luxuryCard()
}

// MARK: - Empty State Row

func emptyStateRow(title: String, icon: String) -> some View {
    HStack(spacing: 12) {
        Image(systemName: icon)
            .foregroundStyle(RSMSColors.burgundy)
            .frame(width: 42, height: 42)
            .background(RSMSColors.burgundy.opacity(0.08))
            .clipShape(Circle())
        Text(title)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(RSMSColors.secondaryText)
        Spacer()
    }
    .padding(16)
}

// MARK: - Appointment Row

func appointmentRow(_ appointment: AssociateAppointment) -> some View {
    HStack(spacing: 14) {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(RSMSColors.burgundy.opacity(0.09))
            .frame(width: 46, height: 46)
            .overlay {
                Image(systemName: appointment.mode.icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(RSMSColors.burgundy)
            }

        VStack(alignment: .leading, spacing: 4) {
            Text(appointment.clientName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(RSMSColors.primaryText)
            Text(appointment.time)
                .font(RSMSFonts.subheadline)
                .foregroundStyle(RSMSColors.secondaryText)
        }
        Spacer()

        Text(appointment.mode.title)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(RSMSColors.burgundy)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(RSMSColors.burgundy.opacity(0.08))
            .clipShape(Capsule())
    }
    .padding(14)
}

// MARK: - Initials Helper

func salesInitials(for name: String?) -> String {
    guard let name, !name.isEmpty else { return "SA" }
    let parts = name.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
    if parts.count >= 2 {
        return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
    }
    return String((parts.first ?? "SA").prefix(2)).uppercased()
}
