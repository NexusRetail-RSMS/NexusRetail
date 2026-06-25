//
//  AdminDashboardView.swift
//  NexusRetail
//
//  A beautiful, premium dashboard for Admin users.
//  Includes greeting, store selector, KPI cards, store setup/payments, and recent activity.
//

import SwiftUI
import Supabase

struct AdminDashboardView: View {
    @Environment(SessionStore.self) private var sessionStore
    
    // Dynamic store ID fetched from Supabase
    @State private var selectedStoreID: UUID? = nil
    @State private var storeName: String = "Loading..."
    @State private var isLoadingStore: Bool = true
    @State private var isProfilePresented = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RSMSSpacing.xl) {
                
                // MARK: - Header Section
                headerSection
                    .padding(.bottom, -RSMSSpacing.xl) // Blend header with the cards below
                
                VStack(alignment: .leading, spacing: RSMSSpacing.xl) {
                    // MARK: - Store Info Card
                    storeSelectorCard
                    
                    // MARK: - KPI Cards Section
                    kpiSection
                    
                    // MARK: - Store Setup Section
                    storeSetupSection
                    
                    // MARK: - Recent Activity Section
                    recentActivitySection
                    
                    // MARK: - Sign Out Button
                    signOutSection
                }
                .padding(.horizontal, RSMSSpacing.lg)
                .padding(.bottom, RSMSSpacing.xxl)
            }
        }
        .background(RSMSColors.background.ignoresSafeArea())
        .ignoresSafeArea(edges: .top)
        .navigationBarHidden(true)
        .sheet(isPresented: $isProfilePresented) {
            AdminProfileSheet()
        }
        .task {
            await loadStore()
        }
    }
    
    // MARK: - Load Store logic
    private func loadStore() async {
        if let assignedID = sessionStore.currentUser?.storeID {
            self.selectedStoreID = assignedID
            self.storeName = "Assigned Store"
            self.isLoadingStore = false
            return
        }
        
        do {
            let client = SupabaseManager.shared.client
            let stores: [Store] = try await client
                .from("store")
                .select()
                .limit(1)
                .execute()
                .value
            
            if let firstStore = stores.first {
                self.selectedStoreID = firstStore.id
                self.storeName = firstStore.name
            } else {
                self.storeName = "No Stores Configured"
            }
        } catch {
            self.storeName = "Error Loading Store"
        }
        self.isLoadingStore = false
    }

    // MARK: - Header View
    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: RSMSSpacing.sm) {
                Text("DASHBOARD")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(1.5)
                    .padding(.top, 4)
                
                Text("Welcome back,")
                    .font(RSMSFonts.subheadline)
                    .foregroundColor(.white.opacity(0.85))
                
                Text(sessionStore.currentUser?.name ?? "Admin")
                    .font(RSMSFonts.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Here's what's happening today.")
                    .font(RSMSFonts.caption)
                    .foregroundColor(.white.opacity(0.75))
            }
            
            Spacer()
            
            Button {
                isProfilePresented = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Text(initials(for: sessionStore.currentUser?.name))
                        .font(.headline.bold())
                        .foregroundColor(.white)
                }
            }
            .accessibilityLabel("Profile")
            .accessibilityHint("Opens your profile and settings")
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, 64) // Ensure enough padding to clear the notch and status bar
        .padding(.bottom, RSMSSpacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [RSMSColors.burgundy, RSMSColors.darkBurgundy],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    private func initials(for name: String?) -> String {
        guard let name = name, !name.isEmpty else { return "AD" }
        let components = name.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        if components.count >= 2 {
            let first = components[0].prefix(1)
            let last = components[1].prefix(1)
            return "\(first)\(last)".uppercased()
        } else if let first = components.first {
            return String(first.prefix(2)).uppercased()
        }
        return "AD"
    }

    // MARK: - Store Selector Card
    private var storeSelectorCard: some View {
        HStack(spacing: RSMSSpacing.md) {
            ZStack {
                Circle()
                    .fill(RSMSColors.burgundy.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "building.2.fill")
                    .foregroundColor(RSMSColors.burgundy)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Current Store")
                    .font(RSMSFonts.caption)
                    .foregroundColor(RSMSColors.secondaryText)
                
                if isLoadingStore {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text(storeName)
                        .font(RSMSFonts.headline)
                        .foregroundColor(RSMSColors.primaryText)
                }
            }
            
            Spacer()
            
            Text("Active")
                .font(RSMSFonts.caption)
                .fontWeight(.bold)
                .foregroundColor(RSMSColors.success)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(RSMSColors.success.opacity(0.1))
                .cornerRadius(RSMSRadius.small)
        }
        .padding(RSMSSpacing.lg)
        .background(RSMSColors.cardBackground)
        .cornerRadius(RSMSRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }

    // MARK: - KPI Cards Section
    private var kpiSection: some View {
        VStack(alignment: .leading, spacing: RSMSSpacing.sm) {
            Text("Overview")
                .font(RSMSFonts.headline)
                .foregroundColor(RSMSColors.darkBrown)
                .padding(.leading, 4)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: RSMSSpacing.md) {
                KPICardView(title: "Total Revenue", value: "₹2.4M", icon: "indianrupesign.circle.fill", trend: "+12% this week")
                KPICardView(title: "Active Stores", value: "14", icon: "building.2.fill", trend: nil)
                KPICardView(title: "Pending Transfers", value: "8", icon: "arrow.left.arrow.right.circle.fill", trend: "3 require approval")
                KPICardView(title: "Low-Stock Alerts", value: "24", icon: "exclamationmark.triangle.fill", trend: "-5 from yesterday")
            }
        }
    }

    // MARK: - Store Setup Section
    private var storeSetupSection: some View {
        VStack(alignment: .leading, spacing: RSMSSpacing.sm) {
            Text("Store Setup")
                .font(RSMSFonts.headline)
                .foregroundColor(RSMSColors.darkBrown)
                .padding(.leading, 4)
            
            VStack(spacing: 0) {
                // Row 1: Store Details
                setupRow(title: "Store Details", icon: "building.2.fill", isNavigation: false)
                
                Divider()
                    .padding(.leading, 56)
                
                // Row 2: Users & Roles
                setupRow(title: "Users & Roles", icon: "person.2.fill", isNavigation: false)
                
                Divider()
                    .padding(.leading, 56)
                
                // Row 3: Payment Configuration
                if let currentStoreID = sessionStore.currentUser?.storeID ?? selectedStoreID {
                    NavigationLink {
                        PaymentConfigurationView(isAdmin: true, storeID: currentStoreID)
                    } label: {
                        setupRowContent(title: "Payment Configuration", icon: "creditcard.fill", isNavigation: true)
                    }
                    .buttonStyle(.plain)
                } else {
                    setupRowContent(title: "Payment Configuration (Loading...)", icon: "creditcard.fill", isNavigation: false)
                }
            }
            .background(RSMSColors.cardBackground)
            .cornerRadius(RSMSRadius.large)
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        }
    }

    private func setupRowContent(title: String, icon: String, isNavigation: Bool) -> some View {
        HStack(spacing: RSMSSpacing.md) {
            ZStack {
                Circle()
                    .fill(isNavigation ? RSMSColors.burgundy.opacity(0.12) : Color.gray.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .foregroundColor(isNavigation ? RSMSColors.burgundy : .gray)
                    .font(.system(size: 16))
            }
            
            Text(title)
                .font(RSMSFonts.headline)
                .foregroundColor(isNavigation ? RSMSColors.primaryText : .gray)
            
            Spacer()
            
            if isNavigation {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(RSMSColors.secondaryText)
            } else {
                Text("Coming Soon")
                    .font(RSMSFonts.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(RSMSRadius.small)
            }
        }
        .padding(RSMSSpacing.lg)
    }

    private func setupRow(title: String, icon: String, isNavigation: Bool) -> some View {
        setupRowContent(title: title, icon: icon, isNavigation: isNavigation)
            .contentShape(Rectangle())
    }

    // MARK: - Recent Activity Section
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: RSMSSpacing.sm) {
            Text("Recent Activity")
                .font(RSMSFonts.headline)
                .foregroundColor(RSMSColors.darkBrown)
                .padding(.leading, 4)
            
            VStack(spacing: 0) {
                ActivityRow(title: "New store added: Mumbai Flagship", time: "2 hours ago", icon: "plus.circle.fill", color: .green)
                Divider().padding(.leading, 56)
                ActivityRow(title: "Transfer T-1024 approved", time: "5 hours ago", icon: "checkmark.circle.fill", color: .blue)
                Divider().padding(.leading, 56)
                ActivityRow(title: "Low stock: iPhone 15 Pro Max", time: "Yesterday", icon: "exclamationmark.triangle.fill", color: .orange)
            }
            .background(RSMSColors.cardBackground)
            .cornerRadius(RSMSRadius.large)
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        }
    }

    // MARK: - Sign Out Section
    private var signOutSection: some View {
        Button {
            Task {
                try? await sessionStore.signOut()
            }
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
        .padding(.top, RSMSSpacing.lg)
    }
}

// MARK: - Activity Row component
struct ActivityRow: View {
    let title: String
    let time: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: RSMSSpacing.md) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 16))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(RSMSFonts.body)
                    .foregroundColor(RSMSColors.primaryText)
                
                Text(time)
                    .font(RSMSFonts.caption)
                    .foregroundColor(RSMSColors.secondaryText)
            }
            
            Spacer()
        }
        .padding(RSMSSpacing.md)
    }
}

#Preview {
    NavigationStack {
        AdminDashboardView()
            .environment(SessionStore())
    }
}
