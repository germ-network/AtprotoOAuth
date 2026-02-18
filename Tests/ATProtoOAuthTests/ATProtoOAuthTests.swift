import ATProtoClient
import ATProtoTypes
import Foundation
import OAuthenticator
import Testing

@testable import ATProtoOAuth

struct APITests {
	static let clientId = "https://static.germnetwork.com/client-metadata.json"

	@Test func testHandleResolution() async throws {
		let parsedDid = try ATProtoDID(fullId: "did:plc:4yvwfwxfz5sney4twepuzdu7")
		let resolvedDid = try await ATProtoOAuthRuntime.resolve(handle: "germnetwork.com")
		#expect(parsedDid == resolvedDid)

		await #expect(throws: OAuthRuntimeError.noDidForHandle) {
			let _ = try await ATProtoOAuthRuntime.resolve(handle: "example.com")
		}
	}

	@Test func testRuntimeCreation() async throws {
		let clientMetadata = try await ClientMetadata.load(
			for: Self.clientId,
			provider: URLSession.defaultProvider
		)

		let _ = ATProtoOAuthRuntime(
			appCredentials: clientMetadata.credentials,
			userAuthenticator: Authenticator.failingUserAuthenticator(_:_:),
			responseProvider: URLSession.defaultProvider,
			atprotoClient: MockATProtoClient()
		)
	}
}

struct RuntimeAPITests {
	let runtime: ATProtoOAuthRuntime

	init() async throws {
		let clientMetadata = try await ClientMetadata.load(
			for: APITests.clientId,
			provider: URLSession.defaultProvider
		)

		runtime = .init(
			appCredentials: clientMetadata.credentials,
			userAuthenticator: Authenticator.failingUserAuthenticator(_:_:),
			responseProvider: URLSession.defaultProvider,
			atprotoClient: MockATProtoClient()
		)
	}
}
