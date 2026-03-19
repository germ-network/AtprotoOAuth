import AtprotoClient
import Foundation
import GermConvenience
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
		let parsedDid = try Atproto.DID(string: "did:plc:4yvwfwxfz5sney4twepuzdu7")
		let resolvedDid = try await AtprotoOAuthClient.resolve(handle: "germnetwork.com")
		#expect(parsedDid == resolvedDid)

		await #expect(throws: OAuthClientError.noDidForHandle) {
			let _ = try await AtprotoOAuthClient.resolve(handle: "example.com")
		}
	}

	@Test func testclientCreation() async throws {

		let _ = AtprotoOAuthClient(
			appCredentials: .init(
				clientId: APITests.clientId,
				scopes: [Self.genericScope],
				callbackURL: APITests.redirectUri
			),
			userAuthenticator: AtprotoClient.failingUserAuthenticator(_:_:),
			resourceFetcher: URLSession.shared,
			authFetcher: URLSession.manualRedirect(),
			atprotoClient: MockAtprotoClient(),
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
			resourceFetcher: URLSession.shared,
			authFetcher: URLSession.manualRedirect(),
			atprotoClient: MockAtprotoClient(),

		)
	}

	@Test func exampleUsage() async throws {
		let inputHandle = "markmx.bsky.social"
		let resolvedDid = try await AtprotoOAuthClient.resolve(
			handle: inputHandle
		)
		#expect(
			resolvedDid.stringRepresentation == "did:plc:lbu36k4mysk5g6gcrpw4dbwm"
		)

		//make some unauthed requests. e.g. is this did already using germ?
		let _ = try await AtprotoClient(
			resourceFetcher: URLSession.shared
		)
		.getProfile(did: resolvedDid)
	}
}
