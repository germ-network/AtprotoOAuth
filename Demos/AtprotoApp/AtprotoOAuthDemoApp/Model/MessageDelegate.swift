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
		try await getRecord()
	}
}

extension AtprotoOAuthAgent {
	public func postGermMessagingDelegate(
		_ delegate: Lexicon.Com.GermNetwork.Declaration
	) async throws {
		let _ = try await putRecord(delegate)
	}
}
