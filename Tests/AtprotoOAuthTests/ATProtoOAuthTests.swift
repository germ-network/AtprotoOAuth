import AtprotoClient
import AtprotoOAuth
import AtprotoTypes
import Foundation
import GermConvenience
import Microcosm
import OAuth4Swift
import Testing

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
		let (resolvedDid, _) =
			try await resolver
			.verifiedResolve(handle: .init(string: "germnetwork.com"))
			.tryUnwrap
		#expect(parsedDid == resolvedDid)

		//don't yet have correct resoultion to nil
		//		#expect(try await resolver.verifiedResolve(handle: "null.germnetwork.com") == nil)
		//https://github.com/germ-network/Microcosm/issues/11

		await #expect(throws: (any Error).self) {
			try await resolver.verifiedResolve(handle: .init(string: "example.com"))
				== nil
		}
	}

	@Test func testAgentCreation() async throws {
		let _ = try AtprotoOAuthAgent.restore(
			archive: .init(
				did: "did:plc:4yvwfwxfz5sney4twepuzdu7",
				session: .mock()
			),
			clientId: APITests.clientId,
			authFetcher: URLSession.manualRedirect(),
			atprotoResolver: resolver,
		)
	}
}

enum AuthHarness {
	@Sendable
	public static func failingUserAuthenticator(_ url: URL, _ user: String) throws -> URL {
		throw OAuthClientError.generic("failed user authenticator")
	}
}

struct ClientAPITests {
	let oauthClient: Atproto.XRPC.ProxyCallable
	static let genericScopes = ["atproto", "transition:generic"]
	let resolver = SlingshotResolver(
		slingshot: .init(resourceFetcher: URLSession.shared)
	)

	init() async throws {
		let (oauthAgent, _) = try AtprotoOAuthAgent.restore(
			archive: .init(
				did: "did:plc:4yvwfwxfz5sney4twepuzdu7",
				session: .mock()
			),
			clientId: APITests.clientId,
			authFetcher: URLSession.manualRedirect(),
			atprotoResolver: resolver,
		)
		oauthClient = oauthAgent
	}

	@Test func exampleUsage() async throws {
		let inputHandle = try Atproto.Handle(string: "germnetwork.com")
		let (resolvedDid, _) =
			try await resolver
			.verifiedResolve(handle: inputHandle)
			.tryUnwrap

		#expect(
			resolvedDid.rawValue == "did:plc:4yvwfwxfz5sney4twepuzdu7"
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
