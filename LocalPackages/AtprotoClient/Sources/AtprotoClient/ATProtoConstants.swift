//
//  ATProtoConstants.swift
//  AtprotoClient
//
//  Created by Anna Mistele on 3/3/26.
//

import Foundation

struct ATProtoConstants {
	// Arbitrary value to prevent infinite loops
	static let maxFetches = 2 * Int(pow(Double(10), Double(9)))
}
