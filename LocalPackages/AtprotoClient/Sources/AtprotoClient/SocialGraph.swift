//
//  SocialGraph.swift
//  AtprotoClient
//
//  Created by Anna Mistele on 3/2/26.
//

import AtprotoTypes
import Foundation

extension AtprotoClient {
	public func getAllFollows(
		did: Atproto.DID,
	) async throws -> [Lexicon.App.Bsky.Graph.Follow] {
		//rely on url caching for this value
		let pdsUrl = try await plcDirectoryQuery(did)
			.pdsUrl

		var follows: [Lexicon.App.Bsky.Graph.Follow] = []

		var cursor: String? = nil
		repeat {
			let result: (records: [Lexicon.App.Bsky.Graph.Follow], cursor: String?) =
				try await listRecords(
					pdsUrl: pdsUrl,
					parameters: .init(
						repo: .did(did),
						limit: 100,  // max
						cursor: cursor,
						reverse: nil
					)
				)
			cursor = result.cursor
			follows.append(contentsOf: result.records)
		} while cursor != nil

		return follows
	}
}
