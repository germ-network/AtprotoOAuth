//
//  AtprotoResolver.swift
//  AtprotoOAuth
//
//  Created by Anna Mistele on 3/18/26.
//

import AtprotoTypes

extension Atproto {
	public protocol Resolver: Sendable {
		func resolve(handle: Atproto.Handle) async throws -> Atproto.DID?
		func resolve(did: Atproto.DID) async throws -> Atproto.DIDDocument?
		
		//we supply a default implementation of this
		func verifiedResolve(handle: Atproto.Handle) async throws -> Atproto
			.DIDDocument?
	}
}

// Default implementation for verifiedResolve, can be overridden
extension Atproto.Resolver {
	public func verifiedResolve(handle: Atproto.Handle) async throws -> Atproto
		.DIDDocument?
	{
		guard let did = try await resolve(handle: handle) else {
			return nil
		}
		return try await resolve(did: did)
	}
	
	public func resolve(
		atIdentifier: AtIdentifier
	) async throws -> Atproto.DIDDocument? {
		switch atIdentifier {
		case .handle(let handle):
			try await verifiedResolve(handle: handle)
		case .did(let did):
			try await resolve(did: did)
		}
	}
}
