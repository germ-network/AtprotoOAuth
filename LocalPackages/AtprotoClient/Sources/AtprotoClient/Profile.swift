//
//  Profile.swift
//  AtprotoClient
//
//  Created by Anna Mistele on 3/3/26.
//

import AtprotoTypes
import Foundation

extension AtprotoClientInterface {
	public func getProfile(
		did: Atproto.DID
	) async throws -> Lexicon.App.Bsky.Actor.Profile? {
		//rely on url caching for this value
		let pdsUrl = try await plcDirectoryQuery(did)
			.pdsUrl

		return try await getRecord(
			pdsUrl: pdsUrl,
			parameters: .init(
				repo: .did(did),
				rkey: "self",
				cid: nil
			)
		)
	}

	public func getProfileViewerState(
		did: Atproto.DID,
		session: any AtprotoSession
	) async throws -> Lexicon.App.Bsky.Actor.Defs.ViewerState {
		//rely on url caching for this value
		let pdsUrl = try await plcDirectoryQuery(did)
			.pdsUrl

		return try await authRequest(
			Lexicon.App.Bsky.Actor.GetProfile.self,
			pdsUrl: pdsUrl,
			parameters: .init(actor: .did(did)),
			session: session
		).viewer.tryUnwrap
	}
}
