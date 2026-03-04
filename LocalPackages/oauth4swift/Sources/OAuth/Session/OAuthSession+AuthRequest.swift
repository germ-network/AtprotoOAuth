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

		let issuerOrigin = try URL(string: serverMetadata.issuer).tryUnwrap.origin
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
		let refreshed = try await conservingRefresh(state: sessionState)

		//try again
		return try await dpopResponse(
			for: request,
			issuerOrigin: issuerOrigin,
			token: refreshed.accessToken.value,

		)
	}

	//conserving in that it reuses result if a refresh is alread in flght
	private func conservingRefresh(state: SessionState) async throws -> SessionState.Mutable {
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

	//compare to refreshTokenGrantRequest
	//and processRefreshTokenResponse in
	private func refresh(
		state: SessionState,
		appCredentials: AppCredentials,
	) async throws -> SessionState.Mutable {
		let authServerMetadata = try await getAuthServerMetadata()
		let httpResponse = try await refreshTokenGrantRequest(
			authServerMetadata: authServerMetadata,
			refreshToken: state.mutable.refreshToken.tryUnwrap.value
		)
		let response = try await processRefreshTokenResponse(response: httpResponse)

		return try validate(
			authMetadata: authServerMetadata,
			tokenResponse: response
		)
	}

}
