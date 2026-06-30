//
//  SalesTabView.swift
//  NexusRetail
//
//  Root tab container for the Sales Associate role.
//  Each tab delegates entirely to its own View + ViewModel.
//

import SwiftUI

struct SalesTabView: View {
    // Shared client list so AppointmentsView can read it for the booking picker
    @State private var clientelingVM = ClientelingViewModel()

    var body: some View {
        TabView {
            SalesDashboardView()
                .tabItem { Label("Dashboard", systemImage: "square.grid.2x2.fill") }
            NavigationStack {
                ClientelingView()
            }
            .tabItem { Label("Clients", systemImage: "person.2.fill") }
            NavigationStack {
                AppointmentsView(clients: clientelingVM.clients)
            }
            .tabItem { Label("Appointments", systemImage: "calendar.badge.clock") }
        }
        .tint(RSMSColors.burgundy)
    }
}

#Preview {
    SalesTabView()
        .environment(SessionStore())
}
