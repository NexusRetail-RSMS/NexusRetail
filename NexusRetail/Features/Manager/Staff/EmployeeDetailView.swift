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
    @State private var revenueTimeRange: SalesTimeRange = .monthly
    
    private var revenueChartData: [RevenueChartPoint] {
        let cleanedNumber = employee.revenue
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let totalVal = Double(cleanedNumber) ?? 48500.0
        
        let weights: [Double] = [0.5, 1.0, 1.2, 0.8, 10.5, 19.5, 26.8, 37.2, 12.0, 9.0, 19.5, 1.5]
        let totalWeight = weights.reduce(0, +)
        let scale = (totalVal > 0 ? (totalVal / 1000.0) : 48.5) / (totalWeight / 3.0)
        
        if revenueTimeRange == .weekly {
            let q1 = (weights[0] + weights[1] + weights[2]) * scale
            let q2 = (weights[3] + weights[4] + weights[5]) * scale
            let q3 = (weights[6] + weights[7] + weights[8]) * scale
            let q4 = (weights[9] + weights[10] + weights[11]) * scale
            
            return [
                RevenueChartPoint(label: "W1", index: 0, revenue: q1),
                RevenueChartPoint(label: "W2", index: 1, revenue: q2),
                RevenueChartPoint(label: "W3", index: 2, revenue: q3),
                RevenueChartPoint(label: "W4", index: 3, revenue: q4)
            ]
        } else {
            let months = ["Aug", "Sep", "Oct", "Nov", "Dec", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul"]
            return months.enumerated().map { index, month in
                RevenueChartPoint(label: month, index: index, revenue: weights[index] * scale)
            }
        }
    }
    
    private var revenueMaxValue: Double {
        let maxRev = revenueChartData.map(\.revenue).max() ?? 50.0
        return max(50.0, ceil(maxRev / 10.0) * 10.0)
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
                            .fill(RSMSColors.burgundy)
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
                            .foregroundStyle(RSMSColors.primaryText)
                        
                        Text(employee.phone.isEmpty ? "Not Available" : employee.phone)
                            .font(RSMSFonts.body)
                            .foregroundStyle(RSMSColors.secondaryText)
                            
                        Text(employee.email.isEmpty ? "Not Available" : employee.email)
                            .font(RSMSFonts.body)
                            .foregroundStyle(RSMSColors.secondaryText)
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
                            .foregroundStyle(RSMSColors.burgundy)
                            .frame(width: 34, height: 34)
                            .background(RSMSColors.burgundy.opacity(0.08))
                            .clipShape(Circle())
                        
                        Text("Role")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(RSMSColors.primaryText)
                        
                        Spacer()
                        
                        Text(employee.role)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(RSMSColors.secondaryText)
                    }
                    
                    Divider()
                    
                    // Row 2: Products Sold / Repaired
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: isAfterSales ? "wrench.and.screwdriver" : "bag")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(RSMSColors.burgundy)
                            .frame(width: 34, height: 34)
                            .background(RSMSColors.burgundy.opacity(0.08))
                            .clipShape(Circle())
                        
                        Text(isAfterSales ? "Product Aftercare" : "Products Sold")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(RSMSColors.primaryText)
                        
                        Spacer()
                        
                        Text("\(employee.productsSold)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(RSMSColors.primaryText)
                    }
                    
                    Divider()
                    
                    // Row 3: Customer Attraction
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(RSMSColors.burgundy)
                            .frame(width: 34, height: 34)
                            .background(RSMSColors.burgundy.opacity(0.08))
                            .clipShape(Circle())
                        
                        Text("Customer Attraction")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(RSMSColors.primaryText)
                        
                        Spacer()
                        
                        let cleanedNumber = employee.revenue
                            .replacingOccurrences(of: "$", with: "")
                            .replacingOccurrences(of: ",", with: "")
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        let rawInt = Int(cleanedNumber) ?? 0
                        let attractionCount = rawInt > 500 ? ((rawInt % 25) + 18) : (rawInt == 0 ? 14 : rawInt)
                        Text("\(attractionCount)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(RSMSColors.burgundy)
                    }
                }
                .padding(14)
                .luxuryCard()
                
                // MARK: - Revenue Chart
                RevenueBarChart(
                    title: "Total Revenue",
                    data: revenueChartData,
                    maxValue: revenueMaxValue,
                    timeRange: $revenueTimeRange
                )
                
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
                            .background(RSMSColors.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .shadow(color: .black.opacity(0.045), radius: 18, x: 0, y: 8)
                    }
                }
            }
            .screenPadding()
        }
        .background(RSMSColors.background.ignoresSafeArea())
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
