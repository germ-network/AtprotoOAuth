//
//  MockAtmosphere+AuthPDSAgent.swift
//  AtprotoOAuth
//
//  Created by Mark @ Germ on 6/10/26.
//

import AtprotoClient
import AtprotoOAuth
import AtprotoTypes
import Foundation
import GermConvenience

extension MockAtmosphere {
	/// Vends a mock ``Atproto/AuthPDSAgent`` for `did`.
	///
	/// Unlike `MockPDS.AuthAgent`, which talks directly to a single PDS, the
	/// returned agent routes every request back through the atmosphere's
	/// `data(for:)` fetcher. That means authentication, hosting checks, and
	/// bsky appview service-proxying all behave like the real network.
	public func authPDSAgent(did: Atproto.DID) throws -> MockAuthPDSAgent {
		//ensure the did is actually hosted before vending an agent for it
		let _ = try didDocs[did].tryUnwrap
		return MockAuthPDSAgent(did: did, atmosphere: self)
	}

	//performs an authenticated round-trip for `did`: injects the auth headers
	//the atmosphere expects, then dispatches through the shared fetcher so proxy
	//requests are handled identically to unauthed ones.
	func authedResponse(
		did: Atproto.DID,
		requestComponents: XRPCRequestComponents
	) async throws -> HTTPDataResponse {
		let pdsUrl = try didDocs[did].tryUnwrap.pdsUrl

		var requestComponents = requestComponents
		requestComponents.headers[.authorization] = try "dpop \(salted(did: did))"
		requestComponents.headers[try .dpop.tryUnwrap] = "mock-dpop"

		let request = try requestComponents.constructUrl(serviceUrl: pdsUrl)
		return try await data(for: request)
	}
}

/// A mock auth-capable PDS agent vended by ``MockAtmosphere``.
///
/// Conforms to ``Atproto/AuthPDSAgent`` so it can perform authed PDS calls as
/// well as bsky appview proxy calls (e.g. `streamSocialGraphs`).
public struct MockAuthPDSAgent: Atproto.AuthPDSAgent {
	public let did: Atproto.DID
	let atmosphere: MockAtmosphere

	public func response(
		_ requestComponents: XRPCRequestComponents
	) async throws -> HTTPDataResponse {
		try await atmosphere.authedResponse(
			did: did,
			requestComponents: requestComponents
		)
	}
}
