//
//  Imageuploader.swift
//  NexusRetail
//
//  Created by ANOOP on 01/07/26.
//

import Foundation
import Supabase

enum ImageUploaderError: Error {
    case compressionFailed
    case missingConfig
    case uploadFailed(status: Int, body: String)
}

enum ImageUploader {
    static func upload(data: Data, bucket: String, folder: String) async throws -> String {
        let fileName = "\(UUID().uuidString).jpg"
        let path = "\(folder)/\(fileName)"

        try await SupabaseManager.shared.client.storage
            .from(bucket)
            .upload(path, data: data, options: FileOptions(contentType: "image/jpeg"))

        let publicURL = try SupabaseManager.shared.client.storage
            .from(bucket)
            .getPublicURL(path: path)

        return publicURL.absoluteString
    }

    /// Resilient upload that hits the Supabase Storage REST endpoint directly using a real
    /// URLSession **upload task**. The SDK attaches the body to a data task, which the iOS
    /// simulator frequently drops mid-stream with NSURLError -1005. An upload task streams
    /// the payload and is far more reliable. Also enables `waitsForConnectivity`.
    static func uploadDirect(data: Data, bucket: String, folder: String) async throws -> String {
        guard
            let baseURLString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
            let anonKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
            let baseURL = URL(string: baseURLString)
        else {
            throw ImageUploaderError.missingConfig
        }

        let fileName = "\(UUID().uuidString).jpg"
        let path = "\(folder)/\(fileName)"

        // Prefer the signed-in user's access token; fall back to the anon key.
        let accessToken = (try? await SupabaseManager.shared.client.auth.session.accessToken) ?? anonKey

        let uploadURL = baseURL
            .appendingPathComponent("storage/v1/object")
            .appendingPathComponent(bucket)
            .appendingPathComponent(path)

        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "x-upsert")
        request.setValue("3600", forHTTPHeaderField: "cache-control")

        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        let session = URLSession(configuration: config)

        // Upload task (streams `data`) instead of a data task with an httpBody.
        let (respData, response) = try await session.upload(for: request, from: data)

        guard let http = response as? HTTPURLResponse else {
            throw ImageUploaderError.uploadFailed(status: -1, body: "No HTTP response")
        }
        guard (200...299).contains(http.statusCode) else {
            let body = String(data: respData, encoding: .utf8) ?? ""
            throw ImageUploaderError.uploadFailed(status: http.statusCode, body: body)
        }

        let publicURL = try SupabaseManager.shared.client.storage
            .from(bucket)
            .getPublicURL(path: path)

        return publicURL.absoluteString
    }
}
