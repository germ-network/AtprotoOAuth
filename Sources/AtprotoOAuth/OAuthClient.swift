//
//  OAuthClient.swift
//  AtprotoOAuth
//
//  Created by Mark @ Germ on 4/7/26.
//

import AtprotoTypes
import Foundation
import GermConvenience
import OAuth

//encapsulate the objects needed to authorize and restore a session
public struct AtprotoOAuthClient {
	public let clientMetadata: OAuthClient
	public let resolver: Atproto.Resolver
	public let authFetcher: HTTPFetcher
	public let userAuthenticator: UserAuthenticator
	
	public init(
		clientMetadata: OAuthClient,
		resolver: Atproto.Resolver,
		authFetcher: HTTPFetcher,
		userAuthenticator: @escaping UserAuthenticator
	) {
		self.clientMetadata = clientMetadata
		self.resolver = resolver
		self.authFetcher = authFetcher
		self.userAuthenticator = userAuthenticator
	}
}

extension AtprotoOAuthClient {
	public func authorize(
		identity: AuthIdentity,
	) async throws -> SessionState.Archive {
		let did: Atproto.DID
		switch identity {
		case .did(let _did, _):
			did = _did
		case .handle(let handle):
			//resolve handle to pds, uncached
			did = try await resolver.resolve(handle: handle)
		}

		//resolve pds and pds metadata
		let didDoc = try await resolver.resolve(did: did)
		if case .handle(let handle) = identity {
			if handle != didDoc.handle {
				throw OAuthClientError.handleMismatch
			}
		}

		let authorizationServerUrl = try await Self.getAuthorizationUrl(
			didDoc: didDoc,
			authFetcher: authFetcher
		)

		return try await AuthServerRequestOptions.atproto(
			clientMetadata: clientMetadata,
			did: did,
			authFetcher: authFetcher,
			dpopSigner: AuthDPopState(
				dpopKey: .generateP256(),
				decoder: AuthDPopState.decode
			)
		).performUserAuthentication(
			authorizeInputs: .init(
				clientMetadata: clientMetadata,
				parConfig: .init(
					parameters: ["login_hint": identity.serverHint]
				),
				issuer: authorizationServerUrl
			),
			userAuthenticator: userAuthenticator,
		)
	}

	private static func getAuthorizationUrl(
		didDoc: Atproto.DIDDocument,
		authFetcher: HTTPFetcher
	) async throws -> URL {
		let pdsUrl = try didDoc.pdsUrl

		let pdsMetadata =
			try await authFetcher.resourceDiscoveryRequest(url: pdsUrl)

		//https://datatracker.ietf.org/doc/html/rfc7518#section-3.1
		//PDS doesn't actually fill this field, so we only check it if present
		if let supportedAlgs = pdsMetadata.dpopSigningAlgValuesSupported {
			guard supportedAlgs.contains("ES256")
			else {
				throw OAuthClientError.notImplemented
			}
		}

		guard
			let authorizationServerString = pdsMetadata.authorizationServers?.first,
			let authorizationServerUrl = URL(string: authorizationServerString)
		else {
			throw OAuthClientError.missingUrlHost
		}
		return authorizationServerUrl
	}
}

extension AtprotoOAuthClient {
	public func restore(
		archive: AtprotoOAuthAgent.Archive,
	) throws -> (AtprotoOAuthAgent, AsyncStream<SessionState.Mutable?>) {
		try AtprotoOAuthAgent
			.restore(
				archive: archive,
				clientMetadata: clientMetadata,
				authFetcher: authFetcher,
				atprotoResolver: resolver
			)
	}
}
