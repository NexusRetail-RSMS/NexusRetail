//
//  CustomerHeatmapView.swift
//  NexusRetail
//
//  Plain-white, label-free customer-footprint choropleth for the admin
//  "Top Customer Locations" card. Countries are drawn as vector shapes
//  (grey = no data, burgundy = shaded by distinct-customer count) on a
//  clean white background — no map tiles, no city/country labels.
//
//  Fully interactive: pinch to zoom, drag to pan. Auto-zooms to the
//  currently selected country. Tapping a data country shows a callout.
//

import SwiftUI
import CoreLocation

struct InteractiveChoroplethMap: View {
    @Environment(AppTheme.self) private var theme

    let footprint: [CountryFootprint]
    let countryPolygons: [CountryPolygon]
    /// When set (from the dashboard country filter), the map zooms to it.
    var focusCountry: String? = nil

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var selected: CountryFootprint?

    // Projection bounds (equirectangular, crops Antarctica/high Arctic).
    private let latMin = -60.0
    private let latSpan = 145.0   // -60 ... 85

    private var footprintByKey: [String: CountryFootprint] {
        Dictionary(footprint.map { (Self.canonical($0.country), $0) },
                   uniquingKeysWith: { a, _ in a })
    }
    private var maxCustomers: Int { max(footprint.map(\.customerCount).max() ?? 0, 1) }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack(alignment: .topLeading) {
                // Transformed vector map
                ZStack {
                    Color.white
                    Canvas { ctx, sz in
                        for country in countryPolygons {
                            let fp = footprintByKey[Self.canonical(country.name)]
                            var path = Path()
                            for ring in country.polygons where ring.count > 2 {
                                var sub = Path()
                                for (i, c) in ring.enumerated() {
                                    let p = project(c, in: sz)
                                    if i == 0 { sub.move(to: p) } else { sub.addLine(to: p) }
                                }
                                sub.closeSubpath()
                                path.addPath(sub)
                            }
                            ctx.fill(path, with: .color(color(for: fp)))
                            ctx.stroke(path, with: .color(.white), lineWidth: 0.3)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { loc in handleTap(loc, size: size) }
                }
                .frame(width: size.width, height: size.height)
                .scaleEffect(scale, anchor: .center)
                .offset(offset)
                .gesture(
                    MagnificationGesture()
                        .onChanged { v in scale = min(max(lastScale * v, 1), 8) }
                        .onEnded { _ in
                            lastScale = scale
                            if scale <= 1.01 {
                                withAnimation(.easeOut) { offset = .zero }
                                lastOffset = .zero
                            }
                        }
                        .simultaneously(with:
                            DragGesture()
                                .onChanged { v in
                                    offset = CGSize(width: lastOffset.width + v.translation.width,
                                                    height: lastOffset.height + v.translation.height)
                                }
                                .onEnded { _ in lastOffset = offset }
                        )
                )
                .clipped()

                // Callout (screen-space sibling, not scaled)
                if let sel = selected {
                    calloutBubble(sel)
                        .position(screenPosition(for: sel, size: size))
                        .transition(.scale(scale: 0.85).combined(with: .opacity))
                        .allowsHitTesting(false)
                }
            }
            .onChange(of: focusCountry) { _, newValue in
                focus(on: newValue, size: size)
            }
        }
    }

    // MARK: - Color ramp

    private func color(for fp: CountryFootprint?) -> Color {
        guard let fp, fp.customerCount > 0 else {
            return Color(white: 0.88)   // clean light-grey no-data land
        }
        let t = pow(Double(fp.customerCount) / Double(maxCustomers), 0.6)
        return theme.burgundy.opacity(0.25 + 0.72 * t)
    }

    // MARK: - Projection

    private func project(_ coord: CLLocationCoordinate2D, in size: CGSize) -> CGPoint {
        let x = (coord.longitude + 180.0) / 360.0
        let normLat = (coord.latitude - latMin) / latSpan
        return CGPoint(x: CGFloat(x) * size.width, y: CGFloat(1.0 - normLat) * size.height)
    }

    private func centroid(for name: String, size: CGSize) -> (center: CGPoint, bbox: CGRect)? {
        guard let country = countryPolygons.first(where: {
            Self.canonical($0.name) == Self.canonical(name)
        }), let ring = country.polygons.max(by: { $0.count < $1.count }) else { return nil }
        let pts = ring.map { project($0, in: size) }
        guard !pts.isEmpty else { return nil }
        let minX = pts.map(\.x).min()!, maxX = pts.map(\.x).max()!
        let minY = pts.map(\.y).min()!, maxY = pts.map(\.y).max()!
        let bbox = CGRect(x: minX, y: minY, width: max(maxX - minX, 1), height: max(maxY - minY, 1))
        return (CGPoint(x: bbox.midX, y: bbox.midY), bbox)
    }

    // MARK: - Focus / zoom to a country

    private func focus(on country: String?, size: CGSize) {
        guard let country, let info = centroid(for: country, size: size) else {
            withAnimation(.easeInOut(duration: 0.5)) { scale = 1; offset = .zero }
            lastScale = 1; lastOffset = .zero
            selected = nil
            return
        }
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let s = min(max(0.7 * min(size.width / info.bbox.width, size.height / info.bbox.height), 1.2), 8)
        let off = CGSize(width: (center.x - info.center.x) * s,
                         height: (center.y - info.center.y) * s)
        withAnimation(.easeInOut(duration: 0.6)) { scale = s; offset = off }
        lastScale = s; lastOffset = off
    }

    // MARK: - Tap hit-testing (logical coords)

    private func handleTap(_ loc: CGPoint, size: CGSize) {
        var hit: CountryFootprint?
        outer: for country in countryPolygons {
            guard let fp = footprintByKey[Self.canonical(country.name)], fp.customerCount > 0 else { continue }
            for ring in country.polygons where ring.count > 2 {
                let pts = ring.map { project($0, in: size) }
                if Self.point(loc, inside: pts) { hit = fp; break outer }
            }
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            selected = (hit?.id == selected?.id) ? nil : hit
        }
    }

    private static func point(_ p: CGPoint, inside poly: [CGPoint]) -> Bool {
        guard poly.count > 2 else { return false }
        var inside = false
        var j = poly.count - 1
        for i in 0..<poly.count {
            let a = poly[i], b = poly[j]
            if ((a.y > p.y) != (b.y > p.y)) &&
                (p.x < (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x) { inside.toggle() }
            j = i
        }
        return inside
    }

    // MARK: - Callout placement (logical -> screen via current transform)

    private func screenPosition(for fp: CountryFootprint, size: CGSize) -> CGPoint {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let logical = centroid(for: fp.country, size: size)?.center ?? center
        let sx = center.x + (logical.x - center.x) * scale + offset.width
        let sy = center.y + (logical.y - center.y) * scale + offset.height
        return CGPoint(x: min(max(sx, 70), size.width - 70),
                       y: min(max(sy - 24, 22), size.height - 22))
    }

    private func calloutBubble(_ fp: CountryFootprint) -> some View {
        VStack(spacing: 2) {
            Text("\(CountryMapRegion.flags[fp.country] ?? "📍") \(fp.country)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
            Text("\(fp.customerCount) customers · \(fp.orderCount) orders")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(RSMSColors.darkBurgundy)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.25), radius: 6, y: 2)
    }

    // MARK: - Name canonicalisation (DB name <-> GeoJSON name)

    private static let aliases: [String: String] = [
        "russian federation": "russia",
        "united states of america": "united states",
        "usa": "united states",
        "uk": "united kingdom",
        "uae": "united arab emirates",
        "slovak republic": "slovakia",
        "czech republic": "czechia"
    ]

    static func canonical(_ name: String) -> String {
        let k = name.lowercased().trimmingCharacters(in: .whitespaces)
        return aliases[k] ?? k
    }
}

// MARK: - Legend

struct CustomerHeatmapLegend: View {
    @Environment(AppTheme.self) private var theme

    var body: some View {
        HStack(spacing: 8) {
            Text("Fewer")
                .font(.system(size: 10))
                .foregroundColor(theme.secondaryText)

            HStack(spacing: 2) {
                ForEach(0..<5) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(theme.burgundy.opacity(0.25 + 0.72 * (Double(i) / 4.0)))
                        .frame(width: 18, height: 8)
                }
            }

            Text("More customers")
                .font(.system(size: 10))
                .foregroundColor(theme.secondaryText)

            Spacer()

            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(white: 0.88))
                    .frame(width: 12, height: 8)
                Text("No data")
                    .font(.system(size: 10))
                    .foregroundColor(theme.secondaryText)
            }
        }
    }
}
