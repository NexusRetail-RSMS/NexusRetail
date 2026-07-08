import SwiftUI
import PhotosUI
import CoreImage
import AVFoundation

struct InvoiceScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var path: NavigationPath

    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var invoiceNumber: String = ""
    @State private var isEnteringInvoice = false
    @State private var scanFeedback: String? = nil
    @FocusState private var invoiceFocused: Bool

    var body: some View {
        ZStack(alignment: .top) {
            RSMSColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    scannerCard
                    orDivider
                    optionsCard
                    tipFooter
                }
                .padding(.horizontal, RSMSSpacing.lg)
                .padding(.top, 128)
                .padding(.bottom, 40)
            }
            .ignoresSafeArea(edges: .top)
            .scrollDismissesKeyboard(.interactively)

            header
        }
        .navigationBarHidden(true)
        .contentShape(Rectangle())
        .onTapGesture { invoiceFocused = false }
        .onChange(of: selectedPhoto) { _, item in processSelectedPhoto(item) }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: RSMSSpacing.md) {
            Button { dismiss() } label: {
                ZStack {
                    Circle().fill(RSMSColors.burgundy.opacity(0.1)).frame(width: 40, height: 40)
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(RSMSColors.primaryText)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Scan Bill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(RSMSColors.primaryText)
                Text("INVOICE SCANNER")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .tracking(0.8)
                    .foregroundColor(RSMSColors.secondaryText.opacity(0.7))
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

    // MARK: - Live scanner card

    private var scannerCard: some View {
        ZStack {
            InlineQRScanner { code in
                handleScanned(code)
            }
            .frame(height: 300)

            // Framing reticle
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.9), lineWidth: 2)
                .frame(width: 190, height: 190)
                .overlay(reticleCorners)

            VStack {
                Spacer()
                Text(scanFeedback ?? "Point the camera at the bill's QR code")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.35), in: Capsule())
                    .padding(.bottom, 14)
            }
        }
        .frame(height: 300)
        .frame(maxWidth: .infinity)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(RSMSColors.burgundy.opacity(0.25), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.15), radius: 12, y: 4)
    }

    private var reticleCorners: some View {
        // Four burgundy corner accents
        GeometryReader { geo in
            let s: CGFloat = 22
            ZStack {
                ForEach(0..<4, id: \.self) { i in
                    cornerShape
                        .stroke(RSMSColors.burgundy, lineWidth: 3)
                        .frame(width: s, height: s)
                        .rotationEffect(.degrees(Double(i) * 90))
                        .position(cornerPosition(i, in: geo.size, inset: 2))
                }
            }
        }
    }

    private var cornerShape: Path {
        Path { p in
            p.move(to: CGPoint(x: 0, y: 22))
            p.addLine(to: CGPoint(x: 0, y: 0))
            p.addLine(to: CGPoint(x: 22, y: 0))
        }
    }

    private func cornerPosition(_ i: Int, in size: CGSize, inset: CGFloat) -> CGPoint {
        switch i {
        case 0: return CGPoint(x: inset + 11, y: inset + 11)
        case 1: return CGPoint(x: size.width - inset - 11, y: inset + 11)
        case 2: return CGPoint(x: size.width - inset - 11, y: size.height - inset - 11)
        default: return CGPoint(x: inset + 11, y: size.height - inset - 11)
        }
    }

    private var orDivider: some View {
        HStack(spacing: 12) {
            Rectangle().fill(RSMSColors.cardBorder).frame(height: 1)
            Text("OR").font(.system(size: 12, weight: .bold)).foregroundColor(RSMSColors.secondaryText)
            Rectangle().fill(RSMSColors.cardBorder).frame(height: 1)
        }
    }

    // MARK: - Options (upload + manual entry)

    private var optionsCard: some View {
        VStack(spacing: 0) {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                optionRow(icon: "photo", tint: RSMSColors.burgundy,
                          title: "Upload QR Code", subtitle: "Pick a bill photo from your library")
            }
            Divider().padding(.leading, 64)

            VStack(alignment: .leading, spacing: 0) {
                Button { toggleEntry() } label: {
                    optionRow(icon: "keyboard", tint: RSMSColors.primaryText,
                              title: "Enter Invoice Number", subtitle: "Type it manually",
                              chevronRotation: isEnteringInvoice ? 90 : 0)
                }
                .buttonStyle(.plain)

                if isEnteringInvoice {
                    VStack(spacing: 10) {
                        TextField("Invoice number", text: $invoiceNumber)
                            .font(.system(size: 15, weight: .medium))
                            .focused($invoiceFocused)
                            .padding(.horizontal, 14).padding(.vertical, 12)
                            .background(RSMSColors.background)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSColors.inputBorder, lineWidth: 1))
                            .onSubmit { submitManual() }

                        Button { submitManual() } label: {
                            Text("Continue")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity).padding(.vertical, 13)
                                .background(invoiceNumber.isEmpty ? RSMSColors.secondaryText.opacity(0.4) : RSMSColors.burgundy)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(invoiceNumber.isEmpty)
                    }
                    .padding(.horizontal, 16).padding(.bottom, 16)
                    .transition(.opacity)
                }
            }
        }
        .background(RSMSColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(RSMSColors.cardBorder, lineWidth: 1))
    }

    private func optionRow(icon: String, tint: Color, title: String, subtitle: String, chevronRotation: Double = 0) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(tint.opacity(0.1)).frame(width: 40, height: 40)
                Image(systemName: icon).font(.system(size: 16, weight: .semibold)).foregroundColor(tint)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 15, weight: .semibold)).foregroundColor(RSMSColors.primaryText)
                Text(subtitle).font(.system(size: 12)).foregroundColor(RSMSColors.secondaryText)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(RSMSColors.secondaryText.opacity(0.5))
                .rotationEffect(.degrees(chevronRotation))
        }
        .padding(14)
        .contentShape(Rectangle())
    }

    private var tipFooter: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb.fill").font(.system(size: 13)).foregroundColor(RSMSColors.burgundy.opacity(0.7))
            Text("The QR code is printed at the bottom of the customer's receipt.")
                .font(.system(size: 12.5, weight: .medium))
                .foregroundColor(RSMSColors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RSMSColors.burgundy.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Actions

    private func toggleEntry() {
        withAnimation(.bouncy) { isEnteringInvoice.toggle() }
        if isEnteringInvoice {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { invoiceFocused = true }
        } else {
            invoiceFocused = false
        }
    }

    private func submitManual() {
        let v = invoiceNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !v.isEmpty else { return }
        navigate(to: v)
    }

    private func handleScanned(_ raw: String) {
        let id = raw.hasPrefix("nexus://invoice/")
            ? raw.replacingOccurrences(of: "nexus://invoice/", with: "")
            : raw
        withAnimation { scanFeedback = "Bill detected" }
        navigate(to: id)
    }

    private func navigate(to invoiceId: String) {
        invoiceFocused = false
        path.append(POSFlowDestination.invoiceItemsSelection(invoiceId: invoiceId))
    }

    private func processSelectedPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data),
               let ciImage = CIImage(image: image) {
                let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
                if let feature = (detector?.features(in: ciImage) as? [CIQRCodeFeature])?.first,
                   let str = feature.messageString {
                    let id = str.replacingOccurrences(of: "nexus://invoice/", with: "")
                    await MainActor.run { navigate(to: id) }
                } else {
                    await MainActor.run { withAnimation { scanFeedback = "No QR code found in that image" } }
                }
            }
        }
    }
}

// MARK: - Inline camera scanner (live preview + QR detection)

struct InlineQRScanner: UIViewRepresentable {
    let onCode: (String) -> Void

    func makeUIView(context: Context) -> ScannerPreviewView {
        let view = ScannerPreviewView()
        view.onCode = onCode
        view.startIfPermitted()
        return view
    }

    func updateUIView(_ uiView: ScannerPreviewView, context: Context) {}

    static func dismantleUIView(_ uiView: ScannerPreviewView, coordinator: ()) {
        uiView.stop()
    }
}

final class ScannerPreviewView: UIView, AVCaptureMetadataOutputObjectsDelegate {
    var onCode: ((String) -> Void)?

    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var hasScanned = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
    }
    required init?(coder: NSCoder) { super.init(coder: coder); backgroundColor = .black }

    func startIfPermitted() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureAndRun()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard granted else { return }
                DispatchQueue.main.async { self?.configureAndRun() }
            }
        default:
            break // denied/restricted — camera stays black; upload/manual still work
        }
    }

    private func configureAndRun() {
        guard !session.isRunning else { return }
        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else { return }

        session.beginConfiguration()
        session.addInput(input)
        let output = AVCaptureMetadataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [.qr]
        }
        session.commitConfiguration()

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = bounds
        layer.addSublayer(preview)
        previewLayer = preview

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }

    func stop() {
        if session.isRunning {
            DispatchQueue.global(qos: .background).async { [weak self] in self?.session.stopRunning() }
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !hasScanned,
              let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = obj.stringValue else { return }
        hasScanned = true
        onCode?(value)
    }
}
