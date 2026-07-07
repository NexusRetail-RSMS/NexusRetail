import SwiftUI

struct AfterSalesRepairFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var path: NavigationPath
    
    let invoiceId: String
    let selectedItem: POSProduct
    
    @State private var problemDescription: String = ""
    @State private var additionalAmountText: String = ""
    
    @FocusState private var isInputFocused: Bool
    
    private let serviceCost: Double = 500.0
    
    private var totalAmount: Double {
        let additional = Double(additionalAmountText) ?? 0.0
        return serviceCost + additional
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            RSMSColors.background
                .ignoresSafeArea()
                .onTapGesture {
                    isInputFocused = false
                }
            
            VStack(spacing: 0) {
                customHeaderSection
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        productSummaryCard
                        
                        formSection
                    }
                    .padding(.vertical, RSMSSpacing.lg)
                }
                .onTapGesture {
                    isInputFocused = false
                }
                
                bottomActionBar
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Header
    private var customHeaderSection: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 44, height: 44)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)

                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(RSMSColors.primaryText)
                }
            }
            
            Spacer()
            
            Text("Repair Request")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(RSMSColors.primaryText)
            
            Spacer()
            
            // Dummy view for alignment
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.bottom, RSMSSpacing.sm)
        .background(RSMSColors.background)
    }
    
    // MARK: - Product Summary
    private var productSummaryCard: some View {
        HStack(spacing: 16) {
            CachedAsyncImage(url: URL(string: selectedItem.imageUrl ?? "")) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 70, height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } placeholder: {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 70, height: 70)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(selectedItem.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(RSMSColors.primaryText)
                    .lineLimit(2)
                
                Text(selectedItem.sku)
                    .font(.system(size: 13))
                    .foregroundColor(RSMSColors.secondaryText)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(RSMSColors.cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 12, x: 0, y: 4)
        .padding(.horizontal, RSMSSpacing.lg)
    }
    
    // MARK: - Form Section
    private var formSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Description Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Problem Description")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(RSMSColors.secondaryText)
                
                TextEditor(text: $problemDescription)
                    .focused($isInputFocused)
                    .frame(height: 120)
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(RSMSColors.inputBorder, lineWidth: 1)
                    )
            }
            
            Divider()
                .background(RSMSColors.divider)
            
            // Cost Details
            VStack(alignment: .leading, spacing: 16) {
                Text("Cost Breakdown")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(RSMSColors.primaryText)
                
                HStack {
                    Text("Base Service Cost")
                        .font(.system(size: 15))
                        .foregroundColor(RSMSColors.secondaryText)
                    Spacer()
                    Text(String(format: "₹%.0f", serviceCost))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(RSMSColors.primaryText)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Additional Parts (₹)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(RSMSColors.secondaryText)
                    
                    TextField("Enter amount", text: $additionalAmountText)
                        .focused($isInputFocused)
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(RSMSColors.inputBorder, lineWidth: 1)
                        )
                }
            }
            
            Divider()
                .background(RSMSColors.divider)
            
            // Total
            HStack {
                Text("Total Amount")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(RSMSColors.primaryText)
                
                Spacer()
                
                Text(String(format: "₹%.0f", totalAmount))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(RSMSColors.burgundy)
            }
        }
        .padding(.horizontal, RSMSSpacing.lg)
    }
    
    // MARK: - Bottom Action
    private var bottomActionBar: some View {
        VStack {
            Button {
                isInputFocused = false
                print("Repair form submitted for item \(selectedItem.id). Problem: \(problemDescription). Total Cost: \(totalAmount)")
            } label: {
                Text("Submit Repair Request")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(problemDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? RSMSColors.secondaryText.opacity(0.5) : RSMSColors.burgundy)
                    .cornerRadius(12)
            }
            .disabled(problemDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.vertical, 24)
    }
}
