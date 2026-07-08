//
//  MFAService.swift
//  NexusRetail
//

import Foundation
import Supabase

struct MFAService {
    private var client: SupabaseClient {
        SupabaseManager.shared.client
    }
    
    /// Checks the current Authenticator Assurance Level (AAL) and active MFA factors.
    func checkMFAStatus() async throws -> (aal: Auth.AuthMFAGetAuthenticatorAssuranceLevelResponse, factors: [Auth.Factor]) {
        let aal = try await client.auth.mfa.getAuthenticatorAssuranceLevel()
        let factorsResponse = try await client.auth.mfa.listFactors()
        // 'totp' already contains only verified TOTP factors
        return (aal, factorsResponse.totp)
    }
    
    /// Requests a new TOTP enrollment. Returns the factor ID and the TOTP details (URI, secret).
    func enroll() async throws -> Auth.AuthMFAEnrollResponse {
        return try await client.auth.mfa.enroll(params: .totp(issuer: "NexusRetail"))
    }
    
    /// Creates an MFA challenge for the given factor ID.
    func challenge(factorId: String) async throws -> Auth.AuthMFAChallengeResponse {
        return try await client.auth.mfa.challenge(params: Auth.MFAChallengeParams(factorId: factorId))
    }
    
    /// Verifies the 6-digit code against the created challenge.
    func verify(factorId: String, challengeId: String, code: String) async throws -> Auth.AuthMFAVerifyResponse {
        return try await client.auth.mfa.verify(
            params: Auth.MFAVerifyParams(
                factorId: factorId,
                challengeId: challengeId,
                code: code
            )
        )
    }
}
