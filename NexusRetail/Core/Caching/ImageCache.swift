import UIKit

actor ImageCache {
    static let shared = ImageCache()

    private let memoryCache = NSCache<NSString, UIImage>()
    private let diskCacheURL: URL
    private var inFlightTasks: [String: Task<UIImage?, Never>] = [:]

    private init() {
        memoryCache.countLimit = 150
        memoryCache.totalCostLimit = 100 * 1024 * 1024

        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        diskCacheURL = caches.appendingPathComponent("ImageCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
    }

    func image(for urlString: String) async -> UIImage? {
        let key = cacheKey(for: urlString)

        if let cached = memoryCache.object(forKey: key as NSString) {
            return cached
        }

        if let existingTask = inFlightTasks[key] {
            return await existingTask.value
        }

        let task = Task<UIImage?, Never> {
            if let diskImage = loadFromDisk(key: key) {
                await memoryCache.setObject(diskImage, forKey: key as NSString, cost: diskImage.cost)
                return diskImage
            }

            guard let url = URL(string: urlString) else { return nil }

            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                guard let httpResponse = response as? HTTPURLResponse,
                      200..<300 ~= httpResponse.statusCode,
                      let image = UIImage(data: data) else {
                    return nil
                }

                await memoryCache.setObject(image, forKey: key as NSString, cost: image.cost)
                saveToDisk(data: data, key: key)
                return image
            } catch {
                return nil
            }
        }

        inFlightTasks[key] = task
        let result = await task.value
        inFlightTasks[key] = nil
        return result
    }

    func prefetch(_ urlStrings: [String]) {
        for urlString in urlStrings {
            Task { _ = await image(for: urlString) }
        }
    }

    func clearMemory() {
        memoryCache.removeAllObjects()
    }

    func clearDisk() {
        try? FileManager.default.removeItem(at: diskCacheURL)
        try? FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
    }

    // MARK: - Disk helpers

    private func cacheKey(for urlString: String) -> String {
        var hasher = Hasher()
        hasher.combine(urlString)
        return String(hasher.finalize(), radix: 16)
    }

    private func diskURL(for key: String) -> URL {
        diskCacheURL.appendingPathComponent(key)
    }

    private func loadFromDisk(key: String) -> UIImage? {
        let fileURL = diskURL(for: key)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }

    private func saveToDisk(data: Data, key: String) {
        try? data.write(to: diskURL(for: key), options: .atomic)
    }
}

private extension UIImage {
    var cost: Int {
        guard let cgImage = cgImage else { return 1 }
        return cgImage.bytesPerRow * cgImage.height
    }
}
