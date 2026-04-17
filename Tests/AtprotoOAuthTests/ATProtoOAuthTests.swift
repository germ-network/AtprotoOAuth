import AtprotoClient
import Foundation
import GermConvenience
import Microcosm
import OAuth4Swift
import Testing

@testable import AtprotoOAuth
@testable import AtprotoTypes

struct APITests {
	static let clientId = "https://static.germnetwork.com/client-metadata.json"
	static let redirectUri = URL(string: "com.germnetwork.static:/oauth")!
	static let genericScopes = ["atproto", "transition:generic"]
	//	let mockResolver = AtprotoMockResolver()
	let resolver = Microcosm.Slingshot(resourceFetcher: URLSession.shared)

	//move this to the handle resolution library
	@Test func testHandleResolution() async throws {
		let parsedDid = try Atproto.DID(string: "did:plc:4yvwfwxfz5sney4twepuzdu7")
		let resolvedDid = try await resolver.resolveMiniDoc(
			identifier: "germnetwork.com"
		)?.did
		#expect(parsedDid == resolvedDid)

		await #expect(throws: (any Error).self) {
			let _ = try await resolver.resolve(handle: "example.com")
		}
	}

	@Test func testAgentCreation() async throws {
		let _ = try AtprotoOAuthAgent.restore(
			archive: .init(did: "did:plc:4yvwfwxfz5sney4twepuzdu7", session: nil),
			clientId: APITests.clientId,
			authFetcher: URLSession.manualRedirect(),
			atprotoResolver: resolver,
		)
	}
}

enum AuthHarness {
	@Sendable
	public static func failingUserAuthenticator(_ url: URL, _ user: String) throws -> URL {
		throw OAuthClientError.generic("failed user autheticator")
	}
}

struct ClientAPITests {
	let oauthClient: XRPCProxyCallable
	static let genericScopes = ["atproto", "transition:generic"]
	let resolver = Microcosm.Slingshot(resourceFetcher: URLSession.shared)

	init() async throws {
		let (oauthAgent, _) = try AtprotoOAuthAgent.restore(
			archive: .init(did: "did:plc:4yvwfwxfz5sney4twepuzdu7", session: nil),
			clientId: APITests.clientId,
			authFetcher: URLSession.manualRedirect(),
			atprotoResolver: resolver,
		)
		oauthClient = oauthAgent
	}

	@Test func exampleUsage() async throws {
		let inputHandle = "markmx.bsky.social"
		let resolvedDid = try await resolver.resolveMiniDoc(
			identifier: inputHandle
		)?.did
		#expect(
			resolvedDid?.stringRepresentation == "did:plc:lbu36k4mysk5g6gcrpw4dbwm"
		)

		//		//make some unauthed requests. e.g. is this did already using germ?
		//		let _ = try await AtprotoClient(
		//			agent: AtprotoAgentImpl(
		//				for: resolvedDid,
		//				resolver: resolver
		//			)
		//		)
		//		.getProfile()
	}

	//	@Test func clientUsage() async throws {
	//		await #expect(throws: OAuthSessionError.sessionInactive) {
	//			try await oauthClient.getProfile()
	//		}
	//	}
}
