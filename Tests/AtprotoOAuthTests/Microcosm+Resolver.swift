//
//  Microcosm+Resolver.swift
//  AtprotoOAuth
//
//  Created by Mark @ Germ on 4/2/26.
//

import AtprotoOAuth
import AtprotoTypes
import Foundation
import Microcosm

extension Microcosm.Slingshot: Atproto.Resolver {
	public func resolve(
		did: Atproto.DID
	) async throws -> Atproto.DIDDocument {
		try await resolveMiniDoc(identifier: did.stringRepresentation)
			.tryUnwrap
			.didDocument
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
