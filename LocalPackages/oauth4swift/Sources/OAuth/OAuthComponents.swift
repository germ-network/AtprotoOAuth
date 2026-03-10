//
//  OAuthComponents.swift
//  OAuth
//
//  Created by Mark @ Germ on 3/5/26.
//

import Foundation
import GermConvenience

#if canImport(FoundationNetworking)
	import FoundationNetworking
#endif

///Direct analog to oauth4web's OAuth module in providing stateless API as building blocks for a full client
public enum OAuthComponents {
	static public func processPushedAuthorizationResponse(
		response: HTTPDataResponse
	) throws -> PARResponse {
		let parsed =
			try response
			.success(
				code: 201,
				decodeResult: PARResponse.self,
				orError: OAuthErrorResponse.self
			)

		switch parsed {
		case .result(let result):
			return result
		case .error(let errorResponse, _):
			throw OAuthError.oauthError(errorResponse, response.response)
		}
	}

	static public func validateAuthResponse(
		authServerMetadata: AuthServerMetadata,
		redirectURL: URL,
		expectedState: String
	) throws -> ParsedRedirect {
		// decode the params in the redirectURL
		let redirectComponents = try URLComponents(
			url: redirectURL,
			resolvingAgainstBaseURL: false
		).tryUnwrap

		//first check for iss and state and bail if not present
		guard
			let iss = redirectComponents.queryItems?.first(where: {
				$0.name == "iss"
			})?.value,
			let state = redirectComponents.queryItems?.first(where: {
				$0.name == "state"
			})?.value
		else {
			throw OAuthError.redirectMissingComponents
		}

		//check for error_description or error
		if let errorItem = redirectComponents.queryItems?.first(where: {
			$0.name == "error_description"
		}) {
			throw OAuthError.redirectError(errorItem.value ?? "")
		}

		if let errorItem = redirectComponents.queryItems?.first(where: {
			$0.name == "error"
		}) {
			throw OAuthError.redirectError(errorItem.value ?? "")
		}

		//assert we do not support insecure flows
		assert(
			redirectComponents.queryItems?.first(where: {
				$0.name == "id_token"
			})?.value == nil)
		assert(
			redirectComponents.queryItems?.first(where: {
				$0.name == "token"
			})?.value == nil)

		//finally can check for presence of code
		guard
			let authCode = redirectComponents.queryItems?.first(where: {
				$0.name == "code"
			})?.value
		else {
			throw OAuthError.redirectMissingComponents
		}

		guard state == expectedState else {
			throw OAuthError.stateTokenMismatch(state, expectedState)
		}

		guard iss == authServerMetadata.issuer else {
			throw
				OAuthError
				.issuingServerMismatch(iss, authServerMetadata.issuer)
		}

		return .init(
			authCode: authCode,
			issuer: iss,
			components: redirectComponents
		)
	}

	public struct ParsedRedirect {
		public let authCode: String?
		public let issuer: String

		public let components: URLComponents
	}

	static func processRefreshTokenResponse(
		response: HTTPDataResponse
	) throws -> TokenEndpointResponse {
		try processGenericAccessToken(response: response)
	}

	static func processGenericAccessToken(
		response: HTTPDataResponse
	) throws -> TokenEndpointResponse {
		let decoded: TokenEndpointResponse =
			try response
			.expect(successCode: 200)
			.decode()

		return decoded
	}
}

extension HTTPFetcher {
	//should not redirect
	public func resourceDiscoveryRequest(
		url: URL,
	) async throws -> ProtectedResourceMetadata {
		//TODO: should properly prepend, not append
		let url = url.appending(
			path: "/.well-known/oauth-protected-resource"
		)

		var request = URLRequest(url: url)
		request.httpMethod = HTTPMethod.get.rawValue
		request.setValue("application/json", forHTTPHeaderField: "accept")

		return try await performDiscovery(request: request)
			.expectSuccess()
			.decode()

	}

	public func authServerDiscovery(issuer: URL) async throws -> AuthServerMetadata {
		let url = issuer.appending(
			path: "/.well-known/oauth-authorization-server"
		)

		var request = URLRequest(url: url)
		request.httpMethod = HTTPMethod.get.rawValue
		request.setValue("application/json", forHTTPHeaderField: "accept")

		return try await performDiscovery(request: request)
			.expect(successCode: 200)
			.decode()
	}

	func performDiscovery(
		request: URLRequest
	) async throws -> HTTPDataResponse {
		guard request.url?.scheme == "https" else {
			throw OAuthError.insecureScheme
		}
		return try await data(for: request)
	}
}

extension OAuthComponents {
	static func refreshTokenGrantRequest(
		authServerMetadata: AuthServerMetadata,
		refreshToken: String,
		authServerRequestOptions: AuthServerRequestOptions,
	) async throws -> HTTPDataResponse {
		var parameters = authServerRequestOptions.additionalParameters
		parameters["refresh_token"] = refreshToken

		return try await tokenEndpointRequest(
			authServerMetadata: authServerMetadata,
			grantType: .refreshToken,
			parameters: parameters,
			headers: [:],
			authFetcher: authServerRequestOptions.authFetcher
		)
	}

	static func tokenEndpointRequest(
		authServerMetadata: AuthServerMetadata,
		grantType: GrantType,
		parameters: [String: String],
		headers: [String: String],
		authFetcher: HTTPFetcher
	) async throws -> HTTPDataResponse {
		let url = try authServerMetadata.resolve(endpoint: .token)

		var modifiedParams = parameters
		modifiedParams["grant_type"] = grantType.rawValue

		var headers = headers
		headers["accept"] = "application/json"
		headers["content-type"] = "application/x-www-form-urlencoded;charset=UTF-8"

		var request = URLRequest(url: url)
		for (key, value) in headers {
			request.setValue(value, forHTTPHeaderField: key)
		}

		request.httpMethod = HTTPMethod.post.rawValue
		let paramsString =
			try modifiedParams
			.map({ [$0, $1].joined(separator: "=") })
			.joined(separator: "&")
		request.httpBody = try modifiedParams.urlEncodedHTTPBody

		if let dpopSigner = self as? DPoPSigning {
			return try await dpopSigner.authenticated(
				request: request,
				token: nil,
				fetcher: authFetcher
			)
		} else {
			return try await authFetcher.data(for: request)
		}
	}
}
