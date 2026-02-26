//
//  ATProtoOAuthSession.swift
//  ATProtoOAuth
//
//  Created by Mark @ Germ on 2/17/26.
//

import ATProtoClient
import ATProtoTypes
import Foundation
import GermConvenience
import OAuth

///Usage pattern: A session starts out authenticated. May degrade to lose auth
///Parent should recognize it has an expired session and re-auth

public actor ATProtoOAuthSession {
	let did: ATProtoDID
	public let appCredentials: AppCredentials
	let atprotoClient: ATProtoClientInterface

	private let nonceCache: NSCache<NSString, NonceValue> = NSCache()
	// Return value is (origin, nonce)
	private let nonceDecoder: NonceDecoder = nonceHeaderDecoder(dataResponse:)

	public static func nonceHeaderDecoder(
		dataResponse: HTTPDataResponse
	) throws -> NonceValue? {
		guard let value = dataResponse.response.value(forHTTPHeaderField: "DPoP-Nonce") else {
			return nil
		}

		// I'm not sure why response.url is optional, but maybe we need the request
		// passed into the decoder here, to fallback to request.url.origin
		guard let responseOrigin = dataResponse.response.url?.origin else {
			return nil
		}

		return NonceValue(origin: responseOrigin, nonce: value)
	}

	enum State {
		case authorizing
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

	//starts in authorizing
	static func new(
		did: ATProtoDID,
		appCredentials: AppCredentials,
		atprotoClient: ATProtoClientInterface
	) -> Self {
		.init(
			did: did,
			appCredentials: appCredentials,
			state: .authorizing,
			atprotoClient: atprotoClient
		)
	}

	private init(
		did: ATProtoDID,
		appCredentials: AppCredentials,
		state: State,
		atprotoClient: ATProtoClientInterface
	) {
		self.did = did
		self.appCredentials = appCredentials
		self.state = state
		self.atprotoClient = atprotoClient
		
		self.lazyServerMetadata = .init(fetchTaskGenerator: {
			Task {
				let pdsHost = try await atprotoClient.plcDirectoryQuery(did)
					.pdsUrl
				let pdsMetadata = try await atprotoClient.loadProtectedResourceMetadata(
					host: pdsHost.absoluteString
				)

				//https://datatracker.ietf.org/doc/html/rfc7518#section-3.1
				//PDS doesn't actually fill this field, so we only check it if present
				if let supportedAlgs = pdsMetadata.dpopSigningAlgValuesSupported {
					guard supportedAlgs.contains("ES256")
					else {
						throw OAuthSessionError.unsupported
					}
				}

				guard
					let authorizationServerUrl = pdsMetadata.authorizationServers?.first,
					let authorizationServerHost = URL(string: authorizationServerUrl)?.host()
				else {
					throw OAuthSessionError.cantFormURL
				}

				return try await atprotoClient.loadAuthServerMetadata(
					host: authorizationServerHost
				)
			}
		})

		nonceCache.countLimit = 25
	}
}

extension ATProtoOAuthSession {
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
		atprotoClient: ATProtoClientInterface
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

extension ATProtoOAuthSession: OAuthSession {
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

	public func decode(
		dataResponse: HTTPDataResponse
	) throws -> OAuth.NonceValue? {
		try nonceDecoder(dataResponse)
	}

	public static func response(for request: URLRequest) async throws -> HTTPDataResponse
	{
		try await URLSession.defaultProvider(request)
	}

	public static func authorizationURLProvider(
		authEndpoint: String,
		parRequestURI: String,
		clientId: String,
	) throws -> URL {
		var components = URLComponents(string: authEndpoint)

		components?.queryItems = [
			URLQueryItem(name: "request_uri", value: parRequestURI),
			URLQueryItem(name: "client_id", value: clientId),
		]

		guard let url = components?.url else {
			throw OAuthSessionError.cantFormURL
		}

		return url
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

extension ATProtoOAuthSession {
	func getPDSUrl() async throws -> URL {
		try await atprotoClient.plcDirectoryQuery(did)
			.pdsUrl
	}
}
