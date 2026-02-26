//
//  OAuthSession+AuthRequest.swift
//  OAuth
//
//  Created by Mark @ Germ on 2/25/26.
//

import Foundation
import GermConvenience

extension OAuthSession {
	public func authResponse(
		for request: URLRequest,
	) async throws -> HTTPDataResponse {
		let sessionState = try session

		guard let dpopKey = sessionState.dPopKey else {
			throw OAuthError.missingDPoPKey
		}

		let dataResponse = try await dpopResponse(
			for: request,
			login: sessionState.mutable,
			dPoPKey: dpopKey,
			pkceVerifier: pkceVerifier
		)

		// FIXME: This isn't really to spec: 401 doesn't mean "refresh", it just means unauthorized.
		switch dataResponse.response.statusCode {
		case 200..<300:
			return dataResponse
		case 401:
			break
		default:
			throw OAuthError.httpResponse(response: dataResponse.response)
		}

		//try to refresh the token
		throw OAuthError.notImplemented

		let refreshed = try await refresh(state: sessionState)

		//try again
		return try await dpopResponse(
			for: request,
			login: refreshed,
			dPoPKey: dpopKey,
			pkceVerifier: pkceVerifier
		)
	}

	private func refresh(state: SessionState) async throws -> SessionState.Mutable {
		if let refreshTask {
			return try await refreshTask.value
		}

		let newRefreshTask = Task {
			try await refreshProvider(
				sessionState: state.archive,
				appCredentials: appCredentials
			)
		}

		refreshTask = newRefreshTask

		defer {
			refreshTask = nil
		}

		//handle successful refresh

		return try await newRefreshTask.value
	}
}
