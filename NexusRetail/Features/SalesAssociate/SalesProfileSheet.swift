import SwiftUI

struct SalesProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SessionStore.self) private var sessionStore
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            ZStack {
                                Circle().fill(RSMSColors.burgundy.opacity(0.1)).frame(width: 80, height: 80)
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 48))
                                    .foregroundStyle(RSMSColors.burgundy)
                                    .symbolEffect(.bounce, value: appeared)
                            }
                            .scaleEffect(appeared ? 1 : 0.72)
                            .opacity(appeared ? 1 : 0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.72), value: appeared)

                            Text(sessionStore.currentUser?.name ?? "Sales Associate")
                                .font(.system(size: 20, weight: .bold, design: .rounded))

                            Text("Sales Associate")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(RSMSColors.burgundy)
                                .padding(.horizontal, 14).padding(.vertical, 6)
                                .background(RSMSColors.burgundy.opacity(0.09))
                                .clipShape(Capsule())
                        }
                        .padding(.vertical, 16)
                        Spacer()
                    }
                }

                Section {
                    Button(role: .destructive) {
                        dismiss()
                        Task { try? await sessionStore.signOut() }
                    } label: {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("My Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear { appeared = true }
        .presentationDragIndicator(.visible)
    }
}
