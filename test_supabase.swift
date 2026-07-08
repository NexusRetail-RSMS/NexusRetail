import Supabase
import Foundation

func test(client: SupabaseClient) async throws {
    let aal = try await client.auth.mfa.getAuthenticatorAssuranceLevel()
    let aalStatus = aal.currentLevel
    let factors = try await client.auth.mfa.listFactors()
    
    let enrollRes = try await client.auth.mfa.enroll(params: .init(factorType: .totp))
    let challengeRes = try await client.auth.mfa.challenge(params: .init(factorId: enrollRes.id))
    let verifyRes = try await client.auth.mfa.verify(params: .init(factorId: enrollRes.id, challengeId: challengeRes.id, code: "123456"))
}
