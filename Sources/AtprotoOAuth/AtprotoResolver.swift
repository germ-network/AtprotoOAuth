//
//  AtprotoResolver.swift
//  AtprotoOAuth
//
//  Created by Anna Mistele on 3/18/26.
//

import AtprotoTypes
import Foundation
import GermConvenience

extension Atproto {
	public protocol Resolver: Sendable {
		func resolve(handle: AtIdentifier.Handle) async throws -> Atproto.DID
		func resolve(did: Atproto.DID) async throws -> Atproto.DIDDocument
	}
}

extension Atproto.Resolver {
	public func resolveAuthorizationServer(identity: AtIdentifier, authFetcher: HTTPFetcher)
		async throws -> URL
	{
		let did: Atproto.DID
		switch identity {
		case .did(let _did):
			did = _did
		case .handle(let handle):
			// Resolve handle to pds, uncached
			did = try await resolve(handle: handle)
		}

		// Resolve PDS URL
		let didDoc = try await resolve(did: did)
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
