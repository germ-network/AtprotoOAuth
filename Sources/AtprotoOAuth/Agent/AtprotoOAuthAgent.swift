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
import Logging
import OAuth4Swift

import struct HTTPTypes.HTTPFields

public actor AtprotoOAuthAgent {
	public nonisolated let repo: Atproto.DID
	public nonisolated let authenticatedDID: Atproto.DID
	public nonisolated let resolver: Atproto.Resolver
	public let clientId: String
	public let authFetcher: HTTPFetcher

	enum State {
		case active(OAuth.SessionState)
		case refreshing(
			Task<OAuth.AccessToken, Error>,
			previous: OAuth.SessionState
		)
		case expired

		init(archive: OAuth.SessionState.Archive?) throws {
			if let archive {
				self = .active(
					try .init(
						archive: archive,
						dpopDecoder: OAuth.DPoP.decodeAtproto
					)
				)
			} else {
				self = .expired
			}
		}
	}
	var state: State
	//we require one, so get the reference to the state in the SessionState at restore (or throw)
	public nonisolated let dpopKey: OAuth.DPoP.Key

	public var lazyServerMetadata: LazyResource<AuthServerMetadata>
	public var refreshTask: Task<OAuth.SessionState.TokenState, Error>?

	private let saveStream: AsyncStream<OAuth.SessionState.Archive.Mutable?>
	private let saveContinuation: AsyncStream<OAuth.SessionState.Archive.Mutable?>.Continuation
	public enum StateUpdate {
		case loggedOut
	}
	public let updateStream: AsyncStream<StateUpdate>
	private let updateContinuation: AsyncStream<StateUpdate>.Continuation

	private let clientAuth = OAuth.ClientAuth.None()

	private init?(
		did: Atproto.DID,
		clientId: String,
		state: State,
		authFetcher: HTTPFetcher,
		atprotoResolver: Atproto.Resolver
	) throws {
		guard case .active(let sessionState) = state else {
			return nil
		}
		let dpopState = try sessionState.dPoPState.tryUnwrap
		dpopState.nonceCache.countLimit = 25

		self.repo = did
		self.authenticatedDID = did
		self.clientId = clientId
		self.state = state
		self.authFetcher = authFetcher
		self.resolver = atprotoResolver
		self.dpopKey = dpopState.signingKey

		self.lazyServerMetadata = .init(
			fetchTaskGenerator: {
				Task {
					let didDoc = try await atprotoResolver.resolve(did: did)
						.tryUnwrap
					return
						try await AtprotoOAuthUtils
						.getAuthorizationServerURL(
							pdsServiceEndpoint: didDoc.pdsUrl,
							authFetcher: authFetcher
						).0
				}
			})

		(saveStream, saveContinuation) = AsyncStream<OAuth.SessionState.Archive.Mutable?>
			.makeStream(bufferingPolicy: .bufferingNewest(1))

		(updateStream, updateContinuation) = AsyncStream<StateUpdate>
			.makeStream(bufferingPolicy: .bufferingNewest(1))
	}

	//propagate new state to our in-memory opject properties
	//then through the async streams

	private func save(
		previousSession: OAuth.SessionState,
		newTokenState: OAuth.SessionState.TokenState?
	) {
		if let newTokenState {
			saveContinuation.yield(
				.init(
					clientAuth: clientAuth.archive,
					tokenState: newTokenState
				)
			)
		} else {
			saveContinuation.yield(nil)
		}
		//don't need to undestand refresh in the UI yet
		//		updateContinuation.yield( )
	}

	//TODO: determine when we are expired and call this
	//so clients know they need to get a new session
	private func expired() {
		saveContinuation.yield(nil)
		updateContinuation.yield(.loggedOut)
	}

	var sessionState: OAuth.SessionState? {
		switch state {
		case .active(let sessionState):
			sessionState
		case .refreshing(_, previous: let sessionState):
			sessionState
		case .expired:
			nil
		}
	}
}

extension AtprotoOAuthAgent {
	public struct Archive: Sendable, Codable {
		let did: String
		public var session: OAuth.SessionState.Archive?

		public init(did: String, session: OAuth.SessionState.Archive?) {
			self.did = did
			self.session = session
		}

		public mutating func merge(
			mutableArchive: OAuth.SessionState.Archive.Mutable?
		) {
			guard let mutableArchive else {
				session = nil
				return
			}
			session?.merge(mutable: mutableArchive)
		}
	}

	package static func restore(
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
		).tryUnwrap
		return (session, session.saveStream)
	}

	private init?(
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
	public var authServerMetadata: AuthServerMetadata {
		get async throws {
			try await lazyServerMetadata.lazyValue(isolation: self)
		}
	}

	public var authToken: OAuth.AccessToken {
		get async throws {
			switch state {
			case .active(let sessionState):
				return sessionState.tokenState.accessToken
			case .refreshing(let refreshTask, previous: _):
				return try await refreshTask.value
			case .expired:
				throw OAuthSessionError.sessionInactive
			}
		}
	}

	public func startRefresh(
		continueCondition: (OAuth.RefreshToken?) -> Bool,
		refreshClosure:
			@escaping (
				OAuth.SessionState.Snapshot,
				OAuth.RefreshToken
			) async throws -> OAuth.SessionState.TokenState?
	) -> Task<OAuth.AccessToken, Error>? {
		switch state {
		case .refreshing(let task, previous: _):
			return task
		case .expired:
			return nil
		case .active(let sessionState):
			guard continueCondition(sessionState.tokenState.refreshToken) else {
				Logger(label: "AtprotoOAuthAgent").notice("Skipping refresh")
				return nil
			}
			//get sendable objects from the mutable sessionState
			let snapshot = sessionState.snapshot
			guard let refreshToken = sessionState.tokenState.refreshToken else {
				//can't refresh without a refresh token
				return nil
			}

			let newTask = Task {
				do {
					let newTokenState = try await refreshClosure(
						snapshot,
						refreshToken
					)

					save(
						previousSession: sessionState,
						newTokenState: newTokenState
					)
					if let newTokenState {
						sessionState.updated(tokenState: newTokenState)
						state = .active(sessionState)

						return sessionState.tokenState.accessToken
					} else {
						state = .expired
					}
				} catch {
					//return to previous
					state = .active(sessionState)
					return sessionState.tokenState.accessToken
				}
				throw OAuthSessionError.sessionInactive
			}

			state = .refreshing(newTask, previous: sessionState)

			return newTask
		}
	}

	public var authServerRequestOptions: OAuth.TokenRequestOptions {
		.atproto(
			did: repo,
			authFetcher: authFetcher
		)
	}
}

extension AtprotoOAuthAgent: OAuth.DPoP.Signing {

	public func getNonce(origin: String) -> OAuth.DPoP.IndexedNonce? {
		sessionState?.dPoPState?.getNonce(origin: origin)
	}

	public func cacheNonce(
		response: HTTPDataResponse,
		requestUrl: URL
	) throws {
		try sessionState?.dPoPState?
			.cacheNonce(response: response, requestUrl: requestUrl)
	}

}

extension AtprotoOAuthAgent {
	func getPDSUrl() async throws -> URL {
		try await self.resolver.resolve(did: repo).tryUnwrap.pdsUrl
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
}
