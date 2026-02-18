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
	) async throws -> GermLexicon.MessagingDelegateRecord {
		let response = try await getRepositoryRecord(
			repo: .did(did),
			collection: GermLexicon.MessagingDelegateRecord.type,
			recordKey: "self",
			pdsUrl: pdsURL,
			resultType: GermLexicon.MessagingDelegateRecord.self
		)

		return response.value

	}
}
