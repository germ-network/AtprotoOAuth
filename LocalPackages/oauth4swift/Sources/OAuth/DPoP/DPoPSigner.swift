//
//  DPoPRequestPayload.swift
//  OAuth
//
//  Created by Mark @ Germ on 2/20/26.
//

import Foundation
import GermConvenience

struct DPoPRequestPayload: Codable, Hashable, Sendable {
	let uniqueCode: String
	let httpMethod: String
	let httpRequestURL: String
	/// UNIX type, seconds since epoch
	let createdAt: Int
	/// UNIX type, seconds since epoch
	let expiresAt: Int
	let nonce: String?
	let authorizationServerIssuer: String?
	let accessTokenHash: String?

	enum CodingKeys: String, CodingKey {
		case uniqueCode = "jti"
		case httpMethod = "htm"
		case httpRequestURL = "htu"
		case createdAt = "iat"
		case expiresAt = "exp"
		case nonce
		case authorizationServerIssuer = "iss"
		case accessTokenHash = "ath"
	}

	init(
		endpointUrl: URL,
		httpMethod: String,
		nonce: String?,
		issuingServer: String?,
		accessTokenHash: String?
	) throws {
		self.uniqueCode = UUID().uuidString
		self.httpMethod = httpMethod
		self.httpRequestURL = endpointUrl.absoluteString
		self.createdAt = Int(Date.now.timeIntervalSince1970)
		self.expiresAt = Int(Date.now.timeIntervalSince1970 + 3600)
		self.nonce = nonce
		self.authorizationServerIssuer = issuingServer
		self.accessTokenHash = accessTokenHash
	}
}

enum DPoPError: Error {
	case nonceExpected(URLResponse)
	case requestInvalid(URLRequest)
}

/// Manages state and operations for OAuth Demonstrating Proof-of-Possession (DPoP).
///
/// Currently only uses ES256.
///
/// Details here: https://datatracker.ietf.org/doc/html/rfc9449
public enum DPoPSigner {
	public struct JWTParameters: Sendable, Hashable {
		let keyType: String
		let nonce: String?
		let issuingServer: String?

		public init(
			keyType: String,
			nonce: String?,
			issuingServer: String?
		) {
			self.keyType = keyType
			self.nonce = nonce
			self.issuingServer = issuingServer
		}

		func substitute(newNonce: String) -> Self {
			.init(
				keyType: keyType,
				nonce: newNonce,
				issuingServer: issuingServer
			)
		}
	}
}
