//
//  AtprotoResolver.swift
//  AtprotoOAuth
//
//  Created by Anna Mistele on 3/18/26.
//

import AtprotoTypes

extension Atproto {
	public protocol Resolver: Sendable {
		func resolve(handle: AtIdentifier.Handle) async throws -> Atproto.DID?
		func verifiedResolve(handle: AtIdentifier.Handle) async throws -> Atproto
			.DIDDocument?
		func resolve(did: Atproto.DID) async throws -> Atproto.DIDDocument?
	}
}

// Default implementation for verifiedResolve, can be overridden
extension Atproto.Resolver {
	public func verifiedResolve(handle: AtIdentifier.Handle) async throws -> Atproto
		.DIDDocument?
	{
		guard let did = try await resolve(handle: handle) else {
			return nil
		}
		return try await resolve(did: did)
	}
}
