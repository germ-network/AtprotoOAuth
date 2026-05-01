//
//  SlingshotResolver.swift
//  AtprotoOAuthDemoApp
//
//  Created by Mark @ Germ on 4/14/26.
//

import AtprotoClient
import AtprotoTypes
import Foundation
import Microcosm

//choosing to wrap Slingshot so that we hide its api and expose Atproto.Resolver instead
public struct SlingshotResolver: Atproto.Resolver {
	private let slingshot: Microcosm.Slingshot

	init(slingshot: Microcosm.Slingshot) {
		self.slingshot = slingshot
	}

	public func resolve(handle: AtprotoTypes.Atproto.Handle) async throws
		-> AtprotoTypes.Atproto.DID?
	{
		throw Errors.notImplemented
	}

	public func resolve(did: Atproto.DID) async throws -> Atproto.DIDDocument? {
		try await slingshot
			.resolveMiniDoc(identifier: .did(did))?
			.didDocument
	}

	public func verifiedResolve(
		handle: Atproto.Handle
	) async throws -> (Atproto.DID, Atproto.DIDDocument)? {
		let didDoc =
			try await slingshot
			.resolveMiniDoc(identifier: .handle(handle))
		if let didDoc {
			return (didDoc.did, didDoc.didDocument)
		} else {
			return nil
		}
	}
}

extension SlingshotResolver {
	enum Errors: LocalizedError {
		case notImplemented

		var errorDescription: String? {
			switch self {
			case .notImplemented:
				"not implemented"
			}
		}
	}
}
