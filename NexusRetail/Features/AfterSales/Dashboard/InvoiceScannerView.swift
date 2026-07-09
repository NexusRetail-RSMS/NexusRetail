import SwiftUI
import PhotosUI
import CoreImage

struct InvoiceScannerView: View {
    @Environment(AppTheme.self) private var theme
    @Environment(\.dismiss) private var dismiss
    @Binding var path: NavigationPath

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var invoiceNumber: String = ""
    @State private var showScanner: Bool = false
    @State private var isEnteringInvoice: Bool = false
    @FocusState private var isInvoiceFieldFocused: Bool

    var body: some View {
        ZStack(alignment: .top) {
            theme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    heroSection
                        .opacity(showScanner ? 0 : 1)

                    VStack(spacing: 16) {
                        scannerCard
                        uploadCard
                        enterInvoiceCard
                    }
                        .opacity(showScanner ? 0 : 1)

                    Spacer(minLength: 32)
                }
                .animation(.easeInOut(duration: 0.2), value: showScanner)
                .padding(.horizontal, RSMSSpacing.lg)
                .padding(.top, 28)
                .padding(.bottom, 48)
                .frame(minHeight: 500)
            }
            .padding(.top, 132)
            .ignoresSafeArea(edges: .top)
            .scrollDismissesKeyboard(.interactively)

            customHeaderSection
        }
        .navigationBarHidden(true)
        .contentShape(Rectangle())
        .onTapGesture {
            if isEnteringInvoice {
                collapseInvoiceEntry()
            }
        }
        .qrScanner(isScanning: $showScanner) { code in
            let id = code.hasPrefix("nexus://invoice/")
                ? code.replacingOccurrences(of: "nexus://invoice/", with: "")
                : code
            simulateScan(forInvoice: id)
        }
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
                        .frame(width: 40, height: 40)

                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(theme.primaryText)
                }
            }
            .accessibilityLabel("Back")

            VStack(alignment: .leading, spacing: 2) {
                Text("Scan Bill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(theme.primaryText)
                    .lineLimit(1)

                Text("INVOICE SCANNER")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .tracking(0.8)
                    .foregroundColor(theme.secondaryText.opacity(0.7))
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

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(theme.burgundy.opacity(0.1))
                    .frame(width: 60, height: 60)

                Image(systemName: "doc.text.viewfinder")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(theme.burgundy)
            }

            VStack(spacing: 4) {
                Text("How would you like to add a bill?")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.primaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    // MARK: - Options cards

    private var scannerCard: some View {
        Button {
            showScanner = true
        } label: {
            optionRowLabel(
                systemImage: "camera.fill",
                iconStyle: .filled,
                title: "Open Scanner",
                subtitle: "Live camera detect",
                tag: "CAM"
            )
        }
        .buttonStyle(PremiumPressStyle())
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(theme.inputBorder.opacity(0.5), lineWidth: 1)
        )
    }

    private var uploadCard: some View {
        PhotosPicker(selection: $selectedPhoto, matching: .images) {
            optionRowLabel(
                systemImage: "photo",
                iconStyle: .tinted,
                title: "Upload QR Code",
                subtitle: "From your photos",
                tag: "IMG"
            )
        }
        .onChange(of: selectedPhoto) { _, newItem in
            processSelectedPhoto(newItem)
        }
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(theme.inputBorder.opacity(0.5), lineWidth: 1)
        )
    }

    private var enterInvoiceCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                toggleInvoiceEntry()
            } label: {
                optionRowLabel(
                    systemImage: "keyboard",
                    iconStyle: .outline,
                    title: "Enter Invoice Number",
                    subtitle: "Type it manually",
                    tag: "TXT",
                    chevronRotation: isEnteringInvoice ? 90 : 0
                )
            }
            .buttonStyle(PremiumPressStyle())

            if isEnteringInvoice {
                VStack(alignment: .leading, spacing: 10) {
                    Divider()
                        .padding(.bottom, 4)

                    TextField("Enter invoice number", text: $invoiceNumber)
                        .font(.system(size: 15, weight: .medium))
                        .focused($isInvoiceFieldFocused)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(theme.background)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(theme.inputBorder, lineWidth: 1)
                        )
                        .onSubmit {
                            if !invoiceNumber.isEmpty {
                                simulateScan(forInvoice: invoiceNumber)
                            }
                        }

                    Button {
                        simulateScan(forInvoice: invoiceNumber)
                    } label: {
                        Text("Continue")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(invoiceNumber.isEmpty ? theme.secondaryText.opacity(0.4) : theme.burgundy)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .disabled(invoiceNumber.isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .transition(.opacity)
            }
        }
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(theme.inputBorder.opacity(0.5), lineWidth: 1)
        )
    }

    // MARK: - Row label

    private enum RowIconStyle {
        case filled   // solid dark circle, white icon — the primary/fastest path
        case tinted   // brand-tinted circle
        case outline  // bordered neutral circle
    }

    private func optionRowLabel(
        systemImage: String,
        iconStyle: RowIconStyle,
        title: String,
        subtitle: String,
        tag: String,
        chevronRotation: Double = 0
    ) -> some View {
        HStack(spacing: 16) {
            ZStack {
                switch iconStyle {
                case .filled:
                    Circle()
                        .fill(Color.black)
                        .frame(width: 48, height: 48)
                    Image(systemName: systemImage)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                case .tinted:
                    Circle()
                        .fill(theme.burgundy.opacity(0.1))
                        .frame(width: 48, height: 48)
                    Image(systemName: systemImage)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(theme.burgundy)
                case .outline:
                    Circle()
                        .stroke(theme.inputBorder, lineWidth: 1)
                        .frame(width: 48, height: 48)
                    Image(systemName: systemImage)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(theme.primaryText)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(localized: title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.primaryText)

                Text(localized: subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.secondaryText)
            }

            Spacer()

            Text(tag)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .tracking(0.5)
                .foregroundColor(theme.secondaryText.opacity(0.55))

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(theme.secondaryText.opacity(0.5))
                .rotationEffect(.degrees(chevronRotation))
                .animation(.easeInOut(duration: 0.2), value: chevronRotation)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }

    // MARK: - Actions

    private func toggleInvoiceEntry() {
        if isEnteringInvoice {
            collapseInvoiceEntry()
        } else {
            withAnimation(.bouncy) {
                isEnteringInvoice = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                isInvoiceFieldFocused = true
            }
        }
    }

    private func collapseInvoiceEntry() {
        isInvoiceFieldFocused = false
        withAnimation(.bouncy) {
            isEnteringInvoice = false
        }
    }

    private func simulateScan(forInvoice invoiceId: String) {
        path.append(POSFlowDestination.invoiceItemsSelection(invoiceId: invoiceId))
    }

    private func processSelectedPhoto(_ item: PhotosPickerItem?) {
        guard let item = item else { return }

        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data),
               let ciImage = CIImage(image: image) {

                let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
                if let features = detector?.features(in: ciImage) as? [CIQRCodeFeature],
                   let firstFeature = features.first,
                   let qrCodeString = firstFeature.messageString {

                    let invoiceId = qrCodeString.replacingOccurrences(of: "nexus://invoice/", with: "")

                    await MainActor.run {
                        simulateScan(forInvoice: invoiceId)
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        InvoiceScannerView(path: .constant(NavigationPath()))
    }
}
