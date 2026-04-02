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
import OAuth

public actor AtprotoOAuthAgent {
	public nonisolated let repo: Atproto.DID
	public nonisolated let resolver: Atproto.Resolver
	public let clientMetadata: OAuthClient
	public let authFetcher: HTTPFetcher

	private let nonceCache: NSCache<NSString, IndexedNonce> = NSCache()

	enum State {
		case active(SessionState)
		case expired

		init(archive: SessionState.Archive?) {
			if let archive {
				self = .active(.init(archive: archive))
			} else {
				self = .expired
			}
		}
	}
	var state: State
	public var lazyServerMetadata: LazyResource<AuthServerMetadata>
	public var lazyIssuer: LazyResource<URL>
	public var refreshTask: Task<SessionState.Mutable, Error>?

	private let saveStream: AsyncStream<SessionState.Mutable?>
	private let saveContinuation: AsyncStream<SessionState.Mutable?>.Continuation
	public enum StateUpdate {
		case loggedOut
	}
	public let updateStream: AsyncStream<StateUpdate>
	private let updateContinuation: AsyncStream<StateUpdate>.Continuation

	private init(
		did: Atproto.DID,
		clientMetadata: OAuthClient,
		state: State,
		authFetcher: HTTPFetcher,
		atprotoResolver: Atproto.Resolver
	) {
		self.repo = did
		self.clientMetadata = clientMetadata
		self.state = state
		self.authFetcher = authFetcher
		self.resolver = atprotoResolver

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

		(saveStream, saveContinuation) = AsyncStream<SessionState.Mutable?>
			.makeStream(bufferingPolicy: .bufferingNewest(1))

		(updateStream, updateContinuation) = AsyncStream<StateUpdate>
			.makeStream(bufferingPolicy: .bufferingNewest(1))
	}

	//propagate new state to our in-memory opject properties
	//then through the async streams

	private func save(sessionMutable: SessionState.Mutable) throws {
		try session.updated(mutable: sessionMutable)

		saveContinuation.yield(sessionMutable)
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
		let session: SessionState.Archive?

		public init(did: String, session: SessionState.Archive?) {
			self.did = did
			self.session = session
		}
	}

	public static func restore(
		archive: Archive,
		clientMetadata: OAuthClient,
		authFetcher: HTTPFetcher,
		atprotoResolver: Atproto.Resolver
	) throws -> (AtprotoOAuthAgent, AsyncStream<SessionState.Mutable?>) {
		let session = try AtprotoOAuthAgent(
			archive: archive,
			clientMetadata: clientMetadata,
			authFetcher: authFetcher,
			atprotoResolver: atprotoResolver
		)
		return (session, session.saveStream)
	}

	private init(
		archive: Archive,
		clientMetadata: OAuthClient,
		authFetcher: HTTPFetcher,
		atprotoResolver: Atproto.Resolver
	) throws {
		try self.init(
			did: .init(string: archive.did),
			clientMetadata: clientMetadata,
			state: .init(archive: archive.session),
			authFetcher: authFetcher,
			atprotoResolver: atprotoResolver
		)
	}

	//if expired not worth saving
	var archive: SessionState.Archive? {
		guard case .active(let sessionState) = state else {
			return nil
		}
		return sessionState.archive
	}
}

extension AtprotoOAuthAgent: AtprotoAgent {
	public func response(
		_ requestComponents: XRPCRequestComponents
	) async throws -> HTTPDataResponse {
		let pdsUrl = try await getPDSUrl()

		let request = try requestComponents.constructUrl(serviceUrl: pdsUrl)

		return try await authResponse(for: request)
	}
}

extension AtprotoOAuthAgent: AtprotoProxyAgent {}

extension AtprotoOAuthAgent: OAuthSessionCapabilities {
	public var session: SessionState {
		get throws {
			guard case .active(let sessionState) = state else {
				throw OAuthSessionError.sessionInactive
			}
			return sessionState
		}
	}

	public func refreshed(sessionMutable: SessionState.Mutable) throws {
		try save(sessionMutable: sessionMutable)
	}

	public var retriableIssuer: URL {
		get async throws {
			try await lazyIssuer.lazyValue(isolation: self)
		}
	}

	public var authServerRequestOptions: AuthServerRequestOptions {
		.atproto(
			clientMetadata: clientMetadata,
			did: repo,
			authFetcher: authFetcher,
			dpopSigner: self
		)
	}
}

extension AtprotoOAuthAgent: DPoPSigning {
	public var dpopKey: OAuth.DPoPKey {
		get throws {
			try session.dPopKey.tryUnwrap
		}
	}

	public func getNonce(origin: String) -> OAuth.IndexedNonce? {
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
