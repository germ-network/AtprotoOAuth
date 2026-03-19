//
//  MessageDelegate.swift
//  AtprotoClient
//
//  Created by Mark @ Germ on 2/17/26.
//

import AtprotoTypes
import Foundation

extension AtprotoClient {
	public func getGermMessagingDelegate() async throws -> Lexicon.Com.GermNetwork.Declaration? {
		return try await getRecord(
			parameters: .init(
				repo: .did(agent.repo),
				rkey: "self",
				cid: nil
			)
		)
	}

	public func postGermMessagingDelegate(
		_ delegate: Lexicon.Com.GermNetwork.Declaration
	) async throws {
		try await putRecord(
			parameters: .init(
				repo: .did(agent.repo),
				rkey: "self",
				record: delegate
			)
		)
	}
}
