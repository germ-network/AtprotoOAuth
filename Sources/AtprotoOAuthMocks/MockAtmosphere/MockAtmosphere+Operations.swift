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
			.unwrapped
			.follow(did: subjectDid, from: viewerDid)
	}

	public func block(subjectDid: Atproto.DID, from viewerDid: Atproto.DID) async throws {
		try await pds(for: viewerDid)
			.unwrapped
			.block(did: subjectDid, from: viewerDid)
	}

	public func unfollow(subjectDid: Atproto.DID, from viewerDid: Atproto.DID) async throws {
		try await pds(for: viewerDid)
			.unwrapped
			.unfollow(did: subjectDid, from: viewerDid)
	}
}
