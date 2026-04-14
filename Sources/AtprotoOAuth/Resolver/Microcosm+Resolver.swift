//
//  Microcosm+Resolver.swift
//  AtprotoOAuth
//
//  Created by Mark @ Germ on 4/14/26.
//

import AtprotoTypes
import Foundation

#if canImport(Microcosm)
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
				.resolveMiniDoc(identifier: did.stringRepresentation)?
				.didDocument
		}

		public func verifiedResolve(handle: Atproto.Handle) async throws -> Atproto
			.DIDDocument?
		{
			try await slingshot
				.resolveMiniDoc(identifier: handle.stringRepresentation)?
				.didDocument
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

	extension Microcosm.Slingshot: Atproto.Resolver {
		public func resolve(did: AtprotoTypes.Atproto.DID) async throws -> AtprotoTypes
			.Atproto.DIDDocument?
		{
			return nil
		}

		public func resolve(handle: AtprotoTypes.Atproto.Handle) async throws
			-> AtprotoTypes.Atproto.DID?
		{
			return nil
		}

	}

	extension Lexicon.Blue.Microcosm.Identity.ResolveMiniDoc.Output {
		var didDocument: Atproto.DIDDocument {
			.init(
				context: [],
				id: did.stringRepresentation,
				alsoKnownAs: [handle],
				verificationMethod: [],
				service: [
					.init(
						id: "#atproto_pds",
						type: "AtprotoPersonalDataServer",
						serviceEndpoint: pds
					)
				]
			)
		}
	}
#endif
