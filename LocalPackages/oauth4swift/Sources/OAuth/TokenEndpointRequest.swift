//
//  TokenEndpointRequest.swift
//  OAuth
//
//  Created by Mark @ Germ on 3/4/26.
//

import Foundation
import GermConvenience

enum GrantType: String {
	case authorizationCode = "authorization_code"
	case refreshToken = "refresh_token"
}

//make this a protocol so both the Authorizer and Session can use it
public protocol AuthRequestable: Actor {
	var additionalParameters: [String: String] { get }
	func manualRedirectFetch(request: URLRequest) async throws -> HTTPDataResponse
	func validate(
		authMetadata: AuthServerMetadata,
		tokenResponse: TokenEndpointResponse
	) throws -> SessionState.Mutable
	var lazyIssuer: LazyResource<URL> { get }
}

extension AuthRequestable {
	//initially rely on network stack caching
	func getAuthServerMetadata() async throws -> AuthServerMetadata {
		try await authServerDiscovery(
			issuer: lazyIssuer.lazyValue(isolation: self)
		)
		.successDecode(successCode: 200)
	}

	private func authServerDiscovery(issuer: URL) async throws -> HTTPDataResponse {
		guard issuer.scheme == "https" else {
			throw OAuthError.insecureScheme
		}
		//NOTE: oauth4web prepends this to the incoming path,
		let requestUrl = issuer.appending(path: "/.well-known/oauth-authorization-server")
		var request = URLRequest(url: requestUrl)
		request.setValue("application/json", forHTTPHeaderField: "Accept")
		request.httpMethod = HTTPMethod.get.rawValue

		return try await manualRedirectFetch(request: request)
	}

	func refreshTokenGrantRequest(
		authServerMetadata: AuthServerMetadata,
		refreshToken: String
	) async throws -> HTTPDataResponse {
		var parameters = additionalParameters
		parameters["refresh_token"] = refreshToken

		return try await tokenEndpointRequest(
			authServerMetadata: authServerMetadata,
			grantType: .refreshToken,
			parameters: parameters,
			headers: [:]
		)
	}

	func processRefreshTokenResponse(
		response: HTTPDataResponse
	) throws -> TokenEndpointResponse {
		try OAuth.processGenericAccessToken(response: response)
	}

	func tokenEndpointRequest(
		authServerMetadata: AuthServerMetadata,
		grantType: GrantType,
		parameters: [String: String],
		headers: [String: String]
	) async throws -> HTTPDataResponse {
		let url = try authServerMetadata.resolve(endpoint: .token)

		var modifiedParams = parameters
		modifiedParams["grant_type"] = grantType.rawValue

		var headers = headers
		//swift4web sets the "accept" header, but both may be appropriate
		headers["accept"] = "application/json"
		headers["Content-Type"] = "application/json"
		//swift4web sets the "accept" header, but Content-Type seems

		var request = URLRequest(url: url)

		if let dpopSigner = self as? DPoPSigning {
			try dpopSigner.addProof(request: &request)
		}

		request.httpMethod = HTTPMethod.post.rawValue
		request.httpBody = try JSONEncoder().encode(headers)

		let response = try await authenticated(request: request)
		if let dpopSigner = self as? DPoPSigning {
			try dpopSigner.cacheNonce(response: response.response, requestUrl: url)
		}

		return response
	}

	//here for shadowing of oauth4web.authenticatedRequest
	//but most functionality has been lifted out
	func authenticated(request: URLRequest) async throws -> HTTPDataResponse {
		return try await manualRedirectFetch(request: request)
	}
}
