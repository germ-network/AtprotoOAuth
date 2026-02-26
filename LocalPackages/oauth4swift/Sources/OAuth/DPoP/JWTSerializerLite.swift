//
//  JWTSerializerLite.swift
//  OAuth
//
//  Created by Anna Mistele on 4/24/25.
//

import Foundation

public struct JWTSerializerLite {
	public static func sign(
		_ payload: some Encodable, with header: JWTLexiconLite.JWTHeader,
		using signer: ECDSASigner
	) throws -> String {
		let signingInput = try makeSigningInput(
			payload: payload,
			header: header
		)
		let signatureData = try signer.sign(signingInput)
		let bytes: Data = signingInput + [period] + signatureData.base64URLEncodedBytes()
		return String(decoding: bytes, as: UTF8.self)
	}
}

private func makeSigningInput(
	payload: some Encodable,
	header: JWTLexiconLite.JWTHeader
) throws -> Data {
	// Make the encoder
	let encoder = JSONEncoder()
	encoder.dateEncodingStrategy = .secondsSince1970

	// Make the header
	let encodedHeader = try encoder.encode(header).base64URLEncodedBytes()
	let encodedPayload = try Data(encoder.encode(payload).base64URLEncodedBytes())
	return encodedHeader + [period] + encodedPayload
}

private var period: UInt8 {
	return Character(".").asciiValue!
}
