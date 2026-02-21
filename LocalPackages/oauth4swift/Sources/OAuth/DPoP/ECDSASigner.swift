//
//  ECDSASigner.swift
//  OAuth
//
//  Created by Anna Mistele on 4/24/25.
//

import Crypto
import Foundation

public struct ECDSASigner {
	let privateKey: P256.Signing.PrivateKey?
	let publicKey: P256.Signing.PublicKey

	public init(key: P256.Signing.PrivateKey) {
		self.privateKey = key
		self.publicKey = key.publicKey
	}

	func sign(_ plaintext: some DataProtocol) throws -> [UInt8] {
		let digest = SHA256.hash(data: plaintext)
		guard let privateKey else {
			throw JWTLexiconLite.JWTError.badKey
		}
		let signature = try privateKey.signature(for: digest)
		return [UInt8](signature.rawRepresentation)
	}

	public func verify(_ signature: some DataProtocol, signs plaintext: some DataProtocol)
		throws
		-> Bool
	{
		let digest = SHA256.hash(data: plaintext)
		let signature = try P256.Signing.ECDSASignature(rawRepresentation: signature)
		return publicKey.isValidSignature(signature, for: digest)
	}
}
