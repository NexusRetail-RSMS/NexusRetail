//
//  DashboardHeaderView.swift
//  NexusRetail
//

import SwiftUI

struct DashboardHeaderView: View {
    let name: String
    @Environment(SessionStore.self) private var sessionStore
    
    var body: some View {
        HStack(alignment: .center) {
            Text("Dashboard")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(RSMSColors.primaryText)
            
            Spacer()
            
            HStack(spacing: RSMSSpacing.md) {
                // Globe Button
                Button {
                    // Globe action placeholder
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 40, height: 40)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
                        
                        Image(systemName: "globe.americas.fill")
                            .symbolRenderingMode(.multicolor)
                            .font(.system(size: 20))
                    }
                }
                
                // Profile Avatar with Sign Out Menu
                Menu {
                    Button(role: .destructive) {
                        Task {
                            try? await sessionStore.signOut()
                        }
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
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
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, RSMSSpacing.lg)
        .padding(.bottom, RSMSSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
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
