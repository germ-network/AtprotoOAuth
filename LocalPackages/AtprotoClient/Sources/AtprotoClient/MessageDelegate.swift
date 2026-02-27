//
//  MessageDelegate.swift
//  AtprotoClient
//
//  Created by Mark @ Germ on 2/17/26.
//

import AtprotoTypes
import Foundation

extension AtprotoClient {
	public func getGermMessagingDelegate(
		did: Atproto.DID,
	) async throws -> Lexicon.Com.GermNetwork.Declaration? {
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
}
