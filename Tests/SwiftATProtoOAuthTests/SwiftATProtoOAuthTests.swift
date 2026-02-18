import SwiftATProtoOAuth
import SwiftATProtoTypes
import Testing

@testable import SwiftATProtoOAuth

struct APITests {
	@Test func testHandleResolution() async throws {
		let parsedDid = try ATProtoDID(fullId: "did:plc:4yvwfwxfz5sney4twepuzdu7")
		let resolvedDid = try await ATProtoOAuthRuntime.resolve(handle: "germnetwork.com")
		#expect(parsedDid == resolvedDid)
		
		await #expect(throws: OAuthRuntimeError.noDidForHandle) {
			let _ = try await ATProtoOAuthRuntime.resolve(handle: "example.com")
		}
	}
}
