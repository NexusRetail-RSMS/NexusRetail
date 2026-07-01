//
//  Storeimagecache.swift
//  NexusRetail
//
//  Created by ANOOP on 01/07/26.
//

import SwiftUI

// MARK: - Cache singleton

final class StoreImageCache {
    static let shared = StoreImageCache()

    private let memory = NSCache<NSString, UIImage>()
    private let session: URLSession

    private init() {
        memory.countLimit = 80
        memory.totalCostLimit = 120 * 1024 * 1024 // 120 MB memory cap

        let cache = URLCache(
            memoryCapacity: 20 * 1024 * 1024,   // 20 MB
            diskCapacity: 150 * 1024 * 1024,     // 150 MB on disk
            diskPath: "store_images"
        )
        let config = URLSessionConfiguration.default
        config.urlCache = cache
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.timeoutIntervalForRequest = 15
        session = URLSession(configuration: config)
    }

    // MARK: - Supabase transform URL
    func transformedURL(for rawURL: String) -> URL? {
        guard var components = URLComponents(string: rawURL) else { return nil }
        var items = components.queryItems ?? []
        if !items.contains(where: { $0.name == "width" }) {
            items.append(URLQueryItem(name: "width", value: "800"))
            items.append(URLQueryItem(name: "quality", value: "75"))
        }
        components.queryItems = items
        return components.url
    }

    // MARK: - Fetch (memory → disk → network)
    func image(for rawURL: String) async -> UIImage? {
        guard let url = transformedURL(for: rawURL) else { return nil }
        let key = url.absoluteString as NSString

        if let cached = memory.object(forKey: key) { return cached }

        do {
            let (data, _) = try await session.data(from: url)
            guard let image = UIImage(data: data) else { return nil }
            let cost = data.count
            memory.setObject(image, forKey: key, cost: cost)
            return image
        } catch {
            return nil
        }
    }
}

// MARK: - CachedStoreImage view

struct CachedStoreImage: View {
    let urlString: String?

    @State private var image: UIImage?
    @State private var isLoading = true

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .transition(.opacity.animation(.easeIn(duration: 0.25)))
            } else if isLoading {
                ShimmerPlaceholder()
            } else {
                Color.clear
            }
        }
        .task(id: urlString) {
            guard let rawURL = urlString, !rawURL.isEmpty else {
                isLoading = false
                return
            }
            isLoading = true
            image = await StoreImageCache.shared.image(for: rawURL)
            isLoading = false
        }
    }
}

// MARK: - Shimmer placeholder

private struct ShimmerPlaceholder: View {
    @State private var phase: CGFloat = -1.2

    var body: some View {
        GeometryReader { geo in
            LinearGradient(
                colors: [
                    Color.white.opacity(0.04),
                    Color.white.opacity(0.12),
                    Color.white.opacity(0.04)
                ],
                startPoint: UnitPoint(x: phase, y: 0),
                endPoint: UnitPoint(x: phase + 0.8, y: 1)
            )
        }
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                phase = 1.4
            }
        }
        .background(Color(hex: "1C1C1E"))
    }
}
