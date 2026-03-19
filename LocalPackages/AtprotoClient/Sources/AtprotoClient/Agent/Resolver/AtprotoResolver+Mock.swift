//
//  Resolver.swift
//  AtprotoClient
//
//  Created by Anna Mistele on 3/18/26.
//

import AtprotoTypes

public struct AtprotoMockResolver: AtprotoResolver {
	public init() {}

	public func resolve(handle: AtIdentifier.Handle) async throws -> Atproto.DID {
		.mock()
	}
	public func resolve(did: Atproto.DID) async throws -> DIDDocument {
		try .mock()
	}
}
