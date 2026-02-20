import ATProtoClient
import Foundation
import OAuthenticator
import Testing

@testable import ATProtoOAuth
@testable import ATProtoTypes

struct APITests {
	static let clientId = "https://static.germnetwork.com/client-metadata.json"
	static let redirectUri = "com.germnetwork.static:/oauth"

	//move this to the handle resolution library
	@Test func testHandleResolution() async throws {
		let parsedDid = try ATProtoDID(fullId: "did:plc:4yvwfwxfz5sney4twepuzdu7")
		let resolvedDid = try await ATProtoOAuthClient.resolve(handle: "germnetwork.com")
		#expect(parsedDid == resolvedDid)

		await #expect(throws: OAuthClientError.noDidForHandle) {
			let _ = try await ATProtoOAuthClient.resolve(handle: "example.com")
		}
	}

	@Test func testRuntimeCreation() async throws {
		let clientMetadata = try await ClientMetadata.load(
			for: Self.clientId,
			provider: URLSession.defaultProvider
		)

		let _ = ATProtoOAuthClient(
			clientId: Self.clientId,
			userAuthenticator: Authenticator.failingUserAuthenticator(_:_:),
			responseProvider: URLSession.defaultProvider,
			atprotoClient: MockATProtoClient()
		)
	}
}

struct RuntimeAPITests {
	let oauthClient: ATProtoOAuthClient

	init() async throws {
		oauthClient = .init(
			clientId: APITests.clientId,
			userAuthenticator: Authenticator.failingUserAuthenticator(_:_:),
			responseProvider: URLSession.defaultProvider,
			atprotoClient: MockATProtoClient()
		)
	}

	@Test func exampleUsage() async throws {
		let inputHandle = "markmx.bsky.social"
		let resolvedDid = try await ATProtoOAuthClient.resolve(
			handle: inputHandle
		)
		#expect(resolvedDid.fullId == "did:plc:lbu36k4mysk5g6gcrpw4dbwm")

		//make some unauthed requests. e.g. is this did already using germ?
		let messageDelegate =
			try await oauthClient
			.fetchFromPDS(did: resolvedDid) { pdsUrl, responseProvider in
				try await ATProtoClient(responseProvider: responseProvider)
					.getGermMessagingDelegate(did: resolvedDid, pdsURL: pdsUrl)
			}
		#expect(messageDelegate != nil)

		//now try to login

		let sessionArchive = try await oauthClient.initialLogin(
			identity: .did(resolvedDid)
		)
	}
}
