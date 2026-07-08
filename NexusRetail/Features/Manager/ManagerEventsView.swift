import SwiftUI

struct ManagerEventsView: View {
    @Environment(AppTheme.self) private var theme
    var body: some View {
        EventsView()
    }
}

#Preview {
    ManagerEventsView()
}
