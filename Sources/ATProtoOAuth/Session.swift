//
//  ATProtoOAuthSession.swift
//  ATProtoOAuth
//
//  Created by Mark @ Germ on 2/17/26.
//

import ATProtoClient
import ATProtoTypes
import Foundation
import OAuth

///Usage pattern: A session starts out authenticated. May degrade to lose auth
///Parent should recognize it has an expired session and re-auth

public actor ATProtoOAuthSession {
	let did: ATProtoDID
	let atprotoClient: ATProtoClientInterface

	private let nonceCache: NSCache<NSString, NonceValue> = NSCache()
	// Return value is (origin, nonce)
	private let nonceDecoder: NonceDecoder = nonceHeaderDecoder(data:response:)

	public static func nonceHeaderDecoder(data: Data, response: HTTPURLResponse) throws
		-> NonceValue?
	{
		guard let value = response.value(forHTTPHeaderField: "DPoP-Nonce") else {
			return nil
		}

		// I'm not sure why response.url is optional, but maybe we need the request
		// passed into the decoder here, to fallback to request.url.origin
		guard let responseOrigin = response.url?.origin else {
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

	//starts in authorizing
	static func new(
		did: ATProtoDID,
		atprotoClient: ATProtoClientInterface
	) -> Self {
		.init(
			did: did,
			state: .authorizing,
			atprotoClient: atprotoClient
		)
	}

	private init(
		did: ATProtoDID,
		state: State,
		atprotoClient: ATProtoClientInterface
	) {
		self.did = did
		self.state = state
		self.atprotoClient = atprotoClient

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
		atprotoClient: ATProtoClientInterface
	) throws {
		try self.init(
			did: .init(fullId: archive.did),
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
		nonceResult: Data,
		response: HTTPURLResponse
	) throws -> OAuth.NonceValue? {
		try nonceDecoder(nonceResult, response)
	}

	public static func response(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
	{
		let (data, response) = try await URLSession.defaultProvider(request)
		guard let httpResponse = response as? HTTPURLResponse else {
			throw OAuthSessionError.incorrectResponseType
		}
		return (data, httpResponse)
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
