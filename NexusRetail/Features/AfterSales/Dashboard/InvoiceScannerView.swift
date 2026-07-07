import SwiftUI
import PhotosUI
import CoreImage
import AVFoundation

struct InvoiceScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var path: NavigationPath
    
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var invoiceNumber: String = ""
    
    var body: some View {
        ZStack(alignment: .top) {
            RSMSColors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    scannerViewSection
                }
                .padding(.top, 120)
            }
            .ignoresSafeArea(edges: .top)
            
            customHeaderSection
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Header
    private var customHeaderSection: some View {
        HStack(alignment: .center, spacing: RSMSSpacing.md) {
            Button {
                dismiss()
            } label: {
                ZStack {
                    Circle()
                        .fill(RSMSColors.burgundy.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(RSMSColors.primaryText)
                }
            }
            .accessibilityLabel("Back")
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Scan Bill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(RSMSColors.primaryText)
                    .lineLimit(1)
                
                Text("Invoice Scanner")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(RSMSColors.secondaryText)
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
    
    private var scannerViewSection: some View {
        VStack(spacing: 32) {
            Text("Point camera at bill barcode")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(RSMSColors.secondaryText)
                .multilineTextAlignment(.center)
            
            // Live Camera Viewfinder
            ZStack {
                CameraScannerView { scannedCode in
                    // Extract invoice ID if it's a nexus://invoice URL
                    let id: String
                    if scannedCode.hasPrefix("nexus://invoice/") {
                        id = scannedCode.replacingOccurrences(of: "nexus://invoice/", with: "")
                    } else {
                        id = scannedCode
                    }
                    simulateScan(forInvoice: id)
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
            VStack(alignment: .center, spacing: 16) {
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
                
                Text("OR")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(RSMSColors.secondaryText)
                    .padding(.vertical, 4)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Invoice Number")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(RSMSColors.primaryText)
                    
                    TextField("Enter invoice number", text: $invoiceNumber)
                        .font(.system(size: 15, weight: .medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(RSMSColors.cardBorder, lineWidth: 1)
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
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(invoiceNumber.isEmpty ? RSMSColors.secondaryText.opacity(0.5) : RSMSColors.burgundy)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(invoiceNumber.isEmpty)
                    .padding(.top, 8)
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                // Quick Test Actions
                VStack(spacing: 12) {
                    Button {
                        simulateScan(forInvoice: "ORD-\(Int.random(in: 1000...9999))")
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Simulate Valid Bill (< 7 Days)")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(RSMSColors.primaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    
                    Button {
                        simulateScan(forInvoice: "ORD-\(Int.random(in: 1000...9999))-EXPIRED")
                    } label: {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text("Simulate Expired Bill (> 7 Days)")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(RSMSColors.error)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(RSMSColors.error.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, RSMSSpacing.lg)
        }
        .padding(.top, 24)
        .padding(.bottom, 48)
    }
    
    private func simulateScan(forInvoice invoiceId: String) {
        // Navigate to next screen with the scanned invoice ID
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
                } else {
                    print("No QR code found in selected image.")
                }
            }
        }
    }
}
