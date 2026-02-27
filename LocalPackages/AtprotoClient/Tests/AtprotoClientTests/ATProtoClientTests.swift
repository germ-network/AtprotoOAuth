import Foundation
import Testing

@testable import AtprotoClient
@testable import AtprotoTypes

struct APIOnlineTests {
	@Test func testMessagingDelegateRecord() async throws {
		let did = try Atproto.DID(fullId: "did:plc:lbu36k4mysk5g6gcrpw4dbwm")

		let result =
			try await AtprotoClient(responseProvider: URLSession.defaultProvider)
			.getGermMessagingDelegate(
				did: did,
			).tryUnwrap
		#expect(result.id == "com.germnetwork.declaration")
	}
}
