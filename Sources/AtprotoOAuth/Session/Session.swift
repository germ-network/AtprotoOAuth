//
//  AtprotoOAuthSession.swift
//  AtprotoOAuth
//
//  Created by Mark @ Germ on 2/17/26.
//

import AtprotoClient
import AtprotoTypes
import Foundation
import GermConvenience
import OAuth

///Usage pattern: A session starts out authenticated. May degrade to lose auth
///Parent should recognize it has an expired session and re-auth

public actor AtprotoOAuthSession {
	public nonisolated let did: Atproto.DID
	public let appCredentials: AppCredentials
	let atprotoClient: AtprotoClientInterface

	public let pkceVerifier = PKCEVerifier()
	private let nonceCache: NSCache<NSString, NonceValue> = NSCache()

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
	public var refreshTask: Task<SessionState.Mutable, Error>?

	private init(
		did: Atproto.DID,
		appCredentials: AppCredentials,
		state: State,
		atprotoClient: AtprotoClientInterface
	) {
		self.did = did
		self.appCredentials = appCredentials
		self.state = state
		self.atprotoClient = atprotoClient

		self.lazyServerMetadata = .init(
			fetchTaskGenerator: {
				Task {
					let pdsHost = try await atprotoClient.plcDirectoryQuery(did)
						.pdsUrl
					let pdsMetadata = try await ProtectedResourceMetadata.load(
						for: pdsHost.host().tryUnwrap,
						provider: URLSession.defaultProvider
					)

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
						let authorizationServerHost = URL(
							string: authorizationServerUrl)?.host()
					else {
						throw OAuthSessionError.cantFormURL
					}

					return try await AuthServerMetadata.load(
						for: authorizationServerHost,
						provider: URLSession.defaultProvider
					)
				}
			})

		nonceCache.countLimit = 25
	}

	public func authProcedure<X: XRPCProcedure>(
		_ xrpc: X.Type,
		parameters: X.Parameters
	) async throws -> X.Result {
		try await atprotoClient.authProcedure(
			_: xrpc,
			pdsUrl: try await getPDSUrl(),
			parameters: parameters,
			session: self
		)
	}

	public func authRequest<X: XRPCRequest>(
		_ xrpc: X.Type,
		parameters: X.Parameters
	) async throws -> X.Result {
		try await atprotoClient.authRequest(
			xrpc,
			pdsUrl: try await getPDSUrl(),
			parameters: parameters,
			session: self
		)
	}
}

extension AtprotoOAuthSession {
	public struct Archive {
		let did: String
		let session: SessionState.Archive?

		public init(did: String, session: SessionState.Archive?) {
			self.did = did
			self.session = session
		}
	}

	public init(
		archive: Archive,
		appCredentials: AppCredentials,
		atprotoClient: AtprotoClientInterface
	) throws {
		try self.init(
			did: .init(fullId: archive.did),
			appCredentials: appCredentials,
			state: .init(archive: archive.session),
			atprotoClient: atprotoClient
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

extension AtprotoOAuthSession: OAuthSession {
	public var session: OAuth.SessionState {
		get throws {
			guard case .active(let sessionState) = state else {
				throw OAuthSessionError.sessionInactive
			}
			return sessionState
		}
	}

	public func refreshed(sessionMutable: OAuth.SessionState.Mutable) throws {
		let session = try session

		session.updated(mutable: sessionMutable)
		//TODO: save this
	}

	public static func response(for request: URLRequest) async throws -> HTTPDataResponse {
		try await URLSession.defaultProvider(request)
	}
}

extension AtprotoOAuthSession: DPoPNonceHolding {
	public var dpopKey: OAuth.DPoPKey {
		get throws {
			try session.dPopKey.tryUnwrap
		}
	}

	public func response(request: URLRequest) async throws -> GermConvenience.HTTPDataResponse {
		try await URLSession.defaultProvider(request)
	}

	public static func decode(
		dataResponse: HTTPDataResponse
	) throws -> OAuth.NonceValue? {
		guard let value = dataResponse.response.value(forHTTPHeaderField: "DPoP-Nonce")
		else {
			return nil
		}

		// I'm not sure why response.url is optional, but maybe we need the request
		// passed into the decoder here, to fallback to request.url.origin
		guard let responseOrigin = dataResponse.response.url?.origin else {
			return nil
		}

		return NonceValue(origin: responseOrigin, nonce: value)
	}

	public func getNonce(origin: String) -> NonceValue? {
		nonceCache.object(forKey: origin as NSString)
	}

	public func store(nonce: String, for origin: String) {
		nonceCache.setObject(
			.init(origin: origin, nonce: nonce),
			forKey: origin as NSString
		)

	}
}

extension AtprotoOAuthSession {
	func getPDSUrl() async throws -> URL {
		try await atprotoClient.plcDirectoryQuery(did)
			.pdsUrl
	}
}
