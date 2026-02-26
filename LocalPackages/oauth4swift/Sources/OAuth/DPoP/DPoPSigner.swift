//
//  DPoPRequestPayload.swift
//  OAuth
//
//  Created by Mark @ Germ on 2/20/26.
//

import Foundation

#if canImport(FoundationNetworking)
	import FoundationNetworking
#endif

public struct DPoPRequestPayload: Codable, Hashable, Sendable {
	public let uniqueCode: String
	public let httpMethod: String
	public let httpRequestURL: String
	/// UNIX type, seconds since epoch
	public let createdAt: Int
	/// UNIX type, seconds since epoch
	public let expiresAt: Int
	public let nonce: String?
	public let authorizationServerIssuer: String
	public let accessTokenHash: String

	public enum CodingKeys: String, CodingKey {
		case uniqueCode = "jti"
		case httpMethod = "htm"
		case httpRequestURL = "htu"
		case createdAt = "iat"
		case expiresAt = "exp"
		case nonce
		case authorizationServerIssuer = "iss"
		case accessTokenHash = "ath"
	}

	public init(
		httpMethod: String,
		httpRequestURL: String,
		createdAt: Int,
		expiresAt: Int,
		nonce: String,
		authorizationServerIssuer: String,
		accessTokenHash: String
	) {
		self.uniqueCode = UUID().uuidString
		self.httpMethod = httpMethod
		self.httpRequestURL = httpRequestURL
		self.createdAt = createdAt
		self.expiresAt = expiresAt
		self.nonce = nonce
		self.authorizationServerIssuer = authorizationServerIssuer
		self.accessTokenHash = accessTokenHash
	}
}

public enum DPoPError: Error {
	case nonceExpected(URLResponse)
	case requestInvalid(URLRequest)
}

/// Manages state and operations for OAuth Demonstrating Proof-of-Possession (DPoP).
///
/// Currently only uses ES256.
///
/// Details here: https://datatracker.ietf.org/doc/html/rfc9449
public final class DPoPSigner {
	public struct JWTParameters: Sendable, Hashable {
		public let keyType: String

		public let httpMethod: String
		public let requestEndpoint: String
		public let nonce: String?
		public let tokenHash: String?
		public let issuingServer: String?
	}

	public typealias JWTGenerator = @Sendable (JWTParameters) async throws -> String
}
