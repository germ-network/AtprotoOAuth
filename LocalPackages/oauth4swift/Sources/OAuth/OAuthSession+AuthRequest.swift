//
//  OAuthSession+AuthRequest.swift
//  OAuth
//
//  Created by Mark @ Germ on 2/25/26.
//

import Foundation

extension OAuthSession {
	public func dpopResponse(for request: URLRequest, pkceVerifier: PKCEVerifier) async throws
		-> (
			Data,
			HTTPURLResponse
		)
	{
		let sessionState = try session

		guard let dpopKey = sessionState.dPopKey else {
			throw OAuthError.missingDPoPKey
		}

		let (result, response) = try await dpopResponse(
			for: request,
			login: sessionState.mutable,
			dPoPKey: dpopKey,
			pkceVerifier: pkceVerifier
		)

		// FIXME: This isn't really to spec: 401 doesn't mean "refresh", it just means unauthorized.
		switch response.statusCode {
		case 200..<300:
			return (result, response)
		case 401:
			break
		default:
			throw OAuthError.httpResponse(response: response)
		}

		throw OAuthError.notImplemented

		//		let refreshed = try await refresh()
		//
		//		//try again
		//		let (result, response) = try await dpopResponse(
		//			for: request,
		//			login: sessionState.mutable,
		//			dPoPKey: dpopKey,
		//			pkceVerifier: pkceVerifier
		//		)

	}
}
