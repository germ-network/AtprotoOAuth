//
//  Profile.swift
//  AtprotoClient
//
//  Created by Anna Mistele on 3/3/26.
//

import AtprotoTypes
import Foundation

extension AtprotoClient {
	public func getProfile() async throws -> Lexicon.App.Bsky.Actor.Profile? {
		return try await getRecord(
			parameters: .init(
				repo: .did(agent.repo),
				rkey: "self",
				cid: nil
			)
		)
	}

	public func getProfileViewerState(for did: Atproto.DID) async throws
		-> Lexicon.App.Bsky.Actor.Defs.ViewerState
	{
		return try await authRequest(
			Lexicon.App.Bsky.Actor.GetProfile.self,
			parameters: .init(actor: .did(did))
		).viewer.tryUnwrap
	}
}
