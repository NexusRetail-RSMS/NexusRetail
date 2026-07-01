//
//  DesignSystem.swift
//  NexusRetail
//

import SwiftUI

/// Luxury design tokens for NexusRetail
extension Color {
    /// Deep Maroon / Red Primary
    static let nexusRed = Color(hex: "#720B0D")
    
    /// Warm Cream Background
    static let nexusBackground = Color(hex: "#FAF6F0")
    
    /// Gold/Bronze Accent
    static let nexusGold = Color(hex: "#A68153")
    
    /// Dark Brown/Black for text and solid dark buttons
    static let nexusDark = Color(hex: "#1A1513")
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

/// A primary button style matching the luxury aesthetic.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isEnabled ? Color.nexusDark : Color.gray.opacity(0.3))
            .foregroundColor(isEnabled ? Color.nexusBackground : .gray)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

/// A reusable KPI card for dashboards.
struct KPICardView: View {
    let title: String
    let value: String
    let icon: String
    let trend: String?
    var color: Color = RSMSColors.burgundy
    
    var body: some View {
        HStack(spacing: RSMSSpacing.sm) {
            // Single-color icon on the left
            ZStack {
                Circle()
                    .fill(color.opacity(0.18))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 20, weight: .semibold))
            }
            
            // Value + label on the right
            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(RSMSColors.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(RSMSColors.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, RSMSSpacing.md)
        .frame(height: 94) // Fixed height to ensure all cards match
        .background(color.opacity(0.04))
        .cornerRadius(RSMSRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: RSMSRadius.medium)
                .stroke(color.opacity(0.12), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

/// Custom shape that gives the header a smooth curved bottom edge
/// instead of a harsh straight line. Used in premium top headers.
public struct HeaderCurve: Shape {
    public init() {}
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: rect.maxX, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 20))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: rect.maxY - 20),
            control: CGPoint(x: rect.midX, y: rect.maxY + 10)
        )
        path.closeSubpath()
        return path
    }
}

/// A reusable search bar styled after the iOS system search bar.
/// Rounded pill with a magnifying glass on the left and a mic icon
/// on the right (collapses to xmark when text is present).
struct NexusSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search"
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(RSMSColors.secondaryText)

            TextField(placeholder, text: $text)
                .font(.system(size: 17))
                .foregroundStyle(RSMSColors.primaryText)
                .focused($isFocused)
                .submitLabel(.search)

            Spacer(minLength: 0)

            if text.isEmpty {
                Image(systemName: "mic.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(RSMSColors.secondaryText)
                    .transition(.opacity.combined(with: .scale))
            } else {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 17))
                        .foregroundStyle(RSMSColors.secondaryText)
                }
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.systemFill))
        )
        .animation(.easeInOut(duration: 0.18), value: text.isEmpty)
        .onTapGesture { isFocused = true }
    }
}

/// A drop-in replacement for AsyncImage that caches images in memory/disk
/// to prevent reloading the same image repeatedly.
public struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    @State private var image: Image?

    public init(url: URL?, @ViewBuilder content: @escaping (Image) -> Content, @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }

    public var body: some View {
        if let image = image {
            content(image)
        } else {
            placeholder()
                .task(id: url) {
                    await loadImage()
                }
        }
    }

    private func loadImage() async {
        guard let url = url else { return }
        
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        
        if let cachedResponse = URLCache.shared.cachedResponse(for: request),
           let uiImage = UIImage(data: cachedResponse.data) {
            self.image = Image(uiImage: uiImage)
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
               let uiImage = UIImage(data: data) {
                let cachedData = CachedURLResponse(response: response, data: data)
                URLCache.shared.storeCachedResponse(cachedData, for: request)
                self.image = Image(uiImage: uiImage)
            }
        } catch {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                // Ignore cancellation errors
            } else {
                print("Failed to load image: \(error)")
            }
        }
    }
}
