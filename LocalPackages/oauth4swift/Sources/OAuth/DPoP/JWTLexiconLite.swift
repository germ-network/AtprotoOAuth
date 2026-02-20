//
//  JWTLexiconLite.swift
//  OAuth
//
//  Created by Anna Mistele on 4/23/25.
//

import Crypto
import Foundation

public enum JWTLexiconLite {
	// periphery:ignore
	//ignore codable properties
	public struct JWK: Sendable, Encodable {
		let kty: String = "EC"
		let crv: String = "P-256"
		let x: String
		let y: String

		public init(key: P256.Signing.PrivateKey) throws {
			// Public key consists of 04 | X | Y where X and Y are the same length
			// (Which, for P256, is 256 / 8 = 32 bytes each.)
			// https://developer.apple.com/forums/thread/680554
			let componentSize = JWTLexiconLite.JWTConstants.keySize / 8
			let keyBytes = key.publicKey.x963Representation
			guard keyBytes.count == (componentSize * 2 + 1) else {
				throw JWTLexiconLite.JWTError.badKey
			}
			guard keyBytes[0] == JWTLexiconLite.JWTConstants.keyMarker else {
				throw JWTLexiconLite.JWTError.badKey
			}
			self.x = keyBytes.subdata(in: 1..<(componentSize + 1))
				.base64URLEncodedString()
			self.y = keyBytes.subdata(in: (componentSize + 1)..<(componentSize * 2 + 1))
				.base64URLEncodedString()
		}
	}

	// periphery:ignore
	//ignore codable properties
	public struct JWTHeader: Encodable {
		let typ: String
		let alg: String = JWTConstants.ecdsaSignerAlg
		let jwk: JWK

		public init(typ: String?, jwk: JWK) {
			self.typ = typ ?? "JWT"
			self.jwk = jwk
		}
	}

	public enum JWTError: Error, Equatable {
		case badKey
		case notImplemented
	}

	struct JWTConstants {
		static let keySize = 256
		static let keyMarker = 0x04
		static let ecdsaSignerAlg = "ES256"
	}
}
