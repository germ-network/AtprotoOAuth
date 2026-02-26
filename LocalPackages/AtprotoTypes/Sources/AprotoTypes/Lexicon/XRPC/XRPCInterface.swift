//
//  XRPCInterface.swift
//  AtprotoTypes
//
//  Created by Mark @ Germ on 2/26/26.
//

import Foundation

public protocol XRPCInterface {
	static var nsid: NSID { get }
	associatedtype Result: Decodable, Mockable
}
