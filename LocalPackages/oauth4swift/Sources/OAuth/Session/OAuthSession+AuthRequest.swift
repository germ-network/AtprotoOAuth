//
//  OAuthSession+AuthRequest.swift
//  OAuth
//
//  Created by Mark @ Germ on 2/25/26.
//

import Foundation
import GermConvenience

extension OAuthSessionCapabilities {
	public func authResponse(
		for request: URLRequest,
	) async throws -> HTTPDataResponse {
		let sessionState = try session
		let serverMetadata = try await lazyServerMetadata.lazyValue(
			isolation: self
		)

		let issuerOrigin = try URL(string: serverMetadata.issuer).tryUnwrap.origin.tryUnwrap
		let dataResponse = try await dpopResponse(
			for: request,
			issuerOrigin: issuerOrigin,
			token: sessionState.mutable.accessToken.value,

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
		let refreshed = try await refresh(state: sessionState)

		//try again
		return try await dpopResponse(
			for: request,
			issuerOrigin: issuerOrigin,
			token: refreshed.accessToken.value,

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
