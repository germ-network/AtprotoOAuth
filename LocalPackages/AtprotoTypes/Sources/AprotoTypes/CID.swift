//
//  CID.swift
//  AtprotoTypes
//
//  Created by Mark @ Germ on 2/18/26.
//

import Base32
import Foundation

//https://dasl.ing/cid.html

public struct CID: Sendable {
	//todo: further parse components of the CID data such as the hash
	let bytes: Data

	private init(bytes: Data) {
		self.bytes = bytes
	}

	public init(string: String) throws {
		guard let prefix = string.first, prefix == "b" else {
			throw AtprotoTypeError.invalidPrefix
		}
		let body = String(string.dropFirst())

		//cautious about the force unwraps in the Base32 module
		guard !body.isEmpty else {
			throw AtprotoTypeError.invalidBase32Data
		}

		guard let decoded = body.base32DecodedData else {
			throw AtprotoTypeError.invalidBase32Data
		}

		bytes = decoded
	}

	public var string: String {
		"b" + bytes.base32EncodedStringNoPadding
	}
}

extension CID: Encodable {
	public func encode(to encoder: any Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(self.bytes)
	}
}

extension CID {
	static func mock() -> Self {
		//TODO, mock the internal mechanics of CID
		.init(bytes: Data("mock".utf8))
	}
}
