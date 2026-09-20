//
//  SessionArchiveSecretCustodyTests.swift
//  AtprotoOAuthTests
//
//  The archive's secrets live in oauth4swift now — it holds the DPoP P-256
//  scalar and the access/refresh token values as `@SecretField` `SecretBytes`.
//  These tests prove the properties this package relies on: the whole archive
//  round-trips its secrets intact through a `SecretArchive`, and a plain coder
//  refuses to write them.
//

import Foundation
import OAuth4Swift
import SecretBytes
import Testing

@testable import AtprotoOAuth

@Suite("AtprotoOAuthAgent.Archive secret custody")
struct SessionArchiveSecretCustodyTests {
	private func mockSessionArchive() throws -> OAuth.SessionState.Archive {
		.init(
			clientId: "app.example.com",
			dPopKey: .generateP256(),
			issuingServer: "issuer.example.com",
			grantScopes: ["atproto"],
			tokenState: try .mock(
				accessToken: try .mock(value: "access-token-abc"),
				refreshToken: try .mock(value: "refresh-token-abc"),
				scopes: ["atproto"]
			)
		)
	}

	private func plaintext(of secret: SecretBytes) -> String {
		secret.withUnsafeBytes { String(decoding: $0, as: UTF8.self) }
	}

	@Test("secrets and plain state survive a SecretArchive round-trip")
	func secretArchiveRoundTrip() throws {
		let oauth = try mockSessionArchive()
		let archive = AtprotoOAuthAgent.Archive(
			did: "did:plc:4yvwfwxfz5sney4twepuzdu7",
			session: oauth
		)

		let restored = try SecretArchive(encoding: archive)
			.decode(AtprotoOAuthAgent.Archive.self)

		let original = try #require(archive.session)
		let roundTripped = try #require(restored.session)

		//plain, view-needed state stays plain and intact
		#expect(restored.did == archive.did)
		#expect(roundTripped.clientId == original.clientId)
		#expect(roundTripped.issuingServer == original.issuingServer)
		#expect(roundTripped.tokenState.scopes == original.tokenState.scopes)
		#expect(
			roundTripped.tokenState.accessToken.expiry
				== original.tokenState.accessToken.expiry)

		//secrets restore into zeroizing storage, byte-for-byte
		#expect(
			roundTripped.tokenState.accessToken.value
				== original.tokenState.accessToken.value)
		#expect(plaintext(of: roundTripped.tokenState.accessToken.value).isEmpty == false)
		#expect(
			roundTripped.tokenState.refreshToken?.value
				== original.tokenState.refreshToken?.value)
		#expect(roundTripped.dPopKey?.alg == original.dPopKey?.alg)
		#expect(roundTripped.dPopKey?.keyData == original.dPopKey?.keyData)
	}

	@Test("the archive restores the oauth4swift session")
	func restoresOAuthSession() throws {
		let oauth = try mockSessionArchive()
		let archive = AtprotoOAuthAgent.Archive(
			did: "did:plc:4yvwfwxfz5sney4twepuzdu7",
			session: oauth
		)

		let back = try #require(archive.session)
		#expect(back.tokenState.accessToken.value == oauth.tokenState.accessToken.value)
		#expect(plaintext(of: back.tokenState.accessToken.value) == "access-token-abc")
		#expect(
			back.tokenState.refreshToken?.value
				== oauth.tokenState.refreshToken?.value)
		#expect(back.dPopKey?.keyData == oauth.dPopKey?.keyData)
	}

	@Test("a plain coder refuses to write the secrets")
	func plainCoderThrows() throws {
		let archive = AtprotoOAuthAgent.Archive(
			did: "did:plc:4yvwfwxfz5sney4twepuzdu7",
			session: try mockSessionArchive()
		)
		#expect(throws: SecretArchiveError.secretOutsideSecretArchive) {
			_ = try JSONEncoder().encode(archive)
		}
	}
}
