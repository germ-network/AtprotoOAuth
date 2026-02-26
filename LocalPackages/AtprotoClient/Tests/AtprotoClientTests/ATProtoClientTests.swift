import ATProtoTypes
import Foundation
import Testing

@testable import ATProtoClient

struct APIOnlineTests {
	@Test func testMessagingDelegateRecord() async throws {
		let pdsUrl = try #require(
			URL(
				string: "https://shiitake.us-east.host.bsky.network"
			)
		)
		let did = try ATProtoDID(fullId: "did:plc:lbu36k4mysk5g6gcrpw4dbwm")

		let result =
			try await ATProtoClient(responseProvider: URLSession.defaultProvider)
			.getGermMessagingDelegate(
				did: did,
				pdsURL: pdsUrl
			)
		#expect(result.type == "com.germnetwork.declaration")
	}
}
