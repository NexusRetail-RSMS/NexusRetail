//
//  EmployeeDetailView.swift
//  NexusRetail
//

import SwiftUI

struct EmployeeDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State var employee: DisplayEmployee
    var onUpdate: ((DisplayEmployee) -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    
    @State private var isEditPresented = false
    @State private var showDeleteAlert = false

    var body: some View {
        List {
            // MARK: - Avatar Header Section
            Section {
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(RSMSColors.burgundy.opacity(0.15))
                            .frame(width: 110, height: 110)
                        
                        if let data = employee.imageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 110, height: 110)
                                .clipShape(Circle())
                        } else if let urlString = employee.imageUrl, let url = URL(string: urlString) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 110, height: 110)
                                    .clipShape(Circle())
                            } placeholder: {
                                ProgressView()
                                    .frame(width: 110, height: 110)
                            }
                        } else {
                            Image(systemName: "person.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 58, height: 58)
                                .foregroundColor(RSMSColors.burgundy)
                        }
                    }
                    .shadow(color: RSMSColors.burgundy.opacity(0.15), radius: 10, x: 0, y: 4)
                    
                    Text(employee.name)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(RSMSColors.primaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            
            // MARK: - Employee Information Pill Box
            Section(header: Text("Employee Information")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(RSMSColors.secondaryText)
                .textCase(.none)
            ) {
                infoRow(icon: "person.badge.shield.checkmark.fill",
                        label: "Role",
                        value: employee.role,
                        valueColor: RSMSColors.burgundy)
                
                infoRow(icon: "phone.fill",
                        label: "Phone",
                        value: employee.phone.isEmpty ? "Not Available" : employee.phone)
                
                infoRow(icon: "envelope.fill",
                        label: "Email",
                        value: employee.email.isEmpty ? "Not Available" : employee.email)
            }
            
            // MARK: - Performance Information Pill Box
            Section(header: Text("Performance Information")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(RSMSColors.secondaryText)
                .textCase(.none)
            ) {
                infoRow(icon: "bag.fill",
                        label: "Products Sold",
                        value: "\(employee.productsSold)",
                        valueColor: RSMSColors.primaryText)
                
                infoRow(icon: "dollarsign.circle.fill",
                        label: "Total Revenue",
                        value: employee.revenue,
                        valueColor: RSMSColors.burgundy)
            }
            
            // MARK: - Delete Action
            if onDelete != nil {
                Section {
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Delete Employee")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(RSMSColors.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(RSMSColors.burgundy)
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isEditPresented = true
                } label: {
                    Text("Edit")
                        .font(.system(.body, design: .default).weight(.semibold))
                        .foregroundColor(RSMSColors.burgundy)
                }
            }
        }
        .sheet(isPresented: $isEditPresented) {
            EditEmployeeSheet(employee: employee, onSave: { updatedEmployee in
                self.employee = updatedEmployee
                onUpdate?(updatedEmployee)
            })
        }
        .alert("Delete Employee", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete?()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this employee? This action cannot be undone.")
        }
    }
    
    @ViewBuilder
    private func infoRow(
        icon: String,
        label: String,
        value: String,
        valueColor: Color = .secondary
    ) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(RSMSColors.burgundy)
                .frame(width: 20)
            
            Text(label)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(RSMSColors.primaryText)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16))
                .foregroundColor(valueColor)
                .multilineTextAlignment(.trailing)
                .lineLimit(1)
        }
    }
}

#Preview {
    NavigationStack {
        EmployeeDetailView(
            employee: DisplayEmployee(
                id: UUID(),
                name: "Sarah Jenkins",
                role: "Sales Associate",
                productsSold: 142,
                revenue: "$48,500",
                imageUrl: nil,
                phone: "+1 (555) 234-5678",
                email: "sarah.j@nexusretail.com"
            )
        )
    }
}
