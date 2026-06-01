//
//  MockAtmosphere+Operations.swift
//  AtprotoGerm
//
//  Created by Mark @ Germ on 4/9/26.
//

import AtprotoTypes
import Foundation

extension MockAtmosphere {
	public func follow(subjectDid: Atproto.DID, from viewerDid: Atproto.DID) async throws {
		try await pds(for: viewerDid)
			.tryUnwrap
			.follow(did: subjectDid, from: viewerDid)
	}

	public func block(subjectDid: Atproto.DID, from viewerDid: Atproto.DID) async throws {
		try await pds(for: viewerDid)
			.tryUnwrap
			.block(did: subjectDid, from: viewerDid)
	}
}
