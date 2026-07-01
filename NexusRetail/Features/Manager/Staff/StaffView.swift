//
//  StaffView.swift
//  NexusRetail
//
//  Staff profiles, shift history, performance. (TEAM5-13,14,74)
//

import SwiftUI

struct StaffView: View {
    @State private var isAddEmployeePresented = false
    @State private var searchText = ""
    @State private var selectedRoleFilter: EmployeeRoleFilter = .sales
    
    enum EmployeeRoleFilter: String, CaseIterable {
        case sales = "Sales Associate"
        case afterSales = "After Sales Associate"
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
            
            // MARK: - Content
            ManagerPlaceholderView(
                title: "Employees",
                message: "Monitor staff check-ins, tasks, and sales metrics.",
                icon: "person.2.fill"
            )
        }
        .background(RSMSColors.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $isAddEmployeePresented) {
            NewEmployeeSheet()
        }
    }
}

#Preview {
    StaffView()
}
