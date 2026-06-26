//
//  AdminDashboardView.swift
//  NexusRetail
//

import SwiftUI

struct AdminDashboardView: View {
    @Environment(SessionStore.self) private var sessionStore
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // Greeting Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome back,")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(sessionStore.currentUser?.name ?? "Admin")
                        .font(.largeTitle.bold())
                        .foregroundColor(Color.nexusRed)
                }
                .padding(.horizontal)
                .padding(.top, 16)
                
                // KPI Cards Section
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    KPICardView(title: "Total Revenue", value: "₹2.4M", icon: "indianrupesign.circle.fill", trend: "+12% this week")
                    KPICardView(title: "Active Stores", value: "14", icon: "building.2.fill", trend: nil)
                    KPICardView(title: "Pending Transfers", value: "8", icon: "arrow.left.arrow.right.circle.fill", trend: "3 require approval")
                    KPICardView(title: "Low-Stock Alerts", value: "24", icon: "exclamationmark.triangle.fill", trend: "-5 from yesterday")
                }
                .padding(.horizontal)
                
                // Recent Activity Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Recent Activity")
                        .font(.title3.bold())
                        .foregroundColor(Color.nexusRed)
                        .padding(.horizontal)
                    
                    VStack(spacing: 0) {
                        ActivityRow(title: "New store added: Mumbai Flagship", time: "2 hours ago", icon: "plus.circle.fill", color: .green)
                        Divider().padding(.leading, 56)
                        ActivityRow(title: "Transfer T-1024 approved", time: "5 hours ago", icon: "checkmark.circle.fill", color: .blue)
                        Divider().padding(.leading, 56)
                        ActivityRow(title: "Low stock: iPhone 15 Pro Max", time: "Yesterday", icon: "exclamationmark.triangle.fill", color: .orange)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                    )
                    .padding(.horizontal)
                }
                
                Spacer(minLength: 40)
            }
        }
        .background(Color.nexusBackground.ignoresSafeArea())
    }
}

private struct ActivityRow: View {
    let title: String
    let time: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Text(time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(time)")
    }
}

#Preview {
    NavigationStack {
        AdminDashboardView()
            .environment(SessionStore())
    }
}
