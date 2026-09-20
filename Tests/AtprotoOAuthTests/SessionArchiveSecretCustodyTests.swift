//
//  SessionArchiveSecretCustodyTests.swift
//  AtprotoOAuth
//
//  Proves the two properties PR A3 is about: the secret fields survive a
//  `SecretArchive` round-trip intact, and a plain coder refuses to write them.
//

import AtprotoOAuth
import Foundation
import OAuth4Swift
import SecretBytes
import Testing

@testable import AtprotoOAuth

@Suite("AtprotoOAuthAgent.SessionArchive secret custody")
struct SessionArchiveSecretCustodyTests {
	private func mockSessionArchive() -> OAuth.SessionState.Archive {
		var archive = OAuth.SessionState.Archive.mock()
		archive.tokenState.refreshToken = .mock(value: "refresh-token-abc")
		return archive
	}

	@Test("secrets and plain state survive a SecretArchive round-trip")
	func secretArchiveRoundTrip() throws {
		let oauth = mockSessionArchive()
		let archive = try AtprotoOAuthAgent.Archive(
			did: "did:plc:4yvwfwxfz5sney4twepuzdu7",
			session: oauth
		)

		let restored = try SecretArchive(encoding: archive)
			.decode(AtprotoOAuthAgent.Archive.self)

		let original = try #require(archive.session)
		let roundTripped = try #require(restored.session)

		// plain, view-needed state stays plain and intact
		#expect(roundTripped.clientId == original.clientId)
		#expect(roundTripped.issuingServer == original.issuingServer)
		#expect(roundTripped.tokenState.scopes == original.tokenState.scopes)
		#expect(
			roundTripped.tokenState.accessToken.expiry
				== original.tokenState.accessToken.expiry)

		// secrets restore into zeroizing storage, byte-for-byte
		#expect(
			roundTripped.tokenState.accessToken.value
				== original.tokenState.accessToken.value)
		#expect(
			roundTripped.tokenState.refreshToken?.value
				== original.tokenState.refreshToken?.value)
		#expect(roundTripped.dPopKey?.alg == original.dPopKey?.alg)
		#expect(roundTripped.dPopKey?.keyData == original.dPopKey?.keyData)
	}

	@Test("the secret-bearing archive restores the oauth4swift session")
	func restoresOAuthSession() throws {
		let oauth = mockSessionArchive()
		let archive = try AtprotoOAuthAgent.Archive(
			did: "did:plc:4yvwfwxfz5sney4twepuzdu7",
			session: oauth
		)

		let back = try #require(try archive.oauthSession)
		#expect(back.tokenState.accessToken.value == oauth.tokenState.accessToken.value)
		#expect(
			back.tokenState.refreshToken?.value
				== oauth.tokenState.refreshToken?.value)
		#expect(back.tokenState.accessToken.expiry == oauth.tokenState.accessToken.expiry)

		// the DPoP key reconstructs exactly
		let reMapped = try AtprotoOAuthAgent.SessionArchive(back)
		let originalSession = try #require(archive.session)
		#expect(reMapped.dPopKey?.keyData == originalSession.dPopKey?.keyData)
		#expect(reMapped.dPopKey?.alg == originalSession.dPopKey?.alg)
	}

	@Test("a plain coder refuses to write the secrets")
	func plainCoderThrows() throws {
		let archive = try AtprotoOAuthAgent.Archive(
			did: "did:plc:4yvwfwxfz5sney4twepuzdu7",
			session: mockSessionArchive()
		)
		#expect(throws: SecretArchiveError.secretOutsideSecretArchive) {
			_ = try JSONEncoder().encode(archive)
		}
	}

	// The whole-archive tripwire above proves only that *some* field is secret:
	// de-classifying any single field (e.g. the DPoP key back to plain `Data`)
	// would still let a still-secret sibling throw and the test pass. These pin
	// each secret-bearing sub-struct on its own, so each fails the day its own
	// field is de-classified.
	@Test("each secret-bearing sub-struct refuses a plain coder on its own")
	func perFieldTripwires() throws {
		let session = try AtprotoOAuthAgent.SessionArchive(mockSessionArchive())

		let dPopKey = try #require(session.dPopKey)
		#expect(throws: SecretArchiveError.secretOutsideSecretArchive) {
			_ = try JSONEncoder().encode(dPopKey)
		}

		#expect(throws: SecretArchiveError.secretOutsideSecretArchive) {
			_ = try JSONEncoder().encode(session.tokenState.accessToken)
		}

		let refreshToken = try #require(session.tokenState.refreshToken)
		#expect(throws: SecretArchiveError.secretOutsideSecretArchive) {
			_ = try JSONEncoder().encode(refreshToken)
		}
	}

	@Test("update folds a refreshed token state back into zeroizing custody")
	func updateTokenState() throws {
		let oauth = mockSessionArchive()
		var session = try AtprotoOAuthAgent.SessionArchive(oauth)
		let refreshed = OAuth.SessionState.TokenState.mock(
			accessToken: .mock(value: "new-access-token", expiresIn: 3600),
			refreshToken: .mock(value: "new-refresh-token")
		)
		try session.update(tokenState: refreshed)

		let back = try session.oauthArchive()
		#expect(back.tokenState.accessToken.value == "new-access-token")
		#expect(back.tokenState.refreshToken?.value == "new-refresh-token")
		// a non-nil Date survives the bridge's JSON hop exactly
		#expect(back.tokenState.accessToken.expiry == refreshed.accessToken.expiry)
	}
}
