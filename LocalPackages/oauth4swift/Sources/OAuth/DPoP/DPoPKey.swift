//
//  DPoPKey.swift
//  OAuth
//
//  Created by Mark @ Germ on 2/22/26.
//

import Crypto
import Foundation

public enum DPoPAlg: Codable, Hashable, Sendable {
	case es256
}

//keep this a primitive type and let
public struct DPoPKey: Codable, Hashable, Sendable {
	let alg: DPoPAlg
	let keyData: Data

	static func generateP256() -> Self {
		.init(alg: .es256, keyData: P256.Signing.PrivateKey().rawRepresentation)
	}

	public init(alg: DPoPAlg, keyData: Data) {
		self.alg = alg
		self.keyData = keyData
	}

	func sign(_ parameters: DPoPSigner.JWTParameters) throws -> String {
		switch alg {
		case .es256: try signSha256(parameters)
		}
	}

	private func signSha256(_ parameters: DPoPSigner.JWTParameters) throws -> String {
		let payload: any Encodable = {
			if let nonce = parameters.nonce,
				let authorizationServerIssuer = parameters
					.issuingServer,
				let accessTokenHash = parameters.tokenHash
			{
				DPoPRequestPayload(
					httpMethod: parameters.httpMethod,
					httpRequestURL: parameters.requestEndpoint,
					createdAt: Int(
						Date.now.timeIntervalSince1970),
					expiresAt: Int(
						Date.now.timeIntervalSince1970
							+ 3600),
					nonce: nonce,
					authorizationServerIssuer:
						authorizationServerIssuer,
					accessTokenHash: accessTokenHash
				)
			} else {
				DPoPTokenPayload(
					httpMethod: parameters.httpMethod,
					httpRequestURL: parameters.requestEndpoint,
					createdAt: Int(
						Date.now.timeIntervalSince1970),
					expiresAt: Int(
						Date.now.timeIntervalSince1970
							+ 3600),
					nonce: parameters.nonce
				)
			}
		}()

		let key = try P256.Signing.PrivateKey(rawRepresentation: keyData)

		return try JWTSerializerLite.sign(
			payload,
			with: JWTLexiconLite.JWTHeader(
				typ: parameters.keyType,
				jwk: JWTLexiconLite.JWK(key: key)
			),
			using: ECDSASigner(key: key)
		)
	}
}
