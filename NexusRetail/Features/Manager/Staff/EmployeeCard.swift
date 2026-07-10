//
//  EmployeeCard.swift
//  NexusRetail
//

import SwiftUI

// MARK: - Data Model

struct DisplayEmployee: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var role: String
    var productsSold: Int
    var revenue: String
    var imageUrl: String?
    var phone: String = ""
    var email: String = ""
    var imageData: Data? = nil
    var storeId: UUID?
    var customerAttraction: Int
    var isActive: Bool = true
}

// MARK: - Employee Card View

struct EmployeeCard: View {
    @Environment(AppTheme.self) private var theme
    let employee: DisplayEmployee
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    
    init(
        employee: DisplayEmployee,
        onEdit: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil
    ) {
        self.employee = employee
        self.onEdit = onEdit
        self.onDelete = onDelete
    }
    
    init(
        name: String,
        productsSold: Int,
        amount: String,
        imageUrl: String? = nil,
        role: String = "Sales Associate",
        onEdit: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil
    ) {
        self.employee = DisplayEmployee(
            id: UUID(),
            name: name,
            role: role,
            productsSold: productsSold,
            revenue: amount,
            imageUrl: imageUrl,
            customerAttraction: 0,
            isActive: true
        )
        self.onEdit = onEdit
        self.onDelete = onDelete
    }

    var body: some View {
        HStack(spacing: RSMSSpacing.md) {
            // Profile at centre left
            ZStack {
                Circle()
                    .fill(theme.burgundy.opacity(0.1))
                    .frame(width: 55, height: 55)
                
                if let data = employee.imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 55, height: 55)
                        .clipShape(Circle())
                } else if let urlString = employee.imageUrl, let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 55, height: 55)
                            .clipShape(Circle())
                    } placeholder: {
                        ProgressView()
                            .frame(width: 55, height: 55)
                    }
                } else {
                    Image(systemName: "person.fill")
                        .foregroundColor(theme.burgundy)
                        .font(.system(size: 24))
                }
            }

            // Name & products sold with amount below
            VStack(alignment: .leading, spacing: 4) {
                Text(employee.name)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(theme.primaryText)
                
                HStack(spacing: 5) {
                    let isAfterSales = employee.role.localizedCaseInsensitiveContains("after")
                    Image(systemName: isAfterSales ? "wrench.and.screwdriver" : "bag")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(theme.burgundy)
                    
                    Text("\(employee.productsSold) ") + Text(isAfterSales ? LocalizedStringKey("Products Aftercare") : LocalizedStringKey("Products Sold"))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(theme.secondaryText)
                }
            }

            Spacer()

            if !employee.isActive {
                Text("Archived")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray)
                    .cornerRadius(6)
            } else {
                // Chevron at right edge
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(theme.secondaryText)
            }
        }
        .padding(16)
        .frame(minHeight: 85)
        .background(theme.cardBackground)
        .cornerRadius(RSMSRadius.extraLarge)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: RSMSRadius.large)
                .stroke(theme.cardBorder, lineWidth: 1)
        )
        .opacity(employee.isActive ? 1.0 : 0.6)
        .grayscale(employee.isActive ? 0.0 : 0.8)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .contextMenu {
            Button {
                onEdit?()
            } label: {
                Label {
                    Text("Edit")
                } icon: {
                    Image(systemName: "square.and.pencil")
                        .renderingMode(.template)
                        .foregroundColor(theme.primaryText)
                }
            }
            .tint(.black)

            Button(role: .destructive) {
                onDelete?()
            } label: {
                Label {
                    Text("Archive")
                } icon: {
                    Image(systemName: "archivebox")
                        .renderingMode(.template)
                        .foregroundColor(.red)
                }
            }
            .tint(.red)
        }
    }
}

#Preview {
    ZStack {
        AppTheme().background.ignoresSafeArea()
        VStack(spacing: 16) {
            EmployeeCard(
                name: "Sarah Jenkins",
                productsSold: 142,
                amount: "$48,500"
            )
            EmployeeCard(
                name: "Marcus Aurelius",
                productsSold: 89,
                amount: "$29,100"
            )
        }
        .padding()
    }
}
