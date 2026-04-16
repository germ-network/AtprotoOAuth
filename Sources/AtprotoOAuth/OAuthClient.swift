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
			//TODO: use verified resolve
			did = try await resolver.resolve(handle: handle)
			additionalParameters = FormParameters(["login_hint": handle])
		}

		//resolve pds and pds metadata
		let didDoc = try await resolver.resolve(did: did)
		if case .handle(let handle) = identity {
			if handle != didDoc.handle {
				throw OAuthClientError.handleMismatch
			}
		}

		let authorizationServerUrl =
			try await didDoc
			.getAuthorizationUrl(authFetcher: authFetcher)
		
		let authorizer = Authorizer(
			authorizeInputs: .init(
				clientInfo: clientInfo,
				issuer: authorizationServerUrl,
				inputToken: nil,
				additionalParameters: additionalParameters
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
}
