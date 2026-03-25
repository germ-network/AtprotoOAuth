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
	static let genericScopes = ["atproto", "transition:generic"]
	let mockResolver = AtprotoMockResolver()
	let resolver = AtprotoLegacyResolver(resourceFetcher: URLSession.shared)

	//move this to the handle resolution library
	@Test func testHandleResolution() async throws {
		let parsedDid = try Atproto.DID(string: "did:plc:4yvwfwxfz5sney4twepuzdu7")
		let resolvedDid = try await resolver.resolve(handle: "germnetwork.com")
		#expect(parsedDid == resolvedDid)

		await #expect(throws: AtprotoResolverError.noDidForHandle) {
			let _ = try await resolver.resolve(handle: "example.com")
		}
	}

	@Test func testAgentCreation() async throws {
		let _ = try AtprotoOAuthAgent.restore(
			archive: .init(did: "did:plc:4yvwfwxfz5sney4twepuzdu7", session: nil),
			clientMetadata: .init(
				clientId: APITests.clientId,
				scopes: Self.genericScopes,
				redirectURI: APITests.redirectUri
			),
			userAuthenticator: AtprotoClient.failingUserAuthenticator(_:_:),
			authFetcher: URLSession.manualRedirect(),
			atprotoResolver: resolver,
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
	let oauthClient: AtprotoClient
	static let genericScopes = ["atproto", "transition:generic"]
	let resolver = AtprotoLegacyResolver(resourceFetcher: URLSession.shared)

	init() async throws {
		let (oauthAgent, _) = try AtprotoOAuthAgent.restore(
			archive: .init(did: "did:plc:4yvwfwxfz5sney4twepuzdu7", session: nil),
			clientMetadata: .init(
				clientId: APITests.clientId,
				scopes: Self.genericScopes,
				redirectURI: APITests.redirectUri
			),
			userAuthenticator: AtprotoClient.failingUserAuthenticator(_:_:),
			authFetcher: URLSession.manualRedirect(),
			atprotoResolver: resolver,
		)
		oauthClient = AtprotoClient(agent: oauthAgent)
	}

	@Test func exampleUsage() async throws {
		let inputHandle = "markmx.bsky.social"
		let resolvedDid = try await resolver.resolve(
			handle: inputHandle
		)
		#expect(
			resolvedDid.stringRepresentation == "did:plc:lbu36k4mysk5g6gcrpw4dbwm"
		)

		//make some unauthed requests. e.g. is this did already using germ?
		let _ = try await AtprotoClient(
			agent: AtprotoAgentImpl(
				for: resolvedDid,
				resolver: resolver
			)
		)
		.getProfile()
	}
}
