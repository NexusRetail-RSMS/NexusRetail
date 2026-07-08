import SwiftUI

struct LoginView: View {
    @State private var viewModel: LoginViewModel
    @Environment(SessionStore.self) private var sessionStore
    @State private var showPassword = false
    @State private var showForgotPassword = false

    @State private var didAppear = false
    @State private var errorShake = false
    @FocusState private var focusedField: Field?
    @State private var screenBackgroundColor = Color(hex: "8B0000")
    @State private var iconPulse = false

    private let ambientPalette: [Color] = [
        Color(hex: "8B0000"),
        Color(hex: "5B0202"),
        Color(hex: "200E01")
    ]

    init(viewModel: LoginViewModel = LoginViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    private enum Field {
        case email, password
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            RadialGradient(
                colors: [screenBackgroundColor.opacity(0.85), screenBackgroundColor],
                center: .top,
                startRadius: 40,
                endRadius: 520
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.9), value: screenBackgroundColor)

            VStack(spacing: 0) {
                Spacer()

                logoHeader
                    .padding(.bottom, 28)
                    .opacity(didAppear ? 1 : 0)
                    .offset(y: didAppear ? 0 : 14)

                Spacer()

                card
                    .opacity(didAppear ? 1 : 0)
                    .offset(y: didAppear ? 0 : 28)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.82).delay(0.05)) {
                didAppear = true
            }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                iconPulse = true
            }
        }
        .onChange(of: viewModel.errorMessage) { _, newValue in
            guard !newValue.isEmpty else { return }
            withAnimation(.spring(response: 0.25, dampingFraction: 0.35)) {
                errorShake.toggle()
            }
        }
        .task {
            await cycleAmbientBackground()
        }
    }

    @MainActor
    private func cycleAmbientBackground() async {
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 3_800_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 2.4)) {
                screenBackgroundColor = ambientPalette.filter { $0 != screenBackgroundColor }.randomElement() ?? screenBackgroundColor
            }
        }
    }

    private var cardShape: some InsettableShape {
        UnevenRoundedRectangle(topLeadingRadius: 32, bottomLeadingRadius: 54, bottomTrailingRadius: 54, topTrailingRadius: 32)
    }

    private var card: some View {
        VStack(spacing: 0) {
            VStack(spacing: RSMSSpacing.xl) {
                VStack(alignment: .leading, spacing: RSMSSpacing.xs) {
                    Text("Welcome")
                        .font(RSMSFonts.largeTitle)
                        .fontWeight(.heavy)
                        .tracking(-0.4)
                        .foregroundColor(RSMSColors.primaryText)

                    Text("Sign in to continue to your account")
                        .font(RSMSFonts.subheadline)
                        .foregroundColor(RSMSColors.secondaryText.opacity(0.85))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, RSMSSpacing.sm)

                VStack(spacing: RSMSSpacing.lg) {
                    PremiumField(
                        icon: "envelope.fill",
                        isFocused: focusedField == .email
                    ) {
                        TextField("Email or Username", text: $viewModel.email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .textContentType(.username)
                            .font(RSMSFonts.body)
                            .focused($focusedField, equals: .email)
                            .accessibilityLabel("Email address or username")
                    }

                    PremiumField(
                        icon: "lock.fill",
                        isFocused: focusedField == .password
                    ) {
                        HStack(spacing: RSMSSpacing.sm) {
                            Group {
                                if showPassword {
                                    TextField("Password", text: $viewModel.password)
                                        .textContentType(.password)
                                } else {
                                    SecureField("Password", text: $viewModel.password)
                                        .textContentType(.password)
                                }
                            }
                            .font(RSMSFonts.body)
                            .focused($focusedField, equals: .password)
                            .accessibilityLabel("Password")

                            Button {
                                withAnimation(.easeOut(duration: 0.15)) {
                                    showPassword.toggle()
                                }
                            } label: {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(RSMSColors.secondaryText)
                                    .imageScale(.medium)
                                    .frame(width: 24, height: 24)
                                    .contentTransition(.symbolEffect(.replace))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    HStack {
                        Spacer()
                        Button(action: { showForgotPassword = true }) {
                            Text("Forgot password?")
                                .font(RSMSFonts.subheadline)
                                .foregroundColor(RSMSColors.burgundy)
                        }
                        .buttonStyle(.plain)
                    }
                }

                errorLabel

                signInButton
            }
            .padding(.horizontal, RSMSSpacing.lg)
            .padding(.bottom, 26)
        }
        .frame(maxWidth: 480)
        .frame(maxHeight: 400)
        .background(cardShape.fill(.regularMaterial))
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.10), Color.white.opacity(0.0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(cardShape)
        )
        .clipShape(cardShape)
        .overlay(
            cardShape
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.55), Color.white.opacity(0.04), Color.white.opacity(0.18)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .overlay(
            cardShape
                .inset(by: 0.5)
                .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
        )
        .shadow(color: RSMSColors.burgundy.opacity(0.22), radius: 36, x: 0, y: 22)
        .shadow(color: Color.black.opacity(0.16), radius: 14, x: 0, y: 8)
        .padding(.horizontal, 7)
        .padding(.bottom, 7)
        .offset(x: errorShake ? -8 : 0)
        .animation(.spring(response: 0.12, dampingFraction: 0.25).repeatCount(4, autoreverses: true), value: errorShake)
    }

    private var logoHeader: some View {
        VStack(spacing: RSMSSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 108, height: 108)
                    .scaleEffect(iconPulse ? 1.12 : 1)
                    .opacity(iconPulse ? 0.4 : 0.9)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.22), Color.white.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 78, height: 78)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.28), lineWidth: 1)
                    )

                ZStack {
                    Image(systemName: "bag.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 10))
                        .foregroundColor(screenBackgroundColor)
                        .offset(y: 2)
                }
            }

            Text("NexusRetail")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .tracking(0.3)
        }
    }

    @ViewBuilder
    private var errorLabel: some View {
        if !viewModel.errorMessage.isEmpty {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 13))
                Text(viewModel.errorMessage)
                    .font(RSMSFonts.subheadline)
                    .multilineTextAlignment(.leading)
            }
            .foregroundStyle(RSMSColors.error)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(RSMSColors.error.opacity(0.08))
            )
            .accessibilityLabel("Error: \(viewModel.errorMessage)")
            .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .opacity))
        }
    }

    private var signInButton: some View {
        Button {
            withAnimation(.easeOut(duration: 0.15)) {
                focusedField = nil
            }
            Task { await viewModel.login(using: sessionStore) }
        } label: {
            HStack(spacing: 8) {
                ZStack {
                    Text("Sign In")
                        .font(RSMSFonts.headline)
                        .tracking(0.2)
                        .opacity(viewModel.isLoading ? 0 : 1)

                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                }

                if !viewModel.isLoading {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: viewModel.isLoginButtonEnabled
                        ? [RSMSColors.burgundy, RSMSColors.burgundy.opacity(0.82)]
                        : [RSMSColors.disabled, RSMSColors.disabled],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                LinearGradient(
                    colors: [Color.white.opacity(0.28), Color.white.opacity(0.0)],
                    startPoint: .top,
                    endPoint: .center
                )
            )
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: viewModel.isLoginButtonEnabled ? RSMSColors.burgundy.opacity(0.35) : .clear, radius: 18, x: 0, y: 10)
        }
        .buttonStyle(SpringPressStyle())
        .disabled(!viewModel.isLoginButtonEnabled)
        .animation(.easeOut(duration: 0.2), value: viewModel.isLoginButtonEnabled)
        .accessibilityLabel("Sign in")
        .accessibilityValue(viewModel.isLoading ? "Authenticating" : "")
    }
}

private struct PremiumField<Content: View>: View {
    let icon: String
    let isFocused: Bool
    @ViewBuilder let content: () -> Content

    private var fieldShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
    }

    var body: some View {
        HStack(spacing: RSMSSpacing.sm) {
            ZStack {
                Circle()
                    .fill(RSMSColors.burgundy.opacity(0.10))
                    .frame(width: 30, height: 30)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(RSMSColors.burgundy)
            }

            content()
        }
        .padding(.horizontal, RSMSSpacing.md)
        .frame(height: 54)
        .background(fieldShape.fill(.thinMaterial))
        .overlay(
            fieldShape
                .stroke(
                    isFocused ? RSMSColors.burgundy.opacity(0.5) : Color.white.opacity(0.3),
                    lineWidth: isFocused ? 1.5 : 1
                )
        )
        .shadow(color: Color.black.opacity(isFocused ? 0.1 : 0.04), radius: isFocused ? 10 : 4, x: 0, y: 3)
        .animation(.easeOut(duration: 0.18), value: isFocused)
    }
}

private struct SpringPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.55), value: configuration.isPressed)
    }
}

#Preview("Default") {
    NavigationStack {
        LoginView()
            .environment(SessionStore())
    }
}

#Preview("With error") {
    let viewModel = LoginViewModel()
    viewModel.email = "manager@nexusretail.com"
    viewModel.password = "wrongpass"
    viewModel.errorMessage = "Incorrect email or password"

    return NavigationStack {
        LoginView(viewModel: viewModel)
            .environment(SessionStore())
    }
}

#Preview("Loading") {
    let viewModel = LoginViewModel()
    viewModel.email = "manager@nexusretail.com"
    viewModel.password = "correctpass"
    viewModel.isLoading = true

    return NavigationStack {
        LoginView(viewModel: viewModel)
            .environment(SessionStore())
    }
}

#Preview("Dark mode") {
    NavigationStack {
        LoginView()
            .environment(SessionStore())
    }
    .preferredColorScheme(.dark)
}
