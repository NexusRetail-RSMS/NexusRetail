//
//  DIQRScanner.swift
//  NexusRetail
//
//  Dynamic-island style QR scanner that expands from the top. Optionally shows
//  "Upload QR" and "Enter invoice number" options below the live scanner.
//

import SwiftUI
import AVFoundation
import PhotosUI
import CoreImage

fileprivate struct CameraProperties {
    var session: AVCaptureSession  = .init()
    var output: AVCaptureMetadataOutput = .init()
    var scannedCode: String? = nil
    var permissionState: Permission?

    enum Permission: String {
        case idle = "Not Determined"
        case approved = "Access Granted"
        case denied = "Access Denied"
    }

    static func checkAndAskCameraPermission() async -> Permission? {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return Permission.approved
        case .notDetermined:
            if await AVCaptureDevice.requestAccess(for: .video) {
                return Permission.approved
            } else {
                return Permission.denied
            }
        case .denied, .restricted:
            return Permission.denied
        default:
            return nil
        }
    }
}

extension View {
    @ViewBuilder
    func qrScanner(
        isScanning: Binding<Bool>,
        showInvoiceOptions: Bool = false,
        onScan: @escaping (String) -> Void
    ) -> some View {
        self.modifier(QRScannerViewModifier(isScanning: isScanning, showInvoiceOptions: showInvoiceOptions, onScan: onScan))
    }
}

fileprivate struct QRScannerViewModifier: ViewModifier {
    @Binding var isScanning: Bool
    var showInvoiceOptions: Bool = false
    var onScan: (String) -> Void

    @State private var showFullScreenCover: Bool = false
    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $showFullScreenCover) {
                DIQRScannerView(showInvoiceOptions: showInvoiceOptions) {
                    isScanning = false
                    Task { @MainActor in
                        showFullScreenCoverWithoutAnimation(false)
                    }
                } onScan: { code in
                    onScan(code)
                }
                .presentationBackground(.clear)
            }
            .onChange(of: isScanning) { oldValue, newValue in
                if newValue {
                    showFullScreenCoverWithoutAnimation(true)
                }
            }
    }

    private func showFullScreenCoverWithoutAnimation(_ status: Bool) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            showFullScreenCover = status
        }
    }
}

fileprivate struct DIQRScannerView: View {
    @Environment(AppTheme.self) private var theme
    var showInvoiceOptions: Bool = false
    var onClose: () -> ()
    var onScan: (String) -> Void

    @State private var isInitialized : Bool = false
    @State private var showContent  : Bool = false
    @State private var isExpanding : Bool = false
    @State private var camera: CameraProperties = .init()
    @Environment(\.openURL) private var openURL

    // Invoice options state
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var invoiceNumber: String = ""
    @State private var isEnteringInvoice: Bool = false
    @State private var optionsMessage: String? = nil
    @FocusState private var invoiceFocused: Bool

    var body: some View {
        GeometryReader {
            let size = $0.size
            let safeArea = $0.safeAreaInsets

            let haveDynamicIsland: Bool = safeArea.top >= 59
            let dynamicIslandWidth: CGFloat = 120
            let dynamicIslandHeight: CGFloat = 36
            let topOffset: CGFloat = haveDynamicIsland ? (11 + max((safeArea.top - 59), 0)) : (isExpanding ? (nonDynamicIslandHavingSpacing ? safeArea.top : -20 ) : -50)

            let expandedWidth: CGFloat = size.width - 30
            let expandedHeight: CGFloat = expandedWidth

            ZStack(alignment: .top) {
                Rectangle()
                    .fill(theme.background)
                    .contentShape(.rect)
                    .opacity(isExpanding ? 1 : 0)
                    .onTapGesture {
                        invoiceFocused = false
                        toggle(false)
                    }

                if isExpanding {
                    Button {
                        invoiceFocused = false
                        toggle(false)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(theme.primaryText)
                            .padding(16)
                            .background(Circle().fill(theme.cardBackground).shadow(color: .black.opacity(0.1), radius: 4))
                    }
                    .padding(.leading, 16)
                    .padding(.top, safeArea.top > 0 ? safeArea.top : 16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .transition(.opacity)
                    .zIndex(10)
                }

                // Scanner Animated View
                if showContent {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(.black)
                        .overlay {
                            GeometryReader {
                                let cameraSize = $0.size
                                scannerView(cameraSize)
                            }
                            .overlay(alignment: .bottom) {
                                Text("Scan your QR code")
                                    .font(.caption2)
                                    .foregroundStyle(.white.secondary)
                                    .lineLimit(1)
                                    .fixedSize()
                                    .offset(y: 25)
                            }
                            .padding(80)
                            .compositingGroup()
                            .blur(radius: isExpanding ? 0 : 20)
                            .opacity(isExpanding ? 1 : 0)
                            .geometryGroup()
                            .offset(y: nonDynamicIslandHavingSpacing || haveDynamicIsland ? 0 : 10)
                        }
                        .frame(
                            width: isExpanding ? expandedWidth : dynamicIslandWidth,
                            height: isExpanding ? expandedHeight : dynamicIslandHeight
                        )
                        .offset(y: topOffset)
                        .background {
                            if isExpanding {
                                Rectangle()
                                    .fill(.clear)
                                    .onDisappear {
                                        showContent = false
                                    }
                            }
                        }
                        .transition(.identity)
                        .onDisappear {
                            onClose()
                        }

                    // Invoice options, revealed below the scanner once expanded.
                    if showInvoiceOptions {
                        invoiceOptions
                            .padding(.horizontal, 15)
                            .frame(maxWidth: .infinity, alignment: .top)
                            .opacity(isExpanding ? 1 : 0)
                            .offset(y: topOffset + expandedHeight + 24)
                            .animation(.easeInOut(duration: 0.25).delay(isExpanding ? 0.15 : 0), value: isExpanding)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .ignoresSafeArea()
            .task {
                guard !isInitialized else { return }
                isInitialized = true
                showContent = true
                try? await Task.sleep(for: .seconds(0.05))
                toggle(true)
                camera.permissionState = await CameraProperties.checkAndAskCameraPermission()
            }
            .onChange(of: camera.scannedCode) { oldvalue, newvalue in
                if let newvalue {
                    finish(newvalue)
                }
            }
            .onChange(of: selectedPhoto) { _, item in decodeUploadedQR(item) }
        }
        .statusBarHidden()
    }

    // MARK: - Invoice options (upload + manual)

    private enum RowIconStyle { case filled, outline }

    @ViewBuilder
    private var invoiceOptions: some View {
        VStack(spacing: 12) {
            Text("OR ENTER MANUALLY")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .tracking(1)
                .foregroundColor(theme.secondaryText)

            // Card 1 — Upload
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                optionRow(icon: "photo", iconStyle: .filled, title: "Upload QR Code", subtitle: "From your photos", tag: "IMG")
            }
            .buttonStyle(.plain)
            .background(theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(theme.cardBorder, lineWidth: 1))
            .shadow(color: Color.black.opacity(0.06), radius: 10, y: 3)

            // Card 2 — Manual entry (expands inline)
            VStack(spacing: 0) {
                Button {
                    withAnimation(.bouncy) { isEnteringInvoice.toggle() }
                    if isEnteringInvoice {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { invoiceFocused = true }
                    }
                } label: {
                    optionRow(icon: "keyboard", iconStyle: .outline, title: "Enter Invoice Number", subtitle: "Type it manually", tag: "TXT",
                              chevronRotation: isEnteringInvoice ? 90 : 0)
                }
                .buttonStyle(.plain)

                if isEnteringInvoice {
                    HStack(spacing: 10) {
                        TextField("Invoice number", text: $invoiceNumber)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(theme.primaryText)
                            .focused($invoiceFocused)
                            .padding(.horizontal, 14).padding(.vertical, 12)
                            .background(theme.background, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(theme.inputBorder, lineWidth: 1))
                            .onSubmit { submitManual() }

                        Button { submitManual() } label: {
                            Text("Go")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 18).padding(.vertical, 12)
                                .background(invoiceNumber.isEmpty ? theme.secondaryText.opacity(0.4) : theme.burgundy, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(invoiceNumber.isEmpty)
                    }
                    .padding([.horizontal, .bottom], 14)
                    .transition(.opacity)
                }
            }
            .background(theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(theme.cardBorder, lineWidth: 1))
            .shadow(color: Color.black.opacity(0.06), radius: 10, y: 3)

            if let optionsMessage {
                Text(optionsMessage)
                    .font(.system(size: 12))
                    .foregroundColor(theme.secondaryText)
            }
        }
    }

    private func optionRow(icon: String, iconStyle: RowIconStyle, title: String, subtitle: String, tag: String, chevronRotation: Double = 0) -> some View {
        HStack(spacing: 14) {
            ZStack {
                switch iconStyle {
                case .filled:
                    Circle().fill(theme.burgundy.opacity(0.12)).frame(width: 44, height: 44)
                    Image(systemName: icon).font(.system(size: 17, weight: .semibold)).foregroundColor(theme.burgundy)
                case .outline:
                    Circle().stroke(theme.cardBorder, lineWidth: 1.5).frame(width: 44, height: 44)
                    Image(systemName: icon).font(.system(size: 17, weight: .semibold)).foregroundColor(theme.primaryText)
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 17, weight: .bold)).foregroundColor(theme.primaryText)
                Text(subtitle).font(.system(size: 14)).foregroundColor(theme.secondaryText)
            }
            Spacer()
            Text(tag)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .tracking(0.5)
                .foregroundColor(theme.secondaryText.opacity(0.6))
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(theme.secondaryText.opacity(0.5))
                .rotationEffect(.degrees(chevronRotation))
        }
        .padding(16)
        .contentShape(Rectangle())
    }

    // MARK: - Actions

    private func finish(_ code: String) {
        onScan(code)
        invoiceFocused = false
        toggle(false)
    }

    private func submitManual() {
        let v = invoiceNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !v.isEmpty else { return }
        finish(v)
    }

    private func decodeUploadedQR(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data),
               let ciImage = CIImage(image: image) {
                let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
                if let feature = (detector?.features(in: ciImage) as? [CIQRCodeFeature])?.first,
                   let str = feature.messageString {
                    await MainActor.run { finish(str) }
                } else {
                    await MainActor.run { withAnimation { optionsMessage = "No QR code found in that image." } }
                }
            }
        }
    }

    //Scanner View
    @ViewBuilder
    private func scannerView(_ size: CGSize) -> some View {
        let shape = RoundedRectangle(cornerRadius: size.width * 0.05, style: .continuous)

        ZStack {
            if let permissionState = camera.permissionState {
                if permissionState == .approved {
                    CameraLayerView(size: size, camera: $camera)
                        .overlay(alignment: .top) {
                            ScannerAnimation(size.height)
                        }
                }
                if permissionState == .denied {
                    VStack(spacing: 4) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: size.width * 0.15))
                            .foregroundStyle(.white)
                        Text("Permission denied")
                            .font(.caption)
                            .foregroundStyle(.red)
                        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                            Button("Go to Settings") { openURL(settingsURL) }
                                .font(.caption)
                                .foregroundStyle(.white)
                                .underline()
                        }
                    }
                    .fixedSize()
                }
            }
            shape.stroke(.white, lineWidth: 2)
        }
        .frame(width: size.width, height: size.height)
        .clipShape(shape)
    }

    @ViewBuilder
    private func ScannerAnimation(_ height: CGFloat) -> some View {
        Rectangle()
            .fill(theme.cardBackground)
            .frame(height: 2.5)
            .phaseAnimator([false, true], content: { content, isScanning in
                content
                    .shadow(color: .black.opacity(0.8), radius: 8, x: 0, y: isScanning ? 15 : -15)
                    .offset(y: isScanning ? height : 0)
            }, animation: { _ in
                .easeInOut(duration: 0.85).delay(0.1)
            })
    }

    private func toggle(_ status: Bool) {
        withAnimation(.interpolatingSpring(duration: 0.3, bounce: 0, initialVelocity: 0)) {
            isExpanding = status
        }
        if !status {
            DispatchQueue.global(qos: .background).async {
                camera.session.stopRunning()
            }
        }
    }

    var nonDynamicIslandHavingSpacing: Bool { false }
}

fileprivate struct CameraLayerView: UIViewRepresentable {
    var size: CGSize
    @Binding var camera: CameraProperties
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .init(origin: .zero, size: size))
        view.backgroundColor = .clear
        let layer = AVCaptureVideoPreviewLayer(session: camera.session)
        layer.frame = .init(origin: .zero, size: size)
        layer.videoGravity = .resizeAspectFill
        layer.masksToBounds = true
        view.layer.addSublayer(layer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: CameraLayerView
        init(parent: CameraLayerView) {
            self.parent = parent
            super.init()
            Task { setUpCamera() }
        }

        func setUpCamera() {
            do {
                let session = parent.camera.session
                let output = parent.camera.output
                guard !session.isRunning else { return }
                guard let device = AVCaptureDevice.DiscoverySession(
                    deviceTypes: [.builtInWideAngleCamera],
                    mediaType: .video,
                    position: .back
                ).devices.first else { return }

                let input = try AVCaptureDeviceInput(device: device)
                guard session.canAddInput(input), session.canAddOutput(output) else { return }

                session.beginConfiguration()
                session.addInput(input)
                session.addOutput(output)
                output.metadataObjectTypes = [.qr]
                output.setMetadataObjectsDelegate(self, queue: .main)
                session.commitConfiguration()
                DispatchQueue.global(qos: .background).async {
                    session.startRunning()
                }
            } catch {
                print(error.localizedDescription)
            }
        }
        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            if let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject, let code = object.stringValue {
                guard parent.camera.scannedCode == nil else { return }
                parent.camera.scannedCode = code
            }
        }
    }
}
