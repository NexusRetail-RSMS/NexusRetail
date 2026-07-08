//
//  ExchangeSuccessView.swift
//  NexusRetail
//

import SwiftUI

struct ExchangeSuccessView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var path: NavigationPath
    
    let transaction: ExchangeTransaction
    
    @State private var checkmarkScale: CGFloat = 0.4
    @State private var contentOpacity: Double = 0
    
    private static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy, h:mm a"
        return formatter
    }()
    
    var body: some View {
        ZStack {
            RSMSColors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // 1. Custom curved header
                    customHeaderSection
                    
                    VStack(spacing: 24) {
                        // 2. Success animation section
                        successAnimationSection
                        
                        // 3. Receipt card
                        receiptCardSection
                        
                        // 4. Buttons section
                        buttonsSection
                    }
                    .padding(.horizontal, RSMSSpacing.lg)
                    .padding(.top, RSMSSpacing.xl)
                    .padding(.bottom, RSMSSpacing.xxxl)
                }
            }
            .ignoresSafeArea(edges: .top)
            .opacity(contentOpacity)
            .onAppear {
                withAnimation(.easeIn(duration: 0.5)) {
                    contentOpacity = 1.0
                }
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
    }
    
    // MARK: - Subviews
    
    private var customHeaderSection: some View {
        VStack(spacing: 2) {
            Text("Exchange Complete")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text("Transaction Processed Successfully")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.top, 60)
        .padding(.bottom, RSMSSpacing.xxxl)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [RSMSColors.burgundy, RSMSColors.darkBurgundy],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(HeaderCurve())
    }
    
    private var successAnimationSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(RSMSColors.success.opacity(0.12))
                    .frame(width: 110, height: 110)
                
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 54))
                    .foregroundColor(RSMSColors.success)
                    .scaleEffect(checkmarkScale)
            }
            
            Text("Exchange Successful!")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(RSMSColors.primaryText)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                checkmarkScale = 1.0
            }
        }
    }
    
    private var receiptCardSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Original Product
            Text("ORIGINAL PRODUCT")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(RSMSColors.secondaryText)
            
            HStack(spacing: 12) {
                CachedAsyncImage(url: URL(string: transaction.originalProduct.imageUrl ?? "")) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.1)
                }
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(transaction.originalProduct.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(RSMSColors.primaryText)
                        .lineLimit(1)
                    Text(transaction.originalProduct.sku)
                        .font(.system(size: 12))
                        .foregroundColor(RSMSColors.secondaryText)
                }
                Spacer()
                Text(formatIndianCurrency(transaction.originalProduct.price))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(RSMSColors.burgundy)
            }
            
            Divider()
            
            // Replacement Products
            Text("REPLACEMENT PRODUCT(S)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(RSMSColors.secondaryText)
            
            ForEach(transaction.replacementItems) { item in
                HStack(spacing: 12) {
                    CachedAsyncImage(url: URL(string: item.product.imageUrl ?? "")) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.1)
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.product.name)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(RSMSColors.primaryText)
                            .lineLimit(1)
                        Text(item.product.sku)
                            .font(.system(size: 12))
                            .foregroundColor(RSMSColors.secondaryText)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(formatIndianCurrency(item.lineTotal))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(RSMSColors.burgundy)
                        Text("Qty: \(item.quantity)")
                            .font(.system(size: 12))
                            .foregroundColor(RSMSColors.secondaryText)
                    }
                }
            }
            
            Divider()
            
            // Summary Rows
            summaryRow(label: "Amount Paid", value: transaction.amountPaid > 0 ? formatIndianCurrency(transaction.amountPaid) : "FREE", isHighlight: true)
            summaryRow(label: "Transaction ID", value: transaction.transactionId)
            summaryRow(label: "Invoice", value: transaction.invoiceId)
            summaryRow(label: "Date & Time", value: Self.displayDateFormatter.string(from: transaction.date))
        }
        .padding(20)
        .background(RSMSColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(RSMSColors.cardBorder, lineWidth: 1)
        )
    }
    
    private func summaryRow(label: String, value: String, isHighlight: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(RSMSColors.secondaryText)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isHighlight ? RSMSColors.burgundy : RSMSColors.primaryText)
        }
    }
    
    private var buttonsSection: some View {
        VStack(spacing: 12) {
            Button {
                path = NavigationPath()
            } label: {
                Text("Done")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(RSMSColors.burgundy)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            
            Button {
                // View receipt just closes flow for now
                path = NavigationPath()
            } label: {
                Text("View Receipt")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(RSMSColors.burgundy)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(RSMSColors.burgundy, lineWidth: 1.5)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
    }
}
