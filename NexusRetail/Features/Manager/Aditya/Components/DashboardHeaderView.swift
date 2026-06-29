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
            VStack(alignment: .leading, spacing: 4) {
                Text("Manager Dashboard")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            HStack(spacing: RSMSSpacing.md) {
                // Notification Button
                Button {
                    // Notification action
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                        
                        // Badge
                        Circle()
                            .fill(RSMSColors.error)
                            .frame(width: 10, height: 10)
                            .overlay(
                                Circle().stroke(RSMSColors.burgundy, lineWidth: 2)
                            )
                            .offset(x: -2, y: 2)
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
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 44, height: 44)
                        
                        Text(initials(for: name))
                            .font(.headline.bold())
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, 60)
        .padding(.bottom, RSMSSpacing.xxxl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [RSMSColors.burgundy, RSMSColors.darkBurgundy],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(ManagerHeaderCurve())
        )
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

/// Custom shape that gives the header a smooth curved bottom edge
struct ManagerHeaderCurve: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: rect.maxX, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 20))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: rect.maxY - 20),
            control: CGPoint(x: rect.midX, y: rect.maxY + 10)
        )
        path.closeSubpath()
        return path
    }
}

#Preview {
    VStack {
        DashboardHeaderView(name: "Alex")
        Spacer()
    }
    .background(RSMSColors.background)
    .ignoresSafeArea()
    .environment(SessionStore())
}
