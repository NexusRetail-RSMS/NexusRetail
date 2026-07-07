//
//  StaffView.swift
//  NexusRetail
//
//  Staff profiles, shift history, performance. (TEAM5-13,14,74)
//

import SwiftUI

struct StaffView: View {
    @State private var viewModel = StaffViewModel()
    @State private var isAddEmployeePresented = false
    @State private var searchText = ""
    @State private var selectedRoleFilter: EmployeeRoleFilter = .sales
    @State private var editingEmployee: DisplayEmployee? = nil
    
    enum EmployeeRoleFilter: String, CaseIterable {
        case sales = "Sales Associate"
        case afterSales = "After Sales Associate"
    }
    
    var filteredEmployees: [DisplayEmployee] {
        viewModel.employees.filter { emp in
            let matchesSearch = searchText.isEmpty || emp.name.localizedCaseInsensitiveContains(searchText) || emp.email.localizedCaseInsensitiveContains(searchText)
            let matchesRole = emp.role == selectedRoleFilter.rawValue
            return matchesSearch && matchesRole
        }
    }
    
    private var currentRoleEmployees: [DisplayEmployee] {
        viewModel.employees.filter { $0.role == selectedRoleFilter.rawValue }
    }
    
    private var formattedTotalProducts: String {
        let total = currentRoleEmployees.reduce(0) { $0 + $1.productsSold }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: total)) ?? "\(total)"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Custom Header
            HStack(alignment: .center) {
                Text("Employees")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(RSMSColors.primaryText)
                
                Spacer()
                
                Button {
                    isAddEmployeePresented = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(RSMSColors.burgundy)
                        .frame(width: 44, height: 44)
                        .background(RSMSColors.burgundy.opacity(0.1))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Add new employee")
            }
            .padding(.horizontal, RSMSSpacing.lg)
            .padding(.top, RSMSSpacing.sm)
            .padding(.bottom, RSMSSpacing.sm)
            
            // MARK: - Search Bar
            NexusSearchBar(text: $searchText, placeholder: "Search employees…")
                .padding(.horizontal, RSMSSpacing.lg)
                .padding(.bottom, RSMSSpacing.md)
            
            // MARK: - Role Segmented Control
            Picker("Role Filter", selection: $selectedRoleFilter) {
                ForEach(EmployeeRoleFilter.allCases, id: \.self) { role in
                    Text(LocalizedStringKey(role.rawValue)).tag(role)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, RSMSSpacing.lg)
            .padding(.bottom, RSMSSpacing.md)
            
            // MARK: - Content List
            ScrollView {
                VStack(spacing: RSMSSpacing.md) {
                    // MARK: - Team Overview
                    VStack(alignment: .leading, spacing: RSMSSpacing.md) {
                        Text("Team Overview")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(RSMSColors.primaryText)
                        
                        HStack(spacing: 0) {
                            // Left column
                            VStack(spacing: 8) {
                                Circle()
                                    .fill(RSMSColors.burgundy.opacity(0.12))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Image(systemName: "person.2")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundColor(RSMSColors.burgundy)
                                    )
                                
                                Text("Total Employees")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(RSMSColors.secondaryText)
                                
                                Text("\(currentRoleEmployees.count)")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(RSMSColors.primaryText)
                            }
                            .frame(maxWidth: .infinity)
                            
                            Divider()
                                .frame(height: 85)
                            
                            // Right column
                            VStack(spacing: 8) {
                                Circle()
                                    .fill(Color(red: 0.96, green: 0.93, blue: 0.84))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Image(systemName: selectedRoleFilter == .afterSales ? "wrench.and.screwdriver" : "bag")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundColor(Color(red: 0.55, green: 0.35, blue: 0.15))
                                    )
                                
                                Text(selectedRoleFilter == .afterSales ? "Product Aftercare" : "Products Sold")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(RSMSColors.secondaryText)
                                
                                Text(formattedTotalProducts)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(RSMSColors.primaryText)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.vertical, 16)
                        .background(RSMSColors.cardBackground)
                        .cornerRadius(RSMSRadius.extraLarge)
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: RSMSRadius.extraLarge)
                                .stroke(RSMSColors.cardBorder, lineWidth: 1)
                        )
                    }
                    .padding(.bottom, RSMSSpacing.xs)
                    
                    if filteredEmployees.isEmpty {
                        VStack(spacing: RSMSSpacing.md) {
                            Image(systemName: "person.slash")
                                .font(.system(size: 44))
                                .foregroundColor(RSMSColors.secondaryText)
                            Text("No Employees Found")
                                .font(RSMSFonts.headline)
                                .foregroundColor(RSMSColors.primaryText)
                            Text("No employee matches your search or role filter.")
                                .font(RSMSFonts.subheadline)
                                .foregroundColor(RSMSColors.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    } else {
                        ForEach(filteredEmployees) { employee in
                            NavigationLink(destination: EmployeeDetailView(
                                employee: employee,
                                onUpdate: { updatedEmployee in
                                    viewModel.updateEmployee(updatedEmployee)
                                    if updatedEmployee.role == "After Sales Associate" {
                                        selectedRoleFilter = .afterSales
                                    } else {
                                        selectedRoleFilter = .sales
                                    }
                                },
                                onDelete: {
                                    Task {
                                        _ = await viewModel.deleteEmployee(id: employee.id)
                                    }
                                }
                            )) {
                                EmployeeCard(
                                    employee: employee,
                                    onEdit: {
                                        editingEmployee = employee
                                    },
                                    onDelete: {
                                        Task {
                                            _ = await viewModel.deleteEmployee(id: employee.id)
                                        }
                                    }
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, RSMSSpacing.lg)
                .padding(.bottom, RSMSSpacing.xl)
            }
        }
        .background(RSMSColors.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.loadStaff()
        }
        .refreshable {
            await viewModel.loadStaff()
        }
        .sheet(isPresented: $isAddEmployeePresented) {
            NewEmployeeSheet(initialRole: selectedRoleFilter == .afterSales ? .afterSales : .salesAssociate, onCreate: { newEmployee, password in
                let error = await viewModel.addEmployee(newEmployee, password: password)
                if error == nil {
                    if newEmployee.role == "After Sales Associate" {
                        selectedRoleFilter = .afterSales
                    } else {
                        selectedRoleFilter = .sales
                    }
                }
                return error
            })
        }
        .sheet(item: $editingEmployee) { emp in
            EditEmployeeSheet(employee: emp, onSave: { updatedEmployee in
                viewModel.updateEmployee(updatedEmployee)
                if updatedEmployee.role == "After Sales Associate" {
                    selectedRoleFilter = .afterSales
                } else {
                    selectedRoleFilter = .sales
                }
            })
        }
    }
}

#Preview {
    StaffView()
}
