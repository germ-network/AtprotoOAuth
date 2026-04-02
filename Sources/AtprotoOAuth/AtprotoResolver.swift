//
//  AtprotoResolver.swift
//  AtprotoOAuth
//
//  Created by Anna Mistele on 3/18/26.
//

import AtprotoTypes

extension Atproto {
	public protocol Resolver: Sendable {
		func resolve(handle: AtIdentifier.Handle) async throws -> Atproto.DID
		func resolve(did: Atproto.DID) async throws -> Atproto.DIDDocument
	}
}
