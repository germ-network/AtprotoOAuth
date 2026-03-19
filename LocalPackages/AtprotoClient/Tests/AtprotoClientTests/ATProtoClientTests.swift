import Foundation
import Testing

@testable import AtprotoClient
@testable import AtprotoTypes

struct APIOnlineTests {
	let resolver = AtprotoLegacyResolver(resourceFetcher: URLSession.shared)

	@Test func testMessagingDelegateRecord() async throws {
		let did = try Atproto.DID(string: "did:plc:lbu36k4mysk5g6gcrpw4dbwm")

		let result =
		try await AtprotoClient(
			agent: AtprotoAgentImpl(
			for: did,
			resolver: resolver
			)
		)
		.getProfile().tryUnwrap
		#expect(result.nsid == "app.bsky.actor.profile")
	}

	@Test func testAtprotoMockSession() async throws {
		let did: Atproto.DID = try .init(string: "did:plc:mynameisanna")
		let rkey = "self"
		let record = Lexicon.App.Bsky.Actor.Profile.mock()

		let mockAgent = AtprotoMockAgentImpl(for: did)
		let client = AtprotoClient(agent: mockAgent)

		// Prep by storing the record manually (we don't have put record yet)
		try await mockAgent.putRecord(
			record: record,
			repo: did.stringRepresentation,
			rkey: rkey
		)

		// Make a request via this mock agent and decode the result
		let profile = try await client.request(
			Lexicon.Com.Atproto.Repo.GetRecord<Lexicon.App.Bsky.Actor.Profile>.self,
			parameters: .init(
				repo: .did(did),
				rkey: rkey,
				cid: nil
			)
		)
		assert(profile.value.displayName == record.displayName)
	}
}
