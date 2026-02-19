//
//  CID.swift
//  ATProtoTypes
//
//  Created by Mark @ Germ on 2/18/26.
//

import Base32
import Foundation

//https://dasl.ing/cid.html

public struct CID {
	//todo: further parse components of the CID data such as the hash
	let bytes: Data

	public init(string: String) throws {
		guard let prefix = string.first, prefix == "b" else {
			throw ATProtoTypeError.invalidPrefix
		}
		let body = String(string.dropFirst())

		//cautious about the force unwraps in the Base32 module
		guard !body.isEmpty else {
			throw ATProtoTypeError.invalidBase32Data
		}

		guard let decoded = body.base32DecodedData else {
			throw ATProtoTypeError.invalidBase32Data
		}

		bytes = decoded
	}

	public var string: String {
		"b" + bytes.base32EncodedStringNoPadding
	}
}
