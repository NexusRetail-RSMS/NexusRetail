import SwiftUI

struct Login: View {
    @Environment(SessionStore.self) private var sessionStore
    @State private var viewModel = LoginViewModel()
    @State private var showForgotPassword = false
    @FocusState private var emailFocused: Bool
    @FocusState private var passwordFocused: Bool

    @State private var didAppear = false
    @State private var errorShake = false

    init(viewModel: LoginViewModel = LoginViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            loginContent
                .blur(radius: showForgotPassword ? 8 : 0)
                .allowsHitTesting(!showForgotPassword)

            if showForgotPassword {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.86)) {
                            showForgotPassword = false
                        }
                    }
                    .zIndex(1)

                ForgotPasswordSheet(isPresented: $showForgotPassword)
                    .transition(.move(edge: .bottom))
                    .zIndex(2)
            }
        }
        .ignoresSafeArea(.container, edges: .all)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.82).delay(0.05)) {
                didAppear = true
            }
        }
        .onChange(of: viewModel.errorMessage) { _, newValue in
            guard !newValue.isEmpty else { return }
            withAnimation(.spring(response: 0.25, dampingFraction: 0.35)) {
                errorShake.toggle()
            }
            UIAccessibility.post(notification: .announcement, argument: "Login error: \(newValue)")
        }
        .animation(.spring(response: 0.12, dampingFraction: 0.25).repeatCount(4, autoreverses: true), value: errorShake)
        .animation(.spring(response: 0.45, dampingFraction: 0.86), value: showForgotPassword)
    }

    private var loginContent: some View {
        ZStack {
            RSMSColors.background.ignoresSafeArea()
            backgroundCircleTopLeading
            backgroundCircleBottomTrailing

            VStack(alignment: .leading, spacing: 15) {
                Spacer(minLength: 0)

                Text("Login")
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .foregroundStyle(RSMSColors.primaryText)

                Text("Enter your credentials to continue")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(RSMSColors.secondaryText)
                    .padding(.top, -5)

                VStack(spacing: 20) {
                    CustomTF(
                        sfIcon: "at",
                        hint: "Email ID",
                        keyboardType: .emailAddress,
                        textContentType: .username,
                        value: $viewModel.email,
                        isFocused: $emailFocused
                    )

                    VStack(alignment: .trailing, spacing: 20) {
                        CustomTF(
                            sfIcon: "lock",
                            hint: "Password",
                            isPassword: true,
                            textContentType: .password,
                            value: $viewModel.password,
                            isFocused: $passwordFocused
                        )

                        Button("Forgot Password?") {
                            passwordFocused = false
                            emailFocused = false
                            showForgotPassword = true
                        }
                        .font(.callout)
                        .fontWeight(.heavy)
                        .tint(RSMSColors.burgundy)
                        .accessibilityHint("Double tap to recover your password")
                    }

                    if !viewModel.errorMessage.isEmpty {
                        Text(viewModel.errorMessage)
                            .font(.callout)
                            .foregroundStyle(RSMSColors.error)
                            .hSpacing(.leading)
                            .accessibilityLabel("Error: \(viewModel.errorMessage)")
                            .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .opacity))
                    }
                }
                .padding(.top, 20)

                GradientButton(
                    title: "Login",
                    icon: "arrow.right",
                    isLoading: viewModel.isLoading,
                    isEnabled: viewModel.isLoginButtonEnabled
                ) {
                    emailFocused = false
                    passwordFocused = false
                    Task { await viewModel.login(using: sessionStore) }
                }
                .hSpacing(.trailing)
                .padding(.top, 28)

                Spacer(minLength: 0)
            }
            .padding(.vertical, 15)
            .padding(.horizontal, 25)
            .opacity(didAppear ? 1 : 0)
            .offset(y: didAppear ? 0 : 24)
            .offset(x: errorShake ? -8 : 0)
        }
    }

    private var backgroundCircleTopLeading: some View {
        Circle()
            .fill(.linearGradient(colors: [RSMSColors.burgundy, RSMSColors.darkBurgundy], startPoint: .top, endPoint: .bottom))
            .frame(width: 220, height: 220)
            .blur(radius: 15)
            .opacity(0.35)
            .offset(x: -90, y: -90)
            .hSpacing(.leading)
            .vSpacing(.top)
            .allowsHitTesting(false)
    }

    private var backgroundCircleBottomTrailing: some View {
        Circle()
            .fill(.linearGradient(colors: [RSMSColors.darkBurgundy, RSMSColors.burgundy], startPoint: .top, endPoint: .bottom))
            .frame(width: 260, height: 260)
            .blur(radius: 15)
            .opacity(0.3)
            .offset(x: 100, y: 110)
            .hSpacing(.trailing)
            .vSpacing(.bottom)
            .allowsHitTesting(false)
    }
}

#Preview("Default") {
    NavigationStack {
        Login()
            .environment(SessionStore())
    }
}

#Preview("With error") {
    let viewModel = LoginViewModel()
    viewModel.email = "manager@nexusretail.com"
    viewModel.password = "wrongpass"
    viewModel.errorMessage = "Incorrect email or password"

    return NavigationStack {
        Login(viewModel: viewModel)
            .environment(SessionStore())
    }
}

#Preview("Loading") {
    let viewModel = LoginViewModel()
    viewModel.email = "manager@nexusretail.com"
    viewModel.password = "correctpass"
    viewModel.isLoading = true

    return NavigationStack {
        Login(viewModel: viewModel)
            .environment(SessionStore())
    }
}

#Preview("Dark mode") {
    NavigationStack {
        Login()
            .environment(SessionStore())
    }
    .preferredColorScheme(.dark)
}

#Preview("Forgot Password Sheet") {
    ZStack(alignment: .bottom) {
        Color(.systemGray6).ignoresSafeArea()
        ForgotPasswordSheet(isPresented: .constant(true))
    }
}
