//
//  Resolver.swift
//  AtprotoClient
//
//  Created by Anna Mistele on 3/18/26.
//

import AtprotoTypes
import Foundation

public protocol AtprotoResolver: Sendable {
	func resolve(handle: AtIdentifier.Handle) async throws -> Atproto.DID
	func resolve(did: Atproto.DID) async throws -> DIDDocument
}

public enum AtprotoResolverError: Error {
	case noDidForHandle
}

extension AtprotoResolverError: LocalizedError {
	var localizedDescription: String {
		switch self {
		case .noDidForHandle: "No DID for handle"
		}
	}
}
