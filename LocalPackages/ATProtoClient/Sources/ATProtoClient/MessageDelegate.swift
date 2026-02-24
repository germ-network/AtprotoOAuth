//
//  MessageDelegate.swift
//  ATProtoClient
//
//  Created by Mark @ Germ on 2/17/26.
//

import ATProtoTypes
import Foundation

extension ATProtoClient {
	public func getGermMessagingDelegate(
		did: ATProtoDID,
	) async throws -> Lexicon.Com.GermNetwork.Declaration? {
		//rely on url caching for this value
		let pdsUrl = try await plcDirectoryQuery(did)
			.pdsUrl
		let response = try await getRepository(
			recordType: Lexicon.Com.GermNetwork.Declaration.self,
			repo: .did(did),
			recordKey: "self",
			pdsUrl: pdsUrl,
		)

		return response?.value
	}
}
