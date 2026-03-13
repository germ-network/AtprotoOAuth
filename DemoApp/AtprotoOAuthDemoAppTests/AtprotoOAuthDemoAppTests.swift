//
//  AtprotoOAuthDemoAppTests.swift
//  AtprotoOAuthDemoAppTests
//
//  Created by Mark @ Germ on 2/19/26.
//

import Foundation
internal import GermConvenience
import Testing

@testable import AtprotoClient
@testable import AtprotoTypes

struct AtprotoOAuthDemoAppTests {

	@Test func testAtprotoMockSession() async throws {
		let mockSession = AtprotoMockSession()

		let repo = "did:plc:mynameisanna"
		let rkey = "self"
		let record = Lexicon.App.Bsky.Actor.Profile.mock()

		// Prep by storing the record manually (we don't have put record yet)
		try await mockSession.putRecord(
			record: record,
			repo: repo,
			rkey: rkey
		)

		// TODO: This shouldn't be an auth response it should just be a normal response
		// Make a request via this mock session and decode the result
		let request = URLRequest(
			url: URL(
				string:
					"https://testing.germnetwork.com/xrpc/com.atproto.repo.getRecord?repo=\(repo)&collection=\(record.nsid)&rkey=\(rkey)"
			)!)
		let response = try await mockSession.authResponse(for: request)
		let resp:
			Lexicon.Com.Atproto.Repo.GetRecord<Lexicon.App.Bsky.Actor.Profile>.Result =
				try response.successDecode()
		assert(resp.value.displayName == record.displayName)
	}

}
