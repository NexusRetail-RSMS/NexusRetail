//
//  StoreDetailView.swift
//  NexusRetail
//

import SwiftUI

struct StoreDetailView: View {
    let store: Store
    let manager: DisplayManager?
    @Bindable var viewModel: StoresViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var toastMessage: String? = nil

    private var isActive: Bool { store.status == .active }

    private var statusColor: Color {
        isActive ? RSMSColors.success : RSMSColors.secondaryText
    }

    private var statusLabel: String {
        store.status?.rawValue.capitalized ?? "Unknown"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RSMSSpacing.xl) {
                heroCard
                ManagerCard(manager: manager, openURL: openURL)
                infoCard
            }
            .padding(.horizontal, RSMSSpacing.lg)
            .padding(.top, RSMSSpacing.lg)
            .padding(.bottom, RSMSSpacing.xxxxl)
        }
        .background(RSMSColors.background.ignoresSafeArea())
        .navigationTitle(store.name)
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .bottom) {
            if let toastMessage {
                ToastView(message: toastMessage)
                    .padding(.bottom, RSMSSpacing.xl)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
                            withAnimation(.easeOut(duration: 0.25)) {
                                self.toastMessage = nil
                            }
                        }
                    }
            }
        }
        .animation(.easeOut(duration: 0.25), value: toastMessage)
    }

    // MARK: - Shared URL opener
    private func openURL(_ url: URL, failureMessage: String) {
        UIApplication.shared.open(url) { success in
            if !success {
                withAnimation(.easeOut(duration: 0.2)) {
                    toastMessage = failureMessage
                }
            }
        }
    }

    // MARK: - Hero

    private var heroCard: some View {
        VStack(spacing: RSMSSpacing.md) {
            ZStack {
                Circle()
                    .fill(RSMSColors.burgundy.opacity(0.08))
                    .frame(width: 148, height: 148)
                    .blur(radius: 20)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [RSMSColors.burgundy.opacity(0.20), RSMSColors.burgundy.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 116, height: 116)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [RSMSColors.burgundy.opacity(0.35), RSMSColors.burgundy.opacity(0.05)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    )

                Image(systemName: store.isWarehouse == true ? "shippingbox.fill" : "building.2.fill")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [RSMSColors.burgundy, RSMSColors.burgundy.opacity(0.75)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .shadow(color: RSMSColors.burgundy.opacity(0.20), radius: 20, x: 0, y: 10)
            .padding(.top, RSMSSpacing.xl)

            VStack(spacing: 6) {
                Text(store.name)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(RSMSColors.primaryText)
                    .multilineTextAlignment(.center)

                Text(store.isWarehouse == true ? "Warehouse" : "Retail Store")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundColor(RSMSColors.secondaryText)
            }

            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 6, height: 6)
                Text(statusLabel)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(statusColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(statusColor.opacity(0.10), in: Capsule())
            .overlay(Capsule().stroke(statusColor.opacity(0.25), lineWidth: 0.75))
            .padding(.top, 2)
            .padding(.bottom, RSMSSpacing.xl)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(RSMSColors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32)
                .stroke(
                    LinearGradient(
                        colors: [RSMSColors.burgundy.opacity(0.15), RSMSColors.cardBorder],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 10)
    }

    // MARK: - Info card

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(RSMSColors.burgundy)
                    .frame(width: 3, height: 16)
                Text("Store Information")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(RSMSColors.primaryText)
                Spacer()
            }
            .padding(.horizontal, RSMSSpacing.lg)
            .padding(.top, RSMSSpacing.lg)
            .padding(.bottom, RSMSSpacing.md)

            VStack(spacing: 0) {
                InfoRow(
                    icon: "mappin.and.ellipse",
                    title: "Address",
                    value: store.address ?? "Not provided",
                    actionIcon: directionsURL != nil ? "map.fill" : nil,
                    action: directionsURL.map { url in
                        { openURL(url, failureMessage: "Couldn't open Maps") }
                    }
                )
                RowDivider()
                InfoRow(
                    icon: "phone.fill",
                    title: "Phone",
                    value: store.phone ?? "Not provided",
                    actionIcon: callURL != nil ? "phone.fill" : nil,
                    action: callURL.map { url in
                        { openURL(url, failureMessage: "Couldn't start a call") }
                    }
                )
                RowDivider()
                InfoRow(icon: "globe", title: "Locale & Timezone", value: "\(store.readableLocale) • \(store.timezone ?? "N/A")")
                RowDivider()
                InfoRow(icon: "indianrupeesign.circle.fill", title: "Currency", value: store.currencyCode ?? "N/A", isLast: true)
            }
        }
        .background(RSMSColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: RSMSRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: RSMSRadius.large)
                .stroke(RSMSColors.cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 14, x: 0, y: 6)
    }

    // MARK: - Row URLs

    private var directionsURL: URL? {
        guard let address = store.address, !address.isEmpty,
              let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
        return URL(string: "http://maps.apple.com/?q=\(encoded)")
    }

    private var callURL: URL? {
        guard let phone = store.phone, !phone.isEmpty else { return nil }
        return URL(string: "tel:\(phone.filter { $0.isNumber || $0 == "+" })")
    }
}

// MARK: - Manager card

private struct ManagerCard: View {
    let manager: DisplayManager?
    let openURL: (URL, String) -> Void

    private func initials(_ name: String) -> String {
        name.split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map(String.init)
            .joined()
            .uppercased()
    }

    private func tenureText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return "Store manager · since \(formatter.string(from: date))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(RSMSColors.burgundy)
                    .frame(width: 3, height: 16)
                Text("Manager")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(RSMSColors.primaryText)
                Spacer()
            }
            .padding(.horizontal, RSMSSpacing.lg)
            .padding(.top, RSMSSpacing.lg)
            .padding(.bottom, RSMSSpacing.md)

            if let manager {
                HStack(spacing: RSMSSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(RSMSColors.burgundy.opacity(0.12))
                            .frame(width: 44, height: 44)

                        if let urlString = manager.imageUrl, let url = URL(string: urlString) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 44, height: 44)
                                    .clipShape(Circle())
                            } placeholder: {
                                Text(initials(manager.name))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(RSMSColors.burgundy)
                            }
                        } else {
                            Text(initials(manager.name))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(RSMSColors.burgundy)
                        }
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(manager.name)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(RSMSColors.primaryText)
                        Text(tenureText(manager.createdAt))
                            .font(.system(size: 12.5))
                            .foregroundColor(RSMSColors.secondaryText)
                    }

                    Spacer(minLength: 8)

                    HStack(spacing: 6) {
                        if !manager.phone.isEmpty,
                           let url = URL(string: "tel:\(manager.phone.filter { $0.isNumber || $0 == "+" })") {
                            ManagerIconButton(icon: "phone.fill") {
                                openURL(url, "Couldn't start a call")
                            }
                        }
                        if !manager.email.isEmpty,
                           let url = URL(string: "mailto:\(manager.email)") {
                            ManagerIconButton(icon: "envelope.fill") {
                                openURL(url, "No mail app is set up on this device")
                            }
                        }
                    }
                }
                .padding(.horizontal, RSMSSpacing.lg)
                .padding(.bottom, RSMSSpacing.lg)
            } else {
                HStack(spacing: RSMSSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(RSMSColors.background)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [4]))
                                    .foregroundColor(RSMSColors.cardBorder)
                            )
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 16))
                            .foregroundColor(RSMSColors.secondaryText)
                    }
                    Text("No manager assigned")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(RSMSColors.secondaryText)
                    Spacer()
                }
                .padding(.horizontal, RSMSSpacing.lg)
                .padding(.bottom, RSMSSpacing.lg)
            }
        }
        .background(RSMSColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: RSMSRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: RSMSRadius.large)
                .stroke(RSMSColors.cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 14, x: 0, y: 6)
    }
}

private struct ManagerIconButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(RSMSColors.burgundy)
                .frame(width: 34, height: 34)
                .background(RSMSColors.burgundy.opacity(0.1), in: Circle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Info row

private struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    var actionIcon: String? = nil
    var action: (() -> Void)? = nil
    var isLast: Bool = false

    var body: some View {
        HStack(spacing: RSMSSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 11)
                    .fill(
                        LinearGradient(
                            colors: [RSMSColors.burgundy.opacity(0.12), RSMSColors.burgundy.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(RSMSColors.burgundy)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundColor(RSMSColors.secondaryText)
                Text(value)
                    .font(.system(size: 14.5, weight: .medium))
                    .foregroundColor(RSMSColors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            if let actionIcon, let action {
                Button(action: action) {
                    Image(systemName: actionIcon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(RSMSColors.burgundy)
                        .frame(width: 34, height: 34)
                        .background(RSMSColors.burgundy.opacity(0.1), in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.vertical, RSMSSpacing.md)
    }
}

private struct RowDivider: View {
    var body: some View {
        Rectangle()
            .fill(RSMSColors.divider)
            .frame(height: 0.5)
            .padding(.leading, RSMSSpacing.lg + 36 + RSMSSpacing.md)
    }
}

// MARK: - Toast

private struct ToastView: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 14))
            Text(message)
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.85), in: Capsule())
        .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 6)
    }
}
