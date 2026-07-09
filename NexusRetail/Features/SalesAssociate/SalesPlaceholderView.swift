import SwiftUI

struct SalesPlaceholderView: View {
    @Environment(AppTheme.self) private var theme
    let title: String
    let message: String
    let icon: String
    @State private var appeared = false

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: icon)
                    .font(.system(size: 60))
                    .foregroundStyle(theme.burgundy)
                    .symbolEffect(.pulse, isActive: appeared)
                Text(title).font(.system(size: 22, weight: .bold, design: .rounded)).foregroundStyle(theme.primaryText)
                Text(message).font(.system(size: 15)).foregroundStyle(theme.secondaryText).multilineTextAlignment(.center).padding(.horizontal, 32)
                Text("Coming Soon")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(theme.burgundy)
                    .clipShape(Capsule())
            }
        }
        .onAppear { appeared = true }
    }
}
