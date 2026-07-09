//
//  ChoroplethWebView.swift
//  NexusRetail
//
//  Customer-footprint map rendered with Apache ECharts inside a WKWebView.
//  Fully offline (echarts.min.js + world GeoJSON are bundled), no API key
//  or account required. Plain white land, and each STORE is plotted as a
//  bubble at its real coordinates — sized/shaded (light = fewer, dark =
//  more) by order volume. Works globally and when a country is selected
//  (the map simply zooms in). Native pinch-zoom / drag-pan.
//

import SwiftUI
import WebKit
import MapKit

struct ChoroplethWebView: UIViewRepresentable {
    let storePoints: [StorePoint]
    /// DB country name selected in the dashboard filter (nil = world view).
    var focusCountry: String? = nil

    // Burgundy ramp (light = fewer, dark = more).
    private let colorLo = "#E9A9B6"
    private let colorHi = "#5E1220"

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .white
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        if let url = Bundle.main.url(forResource: "choropleth", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let coord = context.coordinator
        coord.applyBlock = { [weak webView] in
            guard let webView else { return }
            apply(into: webView, coord: coord)
        }
        if coord.isLoaded { apply(into: webView, coord: coord) }
    }

    // MARK: - Rendering

    private func apply(into webView: WKWebView, coord: Coordinator) {
        let dataSig = storePoints.map { "\($0.storeId):\($0.orderCount)" }.joined(separator: ",")
        if dataSig != coord.lastData {
            coord.lastData = dataSig
            renderPoints(into: webView)
        }
        applyFocus(into: webView)
    }

    private func renderPoints(into webView: WKWebView) {
        guard let geo = bundledJSON("countries", "geojson") else { return }
        let maxV = max(storePoints.map(\.orderCount).max() ?? 0, 1)
        let items = storePoints.map { p in
            "{\"name\":\(jsonString(p.name))," +
            "\"city\":\(jsonString(p.city ?? ""))," +
            "\"customers\":\(p.customerCount),\"orders\":\(p.orderCount)," +
            "\"value\":[\(p.longitude),\(p.latitude),\(p.orderCount)]}"
        }.joined(separator: ",")
        let js = "renderPoints(\(geo), [\(items)], \(maxV), \"\(colorLo)\", \"\(colorHi)\");"
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    private func applyFocus(into webView: WKWebView) {
        guard let country = focusCountry, let region = CountryMapRegion.regions[country] else {
            webView.evaluateJavaScript("resetView();", completionHandler: nil)
            return
        }
        let lng = region.center.longitude
        let lat = region.center.latitude
        let maxSpan = max(region.span.latitudeDelta, region.span.longitudeDelta)
        let zoom = min(max(60.0 / maxSpan, 2.0), 12.0)
        webView.evaluateJavaScript("focus(\(lng), \(lat), \(zoom));", completionHandler: nil)
    }

    // MARK: - Helpers

    private func bundledJSON(_ name: String, _ ext: String) -> String? {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else { return nil }
        return try? String(contentsOf: url, encoding: .utf8)
    }

    private func jsonString(_ s: String) -> String {
        if let data = try? JSONSerialization.data(withJSONObject: [s]),
           let arr = String(data: data, encoding: .utf8) {
            return String(arr.dropFirst().dropLast())
        }
        return "\"\(s)\""
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, WKNavigationDelegate {
        var isLoaded = false
        var lastData = ""
        var applyBlock: (() -> Void)?

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoaded = true
            applyBlock?()
        }
    }
}
