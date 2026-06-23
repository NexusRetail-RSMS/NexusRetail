//
//  SupabaseManager.swift
//  NexusRetail
//

import Foundation
import Supabase

/// A singleton holding the configured SupabaseClient.
/// Reads the Supabase URL and anon key from Info.plist.
class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              let anonKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
              let url = URL(string: urlString) else {
            fatalError("Supabase configuration missing or invalid. Please ensure SUPABASE_URL and SUPABASE_ANON_KEY are set in Info.plist (via Config.xcconfig).")
        }
        
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: anonKey,
            options: SupabaseClientOptions(
                auth: SupabaseClientOptions.AuthOptions(
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }
}
