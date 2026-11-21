//
//  PushedAuthorizationRequestTests.swift
//  AtprotoOAuth
//

import AtprotoClient
import AtprotoOAuth
import AtprotoOAuthMocks
import AtprotoTypes
import Foundation
import GermConvenience
import GermConvenienceHTTP
import GermConvenienceMocks
import OAuth4Swift
import Testing

struct PushedAuthorizationRequestTests {
	static let handle = try! Atproto.Handle(string: "alice.example.com")

	///The AT Protocol OAuth profile requires `state` on the authorization request,
	///even though PKCE alone would satisfy plain OAuth 2.1. Most authorization
	///servers don't enforce it (Cocoon does), so assert it here rather than rely
	///on an interop failure to catch a regression.
	@Test func parRequestIncludesState() async throws {
		let (parameters, _) = try await Self.pushedParameters(for: .didWithHandle)

		let state = try #require(parameters.get(name: "state"))
		#expect(!state.isEmpty)
	}

	enum IdentityForm: CaseIterable {
		case didWithHandle, didOnly, handle
	}

	///Runs `authorize()` against a mock PDS that is its own authorization
	///server, halting once the user would be sent to the browser, and returns
	///the form parameters of the pushed authorization request.
	static func pushedParameters(
		for form: IdentityForm
	) async throws -> (FormParameters, Atproto.DID) {
		let atmosphere = MockAtmosphere()
		let did = try await atmosphere.createDid(handle: handle)
		let authorizationServer = try #require(
			await atmosphere.authorizationServer(for: did)
		)

		let parUrl = authorizationServer.url(for: .pushedAuthorizationRequest)
		await authorizationServer.fetcher
			.on(parUrl, method: .post)
			.enqueue(
				.success(
					.status(
						.created,
						data:
							#"{"request_uri":"urn:ietf:params:oauth:request_uri:test","expires_in":60}"#
							.utf8Data
					)))

		let client = AtprotoOAuthClient(
			clientInfo: .init(
				clientId: "https://client.example.com/client-metadata.json",
				scopes: ["atproto"],
				redirectURI: try #require(URL(string: "com.example.client:/oauth"))
			),
			resolver: atmosphere,
			authFetcher: atmosphere,
			//stop the flow here; we only care about what was pushed
			userAuthenticator: AuthHarness.failingUserAuthenticator
		)

		let identity: AuthIdentity =
			switch form {
			case .didWithHandle: .did(did, handle: handle)
			case .didOnly: .did(did, handle: nil)
			case .handle: .handle(handle)
			}
		await #expect(throws: OAuthClientError.self) {
			try await client.authorize(identity: identity)
		}
		#expect(await authorizationServer.fetcher.allRequested)

		let parRequest = try await authorizationServer.fetcher
			.firstRequest(for: parUrl, method: .post)
		return (FormParameters(parsing: try #require(parRequest.body)), did)
	}
}
