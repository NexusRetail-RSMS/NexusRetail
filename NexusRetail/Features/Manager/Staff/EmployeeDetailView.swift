//
//  EmployeeDetailView.swift
//  NexusRetail
//

import SwiftUI
import Supabase
struct EmployeeDetailView: View {
    @Environment(AppTheme.self) private var theme
    @Environment(\.dismiss) private var dismiss
    @State var employee: DisplayEmployee
    var onUpdate: ((DisplayEmployee) -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    
    @State private var isEditPresented = false
    @State private var showDeleteAlert = false
    @State private var revenueTimeRange: SalesTimeRange = .yearly
    @State private var revenueChartData: [ManagerRevenueChartPoint] = []
    @State private var revenueMaxValue: Double = 1.0
    
    private func fetchRevenueData() async {
        let prefix: String
        let allLabels: [String]
        switch revenueTimeRange {
        case .weekly: 
            prefix = "W"
            allLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        case .monthly: 
            prefix = "M"
            allLabels = ["W1", "W2", "W3", "W4", "W5"]
        case .yearly: 
            prefix = "Y"
            allLabels = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: Date()) // Current date for now
        
        let params = [
            "p_associate_id": employee.id.uuidString,
            "p_period": "\(prefix):\(dateString)"
        ]
        
        do {
            struct SalesPeriodResult: Decodable {
                let label: String
                let online: Double
                let offline: Double
            }
            let salesChart: [SalesPeriodResult] = try await SupabaseManager.shared.client
                .rpc("associate_sales_by_period", params: params)
                .execute()
                .value
            
            await MainActor.run {
                var paddedData: [ManagerRevenueChartPoint] = []
                for label in allLabels {
                    if let existing = salesChart.first(where: { $0.label == label }) {
                        paddedData.append(ManagerRevenueChartPoint(label: label, revenue: (existing.online + existing.offline) / 100000.0))
                    } else {
                        paddedData.append(ManagerRevenueChartPoint(label: label, revenue: 0.0))
                    }
                }
                
                self.revenueChartData = paddedData
                self.revenueMaxValue = self.revenueChartData.map(\.revenue).max() ?? 1.0
            }
        } catch {
            print("Associate Revenue fetch error: \(error)")
        }
    }

    var body: some View {
        let isAfterSales = employee.role.localizedCaseInsensitiveContains("after")
        let initials = employee.name
            .split(separator: " ")
            .compactMap { $0.first }
            .prefix(2)
            .map { String($0) }
            .joined()
            .uppercased()
            
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Card 1: Hero card with avatar, name, phone, email
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(theme.burgundy)
                            .frame(width: 68, height: 68)
                        
                        if let data = employee.imageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 68, height: 68)
                                .clipShape(Circle())
                        } else if let urlString = employee.imageUrl, let url = URL(string: urlString) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 68, height: 68)
                                    .clipShape(Circle())
                            } placeholder: {
                                ProgressView()
                                    .frame(width: 68, height: 68)
                            }
                        } else if !initials.isEmpty {
                            Text(initials)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        } else {
                            Image(systemName: "person.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                                .foregroundColor(.white)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(employee.name)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.primaryText)
                        
                        Text(employee.phone.isEmpty ? "Not Available" : employee.phone)
                            .font(RSMSFonts.body)
                            .foregroundStyle(theme.secondaryText)
                            
                        Text(employee.email.isEmpty ? "Not Available" : employee.email)
                            .font(RSMSFonts.body)
                            .foregroundStyle(theme.secondaryText)
                    }
                    Spacer()
                }
                .padding(20)
                .luxuryCard()

                // Card 2: Unified Card for Role and Performance Information
                VStack(alignment: .leading, spacing: 10) {
                    // Row 1: Role
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: "briefcase.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(theme.burgundy)
                            .frame(width: 34, height: 34)
                            .background(theme.burgundy.opacity(0.08))
                            .clipShape(Circle())
                        
                        Text("Role")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(theme.primaryText)
                        
                        Spacer()
                        
                        Text(employee.role)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(theme.secondaryText)
                    }
                    
                    Divider()
                    
                    // Row 2: Products Sold / Repaired
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: isAfterSales ? "wrench.and.screwdriver" : "bag")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(theme.burgundy)
                            .frame(width: 34, height: 34)
                            .background(theme.burgundy.opacity(0.08))
                            .clipShape(Circle())
                        
                        Text(isAfterSales ? "Product Aftercare" : "Products Sold")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(theme.primaryText)
                        
                        Spacer()
                        
                        Text("\(employee.productsSold)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(theme.primaryText)
                    }
                    
                    Divider()
                    
                    // Row 3: Customer Attraction
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(theme.burgundy)
                            .frame(width: 34, height: 34)
                            .background(theme.burgundy.opacity(0.08))
                            .clipShape(Circle())
                        
                        Text("Customer Attraction")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(theme.primaryText)
                        
                        Spacer()
                        
                        Text("\(employee.customerAttraction)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(theme.burgundy)
                    }
                }
                .padding(14)
                .luxuryCard()
                
                // MARK: - Revenue Chart
                VStack {
                    HStack {
                        Text("Sales Report")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(theme.primaryText)
                        Spacer()
                        Picker("Time Range", selection: $revenueTimeRange) {
                            Text("Weekly").tag(SalesTimeRange.weekly)
                            Text("Monthly").tag(SalesTimeRange.monthly)
                            Text("Yearly").tag(SalesTimeRange.yearly)
                        }
                        .pickerStyle(.menu)
                        .onChange(of: revenueTimeRange) { _, _ in
                            Task { await fetchRevenueData() }
                        }
                    }
                    
                    ManagerRevenueChartView(
                        data: revenueChartData,
                        maxValue: revenueMaxValue,
                        sixMonthTotal: employee.revenue,
                        peakMonth: "",
                        timeRange: $revenueTimeRange
                    )
                }
                .padding()
                .luxuryCard()
                
                // MARK: - Delete Action
                if onDelete != nil {
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Text("Delete Employee")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(theme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .shadow(color: .black.opacity(0.045), radius: 18, x: 0, y: 8)
                    }
                }
            }
            .screenPadding()
        }
        .background(theme.background.ignoresSafeArea())
        .task {
            await fetchRevenueData()
        }
        .navigationTitle("Employee Detail")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(theme.burgundy)
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isEditPresented = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(.body, design: .default).weight(.semibold))
                        .foregroundColor(theme.burgundy)
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
                email: "sarah.j@nexusretail.com",
                storeId: nil,
                customerAttraction: 14
            )
        )
    }
}
