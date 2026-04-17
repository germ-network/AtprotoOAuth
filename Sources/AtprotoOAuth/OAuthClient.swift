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
public struct AtprotoOAuthClient: Sendable {
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
		let didDoc: Atproto.DIDDocument = try await {
			switch identity {
			case .handle(let handle):
				return
					try await resolver
					.verifiedResolve(handle: handle)
					.tryUnwrap
			//handle is provided for the login UI, we accept the
			//alsoKnown at from the did doc. Client's job to compare
			//if that matters if they differ
			case .did(let did, _):
				return try await resolver.resolve(did: did)
					.tryUnwrap
			}
		}()

		let authorizationServerUrl =
			try await didDoc
			.getAuthorizationUrl(authFetcher: authFetcher)

		return try await AuthServerRequestOptions.atproto(
			clientMetadata: clientMetadata,
			did: didDoc.did,
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

extension Atproto.DIDDocument {
	func getAuthorizationUrl(
		authFetcher: HTTPFetcher
	) async throws -> URL {
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

	var did: Atproto.DID {
		get throws {
			try .init(string: id)
		}
	}
}
