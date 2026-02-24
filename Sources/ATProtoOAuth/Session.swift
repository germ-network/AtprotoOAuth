//
//  ATProtoOAuthSession.swift
//  ATProtoOAuth
//
//  Created by Mark @ Germ on 2/17/26.
//

import Foundation
import OAuth

///Usage pattern: A session starts out authenticated. May degrade to lose auth
///Parent should recognize it has an expired session and re-auth

public actor ATProtoOAuthSession {
	enum State {
		case active(SessionState)
		case expired
	}
	var state: State

	private init(state: State) {
		self.state = state
	}
}

extension ATProtoOAuthSession {
	public init(archive: SessionState.Archive) {
		self.init(state: .active(.init(archive: archive)))
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
		params: AuthorizationURLParameters
	) throws -> URL {
		var components = URLComponents(string: authEndpoint)

		components?.queryItems = [
			URLQueryItem(name: "request_uri", value: params.parRequestURI),
			URLQueryItem(name: "client_id", value: params.credentials.clientId),
		]

		guard let url = components?.url else {
			throw OAuthSessionError.cantFormURL
		}

		return url
	}

	//	public static func authorizationURLProvider(server: ServerMetadata) -> AuthorizationURLProvider {
	//		{ params in
	//			var components = URLComponents(string: server.authorizationEndpoint)
	//
	//			components?.queryItems = [
	//				URLQueryItem(name: "request_uri", value: params.parRequestURI),
	//				URLQueryItem(name: "client_id", value: params.credentials.clientId),
	//			]
	//
	//			guard let url = components?.url else {
	//				throw OAuthSessionError.cantFormURL
	//			}
	//
	//			return url
	//		}
	//	}
}
