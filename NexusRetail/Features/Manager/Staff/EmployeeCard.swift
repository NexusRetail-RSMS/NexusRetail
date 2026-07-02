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
}

// MARK: - Employee Card View

struct EmployeeCard: View {
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
            imageUrl: imageUrl
        )
        self.onEdit = onEdit
        self.onDelete = onDelete
    }

    var body: some View {
        HStack(spacing: RSMSSpacing.md) {
            // Profile at centre left
            ZStack {
                Circle()
                    .fill(RSMSColors.burgundy.opacity(0.1))
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
                        .foregroundColor(RSMSColors.burgundy)
                        .font(.system(size: 22))
                }
            }

            // Name & products sold with amount below
            VStack(alignment: .leading, spacing: 4) {
                Text(employee.name)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(RSMSColors.primaryText)
                
                Text("\(employee.productsSold) Products Sold • \(employee.revenue)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(RSMSColors.secondaryText)
            }

            Spacer()

            // Chevron at right edge
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(RSMSColors.secondaryText)
        }
        .padding(16)
        .frame(minHeight: 85)
        .background(RSMSColors.cardBackground)
        .cornerRadius(RSMSRadius.extraLarge)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: RSMSRadius.large)
                .stroke(RSMSColors.cardBorder, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                onEdit?()
            } label: {
                Label {
                    Text("Edit")
                } icon: {
                    Image(systemName: "square.and.pencil")
                        .renderingMode(.template)
                        .foregroundColor(.black)
                }
            }
            .tint(.black)

            Button(role: .destructive) {
                onDelete?()
            } label: {
                Label {
                    Text("Delete")
                } icon: {
                    Image(systemName: "trash")
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
        RSMSColors.background.ignoresSafeArea()
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
