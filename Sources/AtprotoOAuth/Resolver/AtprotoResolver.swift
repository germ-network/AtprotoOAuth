//
//  AtprotoResolver.swift
//  AtprotoOAuth
//
//  Created by Anna Mistele on 3/18/26.
//

import AtprotoTypes
import Foundation
import OAuth4Swift
import GermConvenience

extension Atproto {
	public protocol Resolver: Sendable {
		func resolve(handle: Handle) async throws -> DID?
		func resolve(did: DID) async throws -> DIDDocument?

		//we supply a default implementation of this
		func verifiedResolve(
			handle: Handle
		) async throws -> (DID, DIDDocument)?
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

extension Atproto.Resolver {
	public func resolveAuthorizationServer(identity: AtIdentifier, authFetcher: HTTPFetcher)
	async throws -> (AuthServerMetadata, URL)
	{
		let did: Atproto.DID
		switch identity {
		case .did(let _did):
			did = _did
		case .handle(let handle):
			// Resolve handle to pds, uncached
			did = try await resolve(handle: handle).tryUnwrap
		}

		// Resolve PDS URL
		let didDoc = try await resolve(did: did).tryUnwrap
		if case .handle(let handle) = identity {
			if handle != didDoc.handle {
				throw OAuthClientError.handleMismatch
			}
		}

		return try await AtprotoOAuthUtils.getAuthorizationServerURL(
			pdsServiceEndpoint: didDoc.pdsUrl,
			authFetcher: authFetcher
		)
	}
}
