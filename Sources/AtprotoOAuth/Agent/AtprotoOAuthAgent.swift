//
//  AtprotoOAuthAgent.swift
//  AtprotoOAuth
//
//  Created by Mark @ Germ on 2/28/26.
//

import AtprotoClient
import AtprotoTypes
import Foundation
import GermConvenience
import HTTPTypes
import OAuth4Swift

public actor AtprotoOAuthAgent {
	public nonisolated let repo: Atproto.DID
	public nonisolated let authenticatedDID: Atproto.DID
	public nonisolated let resolver: Atproto.Resolver
	public let clientId: String
	public let authFetcher: HTTPFetcher

	private let nonceCache: NSCache<NSString, IndexedNonce> = NSCache()

	enum State {
		case active(OAuth.SessionState)
		case expired

		init(archive: OAuth.SessionState.Archive?) throws {
			if let archive {
				self = .active(try .init(archive: archive))
			} else {
				self = .expired
			}
		}
	}
	var state: State
	//concurrency workaround to store the key held in SessionState
	private let _dpopKey: DPoPKey?
	public var lazyServerMetadata: LazyResource<AuthServerMetadata>
	public var lazyIssuer: LazyResource<URL>
	public var refreshTask: Task<OAuth.SessionState.TokenState, Error>?

	private let saveStream: AsyncStream<OAuth.SessionState.Archive.Mutable?>
	private let saveContinuation: AsyncStream<OAuth.SessionState.Archive.Mutable?>.Continuation
	public enum StateUpdate {
		case loggedOut
	}
	public let updateStream: AsyncStream<StateUpdate>
	private let updateContinuation: AsyncStream<StateUpdate>.Continuation
	
	private let clientAuth = OAuth.ClientAuth.None()

	private init(
		did: Atproto.DID,
		clientId: String,
		state: State,
		authFetcher: HTTPFetcher,
		atprotoResolver: Atproto.Resolver
	) {
		self.repo = did
		self.authenticatedDID = did
		self.clientId = clientId
		self.state = state
		self.authFetcher = authFetcher
		self.resolver = atprotoResolver
		
		switch state {
		case .active(let sessionState):
			_dpopKey = sessionState.dPopKey
		case .expired:
			_dpopKey = nil
		}

		self.lazyServerMetadata = .init(
			fetchTaskGenerator: {
				Task {
					let pdsHost = try await atprotoResolver.resolve(did: did)
						.pdsUrl
					let pdsMetadata =
						try await authFetcher.resourceDiscoveryRequest(
							url: pdsHost)

					//https://datatracker.ietf.org/doc/html/rfc7518#section-3.1
					//PDS doesn't actually fill this field, so we only check it if present
					if let supportedAlgs = pdsMetadata
						.dpopSigningAlgValuesSupported
					{
						guard supportedAlgs.contains("ES256")
						else {
							throw OAuthSessionError
								.unsupportedDpopSigningAlgorithm
						}
					}

					guard
						let authorizationServerUrlString = pdsMetadata
							.authorizationServers?.first,
						let authorizationServerUrl = URL(
							string: authorizationServerUrlString)
					else {
						throw OAuthSessionError.cantFormURL
					}

					return try await authFetcher.authServerDiscovery(
						issuer: authorizationServerUrl)
				}
			})

		self.lazyIssuer = .init(
			fetchTaskGenerator: {
				Task {
					let pdsHost = try await atprotoResolver.resolve(did: did)
						.pdsUrl
					let pdsMetadata =
						try await authFetcher.resourceDiscoveryRequest(
							url: pdsHost)

					//https://datatracker.ietf.org/doc/html/rfc7518#section-3.1
					//PDS doesn't actually fill this field, so we only check it if present
					if let supportedAlgs = pdsMetadata
						.dpopSigningAlgValuesSupported
					{
						guard supportedAlgs.contains("ES256")
						else {
							throw OAuthSessionError.unsupported
						}
					}

					guard
						let authorizationServerUrl = pdsMetadata
							.authorizationServers?.first,
						let authorizationServer = URL(
							string: authorizationServerUrl)
					else {
						throw OAuthSessionError.cantFormURL
					}

					return authorizationServer
				}
			})

		nonceCache.countLimit = 25

		(saveStream, saveContinuation) = AsyncStream<OAuth.SessionState.Archive.Mutable?>
			.makeStream(bufferingPolicy: .bufferingNewest(1))

		(updateStream, updateContinuation) = AsyncStream<StateUpdate>
			.makeStream(bufferingPolicy: .bufferingNewest(1))
	}

	//propagate new state to our in-memory opject properties
	//then through the async streams

	private func save(tokenState: OAuth.SessionState.TokenState) throws {
		try session.updated(tokenState: tokenState)

		saveContinuation.yield(
			.init(
				clientAuth: try session.authArchive,
				tokenState: tokenState
			)
		)
		//don't need to undestand refresh in the UI yet
		//		updateContinuation.yield( )
	}

	//TODO: determine when we are expired and call this
	//so clients know they need to get a new session
	private func expired() {
		saveContinuation.yield(nil)
		updateContinuation.yield(.loggedOut)
	}
}

extension AtprotoOAuthAgent {
	public struct Archive: Sendable, Codable {
		let did: String
		public let session: OAuth.SessionState.Archive?

		public init(did: String, session: OAuth.SessionState.Archive?) {
			self.did = did
			self.session = session
		}
	}

	static func restore(
		archive: Archive,
		clientId: String,
		authFetcher: HTTPFetcher,
		atprotoResolver: Atproto.Resolver
	) throws -> (
		AtprotoOAuthAgent,
		AsyncStream<OAuth.SessionState.Archive.Mutable?>
	) {
		let session = try AtprotoOAuthAgent(
			archive: archive,
			clientId: clientId,
			authFetcher: authFetcher,
			atprotoResolver: atprotoResolver
		)
		return (session, session.saveStream)
	}

	private init(
		archive: Archive,
		clientId: String,
		authFetcher: HTTPFetcher,
		atprotoResolver: Atproto.Resolver
	) throws {
		try self.init(
			did: .init(string: archive.did),
			clientId: clientId,
			state: .init(archive: archive.session),
			authFetcher: authFetcher,
			atprotoResolver: atprotoResolver
		)
	}

	//if expired not worth saving
	var archive: OAuth.SessionState.Archive? {
		get throws {
			guard case .active(let sessionState) = state else {
				return nil
			}
			return try sessionState.archive
		}
	}
}

extension AtprotoOAuthAgent: AuthPDSAgent {
	public nonisolated var did: AtprotoTypes.Atproto.DID {
		repo
	}

	public func response(
		_ requestComponents: XRPCRequestComponents
	) async throws -> HTTPDataResponse {
		let pdsUrl = try await getPDSUrl()

		let request = try requestComponents.constructUrl(serviceUrl: pdsUrl)

		return try await authResponse(for: request)
	}
}

extension AtprotoOAuthAgent: OAuth.SessionCapabilities {
	public func refreshed(tokenState: OAuth.SessionState.TokenState) throws {
		try save(tokenState: tokenState)
	}

	public var session: OAuth.SessionState {
		get throws {
			guard case .active(let sessionState) = state else {
				throw OAuthSessionError.sessionInactive
			}
			return sessionState
		}
	}

	public var retriableIssuer: URL {
		get async throws {
			try await lazyIssuer.lazyValue(isolation: self)
		}
	}

	public var authServerRequestOptions: OAuth.AuthServerRequestOptions {
		.atproto(
			did: repo,
			authFetcher: authFetcher
		)
	}
}

extension AtprotoOAuthAgent: DPoPSigning {
	public nonisolated var dpopKey: DPoPKey {
		get throws {
			try _dpopKey.tryUnwrap
		}
	}

	public func getNonce(origin: String) -> IndexedNonce? {
		nonceCache.object(forKey: origin as NSString)
	}

	public func cacheNonce(response: GermConvenience.HTTPDataResponse, requestUrl: URL) throws {
		let indexedNonce = try AuthDPopState.decode(
			dataResponse: response, requestUrl: requestUrl)
		if let indexedNonce {
			nonceCache.setObject(indexedNonce, forKey: indexedNonce.origin as NSString)
		}
	}

}

extension AtprotoOAuthAgent {
	func getPDSUrl() async throws -> URL {
		try await self.resolver.resolve(did: repo).pdsUrl
	}
}

extension AtprotoOAuthAgent: OAuth.ClientAuth.Authenticable {
	public nonisolated var tokenEndpointAuthMethod: OAuth.ClientAuth.TokenEndpointMethods {
		.none
	}

	public func authenticate(inputs: OAuth.ClientAuth.Inputs) async throws -> (
		FormParameters,
		HTTPFields
	) {
		try await clientAuth.authenticate(clientId: clientId, inputs: inputs)
	}

	public var clientAuthArchive: Data? {
		nil
	}

	
}
