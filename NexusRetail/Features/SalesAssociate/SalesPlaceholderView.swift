import SwiftUI

struct SalesPlaceholderView: View {
    let title: String
    let message: String
    let icon: String
    @State private var appeared = false

    var body: some View {
        ZStack {
            RSMSColors.background.ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: icon)
                    .font(.system(size: 60))
                    .foregroundStyle(RSMSColors.burgundy)
                    .symbolEffect(.pulse, isActive: appeared)
                Text(title).font(.system(size: 22, weight: .bold, design: .rounded)).foregroundStyle(RSMSColors.primaryText)
                Text(message).font(.system(size: 15)).foregroundStyle(RSMSColors.secondaryText).multilineTextAlignment(.center).padding(.horizontal, 32)
                Text("Coming Soon")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(RSMSColors.burgundy)
                    .clipShape(Capsule())
            }
        }
        .onAppear { appeared = true }
    }
}
