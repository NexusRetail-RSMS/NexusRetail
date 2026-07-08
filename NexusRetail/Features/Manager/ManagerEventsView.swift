import SwiftUI

struct ManagerEventsView: View {
    @State private var isShowingCreateForm = false
    @State private var viewModel = EventsViewModel()
    
    var body: some View {
        EventsView()
    }
}

#Preview {
    NavigationStack {
        ManagerEventsView()
    }
}
