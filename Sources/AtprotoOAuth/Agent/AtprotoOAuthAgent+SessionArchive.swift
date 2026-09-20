//
//  AtprotoOAuthAgent+SessionArchive.swift
//  AtprotoOAuth
//
//  Created by Mark @ Germ on 9/20/26.
//

import Foundation
import OAuth4Swift
import SecretBytes

extension AtprotoOAuthAgent {
	/// AtprotoOAuth-owned, secret-bearing mirror of `OAuth.SessionState.Archive`.
	///
	/// oauth4swift's archive carries its secrets as plain `Codable`: the DPoP
	/// private key as `DPoP.Key.keyData: Data`, and the access/refresh tokens as
	/// `String`. This mirror exists so the *persisted* session archive rides
	/// `swift-secret-bytes`' custody instead — the DPoP private key and each
	/// token value land in zeroizing `SecretBytes` (`@SecretField`), while
	/// non-secret state (clientId, issuing server, scopes, expiries) stays plain.
	///
	/// The DPoP key is a **P-256 private signing key**, not a symmetric key, so
	/// it cannot conform to `SecretRestorable` itself: CryptoKit exposes an
	/// asymmetric private key only as a plaintext `rawRepresentation: Data`.
	/// Following `SecretRestorable`'s own guidance, it is carried as its raw
	/// 32-byte scalar (`DPoP.Key.keyData`) in a `SecretBytes`, with the
	/// (non-secret) `alg` beside it; restore rebuilds the key via
	/// `OAuth.DPoP.Key(alg:keyData:)`. This is the "raw/wire bytes" option, not
	/// the serialized-form one — it round-trips exactly, because
	/// `P256.Signing.PrivateKey.rawRepresentation`/`init(rawRepresentation:)` are
	/// inverse and `Alg` has a single case (`.es256`).
	///
	/// The mapping to and from `OAuth.SessionState.Archive` is **direct**: the
	/// archive's fields and initializers are public, so values move property by
	/// property rather than through a shared `Codable` shape. An oauth4swift field
	/// rename now breaks this at compile time, not silently at runtime.
	///
	/// **Legacy-decode gap (deliberate).** Before this type existed, a persisted
	/// session was a plain `Codable` `OAuth.SessionState.Archive` — secrets in
	/// cleartext. That form no longer decodes here: the `SecretField` ingress
	/// throws rather than accepting a plaintext key or token. This is pre-release
	/// with no shipped devices, so no migration is built; the intent is that any
	/// archive carrying a real secret is either re-homed through this type or
	/// re-established by a fresh authorization. If this ever ships, revisit — a
	/// silent refusal to load an existing session is a real (if fail-closed) cost.
	public struct SessionArchive: Codable, Sendable {
		public var clientId: String
		public var issuingServer: String
		public var grantScopes: [String]?
		public var tokenState: TokenStateArchive
		public var dPopKey: DPoPKeyArchive?

		/// The DPoP P-256 key split into its non-secret algorithm tag and its
		/// zeroizing raw scalar.
		public struct DPoPKeyArchive: Codable, Sendable {
			public var alg: OAuth.DPoP.Alg
			@SecretField var keyData: SecretBytes
		}

		public struct TokenStateArchive: Codable, Sendable {
			public var grantExpiry: Date?
			public var scopes: [String]
			public var accessToken: TokenArchive
			public var refreshToken: TokenArchive?
		}

		/// One token: its value in zeroizing custody, its non-secret dates plain.
		/// `expiry`/`fetchedOn` are carried so restore reproduces the archive
		/// byte-for-byte even mid-refresh; the value is what must not be plain.
		public struct TokenArchive: Codable, Sendable {
			@SecretField var value: SecretBytes
			public var expiry: Date?
			public var fetchedOn: Date?

			// Explicit because the token adapters below are declared in this body.
			init(value: SecretBytes, expiry: Date?, fetchedOn: Date?) {
				self.value = value
				self.expiry = expiry
				self.fetchedOn = fetchedOn
			}

			init(_ token: OAuth.AccessToken) throws {
				self.init(
					value: try SecretBytes(bytes: Data(token.value.utf8)),
					expiry: token.expiry,
					fetchedOn: token.fetchedOn
				)
			}

			init(_ token: OAuth.RefreshToken) throws {
				self.init(
					value: try SecretBytes(bytes: Data(token.value.utf8)),
					expiry: token.expiry,
					fetchedOn: token.fetchedOn
				)
			}
		}
	}
}

/// Failures of the mapping between the secret-bearing mirror and oauth4swift's
/// plaintext archive.
public enum SessionArchiveMappingError: Error, Equatable, Sendable {
	/// A token's stored bytes were not valid UTF-8, so they cannot be handed back
	/// to oauth4swift as a `String`. Substituting U+FFFD would silently corrupt a
	/// credential, so this refuses instead.
	case tokenValueNotUTF8
}

// MARK: - Mapping to/from `OAuth.SessionState.Archive`

extension AtprotoOAuthAgent.SessionArchive {
	/// Wraps an oauth4swift session archive, lifting its secrets into
	/// zeroizing custody.
	public init(_ archive: OAuth.SessionState.Archive) throws {
		self.clientId = archive.clientId
		self.issuingServer = archive.issuingServer
		self.grantScopes = archive.grantScopes
		self.dPopKey = try archive.dPopKey.map { try DPoPKeyArchive($0) }
		self.tokenState = try TokenStateArchive(archive.tokenState)
	}

	/// Rebuilds the oauth4swift archive the agent restores from. Secrets are
	/// materialized as plaintext only here, at the boundary oauth4swift's own API
	/// demands; the persisted form never carried them plain.
	public func oauthArchive() throws -> OAuth.SessionState.Archive {
		.init(
			clientId: clientId,
			dPopKey: try dPopKey.map { try $0.oauthKey() },
			issuingServer: issuingServer,
			grantScopes: grantScopes,
			tokenState: try tokenState.oauthTokenState()
		)
	}

	/// Replaces the archived token state with the agent's current (plaintext)
	/// one — the save-stream path's mutation, with the token values re-wrapped
	/// into zeroizing custody.
	public mutating func update(
		tokenState: OAuth.SessionState.TokenState
	) throws {
		self.tokenState = try TokenStateArchive(tokenState)
	}
}

extension AtprotoOAuthAgent.SessionArchive.DPoPKeyArchive {
	init(_ key: OAuth.DPoP.Key) throws {
		self.init(alg: key.alg, keyData: try SecretBytes(bytes: key.keyData))
	}

	func oauthKey() throws -> OAuth.DPoP.Key {
		// The scoped byte view is the unavoidable plaintext hop back into
		// oauth4swift's own `Data` representation.
		.init(alg: alg, keyData: keyData.withUnsafeBytes { Data($0) })
	}
}

extension AtprotoOAuthAgent.SessionArchive.TokenStateArchive {
	init(_ tokenState: OAuth.SessionState.TokenState) throws {
		self.init(
			grantExpiry: tokenState.grantExpiry,
			scopes: tokenState.scopes,
			accessToken: try .init(tokenState.accessToken),
			refreshToken: try tokenState.refreshToken.map { try .init($0) }
		)
	}

	func oauthTokenState() throws -> OAuth.SessionState.TokenState {
		.init(
			accessToken: try accessToken.oauthAccessToken(),
			refreshToken: try refreshToken?.oauthRefreshToken(),
			scopes: scopes,
			grantExpiry: grantExpiry
		)
	}
}

extension AtprotoOAuthAgent.SessionArchive.TokenArchive {
	/// The token's bytes decoded as UTF-8, refusing rather than substituting
	/// U+FFFD on invalid input.
	private func plaintextValue() throws -> String {
		try value.withUnsafeBytes { bytes in
			guard let string = String(bytes: bytes, encoding: .utf8) else {
				throw SessionArchiveMappingError.tokenValueNotUTF8
			}
			return string
		}
	}

	func oauthAccessToken() throws -> OAuth.AccessToken {
		try .init(value: plaintextValue(), expiry: expiry, fetchedOn: fetchedOn)
	}

	func oauthRefreshToken() throws -> OAuth.RefreshToken {
		try .init(value: plaintextValue(), expiry: expiry, fetchedOn: fetchedOn)
	}
}
