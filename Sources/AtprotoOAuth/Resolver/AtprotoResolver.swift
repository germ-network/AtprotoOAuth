//
//  AtprotoResolver.swift
//  AtprotoOAuth
//
//  Created by Anna Mistele on 3/18/26.
//

import AtprotoTypes
import Foundation
import GermConvenience
import OAuth4Swift

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
	public func verifiedResolve(handle: Atproto.Handle) async throws -> (
		Atproto.DID,
		Atproto
			.DIDDocument
	)? {
		guard let did = try await resolve(handle: handle) else {
			return nil
		}

		//if a did doc doesn't resolve it's an error
		let document = try await resolve(did: did).tryUnwrap

		guard document.alsoKnownAs?.count == 1,
			document.alsoKnownAs?.first == handle
		else {
			throw OAuthClientError.handleMismatch
		}
		return (did, document)
	}

	public func resolve(
		atIdentifier: AtIdentifier
	) async throws -> (Atproto.DID, Atproto.DIDDocument)? {
		switch atIdentifier {
		case .handle(let handle):
			try await verifiedResolve(handle: handle)
		case .did(let did):
			(did, try await resolve(did: did).tryUnwrap)
		}
	}
}
