import SwiftUI

extension Color {
    static let nexusRed = Color(hex: "#720B0D")
    static let nexusBackground = Color(hex: "#FAF6F0")
    static let nexusGold = Color(hex: "#A68153")
    static let nexusDark = Color(hex: "#1A1513")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

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

struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct HeroRevenueCard: View {
    let title: String
    let value: String
    let trend: String?
    let sparklineValues: [Double]
    var onTap: (() -> Void)? = nil

    @State private var animateChart = false

    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(title)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.nexusDark.opacity(0.55))

                        Text(value)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(Color.nexusDark)
                            .contentTransition(.numericText())
                    }

                    Spacer()

                    ZStack {
                        Circle()
                            .fill(Color.nexusGold.opacity(0.18))
                            .frame(width: 40, height: 40)

                        Image(systemName: "indianrupeesign")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color.nexusGold)
                    }
                }

                if let trend, !trend.isEmpty {
                    trendBadge(trend)
                        .padding(.top, 10)
                }

                Spacer(minLength: 20)
            }
            .padding(RSMSSpacing.lg)
            .frame(maxWidth: .infinity)
            .frame(height: 168)
            .background(
                ZStack {
                    Color.white
                    sparkline
                        .opacity(0.7)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: RSMSRadius.large, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: RSMSRadius.large, style: .continuous)
                    .strokeBorder(Color.nexusDark.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(CardPressStyle())
        .onAppear {
            withAnimation(.easeOut(duration: 1.1)) {
                animateChart = true
            }
        }
    }

    private var chartColor: Color {
        guard let first = sparklineValues.first, let last = sparklineValues.last, first != last else {
            return Color.nexusDark.opacity(0.3)
        }
        return last > first ? Color(hex: "2FA876") : Color(hex: "D9534F")
    }

    private var sparkline: some View {
        GeometryReader { geo in
            let values = sparklineValues.count > 1 ? sparklineValues : [0, 0]
            let maxValue = values.max() ?? 1
            let minValue = values.min() ?? 0
            let range = max(maxValue - minValue, 1)
            let stepX = geo.size.width / CGFloat(values.count - 1)

            let points = values.enumerated().map { index, value -> CGPoint in
                let x = CGFloat(index) * stepX
                let normalized = (value - minValue) / range
                let y = geo.size.height - (CGFloat(normalized) * geo.size.height * 0.65) - geo.size.height * 0.1
                return CGPoint(x: x, y: y)
            }

            let linePath = smoothPath(through: points)

            let fillPath = Path { fill in
                fill.addPath(linePath)
                fill.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                fill.addLine(to: CGPoint(x: 0, y: geo.size.height))
                fill.closeSubpath()
            }

            ZStack {
                fillPath
                    .fill(
                        LinearGradient(
                            colors: [chartColor.opacity(0.28), chartColor.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                linePath
                    .trim(from: 0, to: animateChart ? 1 : 0)
                    .stroke(chartColor.opacity(0.9), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
        }
    }

    private func smoothPath(through points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        guard points.count > 1 else { return path }

        for index in 0..<points.count - 1 {
            let p0 = points[max(index - 1, 0)]
            let p1 = points[index]
            let p2 = points[index + 1]
            let p3 = points[min(index + 2, points.count - 1)]

            let control1 = CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6)
            let control2 = CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6)

            path.addCurve(to: p2, control1: control1, control2: control2)
        }
        return path
    }

    @ViewBuilder
    private func trendBadge(_ trend: String) -> some View {
        let isPositive = !trend.hasPrefix("-")
        let tint = isPositive ? Color(hex: "2FA876") : Color(hex: "D9534F")
        HStack(spacing: 3) {
            Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 10, weight: .bold))
            Text(trend)
                .font(.system(size: 11.5, weight: .semibold))
        }
        .foregroundColor(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tint.opacity(0.12), in: Capsule())
    }
}

struct KPICardView: View {
    let title: String
    let value: String
    let icon: String
    let trend: String?
    var color: Color = RSMSColors.burgundy

    var body: some View {
        FlatKPICard(title: title, value: value, icon: icon, color: color)
    }
}

struct FlatKPICard: View {
    let title: String
    let value: String
    let icon: String
    var color: Color = RSMSColors.burgundy
    var onTap: (() -> Void)? = nil

    @State private var titleWraps = false
    private let singleLineHeight: CGFloat = 14

    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Spacer()
                ZStack {
                    Circle()
                        .fill(color.opacity(0.14))
                        .frame(width: 34, height: 34)

                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundColor(Color.nexusDark)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .contentTransition(.numericText())

                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.nexusDark.opacity(0.5))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .onAppear {
                                        titleWraps = geo.size.height > singleLineHeight + 2
                                    }
                            }
                        )
                }
                .padding(.top, titleWraps ? 6 : 0)
                .animation(.easeOut(duration: 0.2), value: titleWraps)

                Spacer()
            }
            .padding(RSMSSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 120)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: RSMSRadius.large, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: RSMSRadius.large, style: .continuous)
                    .strokeBorder(Color.nexusDark.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(CardPressStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

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
                .fill(.ultraThinMaterial)
        )
        .animation(.easeInOut(duration: 0.18), value: text.isEmpty)
        .onTapGesture { isFocused = true }
    }
}

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
            } else {
                print("Failed to load image: \(error)")
            }
        }
    }
}
