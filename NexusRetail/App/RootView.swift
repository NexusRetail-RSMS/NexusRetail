import SwiftUI

struct RootView: View {
    @Environment(SessionStore.self) private var sessionStore
    @State private var isRestoring = true

    var body: some View {
        Group {
            if isRestoring {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(RSMSColors.background.ignoresSafeArea())
            } else if sessionStore.currentUser != nil && sessionStore.needsOTPVerification {
                otpGate
            } else if let role = sessionStore.currentRole {
                switch role {
                case .admin:
                    AdminTabView()
                case .manager:
                    ManagerTabView()
                case .salesAssociate:
                    SalesTabView()
                case .afterSales:
                    AfterSalesTabView()
                }
            } else {
                NavigationStack {
                    Login()
                }
            }
        }
        .animation(.easeInOut, value: isRestoring)
        .animation(.spring(response: 0.45, dampingFraction: 0.86), value: sessionStore.needsOTPVerification)
        .animation(.easeInOut, value: sessionStore.currentRole)
        .task {
            await sessionStore.restore()
            withAnimation(.easeInOut) {
                isRestoring = false
            }
        }
    }

    private var otpGate: some View {
        ZStack(alignment: .bottom) {
            RSMSColors.background
            backgroundCircle
            Color.black.opacity(0.001)
                .zIndex(1)
            OTPSheetView(
                email: sessionStore.currentUser?.email ?? "",
                subtitle: "Enter the code to finish signing in.",
                cancelLabel: "Cancel and sign out",
                onSend: { await sendLoginOTP() },
                onVerify: { code in await verifyLoginOTP(code) },
                onCancel: {
                    Task { try? await sessionStore.signOut() }
                }
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .zIndex(2)
        }
        .ignoresSafeArea()
    }

    private var backgroundCircle: some View {
        Circle()
            .fill(.linearGradient(colors: [RSMSColors.burgundy, RSMSColors.darkBurgundy], startPoint: .top, endPoint: .bottom))
            .frame(width: 220, height: 220)
            .blur(radius: 40)
            .opacity(0.35)
            .offset(x: -90, y: -90)
            .hSpacing(.leading)
            .vSpacing(.top)
            .allowsHitTesting(false)
    }

    private func sendLoginOTP() async -> OTPSendOutcome {
        do {
            let resp = try await sessionStore.requestOTP()
            if resp.success {
                return .sent(debugCode: resp.debugCode)
            } else if resp.reason == "rate_limited" {
                return .rateLimited
            } else {
                return .failed
            }
        } catch {
            return .failed
        }
    }

    private func verifyLoginOTP(_ code: String) async -> Bool {
        (try? await sessionStore.verifyOTP(code: code)) ?? false
    }
}
