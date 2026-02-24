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
		pdsURL: URL
	) async throws -> Lexicon.Com.GermNetwork.Declaration? {
		let response = try await getRepository(
			recordType: Lexicon.Com.GermNetwork.Declaration.self,
			repo: .did(did),
			recordKey: "self",
			pdsUrl: pdsURL,
		)

		return response?.value

	}
}
