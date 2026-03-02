//
//  JWTLexiconLite.swift
//  OAuth
//
//  Created by Anna Mistele on 4/23/25.
//

import Crypto
import Foundation

//super compact es256 JWT implmentation instead of BYO JWT signer

struct JWT {
	let header: String
	let payload: String
	let signature: String

	var string: String {
		header + [JWT.period] + payload + [JWT.period] + signature
	}

	var signingInput: String {
		header + [JWT.period] + payload
	}
}

extension JWT {
	static var period: Character {
		.init(".")
	}

	//periphery: ignore
	//ignore codable properties
	struct JWK: Sendable, Encodable {
		let kty: String = "EC"
		let crv: String = "P-256"
		let x: String
		let y: String

		init(key: P256.Signing.PublicKey) throws {
			// Public key consists of 04 | X | Y where X and Y are the same length
			// (Which, for P256, is 256 / 8 = 32 bytes each.)
			// https://developer.apple.com/forums/thread/680554
			let componentSize = JWT.JWTConstants.keySize / 8
			let keyBytes = key.x963Representation
			guard keyBytes.count == (componentSize * 2 + 1) else {
				throw JWTError.badKey
			}
			guard keyBytes[0] == JWT.JWTConstants.keyMarker else {
				throw JWTError.badKey
			}
			self.x = keyBytes.subdata(in: 1..<(componentSize + 1))
				.base64URLEncodedString()
			self.y = keyBytes.subdata(in: (componentSize + 1)..<(componentSize * 2 + 1))
				.base64URLEncodedString()
		}
	}

	//periphery:ignore
	//ignore codable properties
	struct JWTHeader: Encodable {
		let typ: String
		let alg: String = JWTConstants.ecdsaSignerAlg
		let jwk: JWK

		init(typ: String?, jwk: JWK) {
			self.typ = typ ?? "JWT"
			self.jwk = jwk
		}
	}

	struct JWTConstants {
		static let keySize = 256
		static let keyMarker = 0x04
		static let ecdsaSignerAlg = "ES256"
	}
}

extension Encodable {
	var jwtEncoded: String {
		get throws {
			let encoder = JSONEncoder()
			encoder.dateEncodingStrategy = .secondsSince1970
			let encodedHeader = try encoder.encode(self).base64URLEncodedBytes()

			return try String(
				data: .init(encodedHeader),
				encoding: .utf8
			).tryUnwrap
		}
	}
}

enum JWTError: Error, Equatable {
	case badKey
}
