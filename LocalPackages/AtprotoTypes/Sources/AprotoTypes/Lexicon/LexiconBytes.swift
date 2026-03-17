//
//  LexiconBytes.swift
//  AtprotoTypes
//
//  Created by Mark @ Germ on 3/17/26.
//

import Foundation

public struct LexiconBytes: Codable, Equatable, Hashable, Sendable {
	public let bytes: Data

	public init(bytes: Data) {
		self.bytes = bytes
	}

	enum CodingKeys: String, CodingKey {
		case bytes = "$bytes"
	}
}
