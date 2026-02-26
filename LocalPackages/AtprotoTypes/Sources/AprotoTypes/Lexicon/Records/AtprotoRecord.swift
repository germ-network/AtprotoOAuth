//
//  AtprotoRecord.swift
//  ATProtoTypes
//
//  Created by Mark @ Germ on 2/24/26.
//

import Foundation

///define the interface needed to get/put a record
public protocol AtprotoRecord: Sendable, Codable, Mockable {
	static var nsid: String { get }
}

public protocol Mockable {
	static func mock() -> Self
}
