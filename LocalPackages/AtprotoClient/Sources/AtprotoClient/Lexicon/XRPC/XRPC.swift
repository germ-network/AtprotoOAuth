//
//  XRPCInterface.swift
//  AtprotoTypes
//
//  Created by Mark @ Germ on 2/26/26.
//

import AtprotoTypes
import Foundation

///https://atproto.com/specs/xrpc
public protocol XRPC: Sendable {
	static var nsid: Atproto.NSID { get }
	static var acceptValue: String { get }

	associatedtype Result: Decodable, Mockable, Sendable
}

//these are GET queries
public protocol XRPCRequest: XRPC {
	associatedtype Parameters: QueryParameters
}

public protocol QueryParameters: Sendable {
	func asQueryItems() -> [URLQueryItem]
}

//these are POST
public protocol XRPCProcedure: XRPC {
	static var contentTypeValue: String { get }

	associatedtype Parameters: ProcedureParameters
}

public protocol ProcedureParameters: Sendable {
	func httpBody() throws -> Data
}
