import SwiftUI

enum PerformanceTier {
    case gold, silver, bronze, none

    var label: LocalizedStringKey {
        switch self {
        case .gold:   return "Top Performer"
        case .silver: return "Silver Tier"
        case .bronze: return "Bronze Tier"
        case .none:   return ""
        }
    }

    var icon: String {
        switch self {
        case .gold:   return "crown.fill"
        case .silver: return "medal.fill"
        case .bronze: return "medal"
        case .none:   return ""
        }
    }

    var ringColors: [Color] {
        switch self {
        case .gold:
            return [
                Color(red: 1.0,  green: 0.84, blue: 0.0),
                Color(red: 1.0,  green: 0.65, blue: 0.0),
                Color(red: 1.0,  green: 0.90, blue: 0.4),
                Color(red: 0.85, green: 0.65, blue: 0.13),
                Color(red: 1.0,  green: 0.84, blue: 0.0)
            ]
        case .silver:
            return [
                Color(red: 0.85, green: 0.85, blue: 0.88),
                Color(red: 0.60, green: 0.60, blue: 0.65),
                Color(red: 0.95, green: 0.95, blue: 1.0),
                Color(red: 0.70, green: 0.70, blue: 0.75),
                Color(red: 0.85, green: 0.85, blue: 0.88)
            ]
        case .bronze:
            return [
                Color(red: 0.80, green: 0.50, blue: 0.20),
                Color(red: 0.55, green: 0.27, blue: 0.07),
                Color(red: 0.93, green: 0.64, blue: 0.33),
                Color(red: 0.65, green: 0.37, blue: 0.12),
                Color(red: 0.80, green: 0.50, blue: 0.20)
            ]
        case .none:
            return [Color.gray.opacity(0.3)]
        }
    }

    var textColor: Color {
        switch self {
        case .gold:   return Color(red: 0.6,  green: 0.45, blue: 0.0)
        case .silver: return Color(red: 0.35, green: 0.35, blue: 0.45)
        case .bronze: return Color(red: 0.50, green: 0.28, blue: 0.06)
        case .none:   return .clear
        }
    }
}

struct GlobalProfileView: View {
    @Environment(AppTheme.self) private var theme
    @Environment(SessionStore.self) private var sessionStore
    @State private var viewModel = ProfileViewModel()

    @State private var ringRotation: Double = 0
    @State private var performanceTier: PerformanceTier = .gold
    @State private var showEditProfile = false

    private var effectivePerformanceTier: PerformanceTier {
        if sessionStore.currentRole == .manager || sessionStore.currentUser?.role == .manager {
            return performanceTier
        }
        return .none
    }

    private var profileCardColors: [Color] {
        theme.isDarkMode
            ? [Color(hex: "3D0000"), Color(hex: "2C0000"), Color(hex: "1E1E1E")]
            : [theme.burgundy.opacity(0.20), theme.burgundy.opacity(0.05)]
    }

    var body: some View {
        List {
            if viewModel.isLoading && viewModel.profile == nil {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, minHeight: 300)
                    .listRowBackground(Color.clear)
            } else if let profile = viewModel.profile {
                // MARK: - Avatar Header Section
                Section {
                    VStack(spacing: 12) {
                        // Avatar with performance ring
                        ZStack {
                            if effectivePerformanceTier != .none {
                                // Outer rotating shiny ring
                                Circle()
                                    .stroke(
                                        AngularGradient(
                                            colors: effectivePerformanceTier.ringColors,
                                            center: .center,
                                            angle: .degrees(ringRotation)
                                        ),
                                        lineWidth: 5
                                    )
                                    .frame(width: 126, height: 126)
                                    .blur(radius: 0.5)
                                    .onAppear {
                                        if !UIAccessibility.isVoiceOverRunning {
                                            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                                                ringRotation = 360
                                            }
                                        }
                                    }

                                // Glittery sparkle dots
                                ForEach(0..<8, id: \.self) { i in
                                    sparkleDot(index: i)
                                }
                            }

                            // Gap ring — adapts to dark mode
                            Circle()
                                .stroke(theme.isDarkMode ? Color(hex: "1C1C1C") : Color.white, lineWidth: 4)
                                .frame(width: 118, height: 118)

                            // Profile photo
                            ZStack {
                                Circle()
                                    .fill(theme.isDarkMode
                                          ? Color(hex: "2C0000")
                                          : theme.burgundy.opacity(0.15))
                                    .frame(width: 110, height: 110)

                                if let urlString = profile.profileImage, let url = URL(string: urlString) {
                                    CachedAsyncImage(url: url) { image in
                                        image.resizable().scaledToFill()
                                            .frame(width: 110, height: 110)
                                            .clipShape(Circle())
                                    } placeholder: { ProgressView().frame(width: 110, height: 110) }
                                } else {
                                    Image(systemName: "person.fill")
                                        .resizable().scaledToFit()
                                        .frame(width: 58, height: 58)
                                        .foregroundColor(theme.isDarkMode ? theme.antiqueGold : theme.burgundy)
                                }
                            }
                        }

                        // Name
                        Text(profile.fullName)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(theme.isDarkMode ? theme.antiqueGold : theme.primaryText)

                        // Performance tier badge
                        if effectivePerformanceTier != .none {
                            tierBadgeView
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
                }
                .listRowBackground(
                    // Gradient fills behind the avatar
                    LinearGradient(
                        colors: profileCardColors,
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .listRowInsets(EdgeInsets())

                // MARK: - Pill 1: Role · Phone · Email
                Section {
                    infoRow(icon: "person.badge.shield.checkmark.fill",
                            label: "Role",
                            value: profile.role.rawValue.capitalized,
                            valueColor: theme.isDarkMode ? theme.antiqueGold : theme.burgundy)

                    infoRow(icon: "phone.fill",
                            label: "Phone",
                            value: profile.phone)

                    infoRow(icon: "envelope.fill",
                            label: "Email",
                            value: profile.email)
                }

                // MARK: - Pill 2: Address · Country
                Section {
                    infoRow(icon: "location.fill",
                            label: "Address",
                            value: profile.address,
                            multiline: true)

                    infoRow(icon: "globe",
                            label: "Country",
                            value: profile.country,
                            valueColor: theme.isDarkMode ? theme.antiqueGold : theme.burgundy)
                }

                // MARK: - Pill 3: Settings
                Section {
                    NavigationLink(destination: SettingsView(viewModel: viewModel)) {
                        HStack(spacing: 12) {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(theme.burgundy)
                                .font(.system(size: 16, weight: .semibold))
                                .frame(width: 20)

                            Text("Settings")
                                .font(RSMSFonts.body)
                                .foregroundColor(theme.primaryText)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(theme.groupedBackground)
        .navigationTitle("Profile")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showEditProfile = true
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 16, weight: .semibold))
                }
                .accessibilityLabel("Edit Profile")
            }
        }
        .navigationDestination(isPresented: $showEditProfile) {
            EditProfileView(viewModel: viewModel)
        }
        .task {
            if viewModel.profile == nil {
                await viewModel.fetchProfile(from: sessionStore.currentUser)
            }
        }
    }

    // MARK: - View Builders

    // Tier Badge
    private var tierBadgeView: some View {
        let bgColors: [Color] = Array(effectivePerformanceTier.ringColors.prefix(3)).map { $0.opacity(0.25) }
        let strokeColors: [Color] = Array(effectivePerformanceTier.ringColors.prefix(3))
        return HStack(spacing: 6) {
            Image(systemName: effectivePerformanceTier.icon)
                .font(.system(size: 11, weight: .bold))
            Text(effectivePerformanceTier.label)
                .font(.system(size: 12, weight: .bold))
        }
        .foregroundColor(effectivePerformanceTier.textColor)
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(LinearGradient(colors: bgColors, startPoint: .leading, endPoint: .trailing))
        )
        .overlay(
            Capsule()
                .stroke(LinearGradient(colors: strokeColors, startPoint: .leading, endPoint: .trailing), lineWidth: 1.2)
        )
    }

    // Sparkle dot helper
    private func sparkleDot(index i: Int) -> some View {
        let angle = Double(i) * 45.0
        let radians = angle * .pi / 180
        let size: CGFloat = i % 2 == 0 ? 5 : 3
        let color = effectivePerformanceTier.ringColors.first ?? .yellow
        let xOffset = cos(radians) * 66
        let yOffset = sin(radians) * 66
        return Circle()
            .fill(color)
            .frame(width: size, height: size)
            .offset(x: xOffset, y: yOffset)
            .opacity(0.85)
            .blur(radius: 0.3)
    }

    @ViewBuilder
    private func infoRow(
        icon: String,
        label: String,
        value: String,
        valueColor: Color = .secondary,
        multiline: Bool = false
    ) -> some View {
        HStack(alignment: multiline ? .top : .center, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(theme.isDarkMode ? theme.antiqueGold : theme.burgundy)
                .frame(width: 20)

            Text(localized: label)
                .foregroundColor(theme.primaryText)

            Spacer()

            Text(localized: value)
                .foregroundColor(valueColor)
                .multilineTextAlignment(.trailing)
                .lineLimit(multiline ? 3 : 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label.localizedUI), \(value)")
    }
}
