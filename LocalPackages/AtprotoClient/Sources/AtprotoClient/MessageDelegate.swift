//
//  MessageDelegate.swift
//  ATProtoClient
//
//  Created by Mark @ Germ on 2/17/26.
//

import AtprotoTypes
import Foundation

extension ATProtoClient {
	public func getGermMessagingDelegate(
		did: Atproto.DID,
	) async throws -> Lexicon.Com.GermNetwork.Declaration? {
		//rely on url caching for this value
		let pdsUrl = try await plcDirectoryQuery(did)
			.pdsUrl
		let response = try await getRepository(
			recordType: Lexicon.Com.GermNetwork.Declaration.self,
			pdsUrl: pdsUrl,
			repo: .did(did),
			recordKey: "self",
		)

		return response?.value
	}
}
