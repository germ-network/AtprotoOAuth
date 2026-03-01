//
//  ECDSASigner.swift
//  OAuth
//
//  Created by Anna Mistele on 4/24/25.
//

import Crypto
import Foundation

struct ECDSASigner {
	let publicKey: P256.Signing.PublicKey
	private let privateKey: P256.Signing.PrivateKey?

	init(key: P256.Signing.PrivateKey) {
		self.privateKey = key
		self.publicKey = key.publicKey
	}

	func sign(
		_ payload: some Encodable, with header: JWT.JWTHeader,
	) throws -> String {
		let signingInput = try header.makeSigningInput(
			payload: payload,
		)
		let signatureData = try sign(signingInput)
		let bytes: Data =
			signingInput + [JWT.period] + signatureData.base64URLEncodedBytes()
		return String(decoding: bytes, as: UTF8.self)
	}

	private func sign(_ plaintext: some DataProtocol) throws -> [UInt8] {
		let digest = SHA256.hash(data: plaintext)
		guard let privateKey else {
			throw JWTError.badKey
		}
		let signature = try privateKey.signature(for: digest)
		return [UInt8](signature.rawRepresentation)
	}

	func verify(
		_ signature: some DataProtocol,
		signs plaintext: some DataProtocol
	) throws -> Bool {
		let digest = SHA256.hash(data: plaintext)
		let signature = try P256.Signing.ECDSASignature(rawRepresentation: signature)
		return publicKey.isValidSignature(signature, for: digest)
	}
}
