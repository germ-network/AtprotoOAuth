//
//  Resolver.swift
//  AtprotoClient
//
//  Created by Anna Mistele on 3/18/26.
//

import AtprotoTypes

public protocol AtprotoResolver: Sendable {
	func resolve(handle: AtIdentifier.Handle) async throws -> Atproto.DID
	func resolve(did: Atproto.DID) async throws -> DIDDocument
}
