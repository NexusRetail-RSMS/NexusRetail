//
//  AfterSalesTabView.swift
//  NexusRetail
//
//  After-Sales shell: Intake, Estimate, Repair, Return, Workload.
//  Styled with the premium RSMS cream and burgundy layout.
//

import SwiftUI

struct AfterSalesTabView: View {
    var body: some View {
        TabView {
            // 1. Intake
            NavigationStack {
                AfterSalesPlaceholderView(
                    title: "Item Intake",
                    message: "Register customer returns or check items in for warranty repair.",
                    icon: "tray.and.arrow.down.fill"
                )
                .modifier(AfterSalesToolbarModifier(title: "Intake"))
            }
            .tabItem {
                Label("Intake", systemImage: "tray.and.arrow.down.fill")
            }
            
            // 2. Estimate
            NavigationStack {
                AfterSalesPlaceholderView(
                    title: "Repair Estimates",
                    message: "Generate repair cost estimates and send them for manager approval.",
                    icon: "doc.text.magnifyingglass"
                )
                .modifier(AfterSalesToolbarModifier(title: "Estimates"))
            }
            .tabItem {
                Label("Estimate", systemImage: "doc.text.magnifyingglass")
            }
            
            // 3. Repair
            NavigationStack {
                AfterSalesPlaceholderView(
                    title: "Active Repairs",
                    message: "Track and update items currently in queue for diagnostics or repair.",
                    icon: "wrench.and.screwdriver.fill"
                )
                .modifier(AfterSalesToolbarModifier(title: "Repairs"))
            }
            .tabItem {
                Label("Repair", systemImage: "wrench.and.screwdriver.fill")
            }
            
            // 4. Return
            NavigationStack {
                AfterSalesPlaceholderView(
                    title: "Customer Handover",
                    message: "Process item pick-ups and complete return handovers to customers.",
                    icon: "arrow.uturn.backward.circle.fill"
                )
                .modifier(AfterSalesToolbarModifier(title: "Returns"))
            }
            .tabItem {
                Label("Return", systemImage: "arrow.uturn.backward")
            }
            
            // 5. Workload
            NavigationStack {
                AfterSalesPlaceholderView(
                    title: "My Workload",
                    message: "View assigned repairs, tasks, and daily service queue status.",
                    icon: "clock.badge.checkmark.fill"
                )
                .modifier(AfterSalesToolbarModifier(title: "Workload"))
            }
            .tabItem {
                Label("Workload", systemImage: "checklist")
            }
        }
        .tint(RSMSColors.burgundy)
    }
}

/// A view modifier that applies the common After-Sales toolbar (title + profile button).
struct AfterSalesToolbarModifier: ViewModifier {
    let title: String
    
    @Environment(SessionStore.self) private var sessionStore
    @State private var isProfilePresented = false
    
    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isProfilePresented = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(RSMSColors.burgundy)
                                .frame(width: 32, height: 32)
                            
                            Text(initials(for: sessionStore.currentUser?.name))
                                .font(.caption.bold())
                                .foregroundColor(.white)
                        }
                    }
                    .accessibilityLabel("Profile")
                    .accessibilityHint("Opens your after-sales specialist profile")
                }
            }
            .sheet(isPresented: $isProfilePresented) {
                AfterSalesProfileSheet()
            }
    }
    
    private func initials(for name: String?) -> String {
        guard let name = name, !name.isEmpty else { return "AS" }
        let components = name.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        if components.count >= 2 {
            let first = components[0].prefix(1)
            let last = components[1].prefix(1)
            return "\(first)\(last)".uppercased()
        } else if let first = components.first {
            return String(first.prefix(2)).uppercased()
        }
        return "AS"
    }
}

/// A reusable placeholder view for the after-sales associate tabs.
struct AfterSalesPlaceholderView: View {
    let title: String
    let message: String
    let icon: String
    
    var body: some View {
        ZStack {
            RSMSColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: icon)
                    .font(.system(size: 60))
                    .foregroundColor(RSMSColors.burgundy)
                    .accessibilityHidden(true)
                
                Text(title)
                    .font(RSMSFonts.title)
                    .fontWeight(.bold)
                    .foregroundColor(RSMSColors.primaryText)
                
                Text(message)
                    .font(RSMSFonts.body)
                    .foregroundColor(RSMSColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Text("Coming Soon")
                    .font(RSMSFonts.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(RSMSColors.burgundy)
                    .cornerRadius(RSMSRadius.small)
            }
        }
    }
}

/// Simple sheet to allow After-Sales Associate to Sign Out
struct AfterSalesProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SessionStore.self) private var sessionStore
    
    var body: some View {
        NavigationStack {
            ZStack {
                RSMSColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: RSMSSpacing.xl) {
                    VStack(spacing: RSMSSpacing.sm) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(RSMSColors.burgundy)
                        
                        Text(sessionStore.currentUser?.name ?? "After-Sales Specialist")
                            .font(RSMSFonts.title)
                            .fontWeight(.bold)
                            .foregroundColor(RSMSColors.primaryText)
                        
                        Text("After-Sales Specialist")
                            .font(RSMSFonts.subheadline)
                            .foregroundColor(RSMSColors.secondaryText)
                    }
                    .padding(.top, RSMSSpacing.xxl)
                    
                    Spacer()
                    
                    Button {
                        dismiss()
                        Task { try? await sessionStore.signOut() }
                    } label: {
                        Text("Sign Out")
                            .font(RSMSFonts.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(RSMSColors.error)
                            .cornerRadius(RSMSRadius.medium)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, RSMSSpacing.lg)
                    .padding(.bottom, RSMSSpacing.xxl)
                }
            }
            .navigationTitle("Specialist Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(RSMSColors.burgundy)
                }
            }
        }
    }
}

#Preview {
    let mockSession = SessionStore()
    return AfterSalesTabView()
        .environment(mockSession)
}
