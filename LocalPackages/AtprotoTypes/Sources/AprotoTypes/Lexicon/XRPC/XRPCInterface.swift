//
//  XRPCInterface.swift
//  AtprotoTypes
//
//  Created by Mark @ Germ on 2/26/26.
//

import Foundation

public protocol XRPCInterface: Sendable {
	static var nsid: Atproto.NSID { get }
	associatedtype Parameters: XRPCParameters
	associatedtype Result: Decodable, Mockable
}

public protocol XRPCParameters: Sendable {
	func asQueryItems() -> [URLQueryItem]
}
