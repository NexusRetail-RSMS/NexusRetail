import SwiftUI

struct SalesToolbarModifier: ViewModifier {
    let title: String
    @Environment(SessionStore.self) private var sessionStore
    @State private var isProfilePresented = false

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { isProfilePresented = true } label: {
                        ZStack {
                            Circle().fill(RSMSColors.burgundy).frame(width: 32, height: 32)
                            Text(initials(for: sessionStore.currentUser?.name))
                                .font(.system(size: 11, weight: .bold)).foregroundStyle(.white)
                        }
                    }
                }
            }
            .sheet(isPresented: $isProfilePresented) { SalesProfileSheet() }
    }

    private func initials(for name: String?) -> String {
        guard let name, !name.isEmpty else { return "SA" }
        let parts = name.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        if parts.count >= 2 { return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased() }
        return String((parts.first ?? "SA").prefix(2)).uppercased()
    }
}
