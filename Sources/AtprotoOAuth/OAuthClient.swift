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
//<<<<<<< HEAD
	) async throws -> OAuth.SessionState.Archive {
		let did: Atproto.DID
		let additionalParameters: FormParameters?
		switch identity {
		case .did(let _did, let handle):
			did = _did
			if let handle {
				additionalParameters = FormParameters(["login_hint": handle])
			} else {
				additionalParameters = nil
			}
		
		case .handle(let handle):
			//resolve handle to pds, uncached

			(did, _) = try await resolver
				.verifiedResolve(handle: handle)
				.tryUnwrap
			additionalParameters = FormParameters(["login_hint": handle])
		}
		

		let (authServerMetadata, authorizationServerUrl) =
		try await resolver
			.resolveAuthorizationServer(
				identity: .did(did),
				authFetcher: authFetcher
			)

		
		let clientAuthenticator = InitialAuthorizer(
			clientId: clientInfo.clientId,
			authFetcher: authFetcher,
			dpopKey: .generateP256(),
			decoder: AuthDPopState.decode
		)
		
		let authorizer = Authorizer(
			authorizeInputs:
					.init(
						clientInfo: clientInfo,
						authServerMetadata: authServerMetadata,
						authEndpoint: authorizationServerUrl,
						inputToken: nil,
						additionalParameters: additionalParameters,
						clientAuthenticator: clientAuthenticator
					),
					
			authServerRequestOptions:
					.atproto(
						did: did,
						authFetcher: authFetcher
					),
			userAuthenticator: userAuthenticator,
			authFetcher: authFetcher
		)
		
		return try await authorizer.performUserAuthentication()
	}
	
	struct Authorizer {
		let authorizeInputs: OAuth.AuthorizeInputs
		let authServerRequestOptions: OAuth.AuthServerRequestOptions
		let userAuthenticator: UserAuthenticator
		let authFetcher: any HTTPFetcher
	}
}

extension AtprotoOAuthClient.Authorizer: OAuth.Authorizer {
	func negotiate(authServerMetadata: AuthServerMetadata) throws -> any OAuth.ClientAuth.Authenticable {
		let serverMethods = authServerMetadata.tokenEndpointAuthMethodsSupported ?? []
		guard serverMethods
			.contains(OAuth.ClientAuth.TokenEndpointMethods.none.rawValue) else {
			throw OAuth.Errors.notImplemented
		}
		
		return InitialAuthorizer(
			clientId: authorizeInputs.clientInfo.clientId,
			authFetcher: authFetcher,
			dpopKey: .generateP256(),
			decoder: AuthDPopState.decode
		)
	}
}

actor InitialAuthorizer {
	nonisolated public let clientId: String
	nonisolated public let dpopKey: DPoPKey
	nonisolated public let authFetcher: any HTTPFetcher
	
	nonisolated public let tokenEndpointAuthMethod:  OAuth.ClientAuth.TokenEndpointMethods = .none
	let clientAuth = OAuth.ClientAuth.None()

	let nonceCache: NSCache<NSString, IndexedNonce> = NSCache()
	private let decoder: (HTTPDataResponse, URL) throws -> IndexedNonce?

	public init(
		clientId: String,
		authFetcher: HTTPFetcher,
		dpopKey: DPoPKey,
		decoder: @escaping (HTTPDataResponse, URL) throws -> IndexedNonce?
	) {
		self.clientId = clientId
		self.dpopKey = dpopKey
		self.decoder = decoder
		self.authFetcher = authFetcher
	}
}

extension InitialAuthorizer: OAuth.ClientAuth.Authenticable {
	func authenticate(inputs: OAuth.ClientAuth.Inputs) async throws -> (
		FormParameters,
		HTTPFields
	) {
		try await clientAuth.authenticate(
			clientId: clientId,
			inputs: inputs
		)
	}
	
	var clientAuthArchive: Data? {
		nil
	}
}

extension InitialAuthorizer: DPoPSigning {
	func getNonce(origin: String) -> OAuth4Swift.IndexedNonce? {
		nonceCache.object(forKey: origin as NSString)
	}
	
	func cacheNonce(response: GermConvenience.HTTPDataResponse, requestUrl: URL) throws {
		let indexedNonce = try AuthDPopState.decode(
			dataResponse: response, requestUrl: requestUrl)
		if let indexedNonce {
			nonceCache.setObject(indexedNonce, forKey: indexedNonce.origin as NSString)
		}
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
