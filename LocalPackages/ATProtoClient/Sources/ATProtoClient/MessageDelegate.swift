//
//  MessageDelegate.swift
//  ATProtoClient
//
//  Created by Mark @ Germ on 2/17/26.
//

import ATProtoKit
import ATProtoTypes
import Foundation

extension ATProtoClient {
	public static func getGermMessagingDelegate(
		did: ATProtoDID,
		pdsURL: URL
	) async throws -> GermLexicon.MessagingDelegateRecord {
		//this uses the url request internal to ATProtoKit and not
		//ATProtoClient's

		let resp = try await ATProtoKit(pdsURL: pdsURL.absoluteString)
			.getRepositoryRecord(
				from: did.fullId,
				collection: GermLexicon.MessagingDelegateRecord.type,
				recordKey: "self"
			)

		guard let value = resp.value else {
			throw ATProtoClientError.missingRecordValue
		}

		let decoded = value.getRecord(
			ofType: GermLexicon.MessagingDelegateRecord.self)
		guard let decoded else {
			throw ATProtoClientError.failedToDecodeRecord
		}

		return decoded
	}
}
