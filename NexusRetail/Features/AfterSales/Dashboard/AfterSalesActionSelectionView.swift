//
//  AfterSalesActionSelectionView.swift
//  NexusRetail
//
//  Redesigned action screen (hero carousel + item details + customer contact +
//  PDF export). Exchange/Repair are wired to the real after-sales backend.
//
import SwiftUI
import UIKit

struct ActionSelectionView: View {
    @Environment(AppTheme.self) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Binding var path: NavigationPath

    let invoiceId: String
    let selectedItem: POSProduct
    let purchaseDate: Date?
    let warrantyEndDate: Date?
    let customer: RequestCustomer?
    let imageUrls: [String]

    @State private var currentImageIndex: Int = 0
    @State private var showCustomerSheet: Bool = false
    @State private var shareURL: IdentifiableURL?

    // Backend / processing state
    @State private var isProcessing = false
    @State private var showExchangeConfirm = false
    @State private var resultTitle = ""
    @State private var resultMessage = ""
    @State private var showResult = false
    @State private var resultWasSuccess = false

    private let heroImageHeight: CGFloat = 380
    private let cardCornerRadius: CGFloat = 28

    private static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter
    }()

    init(
        path: Binding<NavigationPath>,
        invoiceId: String,
        selectedItem: POSProduct,
        purchaseDate: Date? = nil,
        warrantyEndDate: Date? = nil,
        customer: RequestCustomer? = nil,
        imageUrls: [String]? = nil
    ) {
        self._path = path
        self.invoiceId = invoiceId
        self.selectedItem = selectedItem
        self.purchaseDate = purchaseDate
        self.warrantyEndDate = warrantyEndDate
        self.customer = customer
        self.imageUrls = imageUrls ?? [selectedItem.imageUrl].compactMap { $0 }
    }

    private var isWarrantyExpired: Bool {
        guard let warrantyEndDate else { return false }
        return warrantyEndDate < Date()
    }

    /// Exchange is allowed within 15 days of purchase (mirrors the server policy).
    private var isExchangeAllowed: Bool {
        guard let purchaseDate else { return false }
        guard let deadline = Calendar.current.date(byAdding: .day, value: 15, to: purchaseDate) else { return false }
        return Date() <= deadline
    }

    var body: some View {
        ZStack(alignment: .top) {
            theme.background
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 0) {
                        heroImageSection
                        cardSection
                            .padding(.top, -cardCornerRadius)
                    }

                    detailsSection
                        .padding(.horizontal, RSMSSpacing.lg)
                }
                .padding(.bottom, 24)
            }
            .ignoresSafeArea(edges: .top)
            // Exchange / Repair stay fixed at the bottom even while scrolling.
            .safeAreaInset(edge: .bottom) {
                actionsSection
                    .padding(.horizontal, RSMSSpacing.lg)
                    .padding(.top, 10)
                    .padding(.bottom, 8)
            }

            floatingHeader

            if isProcessing {
                Color.black.opacity(0.25).ignoresSafeArea()
                ProgressView().tint(.white)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showCustomerSheet) {
            customerSheetContent
                .presentationDetents([.height(320)])
        }
        .sheet(item: $shareURL) { wrapped in
            ShareSheet(items: [wrapped.url])
        }
        .sheet(isPresented: $showExchangeConfirm) {
            exchangeConfirmSheet
                .presentationDetents([.height(420)])
                .presentationDragIndicator(.visible)
        }
        .alert(resultTitle, isPresented: $showResult) {
            Button("OK") { if resultWasSuccess { path = NavigationPath() } }
        } message: {
            Text(resultMessage)
        }
    }

    // MARK: - Hero image carousel

    private var heroImageSection: some View {
        ZStack(alignment: .trailing) {
            TabView(selection: $currentImageIndex) {
                ForEach(Array(imageUrls.enumerated()), id: \.offset) { index, url in
                    AsyncImage(url: URL(string: url)) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            theme.secondaryText.opacity(0.08)
                        }
                    }
                    .frame(height: heroImageHeight)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: heroImageHeight)

            if imageUrls.count > 1 {
                pageDots
                    .padding(.trailing, 14)
            }
        }
    }

    private var pageDots: some View {
        VStack(spacing: 6) {
            ForEach(imageUrls.indices, id: \.self) { index in
                Circle()
                    .fill(index == currentImageIndex ? theme.primaryText : theme.primaryText.opacity(0.25))
                    .frame(width: 6, height: 6)
            }
        }
    }

    // MARK: - Floating header

    private var floatingHeader: some View {
        HStack {
            floatingIconButton(systemImage: "chevron.left") { dismiss() }
            Spacer()
            HStack(spacing: 10) {
                floatingIconButton(systemImage: "square.and.arrow.up") { exportInvoicePDF() }
                floatingIconButton(systemImage: "person") { showCustomerSheet = true }
            }
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, 10)
    }

    private func floatingIconButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(.white)
                    .frame(width: 44, height: 44)
                    .shadow(color: .black.opacity(0.12), radius: 6, y: 3)

                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(theme.primaryText)
            }
        }
    }

    // MARK: - Card

    private var cardSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(selectedItem.name)
                .font(.system(size: 28, weight: .heavy))
                .foregroundColor(theme.primaryText)

            Text("\(selectedItem.category) \u{00B7} Size: \(selectedItem.size)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.secondaryText.opacity(0.8))
                .padding(.top, 2)

            Text(formatIndianCurrency(selectedItem.price))
                .font(.system(size: 28, weight: .heavy))
                .foregroundColor(theme.burgundy)
                .padding(.top, 8)
        }
        .padding(20)
        .padding(.top, cardCornerRadius + 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.cardBackground)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: cardCornerRadius,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: cardCornerRadius,
                style: .continuous
            )
        )
    }

    // MARK: - Item details

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Item Details")
                .font(.system(size: 12, weight: .semibold))
                .textCase(.uppercase)
                .tracking(0.6)
                .foregroundColor(theme.secondaryText.opacity(0.7))
                .padding(.bottom, 14)

            detailRow(icon: "number", label: "SKU", value: selectedItem.sku)

            Divider().padding(.vertical, 12)

            detailRow(icon: "doc.text", label: "Invoice", value: invoiceId)

            if let purchaseDate {
                Divider().padding(.vertical, 12)
                detailRow(icon: "calendar", label: "Purchased on",
                          value: Self.displayDateFormatter.string(from: purchaseDate))
            }

            if let warrantyEndDate {
                Divider().padding(.vertical, 12)
                warrantyRow(warrantyEndDate)
            }
        }
        .padding(20)
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(theme.cardBorder, lineWidth: 1)
        )
    }

    private func detailRow(icon: String, label: String, value: String, action: (() -> Void)? = nil) -> some View {
        let row = HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(theme.secondaryText.opacity(0.08))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(theme.secondaryText)
            }
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.secondaryText)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(theme.primaryText)
        }

        if let action {
            return AnyView(Button(action: action) { row }.buttonStyle(.plain))
        } else {
            return AnyView(row)
        }
    }

    private func warrantyRow(_ endDate: Date) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill((isWarrantyExpired ? theme.burgundy : Color.green).opacity(0.1))
                    .frame(width: 32, height: 32)
                Image(systemName: isWarrantyExpired ? "shield.slash" : "checkmark.shield")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isWarrantyExpired ? theme.burgundy : .green)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Warranty")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.secondaryText)
                Text(Self.displayDateFormatter.string(from: endDate))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(theme.secondaryText.opacity(0.7))
            }
            Spacer()
            Text(isWarrantyExpired ? "Expired" : "Valid")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isWarrantyExpired ? theme.burgundy : .green)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background((isWarrantyExpired ? theme.burgundy : Color.green).opacity(0.1))
                .clipShape(Capsule())
        }
    }

    // MARK: - Actions (wired to real backend)

    private var actionsSection: some View {
        VStack(spacing: 6) {
            HStack(spacing: 12) {
                Button(action: {
                    path.append(POSFlowDestination.exchangeWarrantyCheck(
                        invoiceId: invoiceId,
                        selectedItem: selectedItem,
                        purchaseDate: purchaseDate,
                        warrantyEndDate: warrantyEndDate,
                        customer: customer
                    ))
                }) {
                    Label("Exchange", systemImage: "arrow.triangle.2.circlepath")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.burgundy)
                .controlSize(.large)
                .disabled(!isExchangeAllowed)

                Button(action: { path.append(POSFlowDestination.repairForm(invoiceId: invoiceId, selectedItem: selectedItem, warrantyEndDate: warrantyEndDate)) }) {
                    Label("Repair", systemImage: "wrench.and.screwdriver")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.bordered)
                .tint(theme.burgundy)
                .controlSize(.large)
            }

            if !isExchangeAllowed {
                Text("Exchange window (15 days) has passed for this item.")
                    .font(.system(size: 11))
                    .foregroundColor(theme.secondaryText)
            }
        }
    }

    // MARK: - Exchange confirmation sheet + processing

    private var exchangeConfirmSheet: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                ZStack {
                    Circle().fill(theme.burgundy.opacity(0.1)).frame(width: 64, height: 64)
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(theme.burgundy)
                }
                Text("Confirm Exchange")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(theme.primaryText)
            }
            .padding(.top, 28)

            Text("This will record an exchange for \(selectedItem.name) and restock the returned unit into inventory.")
                .font(.system(size: 14))
                .foregroundColor(theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, RSMSSpacing.lg)
                .padding(.top, 16)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    Task {
                        showExchangeConfirm = false
                        await processExchange()
                    }
                } label: {
                    Text("Process Exchange")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(theme.burgundy)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                Button("Cancel") { showExchangeConfirm = false }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(theme.secondaryText)
            }
            .padding(.horizontal, RSMSSpacing.lg)
            .padding(.bottom, 28)
        }
        .background(theme.background.ignoresSafeArea())
    }

    private func processExchange() async {
        isProcessing = true
        defer { isProcessing = false }
        do {
            let result = try await AfterSalesService.process(
                orderId: invoiceId, itemId: selectedItem.itemId,
                type: "exchange", issue: "Exchange requested", partsCost: 0)
            if result.success {
                resultWasSuccess = true
                resultTitle = "Exchange Approved"
                resultMessage = "The exchange for \(selectedItem.name) has been recorded and the unit restocked."
            } else {
                resultWasSuccess = false
                resultTitle = "Exchange Not Allowed"
                resultMessage = result.message ?? "This item is no longer eligible for exchange."
            }
            showResult = true
        } catch {
            resultWasSuccess = false
            resultTitle = "Something went wrong"
            resultMessage = "Couldn't process the exchange. Please try again."
            showResult = true
        }
    }
    // MARK: - Customer sheet

    private var customerSheetContent: some View {
        VStack(spacing: 20) {
            Capsule()
                .fill(theme.secondaryText.opacity(0.25))
                .frame(width: 40, height: 5)
                .padding(.top, 8)

            if let customer {
                ZStack {
                    Circle()
                        .fill(theme.burgundy.opacity(0.1))
                        .frame(width: 64, height: 64)
                    Text(initials(for: customer.name))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(theme.burgundy)
                }
                Text(customer.name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(theme.primaryText)
                Text("Raised this request on invoice \(invoiceId)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(theme.secondaryText)

                VStack(spacing: 0) {
                    detailRow(icon: "phone", label: "Phone", value: customer.phone.isEmpty ? "—" : customer.phone) {
                        if !customer.phone.isEmpty { callCustomer(customer.phone) }
                    }
                    Divider().padding(.vertical, 12)
                    detailRow(icon: "envelope", label: "Email", value: customer.email.isEmpty ? "—" : customer.email) {
                        if !customer.email.isEmpty { emailCustomer(customer.email) }
                    }
                }
            } else {
                Spacer()
                Text("No customer information available for this invoice.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, RSMSSpacing.lg)
            }

            Spacer()
        }
        .padding(.bottom, 12)
    }

    private func actionCard(title: String, description: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 64, height: 64)
                    Image(systemName: icon)
                        .font(.system(size: 26, weight: .medium))
                        .foregroundColor(color)
                }
                .padding(20)
                .background(theme.background)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, RSMSSpacing.lg)
                .padding(.top, 8)
            }
        }
    }

    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }

    private func callCustomer(_ phone: String) {
        let digits = phone.filter { $0.isNumber || $0 == "+" }
        guard let url = URL(string: "tel://\(digits)") else { return }
        openURL(url)
    }

    private func emailCustomer(_ email: String) {
        let supportAddress = "nexus.support@nexus.com"
        let subject = "Regarding Invoice \(invoiceId)"
        let ccEncoded = supportAddress.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? supportAddress
        let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subject
        let urlString = "mailto:\(email)?cc=\(ccEncoded)&subject=\(subjectEncoded)"
        guard let url = URL(string: urlString) else { return }
        openURL(url)
    }

    // MARK: - PDF export

    private func exportInvoicePDF() {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let data = renderer.pdfData { context in
            context.beginPage()
            var y: CGFloat = 48
            let leftMargin: CGFloat = 48
            func draw(_ text: String, font: UIFont, color: UIColor = .black, spacingAfter: CGFloat = 10) {
                let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
                text.draw(at: CGPoint(x: leftMargin, y: y), withAttributes: attrs)
                y += font.lineHeight + spacingAfter
            }
            draw("Invoice Item Summary", font: .boldSystemFont(ofSize: 22), spacingAfter: 24)
            draw("Invoice", font: .systemFont(ofSize: 11, weight: .semibold), color: .darkGray, spacingAfter: 2)
            draw(invoiceId, font: .systemFont(ofSize: 14), spacingAfter: 16)
            draw("Item", font: .systemFont(ofSize: 11, weight: .semibold), color: .darkGray, spacingAfter: 2)
            draw(selectedItem.name, font: .systemFont(ofSize: 14), spacingAfter: 16)
            draw("SKU", font: .systemFont(ofSize: 11, weight: .semibold), color: .darkGray, spacingAfter: 2)
            draw(selectedItem.sku, font: .systemFont(ofSize: 14), spacingAfter: 16)
            draw("Price", font: .systemFont(ofSize: 11, weight: .semibold), color: .darkGray, spacingAfter: 2)
            draw(formatIndianCurrency(selectedItem.price), font: .systemFont(ofSize: 14), spacingAfter: 16)
            if let purchaseDate {
                draw("Purchased On", font: .systemFont(ofSize: 11, weight: .semibold), color: .darkGray, spacingAfter: 2)
                draw(Self.displayDateFormatter.string(from: purchaseDate), font: .systemFont(ofSize: 14), spacingAfter: 16)
            }
            if let warrantyEndDate {
                draw("Warranty", font: .systemFont(ofSize: 11, weight: .semibold), color: .darkGray, spacingAfter: 2)
                let status = isWarrantyExpired ? "Expired" : "Valid"
                draw("\(Self.displayDateFormatter.string(from: warrantyEndDate)) (\(status))", font: .systemFont(ofSize: 14), spacingAfter: 16)
            }
            if let customer {
                draw("Customer", font: .systemFont(ofSize: 11, weight: .semibold), color: .darkGray, spacingAfter: 2)
                draw(customer.name, font: .systemFont(ofSize: 14), spacingAfter: 2)
                draw(customer.phone, font: .systemFont(ofSize: 14), spacingAfter: 2)
                draw(customer.email, font: .systemFont(ofSize: 14), spacingAfter: 16)
            }
        }
        let fileName = "Invoice_\(invoiceId)_\(selectedItem.sku).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: url)
            shareURL = IdentifiableURL(url: url)
        } catch {
            print("Failed to write invoice PDF: \(error)")
        }
    }
}

// MARK: - Share sheet wrapper

private struct IdentifiableURL: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

// Button style for press animation
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}
