import SwiftUI

struct InvoiceItemsSelectionView: View {
    @Environment(AppTheme.self) private var theme
    @Environment(\.dismiss) private var dismiss
    @Binding var path: NavigationPath
    let invoiceId: String
    // Real, DB-backed invoice data.
    @State private var items: [AfterSalesInvoiceLine] = []
    @State private var customer: RequestCustomer? = nil
    @State private var isLoading = true
    @State private var loadError: String? = nil
    @State private var expandedItemId: UUID? = nil

    private static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter
    }()

    var body: some View {
        ZStack(alignment: .top) {
            theme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Select item to process")
                        .font(.system(size: 14, weight: .medium))
                        .textCase(.uppercase)
                        .foregroundColor(theme.secondaryText.opacity(0.8))
                        .padding(.horizontal, RSMSSpacing.lg)
                        .padding(.bottom, 4)

                    if isLoading {
                        HStack { Spacer(); ProgressView("Loading invoice...").tint(theme.burgundy); Spacer() }
                            .padding(.top, 40)
                    } else if let loadError {
                        emptyState(message: loadError, icon: "exclamationmark.triangle")
                    } else if items.isEmpty {
                        emptyState(message: "No items found for this invoice. Check the invoice number and try again.", icon: "doc.text.magnifyingglass")
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(items) { item in
                                itemCard(item)
                            }
                        }
                        .padding(.horizontal, RSMSSpacing.lg)
                        .padding(.bottom, 40)
                    }
                }
                .padding(.top, 150)
            }
            .ignoresSafeArea(edges: .top)

            customHeaderSection
        }
        .navigationBarHidden(true)
        .task { await loadItems() }
    }

    private func emptyState(message: String, icon: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(theme.secondaryText.opacity(0.5))
            Text(localized: message)
                .font(.system(size: 14))
                .foregroundColor(theme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, 40)
    }

    private func loadItems() async {
        isLoading = true
        loadError = nil
        do {
            let details = try await AfterSalesService.fetchInvoiceDetails(orderId: invoiceId)
            if details.found {
                self.items = details.items
                self.customer = details.customer
                
                if self.items.count == 1 {
                    self.expandedItemId = self.items.first?.id
                }
            } else {
                self.loadError = "Couldn't find this invoice. It may not exist or belongs to another store."
            }
        } catch {
            self.loadError = "Couldn't load this invoice. Please try again."
            print("After Sales invoice fetch error: \(error)")
        }
        isLoading = false
    }

    // MARK: - Header

    private var customHeaderSection: some View {
        HStack(alignment: .center, spacing: RSMSSpacing.md) {
            Button {
                dismiss()
            } label: {
                ZStack {
                    Circle()
                        .fill(theme.burgundy.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(theme.primaryText)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Invoice Item")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(theme.primaryText)

                Text(invoiceId)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.secondaryText)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, 60)
        .padding(.bottom, RSMSSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Expandable item card

    private func itemCard(_ item: AfterSalesInvoiceLine) -> some View {
        let isExpanded = expandedItemId == item.id
        let isExpired = !item.inWarranty

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    expandedItemId = isExpanded ? nil : item.id
                }
            } label: {
                HStack(spacing: 16) {
                    AsyncImage(url: URL(string: item.imageUrl ?? "")) { phase in
                        if let image = phase.image {
                            image.resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            theme.secondaryText.opacity(0.08)
                        }
                    }
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(theme.primaryText)
                            .lineLimit(1)

                        Text("\(item.category) \u{00B7} Qty: \(item.quantity)")
                            .font(.system(size: 12))
                            .foregroundColor(theme.secondaryText)
                    }

                    Spacer()

                    Text(formatIndianCurrency(item.price))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.burgundy)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    Divider()
                        .padding(.vertical, 12)

                    if let purchase = item.purchaseDate {
                        detailRow(label: "Date of purchase",
                                  value: Self.displayDateFormatter.string(from: purchase))
                    }

                    detailRow(label: "Cost", value: formatIndianCurrency(item.price))

                    if let warranty = item.warrantyEndDate {
                        detailRow(
                            label: isExpired ? "Warranty expired on" : "Warranty valid until",
                            value: Self.displayDateFormatter.string(from: warranty),
                            isWarning: isExpired
                        )
                    }

                    Button {
                        // Map to POSProduct for the shared downstream views; carry real dates + customer.
                        let posProduct = POSProduct(
                            id: item.lineId,
                            itemId: item.itemId,
                            name: item.name,
                            sku: item.sku,
                            category: item.category,
                            price: item.price,
                            stock: item.quantity,
                            size: "—",
                            imageUrl: item.imageUrl
                        )
                        path.append(
                            POSFlowDestination.actionSelection(
                                invoiceId: invoiceId,
                                selectedItem: posProduct,
                                purchaseDate: item.purchaseDate,
                                warrantyEndDate: item.warrantyEndDate,
                                customer: customer
                            )
                        )
                    } label: {
                        Text("Proceed")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(theme.burgundy)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 14)
                }
                .transition(.opacity)
            }
        }
        .padding(16)
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isExpanded ? theme.burgundy : theme.cardBorder, lineWidth: isExpanded ? 1.5 : 1)
        )
    }

    private func detailRow(label: String, value: String, isWarning: Bool = false) -> some View {
        HStack {
            Text(localized: label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(theme.secondaryText)

            Spacer()

            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isWarning ? theme.burgundy : theme.primaryText)
        }
        .padding(.vertical, 5)
    }
}
