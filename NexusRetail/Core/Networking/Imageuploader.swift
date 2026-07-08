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
}
