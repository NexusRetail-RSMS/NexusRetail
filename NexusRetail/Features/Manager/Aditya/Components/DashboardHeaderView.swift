//
//  DashboardHeaderView.swift
//  NexusRetail
//

import SwiftUI

struct DashboardHeaderView: View {
    let name: String
    @Environment(SessionStore.self) private var sessionStore
    @State private var showProfile = false
    
    var body: some View {
        HStack(alignment: .center) {
            Text("Dashboard")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(RSMSColors.primaryText)
            
            Spacer()
            
            // Profile Avatar Button
            Button {
                showProfile = true
            } label: {
                ZStack {
                    Circle()
                        .fill(RSMSColors.burgundy)
                        .frame(width: 40, height: 40)
                    
                    Text(initials(for: name))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, RSMSSpacing.lg)
        .padding(.bottom, RSMSSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(isPresented: $showProfile) {
            ProfileView()
                .environment(sessionStore)
                .presentationDetents([.fraction(0.6), .large])
        }
    }
    
    private func initials(for name: String) -> String {
        guard !name.isEmpty else { return "M" }
        let components = name.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        if components.count >= 2 {
            let first = components[0].prefix(1)
            let last = components[1].prefix(1)
            return "\(first)\(last)".uppercased()
        } else if let first = components.first {
            return String(first.prefix(2)).uppercased()
        }
        return "M"
    }
}

#Preview {
    VStack {
        DashboardHeaderView(name: "Alex")
        Spacer()
    }
    .background(RSMSColors.background)
    .ignoresSafeArea(edges: .bottom)
    .environment(SessionStore())
}
