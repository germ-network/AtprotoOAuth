//
//  OAuthClient.swift
//  AtprotoOAuth
//
//  Created by Mark @ Germ on 4/7/26.
//

import AtprotoTypes
import Foundation
import GermConvenience
import HTTPTypes
import OAuth4Swift

//encapsulate the objects needed to authorize and restore a session
public struct AtprotoOAuthClient: Sendable {
	public let clientInfo: OAuth.ClientInfo
	public let resolver: Atproto.Resolver
	public let authFetcher: HTTPFetcher
	public let userAuthenticator: UserAuthenticator

	public init(
		clientInfo: OAuth.ClientInfo,
		resolver: Atproto.Resolver,
		authFetcher: HTTPFetcher,
		userAuthenticator: @escaping UserAuthenticator
	) {
		self.clientInfo = clientInfo
		self.resolver = resolver
		self.authFetcher = authFetcher
		self.userAuthenticator = userAuthenticator
	}
}

extension AtprotoOAuthClient {
	public func authorize(
		identity: AuthIdentity,
	) async throws -> OAuth.SessionState.Archive {
		let did: Atproto.DID
		let didDoc: Atproto.DIDDocument
		switch identity {
		case .did(let _did, let handle):
			did = _did
			didDoc = try await resolver.resolve(did: did).tryUnwrap

		case .handle(let handle):
			//resolve handle to pds, uncached

			(did, didDoc) =
				try await resolver
				.verifiedResolve(handle: handle)
				.tryUnwrap
		}
		let additionalParameters = FormParameters(
			["login_hint": identity.serverHint]
		)

		let (authServerMetadata, authorizationServerUrl) =
			try await AtprotoOAuthUtils.getAuthorizationServerURL(
				pdsServiceEndpoint: didDoc.pdsUrl,
				authFetcher: authFetcher
			)

		let authorizer = Authorizer(
			clientId: clientInfo.clientId,
			authorizeInputs:
				.init(
					clientInfo: clientInfo,
					authServerMetadata: authServerMetadata,
					authEndpoint: authorizationServerUrl,
					inputToken: nil,
					additionalParameters: additionalParameters,
					userAuthenticator: userAuthenticator,
				),

			tokenRequestOptions:
				.atproto(
					did: did,
					authFetcher: authFetcher
				),
			authFetcher: authFetcher,
		)

		return try await authorizer.performUserAuthentication()
	}

	actor Authorizer: OAuth.Authorizer, OAuth.DPoP.Signing {
		let clientId: String
		let authorizeInputs: OAuth.AuthorizeInputs
		let tokenRequestOptions: OAuth.TokenRequestOptions
		let authFetcher: any HTTPFetcher

		//for client auth
		nonisolated public let tokenEndpointAuthMethod:
			OAuth.ClientAuth.TokenEndpointMethods =
				.none
		let clientAuth = OAuth.ClientAuth.None()

		//for dpop
		let dpopState = OAuth.DPoP.State(
			signingKey: .generateP256(),
			decoder: OAuth.DPoP.decodeAtproto(dataResponse:requestUrl:)
		)

		public init(
			clientId: String,
			authorizeInputs: OAuth.AuthorizeInputs,
			tokenRequestOptions: OAuth.TokenRequestOptions,
			authFetcher: any HTTPFetcher,
		) {
			self.clientId = clientId
			self.authorizeInputs = authorizeInputs
			self.tokenRequestOptions = tokenRequestOptions
			self.authFetcher = authFetcher
		}
	}
}

//OAuth.ClientAuth.Authenticable
extension AtprotoOAuthClient.Authorizer {
	func authenticate(inputs: OAuth.ClientAuth.Inputs) async throws -> (
		FormParameters,
		HTTPFields
	) {
		try await clientAuth.authenticate(
			clientId: clientId,
			inputs: inputs
		)
	}

	nonisolated var clientAuthArchive: Data? {
		nil
	}
}

extension AtprotoOAuthClient.Authorizer {
	var dpopKey: OAuth.DPoP.Key {
		dpopState.signingKey
	}

	func getNonce(origin: String) -> OAuth.DPoP.IndexedNonce? {
		dpopState.getNonce(origin: origin)
	}

	func cacheNonce(response: HTTPDataResponse, requestUrl: URL) throws {
		try dpopState.cacheNonce(response: response, requestUrl: requestUrl)
	}
}

extension AtprotoOAuthClient {
	public func restore(
		archive: AtprotoOAuthAgent.Archive,
	) throws -> (
		AtprotoOAuthAgent,
		AsyncStream<OAuth.SessionState.Archive.Mutable?>
	) {
		try AtprotoOAuthAgent
			.restore(
				archive: archive,
				clientId: clientInfo.clientId,
				authFetcher: authFetcher,
				atprotoResolver: resolver
			)
	}
}
