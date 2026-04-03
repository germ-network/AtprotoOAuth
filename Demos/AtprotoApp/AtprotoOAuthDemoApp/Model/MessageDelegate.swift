//
//  MessageDelegate.swift
//  AtprotoClient
//
//  Created by Mark @ Germ on 2/17/26.
//

import AtprotoClient
import AtprotoOAuth
import AtprotoTypes
import Foundation

extension PublicPDSAgent {
	public func getGermMessagingDelegate() async throws -> Lexicon.Com.GermNetwork.Declaration?
	{
		try await getRecord(
			rkey: "self",
			cid: nil
		)
	}
}

extension AtprotoOAuthAgent {
	public func postGermMessagingDelegate(
		_ delegate: Lexicon.Com.GermNetwork.Declaration
	) async throws {
		try await put(
			Lexicon.Com.GermNetwork.Declaration.self,
			input: .init(
				schema: .init(
					repo: .did(repo),
					rkey: "self",
					record: delegate
				)
			)
		)
	}
}
