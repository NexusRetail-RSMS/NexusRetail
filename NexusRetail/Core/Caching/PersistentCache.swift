//
//  Persistentcache.swift
//  NexusRetail
//
//  Created by ANOOP on 10/07/26.
//

import Foundation

actor PersistentCache {
    static let shared = PersistentCache()

    private let cacheDirectory: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = caches.appendingPathComponent("DataCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    /// Save a Codable value under a key, tagged with the time it was written.
    func save<T: Codable>(_ value: T, forKey key: String) {
        let envelope = CacheEnvelope(savedAt: Date(), value: value)
        guard let data = try? encoder.encode(envelope) else { return }
        try? data.write(to: fileURL(for: key), options: .atomic)
    }

    /// Load a cached value regardless of age. Returns nil if nothing is cached
    /// or if it fails to decode (e.g. the model shape changed).
    func load<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = try? Data(contentsOf: fileURL(for: key)) else { return nil }
        guard let envelope = try? decoder.decode(CacheEnvelope<T>.self, from: data) else { return nil }
        return envelope.value
    }

    /// Load a cached value only if it's younger than maxAge. Use this when staleness
    /// would be actively wrong to show (e.g. live pricing) rather than just outdated.
    func load<T: Codable>(_ type: T.Type, forKey key: String, maxAge: TimeInterval) -> T? {
        guard let data = try? Data(contentsOf: fileURL(for: key)) else { return nil }
        guard let envelope = try? decoder.decode(CacheEnvelope<T>.self, from: data) else { return nil }
        guard Date().timeIntervalSince(envelope.savedAt) <= maxAge else { return nil }
        return envelope.value
    }

    func remove(forKey key: String) {
        try? FileManager.default.removeItem(at: fileURL(for: key))
    }

    func clearAll() {
        try? FileManager.default.removeItem(at: cacheDirectory)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    private func fileURL(for key: String) -> URL {
        let safeKey = key.replacingOccurrences(of: "/", with: "_")
        return cacheDirectory.appendingPathComponent("\(safeKey).json")
    }
}

private struct CacheEnvelope<T: Codable>: Codable {
    let savedAt: Date
    let value: T
}
