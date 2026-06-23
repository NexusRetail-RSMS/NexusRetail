//
//  RoleSelectionView.swift
//  NexusRetail
//

import SwiftUI

/// Pre-login screen where the user selects their expected role before proceeding.
struct RoleSelectionView: View {
    @State private var selectedRole: UserRole? = nil

    var body: some View {
        VStack(spacing: 16) {
            // Header Image / Icon
            Image(systemName: "person.3.sequence.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .foregroundStyle(.green.opacity(0.8))
                .padding(.top, 16)
            
            // Titles
            VStack(spacing: 6) {
                Text("Choose your role")
                    .font(.title2.bold())
                
                Text("Select the option that best describes\nyour responsibilities.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 8)
            
            // Role Cards
            VStack(spacing: 12) {
                ForEach(UserRole.allCases, id: \.self) { role in
                    RoleCardView(
                        role: role,
                        isSelected: selectedRole == role
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedRole = role
                        }
                    }
                }
            }
            
            Spacer(minLength: 16)
            
            // Continue Button
            NavigationLink(destination: destinationView) {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(selectedRole == nil ? Color.gray.opacity(0.3) : Color.green.opacity(0.8))
                    .foregroundColor(selectedRole == nil ? .gray : .white)
                    .cornerRadius(12)
            }
            .disabled(selectedRole == nil)
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 20)
        .navigationBarBackButtonHidden(true)
    }
    
    @ViewBuilder
    private var destinationView: some View {
        if let role = selectedRole {
            LoginView(selectedRole: role)
        } else {
            EmptyView()
        }
    }
}

fileprivate struct RoleCardView: View {
    let role: UserRole
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: role.iconName)
                        .font(.title3)
                        .foregroundStyle(Color.green.opacity(0.8))
                }
                
                // Text Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(role.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(role.descriptionText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Radio Button
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.green.opacity(0.8) : Color.gray.opacity(0.5), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.green.opacity(0.8))
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.green.opacity(0.8) : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                    .background(Color(uiColor: .systemBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

// UI extensions for UserRole
extension UserRole: CaseIterable {
    public static var allCases: [UserRole] {
        [.admin, .manager, .salesAssociate, .afterSales]
    }
    
    var displayName: String {
        switch self {
        case .admin: return "Admin"
        case .manager: return "Manager"
        case .salesAssociate: return "Sales Associate"
        case .afterSales: return "After Sales"
        }
    }
    
    var descriptionText: String {
        switch self {
        case .admin: return "Manage global pricing, onboarding, and store transfers."
        case .manager: return "Manage store operations, inventory, and staff performance."
        case .salesAssociate: return "Operate point of sale, clienteling, and order fulfillment."
        case .afterSales: return "Manage returns, warranties, and item condition estimates."
        }
    }
    
    var iconName: String {
        switch self {
        case .admin: return "globe.desk"
        case .manager: return "briefcase.fill"
        case .salesAssociate: return "cart.fill"
        case .afterSales: return "wrench.and.screwdriver.fill"
        }
    }
}

#Preview {
    NavigationStack {
        RoleSelectionView()
    }
}
