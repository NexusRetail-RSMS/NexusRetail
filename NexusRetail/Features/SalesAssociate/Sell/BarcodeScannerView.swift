import SwiftUI
import PhotosUI
import CoreImage

struct BarcodeScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SellViewModel.self) private var viewModel
    @Environment(SessionStore.self) private var sessionStore
    @Binding var path: NavigationPath
    
    @State private var allProducts: [POSProduct] = []
    @State private var scannedProduct: POSProduct? = nil
    @State private var isScanning = true
    @State private var selectedPhoto: PhotosPickerItem? = nil
    
    var body: some View {
        ZStack {
            RSMSColors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Custom Curved Header
                    customHeaderSection
                    
                    if scannedProduct == nil {
                        // Scanner view
                        scannerViewSection
                    } else if let product = scannedProduct {
                        // Details and alternatives
                        productDetailSection(product)
                    }
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarHidden(true)
        .onAppear {
            scannedProduct = nil
            isScanning = true
        }
        .task {
            allProducts = await POSProductRepository.shared.fetchProducts(storeID: sessionStore.currentUser?.storeID)
        }
    }
    
    // MARK: - Header
    private var customHeaderSection: some View {
        HStack(alignment: .center, spacing: RSMSSpacing.md) {
            Button {
                if scannedProduct != nil {
                    withAnimation {
                        scannedProduct = nil
                        isScanning = true
                    }
                } else {
                    dismiss()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .accessibilityLabel("Back")
            
            VStack(alignment: .leading, spacing: 2) {
                Text(scannedProduct == nil ? "Scan Barcode" : scannedProduct!.name)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(scannedProduct == nil ? "Barcode Scanner" : scannedProduct!.sku)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, 60)
        .padding(.bottom, RSMSSpacing.xxxl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [RSMSColors.burgundy, RSMSColors.darkBurgundy],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(HeaderCurve())
    }
    
    private var scannerViewSection: some View {
        VStack(spacing: 32) {
            Text("Point camera at product barcode")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(RSMSColors.secondaryText)
                .multilineTextAlignment(.center)
            
            // Live Camera Viewfinder
            ZStack {
                CameraScannerView { scannedCode in
                    // Extract SKU if it's a nexus://product URL
                    let sku: String
                    if scannedCode.hasPrefix("nexus://product/") {
                        sku = scannedCode.replacingOccurrences(of: "nexus://product/", with: "")
                    } else {
                        sku = scannedCode
                    }
                    simulateScan(forSku: sku)
                }
                .frame(height: 300)
                .cornerRadius(20)
                
                // Overlay outline
                RoundedRectangle(cornerRadius: 20)
                    .stroke(RSMSColors.burgundy, lineWidth: 2)
                    .frame(height: 300)
            }
            .padding(.horizontal, RSMSSpacing.lg)
            
            // Simulator Controls
            VStack(alignment: .leading, spacing: 14) {
                // Photo picker for simulator QR testing
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    HStack {
                        Image(systemName: "photo")
                        Text("Upload QR Code Image")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(RSMSColors.primaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.gray.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .onChange(of: selectedPhoto) { _, newItem in
                    processSelectedPhoto(newItem)
                }
            }
            .padding(.horizontal, RSMSSpacing.lg)
        }
        .padding(.top, 24)
        .padding(.bottom, 48)
    }
    
    private func simulateScan(forSku sku: String) {
        if let match = allProducts.first(where: { $0.sku == sku }) {
            withAnimation {
                isScanning = false
                scannedProduct = match
                viewModel.originalUnavailableProduct = match
            }
        }
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
                    
                    // Parse nexus://product/SKU format
                    let skuCode = qrCodeString.replacingOccurrences(of: "nexus://product/", with: "")
                    
                    await MainActor.run {
                        simulateScan(forSku: skuCode)
                    }
                } else {
                    print("No QR code found in selected image.")
                }
            }
        }
    }
    
    // MARK: - Product Detail & Alternatives for Out-of-stock
    private func productDetailSection(_ product: POSProduct) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            // Main Product Detail Card
            HStack(spacing: 20) {
                AsyncImage(url: URL(string: product.imageUrl ?? "")) { phase in
                    if let image = phase.image {
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Color.gray.opacity(0.1)
                            .overlay(Image(systemName: "shippingbox"))
                    }
                }
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(product.name)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(RSMSColors.primaryText)
                    
                    Text("Category: \(product.category)  •  Size: \(product.size)")
                        .font(.system(size: 13))
                        .foregroundColor(RSMSColors.secondaryText)
                    
                    Text("$\(String(format: "%.2f", product.price))")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(RSMSColors.burgundy)
                    
                    if product.stock > 0 {
                        // In stock banner
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("In Stock (\(product.stock) available)")
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(RSMSColors.success)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(RSMSColors.success.opacity(0.08))
                        .clipShape(Capsule())
                        .padding(.top, 4)
                    } else {
                        // Out of stock banner
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                            Text("Out of Stock")
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(RSMSColors.error)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(RSMSColors.error.opacity(0.08))
                        .clipShape(Capsule())
                        .padding(.top, 4)
                    }
                }
                Spacer()
            }
            .padding(18)
            .background(RSMSColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(RSMSColors.cardBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
            
            if product.stock > 0 {
                // In Stock Actions
                VStack(spacing: 14) {
                    Button {
                        // Add to cart and begin checkout
                        viewModel.addToCart(product: product)
                        path.append(POSFlowDestination.checkout)
                    } label: {
                        HStack {
                            Text("Begin Checkout")
                                .font(.system(size: 16, weight: .bold))
                            Spacer()
                            Image(systemName: "arrow.right")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
                        .background(RSMSColors.burgundy)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: RSMSColors.burgundy.opacity(0.2), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        // Add to cart and resume scanning
                        viewModel.addToCart(product: product)
                        withAnimation {
                            scannedProduct = nil
                            isScanning = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: "barcode.viewfinder")
                            Text("Add to Cart & Scan More")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(RSMSColors.burgundy)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(RSMSColors.burgundy, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            } else {
                // Suggested Alternatives Checklist (Out of Stock)
                VStack(alignment: .leading, spacing: 14) {
                    Text("Suggested Alternatives")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(RSMSColors.darkBrown)
                    
                    HStack(spacing: 12) {
                        checklistBadge("Same Category")
                        checklistBadge("Similar Price")
                        checklistBadge("Same Size")
                    }
                    .padding(.bottom, 6)
                    
                    // Fetch and list alternatives
                    let alternatives = getAlternatives(for: product)
                    if alternatives.isEmpty {
                        Text("No suitable alternatives found in stock.")
                            .font(.system(size: 14))
                            .foregroundColor(RSMSColors.secondaryText)
                            .padding(.vertical, 10)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(alternatives) { alt in
                                alternativeRow(alt)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, RSMSSpacing.lg)
        .padding(.bottom, RSMSSpacing.xxl)
    }
    
    private func checklistBadge(_ text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .bold))
            Text(text)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundColor(RSMSColors.burgundy)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(RSMSColors.burgundy.opacity(0.08))
        .clipShape(Capsule())
    }
    
    private func alternativeRow(_ alt: POSProduct) -> some View {
        HStack(spacing: 14) {
            AsyncImage(url: URL(string: alt.imageUrl ?? "")) { phase in
                if let image = phase.image {
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color.gray.opacity(0.1)
                }
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(alt.name)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(RSMSColors.primaryText)
                
                Text("Price: $\(String(format: "%.2f", alt.price))  •  Size: \(alt.size)")
                    .font(.system(size: 11))
                    .foregroundColor(RSMSColors.secondaryText)
            }
            
            Spacer()
            
            Button {
                // Add to cart as alternative
                viewModel.isAlternativeSuggested = true
                viewModel.addToCart(product: alt, isAlternative: true)
                path.append(POSFlowDestination.cart)
            } label: {
                Text("Add")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(RSMSColors.burgundy)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(12)
        .background(RSMSColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(RSMSColors.cardBorder, lineWidth: 1)
        )
    }
    
    private func getAlternatives(for product: POSProduct) -> [POSProduct] {
        // Try ML-powered recommendations first
        let mlRecommendations = RecommendationService.shared.getRecommendedProducts(
            for: product,
            from: allProducts,
            count: 5
        )
        
        if !mlRecommendations.isEmpty {
            return mlRecommendations
        }
        
        // Fallback: same category, stock > 0, not itself, similar price
        return allProducts.filter { item in
            item.id != product.id &&
            item.category == product.category &&
            item.stock > 0 &&
            abs(item.price - product.price) / product.price <= 0.3
        }
    }
}

// MARK: - Camera Scanner View
import AVFoundation

struct CameraScannerView: UIViewControllerRepresentable {
    
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: CameraScannerView
        
        init(parent: CameraScannerView) {
            self.parent = parent
        }
        
        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            if let metadataObject = metadataObjects.first {
                guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
                guard let stringValue = readableObject.stringValue else { return }
                
                // Vibrate on successful scan
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                
                parent.didFindCode(stringValue)
            }
        }
    }
    
    var didFindCode: (String) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> ScannerViewController {
        let viewController = ScannerViewController()
        viewController.delegate = context.coordinator
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {
        // No updates needed for now
    }
}

class ScannerViewController: UIViewController {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var delegate: AVCaptureMetadataOutputObjectsDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(delegate, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr, .ean8, .ean13, .pdf417]
        } else {
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (captureSession?.isRunning == false) {
            DispatchQueue.global(qos: .background).async {
                self.captureSession.startRunning()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }
}
