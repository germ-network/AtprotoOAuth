import ATProtoKit
import ATProtoTypes
import Foundation
import Testing

@testable import ATProtoClient

struct APITests {
	@Test func testMessagingDelegateRecord() async throws {
		let pdsUrl = try #require(
			URL(
				string: "https://shiitake.us-east.host.bsky.network"
			)
		)
		let did = try ATProtoDID(fullId: "did:plc:lbu36k4mysk5g6gcrpw4dbwm")

		//haven't yet registered the type
		await #expect(
			throws: ATProtoClientError.failedToDecodeRecord
		) {
			let _ =
				try await ATProtoClient
				.getGermMessagingDelegate(
					did: did,
					pdsURL: pdsUrl
				)
		}

		await ATRecordTypeRegistry.shared.register(
			types: [GermLexicon.MessagingDelegateRecord.self]
		)

		let _ =
			try await ATProtoClient
			.getGermMessagingDelegate(
				did: did,
				pdsURL: pdsUrl
			)
	}
}
