import Foundation
import Testing

@testable import AtprotoClient
@testable import AtprotoTypes

struct APIOnlineTests {
	@Test func testMessagingDelegateRecord() async throws {
		let did = try Atproto.DID(string: "did:plc:lbu36k4mysk5g6gcrpw4dbwm")

		let result =
			try await AtprotoClient(responseProvider: URLSession.defaultProvider)
			.getGermMessagingDelegate(
				did: did,
			).tryUnwrap
		#expect(result.nsid == "com.germnetwork.declaration")
	}

	@Test func testAtprotoMockSession() async throws {
		let mockAgent = AtprotoMockAgent()

		let repo = "did:plc:mynameisanna"
		let rkey = "self"
		let record = Lexicon.App.Bsky.Actor.Profile.mock()

		// Prep by storing the record manually (we don't have put record yet)
		try await mockAgent.putRecord(
			record: record,
			repo: repo,
			rkey: rkey
		)

		// TODO: This shouldn't be an auth response it should just be a normal response
		// Make a request via this mock agent and decode the result
		let request = URLRequest(
			url: URL(
				string:
					"https://testing.germnetwork.com/xrpc/com.atproto.repo.getRecord?repo=\(repo)&collection=\(record.nsid)&rkey=\(rkey)"
			)!)
		let response = try await mockAgent.authResponse(for: request)
		let resp:
			Lexicon.Com.Atproto.Repo.GetRecord<Lexicon.App.Bsky.Actor.Profile>.Result =
				try response.successDecode()
		assert(resp.value.displayName == record.displayName)
	}
}
