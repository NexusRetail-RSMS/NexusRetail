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
                    Text(role.rawValue).tag(role)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, RSMSSpacing.lg)
            .padding(.bottom, RSMSSpacing.md)
            
            // MARK: - Content List
            ScrollView {
                VStack(spacing: RSMSSpacing.md) {
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
            NewEmployeeSheet(onCreate: { newEmployee, password in
                viewModel.addEmployee(newEmployee, password: password)
                if newEmployee.role == "After Sales Associate" {
                    selectedRoleFilter = .afterSales
                } else {
                    selectedRoleFilter = .sales
                }
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
