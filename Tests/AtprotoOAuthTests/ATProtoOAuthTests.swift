import AtprotoClient
import Foundation
import OAuth
import Testing

@testable import AtprotoOAuth
@testable import AtprotoTypes

struct APITests {
	static let clientId = "https://static.germnetwork.com/client-metadata.json"
	static let redirectUri = URL(string: "com.germnetwork.static:/oauth")!
	static let genericScope = "atproto transition:generic"

	//move this to the handle resolution library
	@Test func testHandleResolution() async throws {
		let parsedDid = try Atproto.DID(fullId: "did:plc:4yvwfwxfz5sney4twepuzdu7")
		let resolvedDid = try await AtprotoOAuthClient.resolve(handle: "germnetwork.com")
		#expect(parsedDid == resolvedDid)

		await #expect(throws: OAuthClientError.noDidForHandle) {
			let _ = try await AtprotoOAuthClient.resolve(handle: "example.com")
		}
	}

	@Test func testRuntimeCreation() async throws {
		let clientMetadata = try await ClientMetadata.load(
			for: Self.clientId,
			provider: URLSession.defaultProvider
		)

		let _ = AtprotoOAuthClient(
			appCredentials: .init(
				clientId: APITests.clientId,
				scopes: [Self.genericScope],
				callbackURL: APITests.redirectUri
			),
			userAuthenticator: AtprotoClient.failingUserAuthenticator(_:_:),
			responseProvider: URLSession.defaultProvider,
			atprotoClient: MockAtprotoClient()
		)
	}
}

extension AtprotoClient {
	@Sendable
	public static func failingUserAuthenticator(_ url: URL, _ user: String) throws -> URL {
		throw OAuthClientError.generic("failed user autheticator")
	}
}

struct ClientAPITests {
	let oauthClient: AtprotoOAuthClient

	init() async throws {
		oauthClient = .init(
			appCredentials: .init(
				clientId: APITests.clientId,
				scopes: [APITests.genericScope],
				callbackURL: APITests.redirectUri
			),
			userAuthenticator: AtprotoClient.failingUserAuthenticator(_:_:),
			responseProvider: URLSession.defaultProvider,
			atprotoClient: MockAtprotoClient()
		)
	}

	@Test func exampleUsage() async throws {
		let inputHandle = "markmx.bsky.social"
		let resolvedDid = try await AtprotoOAuthClient.resolve(
			handle: inputHandle
		)
		#expect(resolvedDid.fullId == "did:plc:lbu36k4mysk5g6gcrpw4dbwm")

		//make some unauthed requests. e.g. is this did already using germ?
		let messageDelegate = try await AtprotoClient(
			responseProvider: oauthClient.responseProvider
		).getGermMessagingDelegate(did: resolvedDid)

		#expect(messageDelegate != nil)
	}
}
