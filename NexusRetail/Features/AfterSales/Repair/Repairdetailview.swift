//
//  Repairdetailview.swift
//  NexusRetail
//
//  Created by ANOOP on 08/07/26.
//

import SwiftUI

struct RepairDetailView: View {
    @Environment(AppTheme.self) private var theme
    let item: AfterSalesHistoryView.RepairItem

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        return formatter
    }()

    private var reference: String {
        if let orderId = item.orderId, !orderId.isEmpty {
            return orderId
        }
        return String(item.id.uuidString.prefix(8)).uppercased()
    }

    private var costLabel: String {
        guard let cost = item.serviceCost, cost > 0 else { return "Free" }
        return String(format: "₹%.0f", cost)
    }

    var body: some View {
        ZStack(alignment: .top) {
            theme.background
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    customerCard
                    productCard
                    if let issueDescription = item.issueDescription, !issueDescription.isEmpty {
                        problemCard(issueDescription)
                    }
                    if let invoice = item.invoice {
                        invoiceCard(invoice)
                    }
                    detailsCard
                }
                .padding(.horizontal, RSMSSpacing.lg)
                .padding(.top, 4)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Repair")
        .navigationBarTitleDisplayMode(.large)
        .tint(theme.burgundy)
    }

    // MARK: - Customer
    private var customerCard: some View {
        HStack(alignment: .top, spacing: 12) {
            monogram

            VStack(alignment: .leading, spacing: 2) {
                Text(item.customerName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(theme.primaryText)
                Text("#\(reference)")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(theme.secondaryText)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: RSMSRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: RSMSRadius.large)
                .stroke(theme.cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }

    // MARK: - Product
    private var productCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("Item repaired")

            HStack(alignment: .center, spacing: 12) {
                productVisual

                Text(item.productName)
                    .font(.system(size: 16.5, weight: .bold))
                    .foregroundColor(theme.primaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: RSMSRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: RSMSRadius.large)
                .stroke(theme.cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }

    // MARK: - Problem description
    private func problemCard(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Problem description")

            Text(description)
                .font(.system(size: 14.5))
                .foregroundColor(theme.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(theme.background)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(16)
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: RSMSRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: RSMSRadius.large)
                .stroke(theme.cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }

    // MARK: - Invoice (all details shown inline, no extra navigation)
    private func invoiceCard(_ invoice: AfterSalesHistoryView.InvoiceInfo) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("Invoice")

            detailRow(icon: "number", label: "Reference", value: "#\(reference)")

            Divider()

            detailRow(icon: "calendar", label: "Order date", value: Self.dateFormatter.string(from: invoice.orderDate))

            Divider()

            detailRow(icon: "indianrupeesign.circle.fill", label: "Order total", value: currency(invoice.orderTotal))

            if let pricePaid = invoice.pricePaid {
                Divider()
                detailRow(icon: "indianrupeesign.circle", label: "Price paid", value: currency(pricePaid))
            }

            if let pickupCode = invoice.pickupCode, !pickupCode.isEmpty {
                Divider()
                detailRow(icon: "qrcode", label: "Pickup code", value: pickupCode)
            }
        }
        .padding(16)
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: RSMSRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: RSMSRadius.large)
                .stroke(theme.cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }

    private func currency(_ amount: Double) -> String {
        String(format: "₹%.0f", amount)
    }

    // MARK: - Details
    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("Repair details")

            detailRow(icon: "calendar", label: "Date completed", value: Self.dateFormatter.string(from: item.date))

            Divider()

            detailRow(icon: "indianrupeesign.circle", label: "Service cost", value: costLabel)

            Divider()

            detailRow(icon: "checkmark.seal", label: "Status", value: item.status)
        }
        .padding(16)
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: RSMSRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: RSMSRadius.large)
                .stroke(theme.cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }

    // MARK: - Shared subviews

    private var productVisual: some View {
        Group {
            if let imageUrl = item.imageUrl, let url = URL(string: imageUrl) {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } placeholder: {
                    productIconTile
                }
            } else {
                productIconTile
            }
        }
    }

    private var productIconTile: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(theme.burgundy.opacity(0.08))
            .frame(width: 44, height: 44)
            .overlay(
                Image(systemName: iconName(for: item.productName))
                    .font(.system(size: 19, weight: .medium))
                    .foregroundColor(theme.burgundy)
            )
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11.5, weight: .bold))
            .foregroundColor(theme.secondaryText)
            .tracking(0.5)
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(theme.secondaryText)
                    .frame(width: 18)
                Text(LocalizedStringKey(label))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.secondaryText)
            }

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(theme.primaryText)
        }
    }

    private var monogram: some View {
        Circle()
            .fill(theme.burgundy)
            .frame(width: 44, height: 44)
            .overlay(
                Text(initials(for: item.customerName))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            )
    }

    private func iconName(for productName: String) -> String {
        let name = productName.lowercased()

        let earbudKeywords = ["airpods", "earbud", "earphone", "buds"]
        let headphoneKeywords = ["headphone", "wh-", "over-ear", "on-ear"]
        let watchKeywords = ["watch", "chronograph", "timex", "rolex", "casio", "titan", "fossil", "seiko"]
        let shoeKeywords = ["shoe", "air max", "sneaker", "jordan", "boot", "sandal", "loafer", "cleat"]
        let laptopKeywords = ["macbook", "laptop", "notebook", "chromebook"]
        let tabletKeywords = ["ipad", "tablet"]
        let phoneKeywords = ["iphone", "galaxy s", "galaxy note", "pixel", "smartphone"]
        let tvKeywords = ["tv", "television"]
        let cameraKeywords = ["camera", "gopro", "dslr"]
        let speakerKeywords = ["speaker", "soundbar", "boombox"]
        let bagKeywords = ["bag", "backpack", "handbag", "wallet", "purse"]
        let clothingKeywords = ["shirt", "jacket", "trouser", "jean", "dress", "hoodie", "sweater"]

        if earbudKeywords.contains(where: name.contains) {
            return "airpodspro"
        } else if headphoneKeywords.contains(where: name.contains) {
            return "headphones"
        } else if watchKeywords.contains(where: name.contains) {
            return "applewatch"
        } else if shoeKeywords.contains(where: name.contains) {
            return "shoe.2"
        } else if laptopKeywords.contains(where: name.contains) {
            return "laptopcomputer"
        } else if tabletKeywords.contains(where: name.contains) {
            return "ipad"
        } else if phoneKeywords.contains(where: name.contains) {
            return "iphone"
        } else if tvKeywords.contains(where: name.contains) {
            return "tv"
        } else if cameraKeywords.contains(where: name.contains) {
            return "camera"
        } else if speakerKeywords.contains(where: name.contains) {
            return "hifispeaker"
        } else if bagKeywords.contains(where: name.contains) {
            return "bag"
        } else if clothingKeywords.contains(where: name.contains) {
            return "tshirt"
        } else {
            return "shippingbox"
        }
    }

    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }
}

#Preview {
    NavigationStack {
        RepairDetailView(
            item: AfterSalesHistoryView.RepairItem(
                id: UUID(),
                customerName: "Vikram Singh",
                orderId: "INV-1011",
                productName: "Sony WH-1000XM5",
                imageUrl: nil,
                issueDescription: "Left hinge is loose and creaks when folded.",
                serviceCost: 450,
                date: Date(),
                status: "Completed",
                invoice: AfterSalesHistoryView.InvoiceInfo(
                    id: UUID(), orderTotal: 7999, pricePaid: 7999,
                    pickupCode: "PU-2210", orderDate: Date()
                )
            )
        )
    }
}
