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
	let resolver = SlingshotResolver(
		slingshot: .init(resourceFetcher: URLSession.shared)
	)

	//move this to the handle resolution library
	@Test func testHandleResolution() async throws {
		let parsedDid = try Atproto.DID(string: "did:plc:4yvwfwxfz5sney4twepuzdu7")
		let (resolvedDid, _) = try await resolver
			.verifiedResolve(handle: "germnetwork.com")
			.tryUnwrap
		#expect(parsedDid == resolvedDid)

		//don't yet have correct resoultion to nil
//		#expect(try await resolver.verifiedResolve(handle: "null.germnetwork.com") == nil)
		//https://github.com/germ-network/Microcosm/issues/11
		
		await #expect(throws: (any Error).self) {
			try await resolver.verifiedResolve(handle: "example.com") == nil
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
	let resolver = SlingshotResolver(
		slingshot: .init(resourceFetcher: URLSession.shared)
	)

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
		let (resolvedDid, _) = try await resolver
			.verifiedResolve(handle: inputHandle)
			.tryUnwrap

		#expect(
			resolvedDid.stringRepresentation == "did:plc:lbu36k4mysk5g6gcrpw4dbwm"
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
